/*====================================================================
Project:		Labor Transitions and Poverty/Vulnerability Analysis - Argentina
Author:			Luis Castellanos (lcastellanosrodr@worldbank.org)
Team:			Stats Team - World Bank	
Country:		Argentina
Creation Date:	2025/11/14
Modified Date:	2025/11/14

====================================================================
PURPOSE: 
This code creates a regression-ready dataset for analyzing household labor 
transitions and their relationship to poverty/vulnerability outcomes in Argentina.

METHODOLOGY:
1. Takes panel data (2021-2023) and analyzes TWO transition periods:
   - Period 1: 2021-2022
   - Period 2: 2022-2023
2. Creates baseline (t0) and endline (t1) measures for EACH period:
   - Socioeconomic status (poverty, vulnerability, income)
   - Labor market status (employment, skill level, sector)
3. Constructs transition variables for each period
4. Pools both periods into single dataset with period fixed effects
5. Runs regression specifications examining how labor transitions affect
   poverty/vulnerability transitions, controlling for demographics

OUTPUT:
- One observation per household head per period (up to 2 rows per household)
- Four regression outputs: falling/escaping poverty/vulnerability
- Compatible with Peru and Brazil codes for multi-country pooled analysis
*=================================================================*/

clear all
set more off

**# ==============================================================================
**# 0. SETUP AND MACROS DEFINITION
**# ==============================================================================

* Define macros for flexible path management
global input_path "C:\Users\wb593225\OneDrive - WBG\Desktop\Shared\FY2025\2021PPP\Vulnerability line\Data\Argentina"
global dataset_name "01_ARG_SEDLAC_Panel_2016_2024.dta"
global output_path "C:\Users\wb593225\OneDrive - WBG\Desktop\Shared\FY2025\2021PPP\Vulnerability line\Output\ARG\Regressions Brief"
global save_path "C:\Users\wb593225\OneDrive - WBG\Desktop\Shared\FY2025\2021PPP\Vulnerability line\Data"

* Create output directory if it doesn't exist
cap mkdir "$output_path"
cap mkdir "$save_path"

* Define poverty and vulnerability lines in 2021 PPP terms
global poverty_line_monthly_2021ppp = 8.30*(365/12)
global vul_line_monthly = 17.0*(365/12)

* Set period parameters for pooled analysis
local period1_t0 = 2021
local period1_t1 = 2022
local period2_t0 = 2022  
local period2_t1 = 2023
local period_desc "Pooled 2021-2022 & 2022-2023"

noi di ""
noi di "=== LABOR TRANSITIONS ANALYSIS: ARGENTINA 2021-2022 & 2022-2023 ==="
noi di "Dataset: $input_path/$dataset_name"
noi di "Output: $output_path"
noi di ""

**# ==============================================================================
**# 1. DATA LOADING AND SAMPLE PREPARATION
**# ==============================================================================

* Load dataset
use "$input_path/$dataset_name", clear

* Step 0: CREATE PARTNER INDICATORS BEFORE FILTERING
* Create partner presence indicators at household level for each year
bysort idp_h: egen has_partner_2021 = max((relacion == 2) * (ano == 2021)) if !missing(relacion)
bysort idp_h: egen has_partner_2022 = max((relacion == 2) * (ano == 2022)) if !missing(relacion)
bysort idp_h: egen has_partner_2023 = max((relacion == 2) * (ano == 2023)) if !missing(relacion)

* Step 1: Keep only household heads and identify those present in transition periods
keep if jefe == 1
sort idp_i ano

* Keep only years needed for analysis (2021, 2022, 2023)
keep if inlist(ano, 2021, 2022, 2023)

* Create indicators for presence in each year
by idp_i: egen has_2021 = max(ano == 2021)
by idp_i: egen has_2022 = max(ano == 2022)
by idp_i: egen has_2023 = max(ano == 2023)

* Identify households in each transition period
gen in_period1 = (has_2021 == 1 & has_2022 == 1)  // 2021-2022 transition
gen in_period2 = (has_2022 == 1 & has_2023 == 1)  // 2022-2023 transition

