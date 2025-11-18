/*====================================================================
Project:		Pooled Labor Transitions Analysis - 5 LAC Countries (Modified v22)
Author:			Luis Castellanos (lcastellanosrodr@worldbank.org)
Creation Date:	2025/01/15
Modified:       2025/01/18 - New specification with stayed_employed variable
====================================================================
PURPOSE: Pooled analysis across PER, BRA, ARG, DOM, SLV for labor transitions
         and poverty/vulnerability outcomes with equal weights only.

KEY CHANGES IN V22:
- Focus only on specifications WITHOUT base skill level controls
- Column 1: stayed_employed + skill_increased + skill_decreased
- Column 2: sum_var (sum of all skill changes) + skill_increased + skill_decreased
- Column 3: stayed_employed only (no individual skill controls)
- Column 4: sum_var only (no individual skill controls)
- Changed output prefix from 19_ to 22_

IMPORTANT MULTICOLLINEARITY NOTES:
- Columns 1 and 2 include variables that sum to stayed_employed, creating
  near-perfect multicollinearity. This is intentional for robustness checks.
- See detailed explanations in comments before each regression section.
================================================================= */

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
noi di "=== POOLED LABOR TRANSITIONS ANALYSIS: 5 LAC COUNTRIES (v22 - STAYED EMPLOYED) ==="
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
* UPDATED: Added employed_t0 and employed_t1 to keep list
local keep_vars "id* peri* ano region_est1_t0 pondera same_skill entered_job exited_job skill_increased skill_decreased employed_t0 employed_t1 poor_t0 vuln_t0 fell_into_poverty escaped_poverty fell_into_vulnerability escaped_vulnerability urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ* hh_members_t0 hh_children_t0 n_workers_t0 skill_level_2_t0 skill_level_3_t0 employed_t0 employed_t1"

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
**# 2B. CREATE NEW LABOR TRANSITION VARIABLES (V22)
**# ==============================================================================

noi di ""
noi di "=== CREATING NEW LABOR TRANSITION VARIABLES FOR V22 ==="

* Verify employment status variables exist
cap confirm variable employed_t0
if _rc {
    noi di "ERROR: employed_t0 variable not found in dataset!"
    exit 111
}

cap confirm variable employed_t1
if _rc {
    noi di "ERROR: employed_t1 variable not found in dataset!"
    exit 111
}

* Create stayed_employed variable
* This equals 1 if person was employed at both t0 and t1
gen stayed_employed = (employed_t0 == 1 & employed_t1 == 1)
label variable stayed_employed "Employed at both t0 and t1"

* Verify that stayed_employed matches skill transition categories
* If skill_increased=1 OR skill_decreased=1 OR same_skill=1, then stayed_employed should equal 1
gen check_stayed = (skill_increased == 1 | skill_decreased == 1 | same_skill == 1) if !missing(skill_increased, skill_decreased, same_skill)
count if stayed_employed != check_stayed & !missing(stayed_employed, check_stayed)
if r(N) > 0 {
    noi di "WARNING: " r(N) " observations where stayed_employed does not match skill transitions!"
    noi di "This could indicate individuals who changed jobs but stayed employed."
}
else {
    noi di "✓ stayed_employed perfectly matches skill transition categories"
}
drop check_stayed

* Create sum_var = sum of all skill change categories
* This should equal stayed_employed if the three categories are mutually exclusive and exhaustive
gen sum_var = skill_increased + skill_decreased + same_skill
label variable sum_var "Sum of skill_increased + skill_decreased + same_skill"

* Verify that sum_var equals stayed_employed
count if sum_var != stayed_employed & !missing(sum_var, stayed_employed)
if r(N) > 0 {
    noi di "WARNING: " r(N) " observations where sum_var != stayed_employed"
    noi di "This suggests the skill categories may not be mutually exclusive or exhaustive."
}
else {
    noi di "✓ sum_var equals stayed_employed (skill categories are mutually exclusive and exhaustive)"
}

