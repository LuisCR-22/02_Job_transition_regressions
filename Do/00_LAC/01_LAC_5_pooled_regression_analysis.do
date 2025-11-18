/*====================================================================
Project:		Pooled Labor Transitions Analysis - 5 LAC Countries (Modified v4)
Author:			Luis Castellanos (lcastellanosrodr@worldbank.org)
Creation Date:	2025/01/15
Modified:       2025/01/15 - Optimized version with 4 columns per outcome
====================================================================
PURPOSE: Pooled analysis across PER, BRA, ARG, DOM, SLV for labor transitions
         and poverty/vulnerability outcomes with equal weights only.
         
KEY CHANGES IN V4:
- Added keep statement to preserve only necessary variables (memory efficient)
- Removed absorbed FE columns (old columns 3,4,7,8) - now only 4 columns per outcome
- Excel outputs only (no Word format)
- Changed output prefix from 18_ to 19_
- Improved efficiency and runtime
*=================================================================*/

clear all
set more off
set maxvar 10000

**# ==============================================================================
**# 0. SETUP AND PATHS
**# ==============================================================================

global data_path "C:\Users\wb593225\OneDrive - WBG\Desktop\Shared\FY2025\2021PPP\Vulnerability line\Data"
global output_path "C:\Users\wb593225\OneDrive - WBG\Desktop\Shared\FY2025\2021PPP\Vulnerability line\Output"

* Create output directory if it doesn't exist
cap mkdir "$output_path"

noi di ""
noi di "=== POOLED LABOR TRANSITIONS ANALYSIS: 5 LAC COUNTRIES (v4 - OPTIMIZED) ==="
noi di "Data path: $data_path"
noi di "Output: $output_path"
noi di ""

**# ==============================================================================
**# 1. IMPORT AND APPEND COUNTRY DATASETS (WITH EFFICIENT KEEP)
**# ==============================================================================

noi di "=== LOADING AND COMBINING COUNTRY DATASETS (OPTIMIZED) ==="

* Define countries, file numbers, and corresponding periods
local countries "PER BRA ARG DOM SLV"
local file_numbers "01 02 03 04 05"
local periods "2021-2023 2022-2023 2021-2023 2021-2023 2022-2023"

* Define variables to keep (all necessary for analysis)
local keep_vars "id* peri* ano region_est1_t0 pondera same_skill entered_job exited_job skill_increased skill_decreased poor_t0 vuln_t0 fell_into_poverty escaped_poverty fell_into_vulnerability escaped_vulnerability urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ* hh_members_t0 hh_children_t0 n_workers_t0 skill_level_2_t0 skill_level_3_t0"

tempfile combined_data

forvalues i = 1/5 {
    local country : word `i' of `countries'
    local file_num : word `i' of `file_numbers'
    local period_range : word `i' of `periods'
    
    noi di "Loading `country' data (Period: `period_range')..."
    use "${data_path}/`file_num'_`country'_reg_data_`period_range'.dta", clear
    
    * Keep only necessary variables for efficiency
    keep `keep_vars'
    
    * Handle SLV variable transformations
    if "`country'" == "SLV" {
        noi di "  - Checking/creating SLV variables..."
        
        * Check and create idp_h if needed
        cap confirm variable idp_h
        if _rc {
            cap confirm variable idh
            if !_rc {
                encode idh, gen(idp_h)
                noi di "    - Created idp_h from idh"
            }
        }
        
        * Check and create idp_i if needed
        cap confirm variable idp_i
        if _rc {
            cap confirm variable idi
            if !_rc {
                encode idi, gen(idp_i)
                noi di "    - Created idp_i from idi"
            }
        }
        
        * Check and create period if needed
        cap confirm variable period
        if _rc {
            cap confirm variable ano
            if !_rc {
                gen period = ano
                noi di "    - Created period from ano"
            }
        }
    }
    
    * Handle BRA variable transformations
    if "`country'" == "BRA" {
        noi di "  - Checking/creating BRA variables..."
        
        * Check and create period if needed
        cap confirm variable period
        if _rc {
            cap confirm variable ano
            if !_rc {
                gen period = ano
                noi di "    - Created period from ano"
            }
        }
    }
    
    * Add country identifier
    cap confirm variable country
    if _rc {
        gen country = "`country'"
    }
    else {
        replace country = "`country'"
    }
    
    noi di "  - `country': " _N " observations"
    
    if `i' == 1 {
        save `combined_data'
    }
    else {
        append using `combined_data', force
        save `combined_data', replace
    }
}