* Keep households present in at least one transition period
keep if in_period1 == 1 | in_period2 == 1
keep if cohp == 1 & cohh == 1

* Filter to household heads with age > 15
keep if edad > 15

noi di "Sample after filtering to household heads with edad > 15: "
count

**# ==============================================================================
**# 2. EMPLOYMENT STATUS AND SKILL LEVEL CREATION
**# ==============================================================================

* Create employment status based on ocupado variable
gen employed = (ocupado == 1) if !missing(ocupado)

* Convert isco08_2d to string and handle missing values
gen isco08_2d_st = string(isco08_2d) if !missing(isco08_2d)
replace isco08_2d_st = "" if missing(isco08_2d)

* Extract the first digit from isco08_2d_st
gen isco08_1d = substr(isco08_2d_st, 1, 1) if isco08_2d_st != ""

* Create skill level variable (only for employed people)
gen skill_level = .
replace skill_level = 3 if inlist(isco08_1d, "1", "2", "3") & employed == 1
replace skill_level = 2 if inlist(isco08_1d, "4", "5", "6", "7", "8") & employed == 1
replace skill_level = 1 if isco08_1d == "9" & employed == 1

**# ==============================================================================
**# 3. SECTOR VARIABLE CREATION (for saving dataset)
**# ==============================================================================

* Create sector variable for all years (including not working category)
gen sector_clean = sector if !missing(sector) & ocupado == 1
replace sector_clean = 12 if ocupado == 0 | missing(ocupado)  // Not working category

* Apply same sector combinations as original code
gen temp_sector = sector_clean

* Combine manufacturing sectors and adjust categories
replace temp_sector = 2 if inlist(temp_sector, 2, 3)  // Manufacturing combined
replace temp_sector = 3 if temp_sector == 4   // Construction
replace temp_sector = 4 if temp_sector == 5   // Wholesale/retail
replace temp_sector = 5 if temp_sector == 6   // Transport/utilities
replace temp_sector = 6 if temp_sector == 7   // Real estate/finance
replace temp_sector = 7 if temp_sector == 8   // Public admin
replace temp_sector = 8 if temp_sector == 9   // Education/health
replace temp_sector = 9 if temp_sector == 10  // Other activities
replace temp_sector = 10 if temp_sector == 12 // Not working

**# ==============================================================================
**# 4. FUNCTION TO CREATE TRANSITION VARIABLES FOR EACH PERIOD
**# ==============================================================================

