/*====================================================================
Project:		Pooled Labor Transitions Analysis - 5 LAC Countries
Author:			Luis Castellanos (lcastellanosrodr@worldbank.org)
Creation Date:	2025/11/19
Modified:       2025/11/19
====================================================================
PURPOSE: Pooled analysis across PER, BRA, ARG, DOM, SLV for labor transitions
         and poverty/vulnerability outcomes with orginal weights for each country.
         
OUTPUTS: 
- Single Excel file with 4 outcomes (going into/out of poverty and middle class)
- Additional Excel file with coefficients×100, SE×100, and CI for graphs
*=================================================================*/

clear all
set more off
set maxvar 10000

**# ==============================================================================
**# 0. SETUP AND PATHS
**# ==============================================================================

global data_path "C:\Users\wb593225\OneDrive - WBG\Desktop\Shared\FY2025\2021PPP\Vulnerability line\Data"
global output_path "C:\Users\wb593225\OneDrive - WBG\Desktop\Shared\FY2025\2021PPP\Vulnerability line\Output"

cap mkdir "$output_path"

**# ==============================================================================
**# 1. IMPORT AND APPEND COUNTRY DATASETS
**# ==============================================================================

* Define countries, file numbers, and periods
local countries "PER BRA ARG DOM SLV"
local file_numbers "01 02 03 04 05"
local periods "2021-2023 2022-2023 2021-2023 2021-2023 2022-2023"

* Variables to keep for analysis
local keep_vars "id* peri* ano region_est1_t0 pondera same_skill entered_job exited_job skill_increased skill_decreased poor_t0 vuln_t0 fell_into_poverty escaped_poverty fell_into_vulnerability escaped_vulnerability urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ* hh_children_t0 n_workers_t0 skill_level_2_t0 skill_level_3_t0 employed_t0 employed_t1 hh_members_t0"

tempfile combined_data

forvalues i = 1/5 {
    local country : word `i' of `countries'
    local file_num : word `i' of `file_numbers'
    local period_range : word `i' of `periods'
    
    use "${data_path}/`file_num'_`country'_reg_data_`period_range'.dta", clear
    keep `keep_vars'
    
    * Handle country-specific variable transformations
    if "`country'" == "SLV" {
        cap confirm variable idp_h
        if _rc {
            cap confirm variable idh
            if !_rc encode idh, gen(idp_h)
        }
        cap confirm variable idp_i
        if _rc {
            cap confirm variable idi
            if !_rc encode idi, gen(idp_i)
        }
        cap confirm variable period
        if _rc {
            cap confirm variable ano
            if !_rc gen period = ano
        }
    }
    
    if "`country'" == "BRA" {
        cap confirm variable period
        if _rc {
            cap confirm variable ano
            if !_rc gen period = ano
        }
    }
    
    * Add country identifier
    cap confirm variable country
    if _rc gen country = "`country'"
    else replace country = "`country'"
    
    if `i' == 1 {
        save `combined_data'
    }
    else {
        append using `combined_data', force
        save `combined_data', replace
    }
}