noi di ""
noi di "=== NEW VARIABLE SUMMARY ==="
noi di "stayed_employed: Mean = " %6.3f r(mean)
sum stayed_employed, meanonly
noi di "stayed_employed: Observations with value=1: "
count if stayed_employed == 1
noi di "sum_var: Mean = " %6.3f r(mean)
sum sum_var, meanonly
noi di "sum_var: Observations with value>0: "
count if sum_var > 0

**# ==============================================================================
**# 2C. VERIFY VARIABLES AND TRANSITION CATEGORIES
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
count if stayed_employed == 1
noi di "  - Stayed employed (NEW): " r(N)
count if sum_var > 0
noi di "  - Sum_var > 0 (NEW): " r(N)
count if entered_job==0 & exited_job==0 & skill_increased==0 & skill_decreased==0 & same_skill==0 & !missing(entered_job)
noi di "  - Remained unemployed (reference): " r(N)

* Verify mutual exclusivity of original categories
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
**# 2D. CREATE SLV-SPECIFIC CONTROL ADJUSTMENTS
**# ==============================================================================

noi di ""
noi di "=== ADJUSTING CONTROLS FOR SLV (NO EDUCATION DATA) ==="

* Create SLV-adjusted education variables
* For SLV: set to 0 (or missing) since education data not available
* For other countries: keep original values

replace educ_2 = 0 if country == "SLV"
replace educ_3 = 0 if country == "SLV"

**# ==============================================================================
**# 3. DEFINE REGRESSION SPECIFICATIONS (V22)
**# ==============================================================================

noi di ""
noi di "=== DEFINING REGRESSION SPECIFICATIONS (V22) ==="

* Control variables
local controls "urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ_2 educ_3 hh_members_t0 hh_children_t0 n_workers_t0"

* Column 1: stayed_employed + skill_increased + skill_decreased + job transitions
* NOTE: This specification has near-perfect multicollinearity because:
* stayed_employed = 1 if and only if (skill_increased=1 OR skill_decreased=1 OR same_skill=1)
* By including stayed_employed AND skill_increased AND skill_decreased (but not same_skill),
* we create a dependency: if stayed_employed=1 but skill_increased=0 and skill_decreased=0,
* this perfectly predicts same_skill=1 (the omitted category).
* The coefficient on stayed_employed will capture the effect of same_skill (the omitted component).
local col1_vars "stayed_employed skill_increased skill_decreased entered_job exited_job"

* Column 2: sum_var + skill_increased + skill_decreased + job transitions
* NOTE: This specification has PERFECT multicollinearity because:
* sum_var = skill_increased + skill_decreased + same_skill (by construction)
* Including sum_var AND skill_increased AND skill_decreased means:
* sum_var - skill_increased - skill_decreased = same_skill (perfectly determined)
* Stata will drop one of these variables automatically. The coefficients will be uninterpretable.
* This is included only for robustness checking as requested.
local col2_vars "sum_var skill_increased skill_decreased entered_job exited_job"

* Column 3: stayed_employed + job transitions (NO individual skill controls)
* This is the clean specification: stayed_employed as aggregate measure
local col3_vars "stayed_employed entered_job exited_job"

* Column 4: sum_var + job transitions (NO individual skill controls)
* This should give identical results to Column 3 if sum_var = stayed_employed
local col4_vars "sum_var entered_job exited_job"

* Fixed effects
local fe_country_period "i.country_fe i.period"