capture program drop create_transition_vars
program define create_transition_vars
    args t0 t1 suffix
    
    noi di "Creating transition variables for period `t0'-`t1'"
    
    * Create poverty status for both periods
    gen poor_`t0'`suffix' = (ipcf_ppp21 <= $poverty_line_monthly_2021ppp) if ano == `t0' & !missing(ipcf_ppp21)
    gen poor_`t1'`suffix' = (ipcf_ppp21 <= $poverty_line_monthly_2021ppp) if ano == `t1' & !missing(ipcf_ppp21)
    
    * Create vulnerability status for both periods
    gen vuln_`t0'`suffix' = (ipcf_ppp21 <= $vul_line_monthly) if ano == `t0' & !missing(ipcf_ppp21)
    gen vuln_`t1'`suffix' = (ipcf_ppp21 <= $vul_line_monthly) if ano == `t1' & !missing(ipcf_ppp21)
    
    * NEW: Create income level variables for both periods (ADDED FOR POOLED ANALYSIS)
    gen ipcf_ppp21_`t0'`suffix' = ipcf_ppp21 if ano == `t0'
    gen ipcf_ppp21_`t1'`suffix' = ipcf_ppp21 if ano == `t1'
    
    * Extend poverty and vulnerability status to both years for each individual
    sort idp_i ano
    by idp_i: egen poor_t0`suffix' = max(poor_`t0'`suffix')
    by idp_i: egen poor_t1`suffix' = max(poor_`t1'`suffix')
    by idp_i: egen vuln_t0`suffix' = max(vuln_`t0'`suffix')
    by idp_i: egen vuln_t1`suffix' = max(vuln_`t1'`suffix')
    
    * NEW: Extend income variables to both years for each individual (ADDED FOR POOLED ANALYSIS)
    by idp_i: egen ipcf_ppp21_t0`suffix' = max(ipcf_ppp21_`t0'`suffix')
    by idp_i: egen ipcf_ppp21_t1`suffix' = max(ipcf_ppp21_`t1'`suffix')
    
    * Create other time-varying variables for t0 and t1
    gen employed_`t0'`suffix' = employed if ano == `t0'
    gen employed_`t1'`suffix' = employed if ano == `t1'
    gen skill_level_`t0'`suffix' = skill_level if ano == `t0'
    gen skill_level_`t1'`suffix' = skill_level if ano == `t1'
    gen sector_`t0'`suffix' = temp_sector if ano == `t0'
    gen sector_`t1'`suffix' = temp_sector if ano == `t1'
    gen asistencia_`t0'`suffix' = asistencia if ano == `t0'
    gen asistencia_`t1'`suffix' = asistencia if ano == `t1'
    
    * Extend to all years for each individual
    by idp_i: egen employed_t0`suffix' = max(employed_`t0'`suffix')
    by idp_i: egen employed_t1`suffix' = max(employed_`t1'`suffix')
    by idp_i: egen skill_level_t0`suffix' = max(skill_level_`t0'`suffix')
    by idp_i: egen skill_level_t1`suffix' = max(skill_level_`t1'`suffix')
    by idp_i: egen sector_t0`suffix' = max(sector_`t0'`suffix')
    by idp_i: egen sector_t1`suffix' = max(sector_`t1'`suffix')
    by idp_i: egen asistencia_t0`suffix' = max(asistencia_`t0'`suffix')
    by idp_i: egen asistencia_t1`suffix' = max(asistencia_`t1'`suffix')
    
    * Create poverty transition outcomes (only falling and escaping)
    gen fell_into_poverty`suffix' = (poor_t0`suffix' == 0 & poor_t1`suffix' == 1)
    gen escaped_poverty`suffix' = (poor_t0`suffix' == 1 & poor_t1`suffix' == 0)
    
    * Create vulnerability transition outcomes (only falling and escaping)
    gen fell_into_vulnerability`suffix' = (vuln_t0`suffix' == 0 & vuln_t1`suffix' == 1)
    gen escaped_vulnerability`suffix' = (vuln_t0`suffix' == 1 & vuln_t1`suffix' == 0)
    
    * Employment transition variables
    gen entered_job`suffix' = (employed_t0`suffix' == 0 & employed_t1`suffix' == 1)
    gen exited_job`suffix' = (employed_t0`suffix' == 1 & employed_t1`suffix' == 0)
    
    * Job-to-job transitions (for those employed both periods)
    gen skill_increased`suffix' = (employed_t0`suffix'==1 & employed_t1`suffix'==1 & skill_level_t1`suffix' > skill_level_t0`suffix')
    gen skill_decreased`suffix' = (employed_t0`suffix'==1 & employed_t1`suffix'==1 & skill_level_t1`suffix' < skill_level_t0`suffix')
    
    * NEW: Same skill transition (remained employed with same skill level) (ADDED FOR POOLED ANALYSIS)
    gen same_skill`suffix' = (employed_t0`suffix'==1 & employed_t1`suffix'==1 & skill_level_t0`suffix' == skill_level_t1`suffix' & !missing(skill_level_t0`suffix') & !missing(skill_level_t1`suffix'))
    
    * Create skill level dummies for t0
    gen skill_level_1_t0`suffix' = (skill_level_t0`suffix' == 1)
    gen skill_level_2_t0`suffix' = (skill_level_t0`suffix' == 2)
    gen skill_level_3_t0`suffix' = (skill_level_t0`suffix' == 3)
    
    * Transfer changes (for dataset saving)
    gen stopped_transfers`suffix' = (asistencia_t0`suffix' == 1 & asistencia_t1`suffix' == 0) if !missing(asistencia_t0`suffix') & !missing(asistencia_t1`suffix')
    gen started_transfers`suffix' = (asistencia_t0`suffix' == 0 & asistencia_t1`suffix' == 1) if !missing(asistencia_t0`suffix') & !missing(asistencia_t1`suffix')
    replace stopped_transfers`suffix' = 0 if missing(stopped_transfers`suffix')
    replace started_transfers`suffix' = 0 if missing(started_transfers`suffix')
    
end

**# ==============================================================================
**# 5. CREATE CONTROL VARIABLES FUNCTION
**# ==============================================================================

capture program drop create_control_vars
program define create_control_vars
    args t0 t1 suffix
    
    noi di "Creating control variables for period starting `t0'"
    
    * Region clustering variable from t0
    encode region_est1, gen(region_est1_num)
    bysort idp_h idp_i: egen region_est1_t0`suffix' = max(region_est1_num * (ano == `t0'))
    
    * Household size and children (measured at t0)
    bysort idp_h: egen hh_members_t0`suffix' = max(miembros * (ano == `t0')) if !missing(miembros)
    bysort idp_h: egen hh_children_t0`suffix' = max(nro_hijos * (ano == `t0')) if !missing(nro_hijos)
    
    * Partner status controls
    * Partner status at t0
    bysort idp_h idp_i: egen partner_t0`suffix' = max(has_partner_`t0')
    
    * Household head education level at t0
    bysort idp_h idp_t: egen hh_head_education`suffix' = max(nivedu * jefe * (ano == `t0')) if !missing(nivedu) & !missing(jefe)
    
    * Health shock (for dataset saving, but won't use in regression)
    bysort idp_h: egen hh_head_health_shock`suffix' = max(enfermo * (ano == `t0')) if !missing(enfermo)
    
    * Age group variables based on gedad from t0 (baseline: gedad==2)
    bysort idp_h idp_i: egen gedad_t0`suffix' = max(gedad * (ano == `t0'))
    gen gedad_25_40`suffix' = (gedad_t0`suffix' == 3) if !missing(gedad_t0`suffix')
    gen gedad_41_64`suffix' = (gedad_t0`suffix' == 4) if !missing(gedad_t0`suffix') 
    gen gedad_65plus`suffix' = (gedad_t0`suffix' == 5) if !missing(gedad_t0`suffix')
    
    * Urban status at t0
    bysort idp_h idp_i: egen urbano_t0`suffix' = max(urbano * (ano == `t0'))
    
    * Gender (time-invariant but capture at t0)
    bysort idp_h idp_i: egen hombre_t0`suffix' = max(hombre * (ano == `t0'))
    
    * Working household members control (equals 1 if head employed at t0)
    gen n_workers_t0`suffix' = employed_t0`suffix'
    
