/*====================================================================
Project:		Pooled Labor Transitions Analysis - 5 LAC Countries (Modified v3)
Author:			Luis Castellanos (lcastellanosrodr@worldbank.org)
Creation Date:	2025/01/15
Modified:       2025/01/15 - Using same_skill variable, proper sample restrictions
====================================================================
PURPOSE: Pooled analysis across PER, BRA, ARG, DOM, SLV for labor transitions
         and poverty/vulnerability outcomes with equal weights only.
         NOW INCLUDES: Proper sample restrictions by initial poverty/vulnerability status
         Two variations: with and without same_skill variable
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
noi di "=== MODIFIED POOLED LABOR TRANSITIONS ANALYSIS: 5 LAC COUNTRIES (v3) ==="
noi di "Data path: $data_path"
noi di "Output: $output_path"
noi di ""

**# ==============================================================================
**# 1. IMPORT AND APPEND COUNTRY DATASETS
**# ==============================================================================

noi di "=== LOADING AND COMBINING COUNTRY DATASETS ==="

* Define countries, file numbers, and corresponding periods
local countries "PER BRA ARG DOM SLV"
local file_numbers "01 02 03 04 05"
local periods "2021-2023 2022-2023 2021-2023 2021-2023 2021-2023"

tempfile combined_data

forvalues i = 1/5 {
    local country : word `i' of `countries'
    local file_num : word `i' of `file_numbers'
    local period_range : word `i' of `periods'
    
    noi di "Loading `country' data (Period: `period_range')..."
    use "${data_path}/`file_num'_`country'_reg_data_`period_range'.dta", clear
	
	*keep idp_h idh idp_i idi period ano region_est1_t0 pondera same_skill ///
     entered_job exited_job skill_increased skill_decreased poor_t0 vuln_t0 ///
     fell_into_poverty escaped_poverty fell_into_vulnerability ///
     escaped_vulnerability urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus ///
     hombre_t0 partner_t0 educ_2 educ_3 hh_members_t0 hh_children_t0 ///
     n_workers_t0 skill_level_2_t0 skill_level_3_t0
    
    * Handle SLV variable transformations (robust check)
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
            else {
                noi di "    - WARNING: Neither idp_h nor idh found"
            }
        }
        else {
            noi di "    - idp_h already exists"
        }
        
        * Check and create idp_i if needed
        cap confirm variable idp_i
        if _rc {
            cap confirm variable idi
            if !_rc {
                encode idi, gen(idp_i)
                noi di "    - Created idp_i from idi"
            }
            else {
                noi di "    - WARNING: Neither idp_i nor idi found"
            }
        }
        else {
            noi di "    - idp_i already exists"
        }
        
        * Check and create period if needed
        cap confirm variable period
        if _rc {
            cap confirm variable ano
            if !_rc {
                gen period = ano
                noi di "    - Created period from ano"
            }
            else {
                noi di "    - WARNING: Neither period nor ano found"
            }
        }
        else {
            noi di "    - period already exists"
        }
    }
	
    * Handle BRA variable transformations (robust check)
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
            else {
                noi di "    - WARNING: Neither period nor ano found"
            }
        }
        else {
            noi di "    - period already exists"
        }
    }
    
    * Add country identifier if not present
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
**# 2. CREATE POOLED VARIABLES AND WEIGHTS
**# ==============================================================================

noi di ""
noi di "=== CREATING POOLED VARIABLES AND WEIGHTS ==="

* Create country-region fixed effects (combining country with region_est1_t0)
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
tab country_region if _n <= 20, missing

**# ==============================================================================
**# 2B. VERIFY SAME_SKILL VARIABLE AND TRANSITION CATEGORIES
**# ==============================================================================

noi di ""
noi di "=== VERIFYING SAME_SKILL VARIABLE AND LABOR TRANSITION CATEGORIES ==="

* Verify same_skill exists
cap confirm variable same_skill
if _rc {
    noi di "ERROR: same_skill variable not found in dataset!"
    noi di "Please ensure the variable exists before running this analysis."
    exit 111
}
else {
    noi di "✓ same_skill variable found"
}

* Label the variable if not already labeled
label variable same_skill "Remained employed in same skill level"

* Verify categories
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

* Quick mutual exclusivity check
gen transition_sum = entered_job + exited_job + skill_increased + skill_decreased + same_skill if !missing(entered_job)
count if transition_sum > 1 & !missing(transition_sum)
if r(N) > 0 {
    noi di "WARNING: " r(N) " observations with multiple transitions!"
}
else {
    noi di "✓ Categories are mutually exclusive"
}
drop transition_sum

**# ==============================================================================
**# 2C. VERIFY SAMPLE RESTRICTION VARIABLES
**# ==============================================================================

noi di ""
noi di "=== VERIFYING SAMPLE RESTRICTION VARIABLES ==="

* Check for poor_t0 and vuln_t0
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

* Display sample sizes for each outcome-specific sample
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
**# 3. DEFINE REGRESSION SPECIFICATIONS
**# ==============================================================================

* Control variables (same as original Peru analysis)
local controls_modified "urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ_2 educ_3 hh_members_t0 hh_children_t0 n_workers_t0"

* Main labor transition variables - WITH same_skill (5 transitions)
* Order: entered_job, exited_job, skill_increased, same_skill, skill_decreased
local main_vars_all "entered_job exited_job skill_increased same_skill skill_decreased skill_level_2_t0 skill_level_3_t0"
local main_vars_no_base "entered_job exited_job skill_increased same_skill skill_decreased"

* Main labor transition variables - WITHOUT same_skill (4 transitions)
* Order: entered_job, exited_job, skill_increased, skill_decreased
local main_vars_no_same "entered_job exited_job skill_increased skill_decreased skill_level_2_t0 skill_level_3_t0"
local main_vars_no_same_base "entered_job exited_job skill_increased skill_decreased"

* Fixed effects specifications
local fe_country_period "i.country_fe i.period"

noi di ""
noi di "=== REGRESSION SPECIFICATIONS ==="
noi di "Main variables (WITH same_skill, full): `main_vars_all'"
noi di "Main variables (WITH same_skill, no base): `main_vars_no_base'"
noi di "Main variables (WITHOUT same_skill, full): `main_vars_no_same'"
noi di "Main variables (WITHOUT same_skill, no base): `main_vars_no_same_base'"
noi di "Controls: `controls_modified'"
noi di "Fixed effects: `fe_country_period'"
noi di "Reference category: Remained unemployed"

**# ==============================================================================
**# 4. POOLED REGRESSIONS - FALLING INTO POVERTY
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 1: FALLING INTO POVERTY (poor_t0==0) ==="

count if !missing(fell_into_poverty) & poor_t0 == 0
local sample_size = r(N)
noi di "Sample size for outcome: `sample_size'"

if `sample_size' > 0 {
    
    * Column 1: WITH same_skill, Equal weights, country+period FE, full controls
    noi di "Column 1: WITH same_skill, Equal weights, country+period FE, full controls"
    reg fell_into_poverty `main_vars_all' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col1
    
    * Column 2: WITHOUT same_skill, Equal weights, country+period FE, full controls
    noi di "Column 2: WITHOUT same_skill, Equal weights, country+period FE, full controls"
    reg fell_into_poverty `main_vars_no_same' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col2
    
    * Column 3: WITH same_skill, Equal weights, country+period+region FE (absorbed), full controls
    noi di "Column 3: WITH same_skill, Equal weights, country+period+region FE (absorbed), full controls"
    areg fell_into_poverty `main_vars_all' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store fall_pov_col3
    
    * Column 4: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), full controls
    noi di "Column 4: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), full controls"
    areg fell_into_poverty `main_vars_no_same' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store fall_pov_col4
    
    * Column 5: WITH same_skill, Equal weights, country+period FE, no base skill levels
    noi di "Column 5: WITH same_skill, Equal weights, country+period FE, no base skill levels"
    reg fell_into_poverty `main_vars_no_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col5
    
    * Column 6: WITHOUT same_skill, Equal weights, country+period FE, no base skill levels
    noi di "Column 6: WITHOUT same_skill, Equal weights, country+period FE, no base skill levels"
    reg fell_into_poverty `main_vars_no_same_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col6
    
    * Column 7: WITH same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels
    noi di "Column 7: WITH same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels"
    areg fell_into_poverty `main_vars_no_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store fall_pov_col7
    
    * Column 8: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels
    noi di "Column 8: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels"
    areg fell_into_poverty `main_vars_no_same_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store fall_pov_col8
}

**# ==============================================================================
**# 5. POOLED REGRESSIONS - ESCAPING POVERTY
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 2: ESCAPING POVERTY (poor_t0==1) ==="

count if !missing(escaped_poverty) & poor_t0 == 1
local sample_size = r(N)
noi di "Sample size for outcome: `sample_size'"

if `sample_size' > 0 {
    
    * Column 1: WITH same_skill, Equal weights, country+period FE, full controls
    noi di "Column 1: WITH same_skill, Equal weights, country+period FE, full controls"
    reg escaped_poverty `main_vars_all' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col1
    
    * Column 2: WITHOUT same_skill, Equal weights, country+period FE, full controls
    noi di "Column 2: WITHOUT same_skill, Equal weights, country+period FE, full controls"
    reg escaped_poverty `main_vars_no_same' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col2
    
    * Column 3: WITH same_skill, Equal weights, country+period+region FE (absorbed), full controls
    noi di "Column 3: WITH same_skill, Equal weights, country+period+region FE (absorbed), full controls"
    areg escaped_poverty `main_vars_all' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, absorb(country_region) cluster(country_region)
    estimates store esc_pov_col3
    
    * Column 4: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), full controls
    noi di "Column 4: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), full controls"
    areg escaped_poverty `main_vars_no_same' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, absorb(country_region) cluster(country_region)
    estimates store esc_pov_col4
    
    * Column 5: WITH same_skill, Equal weights, country+period FE, no base skill levels
    noi di "Column 5: WITH same_skill, Equal weights, country+period FE, no base skill levels"
    reg escaped_poverty `main_vars_no_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col5
    
    * Column 6: WITHOUT same_skill, Equal weights, country+period FE, no base skill levels
    noi di "Column 6: WITHOUT same_skill, Equal weights, country+period FE, no base skill levels"
    reg escaped_poverty `main_vars_no_same_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col6
    
    * Column 7: WITH same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels
    noi di "Column 7: WITH same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels"
    areg escaped_poverty `main_vars_no_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, absorb(country_region) cluster(country_region)
    estimates store esc_pov_col7
    
    * Column 8: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels
    noi di "Column 8: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels"
    areg escaped_poverty `main_vars_no_same_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, absorb(country_region) cluster(country_region)
    estimates store esc_pov_col8
}

**# ==============================================================================
**# 6. POOLED REGRESSIONS - FALLING INTO VULNERABILITY
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 3: FALLING INTO VULNERABILITY (vuln_t0==0) ==="

count if !missing(fell_into_vulnerability) & vuln_t0 == 0
local sample_size = r(N)
noi di "Sample size for outcome: `sample_size'"

if `sample_size' > 0 {
    
    * Column 1: WITH same_skill, Equal weights, country+period FE, full controls
    noi di "Column 1: WITH same_skill, Equal weights, country+period FE, full controls"
    reg fell_into_vulnerability `main_vars_all' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col1
    
    * Column 2: WITHOUT same_skill, Equal weights, country+period FE, full controls
    noi di "Column 2: WITHOUT same_skill, Equal weights, country+period FE, full controls"
    reg fell_into_vulnerability `main_vars_no_same' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col2
    
    * Column 3: WITH same_skill, Equal weights, country+period+region FE (absorbed), full controls
    noi di "Column 3: WITH same_skill, Equal weights, country+period+region FE (absorbed), full controls"
    areg fell_into_vulnerability `main_vars_all' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store fall_vuln_col3
    
    * Column 4: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), full controls
    noi di "Column 4: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), full controls"
    areg fell_into_vulnerability `main_vars_no_same' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store fall_vuln_col4
    
    * Column 5: WITH same_skill, Equal weights, country+period FE, no base skill levels
    noi di "Column 5: WITH same_skill, Equal weights, country+period FE, no base skill levels"
    reg fell_into_vulnerability `main_vars_no_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col5
    
    * Column 6: WITHOUT same_skill, Equal weights, country+period FE, no base skill levels
    noi di "Column 6: WITHOUT same_skill, Equal weights, country+period FE, no base skill levels"
    reg fell_into_vulnerability `main_vars_no_same_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col6
    
    * Column 7: WITH same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels
    noi di "Column 7: WITH same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels"
    areg fell_into_vulnerability `main_vars_no_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store fall_vuln_col7
    
    * Column 8: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels
    noi di "Column 8: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels"
    areg fell_into_vulnerability `main_vars_no_same_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store fall_vuln_col8
}

**# ==============================================================================
**# 7. POOLED REGRESSIONS - ESCAPING VULNERABILITY
**# ==============================================================================

noi di ""
noi di "=== REGRESSION ANALYSIS 4: ESCAPING VULNERABILITY (vuln_t0==1 & poor_t0==0) ==="

count if !missing(escaped_vulnerability) & vuln_t0 == 1 & poor_t0 == 0
local sample_size = r(N)
noi di "Sample size for outcome: `sample_size'"

if `sample_size' > 0 {
    
    * Column 1: WITH same_skill, Equal weights, country+period FE, full controls
    noi di "Column 1: WITH same_skill, Equal weights, country+period FE, full controls"
    reg escaped_vulnerability `main_vars_all' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col1
    
    * Column 2: WITHOUT same_skill, Equal weights, country+period FE, full controls
    noi di "Column 2: WITHOUT same_skill, Equal weights, country+period FE, full controls"
    reg escaped_vulnerability `main_vars_no_same' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col2
    
    * Column 3: WITH same_skill, Equal weights, country+period+region FE (absorbed), full controls
    noi di "Column 3: WITH same_skill, Equal weights, country+period+region FE (absorbed), full controls"
    areg escaped_vulnerability `main_vars_all' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store esc_vuln_col3
    
    * Column 4: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), full controls
    noi di "Column 4: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), full controls"
    areg escaped_vulnerability `main_vars_no_same' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store esc_vuln_col4
    
    * Column 5: WITH same_skill, Equal weights, country+period FE, no base skill levels
    noi di "Column 5: WITH same_skill, Equal weights, country+period FE, no base skill levels"
    reg escaped_vulnerability `main_vars_no_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col5
    
    * Column 6: WITHOUT same_skill, Equal weights, country+period FE, no base skill levels
    noi di "Column 6: WITHOUT same_skill, Equal weights, country+period FE, no base skill levels"
    reg escaped_vulnerability `main_vars_no_same_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col6
    
    * Column 7: WITH same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels
    noi di "Column 7: WITH same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels"
    areg escaped_vulnerability `main_vars_no_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store esc_vuln_col7
    
    * Column 8: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels
    noi di "Column 8: WITHOUT same_skill, Equal weights, country+period+region FE (absorbed), no base skill levels"
    areg escaped_vulnerability `main_vars_no_same_base' `controls_modified' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, absorb(country_region) cluster(country_region)
    estimates store esc_vuln_col8
}

**# ==============================================================================
**# 8. EXPORT REGRESSION RESULTS WITH CUSTOM LABELS
**# ==============================================================================

noi di ""
noi di "=== EXPORTING REGRESSION RESULTS ==="

* Export Falling into Poverty (8 columns)
cap estimates table fall_pov_col1 fall_pov_col2 fall_pov_col3 fall_pov_col4 fall_pov_col5 fall_pov_col6 fall_pov_col7 fall_pov_col8
if _rc == 0 {
    noi di "Exporting: Falling into Poverty"
    
    * Excel output
    estimates restore fall_pov_col1
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.xls", ///
        replace excel label ///
        title("Pooled Analysis: Falling into Poverty - 5 LAC Countries (Sample: poor_t0==0)") ///
        ctitle("(1)WithSameSkill+CountryPeriodFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col2
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(2)NoSameSkill+CountryPeriodFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col3
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(3)WithSameSkill+AllFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col4
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(4)NoSameSkill+AllFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col5
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(5)WithSameSkill+CountryPeriodFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col6
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(6)NoSameSkill+CountryPeriodFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col7
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(7)WithSameSkill+AllFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col8
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(8)NoSameSkill+AllFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
/*    * DOC output with same structure
    estimates restore fall_pov_col1
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.doc", ///
        replace word label ///
        title("Pooled Analysis: Falling into Poverty - 5 LAC Countries (Sample: poor_t0==0)") ///
        ctitle("(1)WithSameSkill+CountryPeriodFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col2
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.doc", ///
        append word label ctitle("(2)NoSameSkill+CountryPeriodFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col3
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.doc", ///
        append word label ctitle("(3)WithSameSkill+AllFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col4
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.doc", ///
        append word label ctitle("(4)NoSameSkill+AllFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col5
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.doc", ///
        append word label ctitle("(5)WithSameSkill+CountryPeriodFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col6
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.doc", ///
        append word label ctitle("(6)NoSameSkill+CountryPeriodFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col7
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.doc", ///
        append word label ctitle("(7)WithSameSkill+AllFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    
    estimates restore fall_pov_col8
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_falling_poverty.doc", ///
        append word label ctitle("(8)NoSameSkill+AllFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Non-poor at t0")*/
}