noi di ""
noi di "=== REGRESSION SPECIFICATIONS (4 COLUMNS PER OUTCOME - NO BASE SKILL) ==="
noi di "Column 1: stayed_employed + skill_increased + skill_decreased + job transitions"
noi di "          WARNING: Near-perfect multicollinearity (stayed_employed includes same_skill)"
noi di "Column 2: sum_var + skill_increased + skill_decreased + job transitions"
noi di "          WARNING: PERFECT multicollinearity (sum_var = skill_increased + skill_decreased + same_skill)"
noi di "Column 3: stayed_employed + job transitions (CLEAN SPECIFICATION)"
noi di "Column 4: sum_var + job transitions (should match Column 3)"
noi di ""
noi di "Column 1 variables: `col1_vars'"
noi di "Column 2 variables: `col2_vars'"
noi di "Column 3 variables: `col3_vars'"
noi di "Column 4 variables: `col4_vars'"
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

    * Column 1: stayed_employed + skill_increased + skill_decreased
    noi di "Column 1: stayed_employed + skill_increased + skill_decreased (near-multicollinearity)"
    reg fell_into_poverty `col1_vars' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col1

    * Column 2: sum_var + skill_increased + skill_decreased
    noi di "Column 2: sum_var + skill_increased + skill_decreased (perfect multicollinearity - expect dropped vars)"
    reg fell_into_poverty `col2_vars' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col2

    * Column 3: stayed_employed only (clean specification)
    noi di "Column 3: stayed_employed only (CLEAN)"
    reg fell_into_poverty `col3_vars' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
    estimates store fall_pov_col3

    * Column 4: sum_var only
    noi di "Column 4: sum_var only (should match Column 3)"
    reg fell_into_poverty `col4_vars' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 0, cluster(country_region)
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

    * Column 1: stayed_employed + skill_increased + skill_decreased
    noi di "Column 1: stayed_employed + skill_increased + skill_decreased (near-multicollinearity)"
    reg escaped_poverty `col1_vars' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col1

    * Column 2: sum_var + skill_increased + skill_decreased
    noi di "Column 2: sum_var + skill_increased + skill_decreased (perfect multicollinearity - expect dropped vars)"
    reg escaped_poverty `col2_vars' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col2

    * Column 3: stayed_employed only (clean specification)
    noi di "Column 3: stayed_employed only (CLEAN)"
    reg escaped_poverty `col3_vars' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
    estimates store esc_pov_col3

    * Column 4: sum_var only
    noi di "Column 4: sum_var only (should match Column 3)"
    reg escaped_poverty `col4_vars' `controls' `fe_country_period' [pweight=weight_equal] if poor_t0 == 1, cluster(country_region)
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

    * Column 1: stayed_employed + skill_increased + skill_decreased
    noi di "Column 1: stayed_employed + skill_increased + skill_decreased (near-multicollinearity)"
    reg fell_into_vulnerability `col1_vars' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col1

    * Column 2: sum_var + skill_increased + skill_decreased
    noi di "Column 2: sum_var + skill_increased + skill_decreased (perfect multicollinearity - expect dropped vars)"
    reg fell_into_vulnerability `col2_vars' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col2

    * Column 3: stayed_employed only (clean specification)
    noi di "Column 3: stayed_employed only (CLEAN)"
    reg fell_into_vulnerability `col3_vars' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
    estimates store fall_vuln_col3

    * Column 4: sum_var only
    noi di "Column 4: sum_var only (should match Column 3)"
    reg fell_into_vulnerability `col4_vars' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 0, cluster(country_region)
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

    * Column 1: stayed_employed + skill_increased + skill_decreased
    noi di "Column 1: stayed_employed + skill_increased + skill_decreased (near-multicollinearity)"
    reg escaped_vulnerability `col1_vars' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col1

    * Column 2: sum_var + skill_increased + skill_decreased
    noi di "Column 2: sum_var + skill_increased + skill_decreased (perfect multicollinearity - expect dropped vars)"
    reg escaped_vulnerability `col2_vars' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col2

    * Column 3: stayed_employed only (clean specification)
    noi di "Column 3: stayed_employed only (CLEAN)"
    reg escaped_vulnerability `col3_vars' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
    estimates store esc_vuln_col3

    * Column 4: sum_var only
    noi di "Column 4: sum_var only (should match Column 3)"
    reg escaped_vulnerability `col4_vars' `controls' `fe_country_period' [pweight=weight_equal] if vuln_t0 == 1 & poor_t0 == 0, cluster(country_region)
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
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_falling_poverty.xls", ///
        replace excel label ///
        title("Pooled Analysis: Falling into Poverty - 5 LAC Countries (Sample: poor_t0==0)") ///
        ctitle("(1) Stayed_Employed + Skill Controls") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "Near-perfect (see notes)", Reference, "Remained Unemployed", Sample, "Non-poor at t0")

    estimates restore fall_pov_col2
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(2) Sum_Var + Skill Controls") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "Perfect (vars may be dropped)", Reference, "Remained Unemployed", Sample, "Non-poor at t0")

    estimates restore fall_pov_col3
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(3) Stayed_Employed Only") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "None (CLEAN)", Reference, "Remained Unemployed", Sample, "Non-poor at t0")

    estimates restore fall_pov_col4
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_falling_poverty.xls", ///
        append excel label ctitle("(4) Sum_Var Only") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "None (CLEAN)", Reference, "Remained Unemployed", Sample, "Non-poor at t0")
}