end

**# ==============================================================================
**# 6. CREATE ANALYSIS DATASETS FOR EACH PERIOD
**# ==============================================================================

* Create transition variables for period 1 (2021-2022)
preserve
keep if in_period1 == 1
create_transition_vars `period1_t0' `period1_t1' "_p1"
create_control_vars `period1_t0' `period1_t1' "_p1"

* Keep only necessary variables and add period indicator
keep if ano == `period1_t0'  // Keep only baseline year
gen period = `period1_t0'  // Year FE indicator
gen period_id = 1  // Period identifier

* UPDATED: Keep all baseline/endline status variables for extended analysis
*keep idp_h idp_i period period_id ///
     fell_into_poverty_p1 escaped_poverty_p1 ///
     fell_into_vulnerability_p1 escaped_vulnerability_p1 ///
     poor_t0_p1 poor_t1_p1 vuln_t0_p1 vuln_t1_p1 ///
     ipcf_ppp21_t0_p1 ipcf_ppp21_t1_p1 ///
     employed_t0_p1 employed_t1_p1 skill_level_t0_p1 skill_level_t1_p1 ///
     entered_job_p1 exited_job_p1 skill_increased_p1 skill_decreased_p1 ///
     same_skill_p1 ///
     skill_level_1_t0_p1 skill_level_2_t0_p1 skill_level_3_t0_p1 ///
     stopped_transfers_p1 started_transfers_p1 ///
     sector_t0_p1 sector_t1_p1 asistencia_t0_p1 asistencia_t1_p1 ///
     region_est1_t0_p1 hh_members_t0_p1 hh_children_t0_p1 ///
     partner_t0_p1 ///
     hh_head_education_p1 hh_head_health_shock_p1 ///
     gedad_25_40_p1 gedad_41_64_p1 gedad_65plus_p1 ///
     urbano_t0_p1 hombre_t0_p1 n_workers_t0_p1 pondera