use `combined_data', clear

noi di ""
noi di "=== COMBINED DATASET SUMMARY ==="
noi di "Total observations: " _N
tab country, missing

**# ==============================================================================
**# 1B. VERIFY PANEL STRUCTURE (ESPECIALLY FOR SLV)
**# ==============================================================================

noi di ""
noi di "=== VERIFYING PANEL STRUCTURE BY COUNTRY ==="

foreach c in PER BRA ARG DOM SLV {
    noi di ""
    noi di "Country: `c'"
    
    * Check observations per individual
    bysort country idp_i: gen obs_check = _N if country == "`c'"
    qui sum obs_check if country == "`c'"
    noi di "  - Observations per individual: min=" r(min) " max=" r(max) " mean=" r(mean)
    
    * Count unique individuals
    bysort country idp_i: gen first_ind = (_n == 1) if country == "`c'"
    count if first_ind == 1 & country == "`c'"
    noi di "  - Unique individuals: " r(N)
    
    drop obs_check first_ind
}

noi di ""
noi di "If SLV shows max observations per individual > 1, the panel was not properly restricted!"

**# ==============================================================================
**# 2. CREATE POOLED VARIABLES AND WEIGHTS
**# ==============================================================================

noi di ""
noi di "=== CREATING POOLED VARIABLES AND WEIGHTS ==="

* Create country-region fixed effects
gen country_region_str = country + "_" + string(region_est1_t0) if !missing(region_est1_t0)
encode country_region_str, gen(country_region)

* Create equal-weight variable (sum to 100 per country)
bysort country: egen total_weight_country = total(pondera) if !missing(pondera)
gen weight_equal = (pondera / total_weight_country) * 100 if !missing(pondera) & !missing(total_weight_country)

* Verify equal weights sum to 100 per country
noi di "Checking equal weights by country:"
bysort country: egen check_sum = total(weight_equal)
bysort country: sum check_sum if _n == 1

* Create country and period fixed effects
encode country, gen(country_fe)
tab period, gen(period_fe_) missing

noi di "Countries in sample:"
tab country_fe, missing
noi di "Periods in sample:"  
tab period, missing
noi di "Country-regions created: " r(r) " unique combinations"

**# ==============================================================================
**# 2B. VERIFY VARIABLES AND TRANSITION CATEGORIES
**# ==============================================================================

noi di ""
noi di "=== VERIFYING VARIABLES AND LABOR TRANSITION CATEGORIES ==="

* Verify same_skill exists
cap confirm variable same_skill
if _rc {
    noi di "ERROR: same_skill variable not found in dataset!"
    exit 111
}
else {
    noi di "✓ same_skill variable found"
    label variable same_skill "Remained employed in same skill level"
}

* Verify sample restriction variables
cap confirm variable poor_t0
if _rc {
    noi di "ERROR: poor_t0 variable not found!"
    exit 111
}

cap confirm variable vuln_t0
if _rc {
    noi di "ERROR: vuln_t0 variable not found!"
    exit 111
}

noi di "✓ Sample restriction variables found"

* Display labor transition counts
noi di ""
noi di "=== LABOR TRANSITION CATEGORIES COUNTS ==="
count if entered_job == 1
noi di "  - Entered job: " r(N)
count if exited_job == 1
noi di "  - Exited job: " r(N)
count if skill_increased == 1
noi di "  - Skill increased: " r(N)
count if same_skill == 1
noi di "  - Same skill: " r(N)
count if skill_decreased == 1
noi di "  - Skill decreased: " r(N)
count if entered_job==0 & exited_job==0 & skill_increased==0 & skill_decreased==0 & same_skill==0 & !missing(entered_job)
noi di "  - Remained unemployed (reference): " r(N)

* Verify mutual exclusivity
gen transition_sum = entered_job + exited_job + skill_increased + skill_decreased + same_skill if !missing(entered_job)
count if transition_sum > 1 & !missing(transition_sum)
if r(N) > 0 {
    noi di "WARNING: " r(N) " observations with multiple transitions!"
}
else {
    noi di "✓ Categories are mutually exclusive"
}
drop transition_sum