use `combined_data', clear

**# ==============================================================================
**# 2. CREATE POOLED VARIABLES AND WEIGHTS
**# ==============================================================================

* Create country-region fixed effects
gen country_region_str = country + "_" + string(region_est1_t0) if !missing(region_est1_t0)
encode country_region_str, gen(country_region)

* Create equal-weight variable (sum to 100 per country)
bysort country: egen total_weight_country = total(pondera) if !missing(pondera)
gen weight_equal = (pondera / total_weight_country) * 100 if !missing(pondera) & !missing(total_weight_country)

* Create country and period fixed effects
encode country, gen(country_fe)
tab period, gen(period_fe_) missing

* Create stayed_employed indicator (employed at both t0 and t1)
gen stayed_employed = (employed_t0 == 1 & employed_t1 == 1)

**# ==============================================================================
**# 3. DEFINE REGRESSION SPECIFICATIONS
**# ==============================================================================

* Labor transition variables (reference: remained unemployed at both t0 and t1)
local transitions "entered_job exited_job skill_increased skill_decreased stayed_employed"

* Control variables
local controls "urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ_2 educ_3 hh_members_t0 hh_children_t0"

* Fixed effects
local fe "i.country_fe i.period"

**# ==============================================================================
**# 4. RUN REGRESSIONS FOR ALL FOUR OUTCOMES
**# ==============================================================================

* (1) Going into poverty: poor_t0 == 0
reg fell_into_poverty `transitions' `controls' `fe' [pweight=pondera] if poor_t0 == 0, robust
estimates store col1_into_poverty
matrix b1 = e(b)
matrix V1 = e(V)

* (2) Going out of poverty: poor_t0 == 1  
reg escaped_poverty `transitions' `controls' `fe' [pweight=pondera] if poor_t0 == 1, robust
estimates store col2_out_poverty
matrix b2 = e(b)
matrix V2 = e(V)

* (3) Going out of middle class (falling into vulnerability): vuln_t0 == 0
reg fell_into_vulnerability `transitions' `controls' `fe' [pweight=pondera] if vuln_t0 == 0, robust
estimates store col3_out_middle
matrix b3 = e(b)
matrix V3 = e(V)

* (4) Going into middle class (escaping vulnerability): vuln_t0 == 1 & poor_t0 == 0
reg escaped_vulnerability `transitions' `controls' `fe' [pweight=pondera] if vuln_t0 == 1 & poor_t0 == 0, robust
estimates store col4_into_middle
matrix b4 = e(b)
matrix V4 = e(V)

**# ==============================================================================
**# 5. EXPORT MAIN RESULTS TO SINGLE EXCEL FILE
**# ==============================================================================

estimates restore col1_into_poverty
outreg2 using "${output_path}/24_LAC_5_countries_pondera.xls", ///
    replace excel label ///
    title("Pooled Labor Transitions Analysis - 5 LAC Countries") ///
    ctitle("(1) Into Poverty") ///
    addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
    addtext(Country FE, Yes, Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Non-poor at t0")

estimates restore col2_out_poverty
outreg2 using "${output_path}/24_LAC_5_countries_pondera.xls", ///
    append excel label ctitle("(2) Out of Poverty") ///
    addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
    addtext(Country FE, Yes, Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Poor at t0")

estimates restore col3_out_middle
outreg2 using "${output_path}/24_LAC_5_countries_pondera.xls", ///
    append excel label ctitle("(3) Out of Middle Class") ///
    addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
    addtext(Country FE, Yes, Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")

estimates restore col4_into_middle
outreg2 using "${output_path}/24_LAC_5_countries_pondera.xls", ///
    append excel label ctitle("(4) Into Middle Class") ///
    addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
    addtext(Country FE, Yes, Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")

**# ==============================================================================
**# 6. CREATE GRAPHICAL OUTPUT FILE (COEFFICIENTS × 100, SE × 100, CI)
**# ==============================================================================

* Extract position of each labor transition variable in coefficient vectors
local varlist "entered_job exited_job skill_increased skill_decreased stayed_employed"
local nvar : word count `varlist'

* Initialize matrices for output
matrix graph_out = J(`=3*`nvar'', 4, .)
matrix rownames graph_out = ///
    "Job_Entry_Coef" "Job_Entry_SE" "Job_Entry_CI" ///
    "Job_Exit_Coef" "Job_Exit_SE" "Job_Exit_CI" ///
    "Skill_Upgrade_Coef" "Skill_Upgrade_SE" "Skill_Upgrade_CI" ///
    "Skill_Downgrade_Coef" "Skill_Downgrade_SE" "Skill_Downgrade_CI" ///
    "Stayed_Employed_Coef" "Stayed_Employed_SE" "Stayed_Employed_CI"
matrix colnames graph_out = "Into_Poverty" "Out_Poverty" "Out_Middle" "Into_Middle"