* Rename variables to common names
rename *_p1 *

tempfile period1_data
save `period1_data'
restore

* Create transition variables for period 2 (2022-2023)
preserve
keep if in_period2 == 1
create_transition_vars `period2_t0' `period2_t1' "_p2"
create_control_vars `period2_t0' `period2_t1' "_p2"

* Keep only necessary variables and add period indicator
keep if ano == `period2_t0'  // Keep only baseline year
gen period = `period2_t0'  // Year FE indicator
gen period_id = 2  // Period identifier

* UPDATED: Keep all baseline/endline status variables for extended analysis
*keep idp_h idp_i period period_id ///
     fell_into_poverty_p2 escaped_poverty_p2 ///
     fell_into_vulnerability_p2 escaped_vulnerability_p2 ///
     poor_t0_p2 poor_t1_p2 vuln_t0_p2 vuln_t1_p2 ///
     ipcf_ppp21_t0_p2 ipcf_ppp21_t1_p2 ///
     employed_t0_p2 employed_t1_p2 skill_level_t0_p2 skill_level_t1_p2 ///
     entered_job_p2 exited_job_p2 skill_increased_p2 skill_decreased_p2 ///
     same_skill_p2 ///
     skill_level_1_t0_p2 skill_level_2_t0_p2 skill_level_3_t0_p2 ///
     stopped_transfers_p2 started_transfers_p2 ///
     sector_t0_p2 sector_t1_p2 asistencia_t0_p2 asistencia_t1_p2 ///
     region_est1_t0_p2 hh_members_t0_p2 hh_children_t0_p2 ///
     partner_t0_p2 ///
     hh_head_education_p2 hh_head_health_shock_p2 ///
     gedad_25_40_p2 gedad_41_64_p2 gedad_65plus_p2 ///
     urbano_t0_p2 hombre_t0_p2 n_workers_t0_p2 pondera

* Rename variables to common names
rename *_p2 *

tempfile period2_data
save `period2_data'
restore

**# ==============================================================================
**# 7. COMBINE DATASETS AND CREATE FINAL VARIABLES
**# ==============================================================================

* Combine both periods
use `period1_data', clear
append using `period2_data'

noi di ""
noi di "Final pooled analysis sample:"
count

* Add country identifier for pooled analysis
gen country = "ARG"

* Create dummy variables for categorical controls
qui tab hh_head_education if !missing(hh_head_education), gen(educ_)

* Create sector dummies (for dataset saving)
qui tab sector_t0 if !missing(sector_t0), gen(sector_t0_)
qui tab sector_t1 if !missing(sector_t1), gen(sector_t1_)

**# ==============================================================================
**# 8. SAVE DATASET FOR POOLED ANALYSIS
**# ==============================================================================

noi di ""
noi di "=== SAVING DATASET FOR POOLED ANALYSIS ==="

save "$save_path/03_ARG_reg_data_2021-2023.dta", replace

noi di "Dataset saved: $save_path/03_ARG_reg_data_2021-2023.dta"

**# ==============================================================================
**# 9. DEFINE CONTROL SETS
**# ==============================================================================

* Modified control set (same as Peru/Brazil)
local controls_modified "urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ_2 educ_3 hh_members_t0 hh_children_t0 n_workers_t0"

**# ==============================================================================
**# 10. REGRESSION ANALYSIS 1: FALLING INTO POVERTY
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 1: FALLING INTO POVERTY ==="

count
local sample_size = r(N)
noi di "Sample size: `sample_size'"