* Export Escaping Poverty (4 columns)
cap estimates table esc_pov_col1 esc_pov_col2 esc_pov_col3 esc_pov_col4
if _rc == 0 {
    noi di "Exporting: Escaping Poverty (4 columns)"

    estimates restore esc_pov_col1
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_escaping_poverty.xls", ///
        replace excel label ///
        title("Pooled Analysis: Escaping Poverty - 5 LAC Countries (Sample: poor_t0==1)") ///
        ctitle("(1) Stayed_Employed + Skill Controls") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "Near-perfect (see notes)", Reference, "Remained Unemployed", Sample, "Poor at t0")

    estimates restore esc_pov_col2
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(2) Sum_Var + Skill Controls") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "Perfect (vars may be dropped)", Reference, "Remained Unemployed", Sample, "Poor at t0")

    estimates restore esc_pov_col3
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(3) Stayed_Employed Only") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "None (CLEAN)", Reference, "Remained Unemployed", Sample, "Poor at t0")

    estimates restore esc_pov_col4
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_escaping_poverty.xls", ///
        append excel label ctitle("(4) Sum_Var Only") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "None (CLEAN)", Reference, "Remained Unemployed", Sample, "Poor at t0")
}

* Export Falling into Vulnerability (4 columns)
cap estimates table fall_vuln_col1 fall_vuln_col2 fall_vuln_col3 fall_vuln_col4
if _rc == 0 {
    noi di "Exporting: Falling into Vulnerability (4 columns)"

    estimates restore fall_vuln_col1
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_falling_vulnerability.xls", ///
        replace excel label ///
        title("Pooled Analysis: Falling into Vulnerability - 5 LAC Countries (Sample: vuln_t0==0)") ///
        ctitle("(1) Stayed_Employed + Skill Controls") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "Near-perfect (see notes)", Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")

    estimates restore fall_vuln_col2
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_falling_vulnerability.xls", ///
        append excel label ctitle("(2) Sum_Var + Skill Controls") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "Perfect (vars may be dropped)", Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")

    estimates restore fall_vuln_col3
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_falling_vulnerability.xls", ///
        append excel label ctitle("(3) Stayed_Employed Only") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "None (CLEAN)", Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")

    estimates restore fall_vuln_col4
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_falling_vulnerability.xls", ///
        append excel label ctitle("(4) Sum_Var Only") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "None (CLEAN)", Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")
}