* Display sample sizes for each outcome
noi di ""
noi di "=== SAMPLE SIZES BY OUTCOME-SPECIFIC RESTRICTIONS ==="
count if poor_t0 == 0 & !missing(fell_into_poverty)
noi di "Fell into poverty (poor_t0==0): " r(N)
count if poor_t0 == 1 & !missing(escaped_poverty)
noi di "Escaped poverty (poor_t0==1): " r(N)
count if vuln_t0 == 0 & !missing(fell_into_vulnerability)
noi di "Fell into vulnerability (vuln_t0==0): " r(N)
count if vuln_t0 == 1 & poor_t0 == 0 & !missing(escaped_vulnerability)
noi di "Escaped vulnerability (vuln_t0==1 & poor_t0==0): " r(N)

**# ==============================================================================
**# 2C. CREATE SLV-SPECIFIC CONTROL ADJUSTMENTS
**# ==============================================================================

noi di ""
noi di "=== ADJUSTING CONTROLS FOR SLV (NO EDUCATION DATA) ==="

* Create SLV-adjusted education variables
* For SLV: set to 0 (or missing) since education data not available
* For other countries: keep original values

replace educ_2 = 0 if country == "SLV"
replace educ_3 = 0 if country == "SLV"

**# ==============================================================================
**# 3. DEFINE REGRESSION SPECIFICATIONS
**# ==============================================================================

* Control variables
local controls "urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ_2 educ_3 hh_members_t0 hh_children_t0 n_workers_t0"

* Main labor transition variables - WITH same_skill + base skill levels
local main_with_skill_base "entered_job exited_job skill_increased same_skill skill_decreased skill_level_2_t0 skill_level_3_t0"

* Main labor transition variables - WITHOUT same_skill + base skill levels
local main_no_skill_base "entered_job exited_job skill_increased skill_decreased skill_level_2_t0 skill_level_3_t0"

* Main labor transition variables - WITH same_skill, NO base skill levels
local main_with_skill_nobase "entered_job exited_job skill_increased same_skill skill_decreased"

* Main labor transition variables - WITHOUT same_skill, NO base skill levels
local main_no_skill_nobase "entered_job exited_job skill_increased skill_decreased"

* Fixed effects
local fe_country_period "i.country_fe i.period"

noi di ""
noi di "=== REGRESSION SPECIFICATIONS (4 COLUMNS PER OUTCOME) ==="
noi di "Column 1: WITH same_skill + Country+Period FE + Full controls (includes base skill)"
noi di "Column 2: WITHOUT same_skill + Country+Period FE + Full controls (includes base skill)"
noi di "Column 3: WITH same_skill + Country+Period FE + Full controls (NO base skill)"
noi di "Column 4: WITHOUT same_skill + Country+Period FE + Full controls (NO base skill)"
noi di ""
noi di "Main variables (Col 1): `main_with_skill_base'"
noi di "Main variables (Col 2): `main_no_skill_base'"
noi di "Main variables (Col 3): `main_with_skill_nobase'"
noi di "Main variables (Col 4): `main_no_skill_nobase'"
noi di "Controls: `controls'"
noi di "Fixed effects: `fe_country_period'"
noi di "Reference category: Remained unemployed"
noi di "Clustering: Country-Region level"

**# ==============================================================================
**# 4. POOLED REGRESSIONS - FALLING INTO POVERTY (poor_t0==0)
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 1: FALLING INTO POVERTY (poor_t0==0) ==="

count if !missing(fell_into_poverty) & poor_t0 == 0
local sample_size = r(N)
noi di "Sample size: `sample_size'"

if `sample_size' > 0 {
    
    * Column 1: WITH same_skill, Equal weights, country+period FE, WITH base skill
    noi di "Column 1: WITH same_skill + base skill controls"
    reg fell_into_poverty `main_with_skill_base' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col1
    
    * Column 2: WITHOUT same_skill, Equal weights, country+period FE, WITH base skill
    noi di "Column 2: WITHOUT same_skill + base skill controls"
    reg fell_into_poverty `main_no_skill_base' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col2
    
    * Column 3: WITH same_skill, Equal weights, country+period FE, NO base skill
    noi di "Column 3: WITH same_skill, NO base skill controls"
    reg fell_into_poverty `main_with_skill_nobase' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col3
    
    * Column 4: WITHOUT same_skill, Equal weights, country+period FE, NO base skill
    noi di "Column 4: WITHOUT same_skill, NO base skill controls"
    reg fell_into_poverty `main_no_skill_nobase' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col4
}

**# ==============================================================================
**# 5. POOLED REGRESSIONS - ESCAPING POVERTY (poor_t0==1)
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 2: ESCAPING POVERTY (poor_t0==1) ==="

count if !missing(escaped_poverty) & poor_t0 == 1
local sample_size = r(N)
noi di "Sample size: `sample_size'"