if `sample_size' > 0 {
    * Column 1: With region FE
    noi di "Column 1: With region FE"
    areg fell_into_poverty skill_increased skill_decreased entered_job exited_job skill_level_2_t0 skill_level_3_t0 `controls_modified' i.period [pweight=pondera], absorb(region_est1_t0) cluster(region_est1_t0)
    estimates store reg01_col1
    
    * Column 2: Without region FE
    noi di "Column 2: Without region FE"  
    reg fell_into_poverty skill_increased skill_decreased entered_job exited_job skill_level_2_t0 skill_level_3_t0 `controls_modified' i.period i.region_est1_t0 [pweight=pondera], cluster(region_est1_t0)
    estimates store reg01_col2
}

**# ==============================================================================
**# 11. REGRESSION ANALYSIS 2: ESCAPING POVERTY
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 2: ESCAPING POVERTY ==="

if `sample_size' > 0 {
    * Column 1: With region FE
    noi di "Column 1: With region FE"
    areg escaped_poverty skill_increased skill_decreased entered_job exited_job skill_level_2_t0 skill_level_3_t0 `controls_modified' i.period [pweight=pondera], absorb(region_est1_t0) cluster(region_est1_t0)
    estimates store reg02_col1
    
    * Column 2: Without region FE
    noi di "Column 2: Without region FE"
    reg escaped_poverty skill_increased skill_decreased entered_job exited_job skill_level_2_t0 skill_level_3_t0 `controls_modified' i.period i.region_est1_t0 [pweight=pondera], cluster(region_est1_t0)
    estimates store reg02_col2
}

**# ==============================================================================
**# 12. REGRESSION ANALYSIS 3: FALLING INTO VULNERABILITY
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 3: FALLING INTO VULNERABILITY ==="

if `sample_size' > 0 {
    * Column 1: With region FE
    noi di "Column 1: With region FE"
    areg fell_into_vulnerability skill_increased skill_decreased entered_job exited_job skill_level_2_t0 skill_level_3_t0 `controls_modified' i.period [pweight=pondera], absorb(region_est1_t0) cluster(region_est1_t0)
    estimates store reg03_col1
    
    * Column 2: Without region FE
    noi di "Column 2: Without region FE"
    reg fell_into_vulnerability skill_increased skill_decreased entered_job exited_job skill_level_2_t0 skill_level_3_t0 `controls_modified' i.period i.region_est1_t0 [pweight=pondera], cluster(region_est1_t0)
    estimates store reg03_col2
}

**# ==============================================================================
**# 13. REGRESSION ANALYSIS 4: ESCAPING VULNERABILITY
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 4: ESCAPING VULNERABILITY ==="

if `sample_size' > 0 {
    * Column 1: With region FE
    noi di "Column 1: With region FE"
    areg escaped_vulnerability skill_increased skill_decreased entered_job exited_job skill_level_2_t0 skill_level_3_t0 `controls_modified' i.period [pweight=pondera], absorb(region_est1_t0) cluster(region_est1_t0)
    estimates store reg04_col1
    
    * Column 2: Without region FE
    noi di "Column 2: Without region FE"
    reg escaped_vulnerability skill_increased skill_decreased entered_job exited_job skill_level_2_t0 skill_level_3_t0 `controls_modified' i.period i.region_est1_t0 [pweight=pondera], cluster(region_est1_t0)
    estimates store reg04_col2
}

**# ==============================================================================
**# 14. EXPORT REGRESSION TABLES
**# ==============================================================================

noi di ""
noi di "=== EXPORTING REGRESSION TABLES ==="

* Export Regression 1: Falling into Poverty
cap estimates table reg01_col1 reg01_col2
if _rc == 0 {
    estimates restore reg01_col1
    outreg2 using "$output_path/01_falling_poverty_ARG.xls", ///
        replace excel label title("Falling into Poverty - Argentina") ///
        addstat(Adjusted R-squared, e(r2_a)) addtext(Year FE, Yes, Regional FE, Yes) ///
        ctitle("With Region FE")
    
    estimates restore reg01_col2
    outreg2 using "$output_path/01_falling_poverty_ARG.xls", ///
        append excel label addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Year FE, Yes, Regional FE, No) ctitle("Without Region FE")
}