* Export Escaping Vulnerability (4 columns)
cap estimates table esc_vuln_col1 esc_vuln_col2 esc_vuln_col3 esc_vuln_col4
if _rc == 0 {
    noi di "Exporting: Escaping Vulnerability (4 columns)"

    estimates restore esc_vuln_col1
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        replace excel label ///
        title("Pooled Analysis: Escaping Vulnerability - 5 LAC Countries (Sample: vuln_t0==1 & poor_t0==0)") ///
        ctitle("(1) Stayed_Employed + Skill Controls") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "Near-perfect (see notes)", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")

    estimates restore esc_vuln_col2
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(2) Sum_Var + Skill Controls") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "Perfect (vars may be dropped)", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")

    estimates restore esc_vuln_col3
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(3) Stayed_Employed Only") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "None (CLEAN)", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")

    estimates restore esc_vuln_col4
    outreg2 using "${output_path}/22_LAC_5_pooled_reg_escaping_vulnerability.xls", ///
        append excel label ctitle("(4) Sum_Var Only") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Country FE, Yes, Year FE, Yes, Clustering, "Country-Region", Multicollinearity, "None (CLEAN)", Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
}

**# ==============================================================================
**# 9. SAVE POOLED DATASET
**# ==============================================================================

noi di ""
noi di "=== SAVING POOLED DATASET ==="

* Add metadata
gen dataset_version = "22_LAC_5_pooled_stayed_employed"
gen analysis_date = date(c(current_date), "DMY")
format analysis_date %td

* Create summary variables
bysort country: gen obs_by_country = _N
egen total_obs = count(idp_i)

save "${data_path}/22_LAC_5_pooled.dta", replace

noi di "Pooled dataset saved: ${data_path}/22_LAC_5_pooled.dta"
noi di "Total observations: " _N

**# ==============================================================================
**# 10. SUMMARY AND MULTICOLLINEARITY EXPLANATION
**# ==============================================================================