* Export Escaping Poverty (8 columns)
cap estimates table esc_pov_col1 esc_pov_col2 esc_pov_col3 esc_pov_col4 esc_pov_col5 esc_pov_col6 esc_pov_col7 esc_pov_col8
if _rc == 0 {
    noi di "Exporting: Escaping Poverty"
    
    * Excel output
    estimates restore esc_pov_col1
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_poverty.xls", ///
        replace excel label ///
        title("Pooled Analysis: Escaping Poverty - 5 LAC Countries (Sample: poor_t0==1)") ///
        ctitle("(1)WithSameSkill+CountryPeriodFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col2
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(2)NoSameSkill+CountryPeriodFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col3
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(3)WithSameSkill+AllFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col4
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(4)NoSameSkill+AllFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col5
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(5)WithSameSkill+CountryPeriodFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col6
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(6)NoSameSkill+CountryPeriodFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col7
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(7)WithSameSkill+AllFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore esc_pov_col8
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(8)NoSameSkill+AllFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Poor at t0")
   
}

* Export Escaping Vulnerability (8 columns)
cap estimates table esc_vuln_col1 esc_vuln_col2 esc_vuln_col3 esc_vuln_col4 esc_vuln_col5 esc_vuln_col6 esc_vuln_col7 esc_vuln_col8
if _rc == 0 {
    noi di "Exporting: Escaping Vulnerability"
    
    * Excel output
    estimates restore esc_vuln_col1
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        replace excel label ///
        title("Pooled Analysis: Escaping Vulnerability - 5 LAC Countries (Sample: vuln_t0==1 & poor_t0==0)") ///
        ctitle("(1)WithSameSkill+CountryPeriodFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col2
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(2)NoSameSkill+CountryPeriodFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col3
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(3)WithSameSkill+AllFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col4
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(4)NoSameSkill+AllFE+FullControls") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col5
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(5)WithSameSkill+CountryPeriodFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col6
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(6)NoSameSkill+CountryPeriodFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, No, Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col7
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(7)WithSameSkill+AllFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Included", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
    estimates restore esc_vuln_col8
    outreg2 using "${output_path}/18_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(8)NoSameSkill+AllFE+NoBaseSkill") ///
        addstat(Adjusted R-squared, e(r2_a)) ///
        addtext(Country FE, Yes, Year FE, Yes, Region FE, "Yes (absorbed)", Clustering, "Country-Region", Same_Skill, "Excluded", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
    
}

**# ==============================================================================
**# 9. SAVE POOLED DATASET
**# ==============================================================================

noi di ""
noi di "=== SAVING POOLED DATASET ==="

* Add summary statistics to dataset
gen dataset_version = "13_LAC_5_pooled"
gen analysis_date = date(c(current_date), "DMY")
format analysis_date %td

* Create summary variables
bysort country: gen obs_by_country = _N
egen total_obs = count(idp_i)

save "${data_path}/13_LAC_5_pooled.dta", replace

noi di "Pooled dataset saved: ${data_path}/13_LAC_5_pooled.dta"
noi di "Total observations: " _N

**# ==============================================================================
**# 10. SUMMARY
**# ==============================================================================

noi di ""
noi di "=== MODIFIED POOLED ANALYSIS COMPLETED (v3 - WITH PROPER SAMPLE RESTRICTIONS) ==="
noi di ""
noi di "COUNTRIES INCLUDED:"
tab country, missing
noi di ""
noi di "PERIODS ANALYZED:"
tab period, missing
noi di ""  
noi di "SPECIFICATIONS (8 columns per outcome):"
noi di "  Columns 1,3,5,7: WITH same_skill variable (5 transitions)"
noi di "  Columns 2,4,6,8: WITHOUT same_skill variable (4 transitions)"
noi di ""
noi di "  - Columns 1-2: Equal weights + Country+Period FE + Full controls"
noi di "  - Columns 3-4: Equal weights + All FE (region absorbed) + Full controls"
noi di "  - Columns 5-6: Equal weights + Country+Period FE + No base skill levels"
noi di "  - Columns 7-8: Equal weights + All FE (region absorbed) + No base skill levels"
noi di ""
noi di "VARIABLE ORDERING (vs. remained unemployed reference):"
noi di "  1. Job gain (entered_job)"
noi di "  2. Job loss (exited_job)"
noi di "  3. Occupational upgrading (skill_increased)"
noi di "  4. Same skill level (same_skill) - When included"
noi di "  5. Occupational downgrading (skill_decreased)"
noi di "  6. Base skill levels (when included)"
noi di "  7. Other controls"
noi di "  ** REFERENCE CATEGORY: Remained unemployed **"
noi di ""
noi di "CRITICAL SAMPLE RESTRICTIONS:"
noi di "  - Falling into poverty: Only non-poor at t0 (poor_t0==0)"
noi di "  - Escaping poverty: Only poor at t0 (poor_t0==1)"
noi di "  - Falling into vulnerability: Only non-vulnerable at t0 (vuln_t0==0)"
noi di "  - Escaping vulnerability: Only vulnerable but not poor at t0 (vuln_t0==1 & poor_t0==0)"
noi di ""
noi di "CLUSTERING:"
noi di "  - Standard errors clustered at country-region level"
noi di ""
noi di "OUTPUTS GENERATED (with 18_ prefix):"
noi di "  - 18_LAC_5_pooled_reg_falling_poverty.xls/.doc (8 columns)"
noi di "  - 18_LAC_5_pooled_reg_escaping_poverty.xls/.doc (8 columns)"
noi di "  - 18_LAC_5_pooled_reg_falling_vulnerability.xls/.doc (8 columns)" 
noi di "  - 18_LAC_5_pooled_reg_escaping_vulnerability.xls/.doc (8 columns)"
noi di ""
noi di "DATASET SAVED:"
noi di "  - 13_LAC_5_pooled.dta"
noi di ""

* Display final sample composition
noi di "FINAL SAMPLE COMPOSITION:"
bysort country: egen country_obs = count(idp_i) if _n == 1
list country country_obs if !missing(country_obs), clean noobs

noi di ""
noi di "TRANSITION CATEGORIES SUMMARY:"
tab same_skill, missing
count if entered_job==0 & exited_job==0 & skill_increased==0 & skill_decreased==0 & same_skill==0 & !missing(entered_job)
noi di "Reference category (remained unemployed): " r(N) " observations"

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