* Export Regression 2: Escaping Poverty  
cap estimates table reg02_col1 reg02_col2
if _rc == 0 {
    estimates restore reg02_col1
    outreg2 using "$output_path/02_escaping_poverty_ARG.xls", ///
        replace excel label title("Escaping Poverty - Argentina") ///
        addstat(Adjusted R-squared, e(r2_a)) addtext(Year FE, Yes, Regional FE, Yes) ///
        ctitle("With Region FE")
    
    estimates restore reg02_col2
    outreg2 using "$output_path/02_escaping_poverty_ARG.xls", ///
        append excel label addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Year FE, Yes, Regional FE, No) ctitle("Without Region FE")
}

* Export Regression 3: Falling into Vulnerability
cap estimates table reg03_col1 reg03_col2
if _rc == 0 {
    estimates restore reg03_col1
    outreg2 using "$output_path/03_falling_vulnerability_ARG.xls", ///
        replace excel label title("Falling into Vulnerability - Argentina") ///
        addstat(Adjusted R-squared, e(r2_a)) addtext(Year FE, Yes, Regional FE, Yes) ///
        ctitle("With Region FE")
    
    estimates restore reg03_col2
    outreg2 using "$output_path/03_falling_vulnerability_ARG.xls", ///
        append excel label addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Year FE, Yes, Regional FE, No) ctitle("Without Region FE")
}

* Export Regression 4: Escaping Vulnerability
cap estimates table reg04_col1 reg04_col2
if _rc == 0 {
    estimates restore reg04_col1
    outreg2 using "$output_path/04_escaping_vulnerability_ARG.xls", ///
        replace excel label title("Escaping Vulnerability - Argentina") ///
        addstat(Adjusted R-squared, e(r2_a)) addtext(Year FE, Yes, Regional FE, Yes) ///
        ctitle("With Region FE")
    
    estimates restore reg04_col2
    outreg2 using "$output_path/04_escaping_vulnerability_ARG.xls", ///
        append excel label addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Year FE, Yes, Regional FE, No) ctitle("Without Region FE")
}

**# ==============================================================================
**# 15. SUMMARY
**# ==============================================================================

noi di ""
noi di "=== ANALYSIS COMPLETED ==="
noi di ""
noi di "SPECIFICATIONS APPLIED:"
noi di "  - Pooled analysis: 2021-2022 and 2022-2023"
noi di "  - Partner controls based on relacion==2"
noi di "  - Same modified control set as Peru/Brazil"
noi di "  - Vulnerability analysis (17.0 USD/day threshold)"
noi di "  - Two-column format: With/Without region FE"
noi di "  - Year fixed effects included via i.period"
noi di ""
noi di "NEW VARIABLES ADDED FOR POOLED ANALYSIS COMPATIBILITY:"
noi di "  - ipcf_ppp21_t0, ipcf_ppp21_t1: Income at baseline and endline"
noi di "  - same_skill: Remained employed with same skill level"
noi di "  - poor_t0, poor_t1: Poverty status at baseline and endline"
noi di "  - vuln_t0, vuln_t1: Vulnerability status at baseline and endline"
noi di "  - sector_t1: Sector at endline (in addition to sector_t0)"
noi di "  - asistencia_t0, asistencia_t1: Transfer status at both periods"
noi di ""
noi di "BASELINE/ENDLINE STATUS VARIABLES PRESERVED:"
noi di "  - poor_t0, poor_t1: Poverty status at t0 and t1"
noi di "  - vuln_t0, vuln_t1: Vulnerability status at t0 and t1"
noi di "  - employed_t0, employed_t1: Employment status at t0 and t1"
noi di "  - skill_level_t0, skill_level_t1: Skill levels at t0 and t1"
noi di "  - sector_t0, sector_t1: Sector at t0 and t1"
noi di "  - asistencia_t0, asistencia_t1: Transfer status at t0 and t1"
noi di ""
noi di "OUTPUTS GENERATED:"
noi di "  01_falling_poverty_ARG.xls"
noi di "  02_escaping_poverty_ARG.xls" 
noi di "  03_falling_vulnerability_ARG.xls"
noi di "  04_escaping_vulnerability_ARG.xls"
noi di ""
noi di "DATASET SAVED:"
noi di "  03_ARG_reg_data_2021-2023.dta"
noi di "  (Contains up to 2 observations per household: one for each transition period)"
noi di ""