if `sample_size' > 0 {
    
    * Column 1: WITH same_skill, Equal weights, country+period FE, WITH base skill
    noi di "Column 1: WITH same_skill + base skill controls"
    reg escaped_poverty `main_with_skill_base' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col1
    
    * Column 2: WITHOUT same_skill, Equal weights, country+period FE, WITH base skill
    noi di "Column 2: WITHOUT same_skill + base skill controls"
    reg escaped_poverty `main_no_skill_base' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col2
    
    * Column 3: WITH same_skill, Equal weights, country+period FE, NO base skill
    noi di "Column 3: WITH same_skill, NO base skill controls"
    reg escaped_poverty `main_with_skill_nobase' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col3
    
    * Column 4: WITHOUT same_skill, Equal weights, country+period FE, NO base skill
    noi di "Column 4: WITHOUT same_skill, NO base skill controls"
    reg escaped_poverty `main_no_skill_nobase' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col4
}

**# ==============================================================================
**# 6. POOLED REGRESSIONS - FALLING INTO VULNERABILITY (vuln_t0==0)
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 3: FALLING INTO VULNERABILITY (vuln_t0==0) ==="

count if !missing(fell_into_vulnerability) & vuln_t0 == 0
local sample_size = r(N)
noi di "Sample size: `sample_size'"

if `sample_size' > 0 {
    
    * Column 1: WITH same_skill, Equal weights, country+period FE, WITH base skill
    noi di "Column 1: WITH same_skill + base skill controls"
    reg fell_into_vulnerability `main_with_skill_base' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col1
    
    * Column 2: WITHOUT same_skill, Equal weights, country+period FE, WITH base skill
    noi di "Column 2: WITHOUT same_skill + base skill controls"
    reg fell_into_vulnerability `main_no_skill_base' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col2
    
    * Column 3: WITH same_skill, Equal weights, country+period FE, NO base skill
    noi di "Column 3: WITH same_skill, NO base skill controls"
    reg fell_into_vulnerability `main_with_skill_nobase' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col3
    
    * Column 4: WITHOUT same_skill, Equal weights, country+period FE, NO base skill
    noi di "Column 4: WITHOUT same_skill, NO base skill controls"
    reg fell_into_vulnerability `main_no_skill_nobase' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col4
}

**# ==============================================================================
**# 7. POOLED REGRESSIONS - ESCAPING VULNERABILITY (vuln_t0==1 & poor_t0==0)
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 4: ESCAPING VULNERABILITY (vuln_t0==1 & poor_t0==0) ==="

count if !missing(escaped_vulnerability) & vuln_t0 == 1 & poor_t0 == 0
local sample_size = r(N)
noi di "Sample size: `sample_size'"