* Fill matrix for each variable and outcome
forvalues v = 1/`nvar' {
    local var : word `v' of `varlist'
    local row_base = (`v' - 1) * 3 + 1
    
    * Column 1: Into poverty
    local pos1 = colnumb(b1, "`var'")
    if `pos1' != . {
        matrix graph_out[`row_base', 1] = b1[1, `pos1'] * 100
        matrix graph_out[`=`row_base'+1', 1] = sqrt(V1[`pos1', `pos1']) * 100
        matrix graph_out[`=`row_base'+2', 1] = 1.96 * sqrt(V1[`pos1', `pos1']) * 100
    }
    
    * Column 2: Out of poverty
    local pos2 = colnumb(b2, "`var'")
    if `pos2' != . {
        matrix graph_out[`row_base', 2] = b2[1, `pos2'] * 100
        matrix graph_out[`=`row_base'+1', 2] = sqrt(V2[`pos2', `pos2']) * 100
        matrix graph_out[`=`row_base'+2', 2] = 1.96 * sqrt(V2[`pos2', `pos2']) * 100
    }
    
    * Column 3: Out of middle class
    local pos3 = colnumb(b3, "`var'")
    if `pos3' != . {
        matrix graph_out[`row_base', 3] = b3[1, `pos3'] * 100
        matrix graph_out[`=`row_base'+1', 3] = sqrt(V3[`pos3', `pos3']) * 100
        matrix graph_out[`=`row_base'+2', 3] = 1.96 * sqrt(V3[`pos3', `pos3']) * 100
    }
    
    * Column 4: Into middle class
    local pos4 = colnumb(b4, "`var'")
    if `pos4' != . {
        matrix graph_out[`row_base', 4] = b4[1, `pos4'] * 100
        matrix graph_out[`=`row_base'+1', 4] = sqrt(V4[`pos4', `pos4']) * 100
        matrix graph_out[`=`row_base'+2', 4] = 1.96 * sqrt(V4[`pos4', `pos4']) * 100
    }
}

* Export to Excel
putexcel set "${output_path}/24_LAC_5_countries_graph_data_pondera.xlsx", replace

* Write headers
putexcel A1 = "Labor Transition" B1 = "Into Poverty" C1 = "Out of Poverty" ///
         D1 = "Out of Middle Class" E1 = "Into Middle Class"

* Job Entry
putexcel A2 = "Job Entry"
putexcel B2 = matrix(graph_out[1,1]) C2 = matrix(graph_out[1,2]) ///
         D2 = matrix(graph_out[1,3]) E2 = matrix(graph_out[1,4])
putexcel A3 = "SE"
putexcel B3 = matrix(graph_out[2,1]) C3 = matrix(graph_out[2,2]) ///
         D3 = matrix(graph_out[2,3]) E3 = matrix(graph_out[2,4])
putexcel A4 = "CI"
putexcel B4 = matrix(graph_out[3,1]) C4 = matrix(graph_out[3,2]) ///
         D4 = matrix(graph_out[3,3]) E4 = matrix(graph_out[3,4])

* Job Exit
putexcel A6 = "Job Exit"
putexcel B6 = matrix(graph_out[4,1]) C6 = matrix(graph_out[4,2]) ///
         D6 = matrix(graph_out[4,3]) E6 = matrix(graph_out[4,4])
putexcel A7 = "SE"
putexcel B7 = matrix(graph_out[5,1]) C7 = matrix(graph_out[5,2]) ///
         D7 = matrix(graph_out[5,3]) E7 = matrix(graph_out[5,4])
putexcel A8 = "CI"
putexcel B8 = matrix(graph_out[6,1]) C8 = matrix(graph_out[6,2]) ///
         D8 = matrix(graph_out[6,3]) E8 = matrix(graph_out[6,4])

* Skill Upgrade
putexcel A10 = "Skill Upgrade"
putexcel B10 = matrix(graph_out[7,1]) C10 = matrix(graph_out[7,2]) ///
         D10 = matrix(graph_out[7,3]) E10 = matrix(graph_out[7,4])
putexcel A11 = "SE"
putexcel B11 = matrix(graph_out[8,1]) C11 = matrix(graph_out[8,2]) ///
         D11 = matrix(graph_out[8,3]) E11 = matrix(graph_out[8,4])
putexcel A12 = "CI"
putexcel B12 = matrix(graph_out[9,1]) C12 = matrix(graph_out[9,2]) ///
         D12 = matrix(graph_out[9,3]) E12 = matrix(graph_out[9,4])

* Skill Downgrade
putexcel A14 = "Skill Downgrade"
putexcel B14 = matrix(graph_out[10,1]) C14 = matrix(graph_out[10,2]) ///
         D14 = matrix(graph_out[10,3]) E14 = matrix(graph_out[10,4])
putexcel A15 = "SE"
putexcel B15 = matrix(graph_out[11,1]) C15 = matrix(graph_out[11,2]) ///
         D15 = matrix(graph_out[11,3]) E15 = matrix(graph_out[11,4])
putexcel A16 = "CI"
putexcel B16 = matrix(graph_out[12,1]) C16 = matrix(graph_out[12,2]) ///
         D16 = matrix(graph_out[12,3]) E16 = matrix(graph_out[12,4])

* Stayed Employed
putexcel A18 = "Stayed Employed"
putexcel B18 = matrix(graph_out[13,1]) C18 = matrix(graph_out[13,2]) ///
         D18 = matrix(graph_out[13,3]) E18 = matrix(graph_out[13,4])
putexcel A19 = "SE"
putexcel B19 = matrix(graph_out[14,1]) C19 = matrix(graph_out[14,2]) ///
         D19 = matrix(graph_out[14,3]) E19 = matrix(graph_out[14,4])
putexcel A20 = "CI"
putexcel B20 = matrix(graph_out[15,1]) C20 = matrix(graph_out[15,2]) ///
         D20 = matrix(graph_out[15,3]) E20 = matrix(graph_out[15,4])

**# ==============================================================================
**# 7. SAVE POOLED DATASET
**# ==============================================================================

gen dataset_version = "23_LAC_5_pooled"
gen analysis_date = date(c(current_date), "DMY")
format analysis_date %td

save "${data_path}/23_LAC_5_pooled.dta", replace

**# ==============================================================================
**# 8. SUMMARY
**# ==============================================================================

noi di ""
noi di "=== POOLED ANALYSIS COMPLETED ==="
noi di ""
noi di "OUTPUTS GENERATED:"
noi di "  1. ${output_path}/24_LAC_5_countries_pondera.xls"
noi di "     - Main regression results with 4 columns"
noi di "  2. ${output_path}/24_LAC_5_countries_graph_data_pondera.xlsx"
noi di "     - Coefficients × 100, SE × 100, and CI for graphs"
noi di "  3. ${data_path}/23_LAC_5_pooled.dta"
noi di "     - Combined dataset"
noi di ""
noi di "SPECIFICATION:"
noi di "  - Labor transitions: Job entry, Job exit, Skill upgrade, Skill downgrade, Stayed employed"
noi di "  - Reference category: Remained unemployed at both t0 and t1"
noi di "  - Original country weights"
noi di "  - Country and Year fixed effects"
noi di "  - Robust standard errors"
noi di ""
noi di "SAMPLE RESTRICTIONS:"
noi di "  - Into poverty: Non-poor at baseline (poor_t0==0)"
noi di "  - Out of poverty: Poor at baseline (poor_t0==1)"
noi di "  - Out of middle class: Non-vulnerable at baseline (vuln_t0==0)"
noi di "  - Into middle class: Vulnerable but not poor at baseline (vuln_t0==1 & poor_t0==0)"
noi di ""
noi di "=== ANALYSIS COMPLETE ==="