noi di ""
noi di "=== POOLED ANALYSIS COMPLETED (v22 - STAYED EMPLOYED SPECIFICATIONS) ==="
noi di ""
noi di "COUNTRIES INCLUDED:"
tab country, missing
noi di ""
noi di "PERIODS ANALYZED:"
tab period, missing
noi di ""
noi di "SPECIFICATIONS (4 COLUMNS PER OUTCOME):"
noi di "  Column 1: stayed_employed + skill_increased + skill_decreased + job transitions"
noi di "  Column 2: sum_var + skill_increased + skill_decreased + job transitions"
noi di "  Column 3: stayed_employed + job transitions (CLEAN - RECOMMENDED)"
noi di "  Column 4: sum_var + job transitions (should match Column 3)"
noi di ""
noi di "ALL COLUMNS:"
noi di "  - Equal weights"
noi di "  - Country + Period fixed effects"
noi di "  - Full demographic controls"
noi di "  - Standard errors clustered at country-region level"
noi di "  - NO base skill level controls (skill_level_2_t0, skill_level_3_t0)"
noi di ""
noi di "╔════════════════════════════════════════════════════════════════════════════╗"
noi di "║                    MULTICOLLINEARITY EXPLANATION                           ║"
noi di "╚════════════════════════════════════════════════════════════════════════════╝"
noi di ""
noi di "COLUMN 1 - NEAR-PERFECT MULTICOLLINEARITY:"
noi di "  Variables: stayed_employed + skill_increased + skill_decreased"
noi di ""
noi di "  The Problem:"
noi di "  • stayed_employed = 1 when person employed at both t0 and t1"
noi di "  • When stayed_employed=1, exactly ONE of these must be true:"
noi di "    - skill_increased = 1 (moved to higher skill level)"
noi di "    - skill_decreased = 1 (moved to lower skill level)"
noi di "    - same_skill = 1 (stayed at same skill level)"
noi di ""
noi di "  • By including stayed_employed + skill_increased + skill_decreased"
noi di "    but EXCLUDING same_skill, we create a dependency:"
noi di "    stayed_employed - skill_increased - skill_decreased = same_skill"
noi di ""
noi di "  Interpretation of Coefficients:"
noi di "  • β(skill_increased) = effect of skill increase vs same_skill (within employed)"
noi di "  • β(skill_decreased) = effect of skill decrease vs same_skill (within employed)"
noi di "  • β(stayed_employed) = effect of same_skill vs remained unemployed"
noi di "    (because it captures the stayed_employed effect net of the other components)"
noi di ""
noi di "  This may work but coefficients require careful interpretation!"
noi di ""
noi di "COLUMN 2 - PERFECT MULTICOLLINEARITY:"
noi di "  Variables: sum_var + skill_increased + skill_decreased"
noi di ""
noi di "  The Problem:"
noi di "  • sum_var = skill_increased + skill_decreased + same_skill (by construction)"
noi di "  • Including sum_var AND skill_increased AND skill_decreased means:"
noi di "    sum_var - skill_increased - skill_decreased = same_skill (perfectly determined)"
noi di ""
noi di "  What Stata Will Do:"
noi di "  • Stata will detect perfect collinearity and drop one variable automatically"
noi di "  • You'll see a message like: 'XXX omitted because of collinearity'"
noi di "  • The remaining coefficients will not be interpretable as intended"
noi di ""
noi di "  This specification is problematic and results should not be interpreted!"
noi di ""
noi di "COLUMNS 3 & 4 - CLEAN SPECIFICATIONS (RECOMMENDED):"
noi di "  Column 3: stayed_employed + job transitions"
noi di "  Column 4: sum_var + job transitions"
noi di ""
noi di "  • No multicollinearity issues"
noi di "  • stayed_employed and sum_var should be identical if skill categories are"
noi di "    mutually exclusive and exhaustive"
noi di "  • Coefficients show aggregate effect of staying employed vs unemployed"
noi di "  • These are the specifications you should use for interpretation!"
noi di ""
noi di "RECOMMENDATION:"
noi di "  Use Column 3 for your main results. Compare with Column 1 if you want to"
noi di "  explore heterogeneity within stayed_employed (but interpret carefully)."
noi di "  Ignore Column 2 (perfect multicollinearity makes it uninterpretable)."
noi di ""
noi di "════════════════════════════════════════════════════════════════════════════"
noi di ""
noi di "LABOR TRANSITION VARIABLE STRUCTURE:"
noi di "  Labor Market Status at t0 and t1:"
noi di "  ┌─────────────────────────────────────────────────────────────────┐"
noi di "  │  entered_job:      Unemployed at t0 → Employed at t1           │"
noi di "  │  exited_job:       Employed at t0 → Unemployed at t1            │"
noi di "  │  stayed_employed:  Employed at t0 → Employed at t1              │"
noi di "  │    ├── skill_increased:  Moved to higher skill level            │"
noi di "  │    ├── same_skill:       Stayed at same skill level             │"
noi di "  │    └── skill_decreased:  Moved to lower skill level             │"
noi di "  │  remained_unemployed: Unemployed at t0 → Unemployed at t1       │"
noi di "  │                       (REFERENCE CATEGORY)                       │"
noi di "  └─────────────────────────────────────────────────────────────────┘"
noi di ""
noi di "SAMPLE RESTRICTIONS BY OUTCOME:"
noi di "  - Falling into poverty: poor_t0==0 (non-poor at baseline)"
noi di "  - Escaping poverty: poor_t0==1 (poor at baseline)"
noi di "  - Falling into vulnerability: vuln_t0==0 (non-vulnerable at baseline)"
noi di "  - Escaping vulnerability: vuln_t0==1 & poor_t0==0 (vulnerable but not poor)"
noi di ""
noi di "OUTPUTS GENERATED (EXCEL ONLY, PREFIX: 22_):"
noi di "  - 22_LAC_5_pooled_reg_falling_poverty.xls"
noi di "  - 22_LAC_5_pooled_reg_escaping_poverty.xls"
noi di "  - 22_LAC_5_pooled_reg_falling_vulnerability.xls"
noi di "  - 22_LAC_5_pooled_reg_escaping_vulnerability.xls"
noi di ""
noi di "DATASET SAVED:"
noi di "  - 22_LAC_5_pooled.dta"
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