if `sample_size' > 0 {
    
    * Column 1: WITH same_skill, Equal weights, country+period FE, WITH base skill
    noi di "Column 1: WITH same_skill + base skill controls"
    reg escaped_vulnerability `main_with_skill_base' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col1
    
    * Column 2: WITHOUT same_skill, Equal weights, country+period FE, WITH base skill
    noi di "Column 2: WITHOUT same_skill + base skill controls"
    reg escaped_vulnerability `main_no_skill_base' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col2
    
    * Column 3: WITH same_skill, Equal weights, country+period FE, NO base skill
    noi di "Column 3: WITH same_skill, NO base skill controls"
    reg escaped_vulnerability `main_with_skill_nobase' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col3
    
    * Column 4: WITHOUT same_skill, Equal weights, country+period FE, NO base skill
    noi di "Column 4: WITHOUT same_skill, NO base skill controls"
    reg escaped_vulnerability `main_no_skill_nobase' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col4
}

**# ==============================================================================
**# 8. EXPORT REGRESSION RESULTS TO EXCEL (4 COLUMNS PER OUTCOME)
**# ==============================================================================

noi di ""
noi di "=== EXPORTING REGRESSION RESULTS (EXCEL ONLY) ==="

* Export Falling into Poverty (4 columns)
cap estimates table fall_pov_col1 fall_pov_col2 fall_pov_col3 fall_pov_col4
if _rc == 0 {
    noi di "Exporting: Falling into Poverty (4 columns)"
    
    estimates restore fall_pov_col1
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_falling_poverty.xls", ///
        replace excel label ///
        title("Pooled Analysis: Falling into Poverty - 5 LAC Countries (Sample: poor_t0==0)") ///
        ctitle("(1) With Same_Skill + Base Skill") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Included", Base Skill Controls, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col2
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(2) No Same_Skill + Base Skill") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Excluded", Base Skill Controls, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col3
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(3) With Same_Skill, No Base") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Included", Base Skill Controls, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col4
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(4) No Same_Skill, No Base") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Excluded", Base Skill Controls, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
}

* Export Escaping Poverty (4 columns)
cap estimates table esc_pov_col1 esc_pov_col2 esc_pov_col3 esc_pov_col4
if _rc == 0 {
    noi di "Exporting: Escaping Poverty (4 columns)"
    
    estimates restore esc_pov_col1
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_escaping_poverty.xls", ///
        replace excel label ///
        title("Pooled Analysis: Escaping Poverty - 5 LAC Countries (Sample: poor_t0==1)") ///
        ctitle("(1) With Same_Skill + Base Skill") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Included", Base Skill Controls, "Included", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col2
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(2) No Same_Skill + Base Skill") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Excluded", Base Skill Controls, "Included", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col3
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(3) With Same_Skill, No Base") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Included", Base Skill Controls, "Excluded", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col4
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(4) No Same_Skill, No Base") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Excluded", Base Skill Controls, "Excluded", Reference, "Remained Unemployed", Sample, "Poor at t0")
}

* Export Falling into Vulnerability (4 columns)
cap estimates table fall_vuln_col1 fall_vuln_col2 fall_vuln_col3 fall_vuln_col4
if _rc == 0 {
    noi di "Exporting: Falling into Vulnerability (4 columns)"
    
    estimates restore fall_vuln_col1
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_falling_vulnerability.xls", ///
        replace excel label ///
        title("Pooled Analysis: Falling into Vulnerability - 5 LAC Countries (Sample: vuln_t0==0)") ///
        ctitle("(1) With Same_Skill + Base Skill") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Included", Base Skill Controls, "Included", Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")
    
    estimates restore fall_vuln_col2
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_falling_vulnerability.xls", ///
        append excel label ctitle("(2) No Same_Skill + Base Skill") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Excluded", Base Skill Controls, "Included", Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")
    
    estimates restore fall_vuln_col3
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_falling_vulnerability.xls", ///
        append excel label ctitle("(3) With Same_Skill, No Base") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Included", Base Skill Controls, "Excluded", Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")
    
    estimates restore fall_vuln_col4
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_falling_vulnerability.xls", ///
        append excel label ctitle("(4) No Same_Skill, No Base") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Excluded", Base Skill Controls, "Excluded", Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")
}

* Export Escaping Vulnerability (4 columns)
cap estimates table esc_vuln_col1 esc_vuln_col2 esc_vuln_col3 esc_vuln_col4
if _rc == 0 {
    noi di "Exporting: Escaping Vulnerability (4 columns)"
    
    estimates restore esc_vuln_col1
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        replace excel label ///
        title("Pooled Analysis: Escaping Vulnerability - 5 LAC Countries (Sample: vuln_t0==1 & poor_t0==0)") ///
        ctitle("(1) With Same_Skill + Base Skill") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Included", Base Skill Controls, "Included", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col2
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(2) No Same_Skill + Base Skill") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Excluded", Base Skill Controls, "Included", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col3
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(3) With Same_Skill, No Base") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Included", Base Skill Controls, "Excluded", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col4
    outreg2 using "${output_path}/19_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(4) No Same_Skill, No Base") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Same_Skill, "Excluded", Base Skill Controls, "Excluded", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
}

**# ==============================================================================
**# 9. SAVE POOLED DATASET
**# ==============================================================================

noi di ""
noi di "=== SAVING POOLED DATASET ==="

* Add metadata
gen dataset_version = "19_LAC_5_pooled_v4"
gen analysis_date = date(c(current_date), "DMY")
format analysis_date %td

* Create summary variables
bysort country: gen obs_by_country = _N
egen total_obs = count(idp_i)

save "${data_path}/19_LAC_5_pooled.dta", replace

noi di "Pooled dataset saved: ${data_path}/19_LAC_5_pooled.dta"
noi di "Total observations: " _N

**# ==============================================================================
**# 10. SUMMARY
**# ==============================================================================

noi di ""
noi di "=== POOLED ANALYSIS COMPLETED (v4 - OPTIMIZED) ==="
noi di ""
noi di "COUNTRIES INCLUDED:"
tab country, missing
noi di ""
noi di "PERIODS ANALYZED:"
tab period, missing
noi di ""  
noi di "SPECIFICATIONS (4 COLUMNS PER OUTCOME):"
noi di "  Column 1: WITH same_skill + base skill controls"
noi di "  Column 2: WITHOUT same_skill + base skill controls"
noi di "  Column 3: WITH same_skill, NO base skill controls"
noi di "  Column 4: WITHOUT same_skill, NO base skill controls"
noi di ""
noi di "ALL COLUMNS:"
noi di "  - Equal weights"
noi di "  - Country + Period fixed effects (visible in output)"
noi di "  - Full demographic controls"
noi di "  - Standard errors clustered at country-region level"
noi di ""
noi di "LABOR TRANSITION VARIABLE ORDERING (vs. remained unemployed):"
noi di "  1. Job gain (entered_job)"
noi di "  2. Job loss (exited_job)"
noi di "  3. Occupational upgrading (skill_increased)"
noi di "  4. Same skill level (same_skill) - When included"
noi di "  5. Occupational downgrading (skill_decreased)"
noi di "  6. Base skill levels (when included): skill_level_2_t0, skill_level_3_t0"
noi di "  ** REFERENCE CATEGORY: Remained unemployed **"
noi di ""
noi di "SAMPLE RESTRICTIONS BY OUTCOME:"
noi di "  - Falling into poverty: poor_t0==0 (non-poor at baseline)"
noi di "  - Escaping poverty: poor_t0==1 (poor at baseline)"
noi di "  - Falling into vulnerability: vuln_t0==0 (non-vulnerable at baseline)"
noi di "  - Escaping vulnerability: vuln_t0==1 & poor_t0==0 (vulnerable but not poor at baseline)"
noi di ""
noi di "OUTPUTS GENERATED (EXCEL ONLY, PREFIX: 19_):"
noi di "  - 19_LAC_5_pooled_reg_falling_poverty.xls (4 columns)"
noi di "  - 19_LAC_5_pooled_reg_escaping_poverty.xls (4 columns)"
noi di "  - 19_LAC_5_pooled_reg_falling_vulnerability.xls (4 columns)"
noi di "  - 19_LAC_5_pooled_reg_escaping_vulnerability.xls (4 columns)"
noi di ""
noi di "DATASET SAVED:"
noi di "  - 19_LAC_5_pooled.dta"
noi di ""
noi di "EFFICIENCY IMPROVEMENTS:"
noi di "  ✓ Added keep statement to load only necessary variables"
noi di "  ✓ Removed absorbed FE columns (from 8 to 4 columns per outcome)"
noi di "  ✓ Reduced from 32 to 16 regressions total"
noi di "  ✓ Excel outputs only (no Word)"
noi di ""

* Display final sample composition
noi di "FINAL SAMPLE COMPOSITION BY COUNTRY:"
bysort country: egen country_n = count(idp_i) if _n == 1
list country country_n if !missing(country_n), clean noobs

noi di ""
noi di "SAMPLE SIZES BY OUTCOME (WITH RESTRICTIONS):"
count if poor_t0 == 0 & !missing(fell_into_poverty)
noi di "  Fell into poverty (poor_t0==0): " r(N)
count if poor_t0 == 1 & !missing(escaped_poverty)
noi di "  Escaped poverty (poor_t0==1): " r(N)
count if vuln_t0 == 0 & !missing(fell_into_vulnerability)
noi di "  Fell into vulnerability (vuln_t0==0): " r(N)
count if vuln_t0 == 1 & poor_t0 == 0 & !missing(escaped_vulnerability)
noi di "  Escaped vulnerability (vuln_t0==1 & poor_t0==0): " r(N)
noi di ""
noi di "=== ANALYSIS COMPLETE ==="
