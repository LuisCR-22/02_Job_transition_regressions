/*====================================================================
Project:		Country-Level Labor Transitions Analysis - 5 LAC Countries
Author:			Luis Castellanos (lcastellanosrodr@worldbank.org)
Creation Date:	2025/11/19
Modified:       2025/11/19
====================================================================
PURPOSE: Country-level analysis for PER, BRA, ARG, DOM, SLV showing labor 
         transitions and poverty/vulnerability outcomes.
         
OUTPUTS: 
- Single Excel file with 5 sheets (one per country), each with 4 outcomes
- Country-level graph data file with coefficients×100, SE×100, and CI
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
**# 1. DEFINE SPECIFICATIONS (SAME AS POOLED)
**# ==============================================================================

* Labor transition variables (reference: remained unemployed at both t0 and t1)
local transitions "entered_job exited_job skill_increased skill_decreased stayed_employed"

* Control variables
local controls "urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ_2 educ_3 hh_members_t0 hh_children_t0"

**# ==============================================================================
**# 2. LOOP THROUGH COUNTRIES
**# ==============================================================================

local countries "PER BRA ARG DOM SLV"
local file_numbers "01 02 03 04 05"
local periods "2021-2023 2022-2023 2021-2023 2021-2023 2022-2023"
local country_names "Peru Brazil Argentina Dominican_Republic El_Salvador"

local c_num = 0
foreach country of local countries {
    local c_num = `c_num' + 1
    local file_num : word `c_num' of `file_numbers'
    local period_range : word `c_num' of `periods'
    local country_name : word `c_num' of `country_names'
    
    noi di ""
    noi di "=== Processing `country' ==="
    
    * Load country data
    use "${data_path}/`file_num'_`country'_reg_data_`period_range'.dta", clear
    
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
    
    * Create stayed_employed indicator
    gen stayed_employed = (employed_t0 == 1 & employed_t1 == 1)
    
    * Adjust education controls for SLV
    if "`country'" == "SLV" {
        replace educ_2 = 0
        replace educ_3 = 0
    }
    
    * Period fixed effects
    qui tab period, gen(period_fe_) missing
    local fe "i.period"
    
    **# =========================================================================
    **# 3. RUN REGRESSIONS FOR ALL FOUR OUTCOMES
    **# =========================================================================
    
    * (1) Going into poverty: poor_t0 == 0
    qui reg fell_into_poverty `transitions' `controls' `fe' [pweight=pondera] if poor_t0 == 0, robust
    estimates store `country'_col1
    matrix b1_`country' = e(b)
    matrix V1_`country' = e(V)
    
    * (2) Going out of poverty: poor_t0 == 1  
    qui reg escaped_poverty `transitions' `controls' `fe' [pweight=pondera] if poor_t0 == 1, robust
    estimates store `country'_col2
    matrix b2_`country' = e(b)
    matrix V2_`country' = e(V)
    
    * (3) Going out of middle class: vuln_t0 == 0
    qui reg fell_into_vulnerability `transitions' `controls' `fe' [pweight=pondera] if vuln_t0 == 0, robust
    estimates store `country'_col3
    matrix b3_`country' = e(b)
    matrix V3_`country' = e(V)
    
    * (4) Going into middle class: vuln_t0 == 1 & poor_t0 == 0
    qui reg escaped_vulnerability `transitions' `controls' `fe' [pweight=pondera] if vuln_t0 == 1 & poor_t0 == 0, robust
    estimates store `country'_col4
    matrix b4_`country' = e(b)
    matrix V4_`country' = e(V)
    
    **# =========================================================================
    **# 4. EXPORT TO EXCEL (ONE SHEET PER COUNTRY)
    **# =========================================================================
    
    estimates restore `country'_col1
    
    if `c_num' == 1 {
        outreg2 using "${output_path}/24_Country_level_reg.xls", ///
            replace excel sheet("`country_name'") ///
            title("`country_name' - Labor Transitions Analysis") ///
            ctitle("(1) Into Poverty") ///
            addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
            addtext(Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    }
    else {
        outreg2 using "${output_path}/24_Country_level_reg.xls", ///
            replace excel sheet("`country_name'") ///
            title("`country_name' - Labor Transitions Analysis") ///
            ctitle("(1) Into Poverty") ///
            addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
            addtext(Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Non-poor at t0")
    }
    
    estimates restore `country'_col2
    outreg2 using "${output_path}/24_Country_level_reg.xls", ///
        append excel sheet("`country_name'") ///
        ctitle("(2) Out of Poverty") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Poor at t0")
    
    estimates restore `country'_col3
    outreg2 using "${output_path}/24_Country_level_reg.xls", ///
        append excel sheet("`country_name'") ///
        ctitle("(3) Out of Middle Class") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Non-vulnerable at t0")
    
    estimates restore `country'_col4
    outreg2 using "${output_path}/24_Country_level_reg.xls", ///
        append excel sheet("`country_name'") ///
        ctitle("(4) Into Middle Class") ///
        addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
        addtext(Year FE, Yes, SE Type, Robust, Reference, "Remained Unemployed", Sample, "Vulnerable not poor at t0")
}

**# ==============================================================================
**# 5. CREATE COUNTRY-LEVEL GRAPH DATA FILE
**# ==============================================================================

local varlist "entered_job exited_job skill_increased skill_decreased stayed_employed"
local nvar : word count `varlist'

* Create one sheet per country
local c_num = 0
foreach country of local countries {
    local c_num = `c_num' + 1
    local country_name : word `c_num' of `country_names'
    
    * Initialize matrices for this country
    matrix graph_out_`country' = J(`=3*`nvar'', 4, .)
    
    * Fill matrix for each variable and outcome
    forvalues v = 1/`nvar' {
        local var : word `v' of `varlist'
        local row_base = (`v' - 1) * 3 + 1
        
        * Column 1: Into poverty
        local pos1 = colnumb(b1_`country', "`var'")
        if `pos1' != . {
            matrix graph_out_`country'[`row_base', 1] = b1_`country'[1, `pos1'] * 100
            matrix graph_out_`country'[`=`row_base'+1', 1] = sqrt(V1_`country'[`pos1', `pos1']) * 100
            matrix graph_out_`country'[`=`row_base'+2', 1] = 1.96 * sqrt(V1_`country'[`pos1', `pos1']) * 100
        }
        
        * Column 2: Out of poverty
        local pos2 = colnumb(b2_`country', "`var'")
        if `pos2' != . {
            matrix graph_out_`country'[`row_base', 2] = b2_`country'[1, `pos2'] * 100
            matrix graph_out_`country'[`=`row_base'+1', 2] = sqrt(V2_`country'[`pos2', `pos2']) * 100
            matrix graph_out_`country'[`=`row_base'+2', 2] = 1.96 * sqrt(V2_`country'[`pos2', `pos2']) * 100
        }
        
        * Column 3: Out of middle class
        local pos3 = colnumb(b3_`country', "`var'")
        if `pos3' != . {
            matrix graph_out_`country'[`row_base', 3] = b3_`country'[1, `pos3'] * 100
            matrix graph_out_`country'[`=`row_base'+1', 3] = sqrt(V3_`country'[`pos3', `pos3']) * 100
            matrix graph_out_`country'[`=`row_base'+2', 3] = 1.96 * sqrt(V3_`country'[`pos3', `pos3']) * 100
        }
        
        * Column 4: Into middle class
        local pos4 = colnumb(b4_`country', "`var'")
        if `pos4' != . {
            matrix graph_out_`country'[`row_base', 4] = b4_`country'[1, `pos4'] * 100
            matrix graph_out_`country'[`=`row_base'+1', 4] = sqrt(V4_`country'[`pos4', `pos4']) * 100
            matrix graph_out_`country'[`=`row_base'+2', 4] = 1.96 * sqrt(V4_`country'[`pos4', `pos4']) * 100
        }
    }
    
    * Export to Excel for this country
    if `c_num' == 1 {
        putexcel set "${output_path}/24_Country_level_graph_data.xlsx", sheet("`country_name'") replace
    }
    else {
        putexcel set "${output_path}/24_Country_level_graph_data.xlsx", sheet("`country_name'") modify
    }
    
    * Write headers
    putexcel A1 = "Labor Transition" B1 = "Into Poverty" C1 = "Out of Poverty" ///
             D1 = "Out of Middle Class" E1 = "Into Middle Class"
    
    * Job Entry
    putexcel A2 = "Job Entry"
    putexcel B2 = matrix(graph_out_`country'[1,1]) C2 = matrix(graph_out_`country'[1,2]) ///
             D2 = matrix(graph_out_`country'[1,3]) E2 = matrix(graph_out_`country'[1,4])
    putexcel A3 = "SE"
    putexcel B3 = matrix(graph_out_`country'[2,1]) C3 = matrix(graph_out_`country'[2,2]) ///
             D3 = matrix(graph_out_`country'[2,3]) E3 = matrix(graph_out_`country'[2,4])
    putexcel A4 = "CI"
    putexcel B4 = matrix(graph_out_`country'[3,1]) C4 = matrix(graph_out_`country'[3,2]) ///
             D4 = matrix(graph_out_`country'[3,3]) E4 = matrix(graph_out_`country'[3,4])
    
    * Job Exit
    putexcel A6 = "Job Exit"
    putexcel B6 = matrix(graph_out_`country'[4,1]) C6 = matrix(graph_out_`country'[4,2]) ///
             D6 = matrix(graph_out_`country'[4,3]) E6 = matrix(graph_out_`country'[4,4])
    putexcel A7 = "SE"
    putexcel B7 = matrix(graph_out_`country'[5,1]) C7 = matrix(graph_out_`country'[5,2]) ///
             D7 = matrix(graph_out_`country'[5,3]) E7 = matrix(graph_out_`country'[5,4])
    putexcel A8 = "CI"
    putexcel B8 = matrix(graph_out_`country'[6,1]) C8 = matrix(graph_out_`country'[6,2]) ///
             D8 = matrix(graph_out_`country'[6,3]) E8 = matrix(graph_out_`country'[6,4])
    
    * Skill Upgrade
    putexcel A10 = "Skill Upgrade"
    putexcel B10 = matrix(graph_out_`country'[7,1]) C10 = matrix(graph_out_`country'[7,2]) ///
             D10 = matrix(graph_out_`country'[7,3]) E10 = matrix(graph_out_`country'[7,4])
    putexcel A11 = "SE"
    putexcel B11 = matrix(graph_out_`country'[8,1]) C11 = matrix(graph_out_`country'[8,2]) ///
             D11 = matrix(graph_out_`country'[8,3]) E11 = matrix(graph_out_`country'[8,4])
    putexcel A12 = "CI"
    putexcel B12 = matrix(graph_out_`country'[9,1]) C12 = matrix(graph_out_`country'[9,2]) ///
             D12 = matrix(graph_out_`country'[9,3]) E12 = matrix(graph_out_`country'[9,4])
    
    * Skill Downgrade
    putexcel A14 = "Skill Downgrade"
    putexcel B14 = matrix(graph_out_`country'[10,1]) C14 = matrix(graph_out_`country'[10,2]) ///
             D14 = matrix(graph_out_`country'[10,3]) E14 = matrix(graph_out_`country'[10,4])
    putexcel A15 = "SE"
    putexcel B15 = matrix(graph_out_`country'[11,1]) C15 = matrix(graph_out_`country'[11,2]) ///
             D15 = matrix(graph_out_`country'[11,3]) E15 = matrix(graph_out_`country'[11,4])
    putexcel A16 = "CI"
    putexcel B16 = matrix(graph_out_`country'[12,1]) C16 = matrix(graph_out_`country'[12,2]) ///
             D16 = matrix(graph_out_`country'[12,3]) E16 = matrix(graph_out_`country'[12,4])
    
    * Stayed Employed
    putexcel A18 = "Stayed Employed"
    putexcel B18 = matrix(graph_out_`country'[13,1]) C18 = matrix(graph_out_`country'[13,2]) ///
             D18 = matrix(graph_out_`country'[13,3]) E18 = matrix(graph_out_`country'[13,4])
    putexcel A19 = "SE"
    putexcel B19 = matrix(graph_out_`country'[14,1]) C19 = matrix(graph_out_`country'[14,2]) ///
             D19 = matrix(graph_out_`country'[14,3]) E19 = matrix(graph_out_`country'[14,4])
    putexcel A20 = "CI"
    putexcel B20 = matrix(graph_out_`country'[15,1]) C20 = matrix(graph_out_`country'[15,2]) ///
             D20 = matrix(graph_out_`country'[15,3]) E20 = matrix(graph_out_`country'[15,4])
}

**# ==============================================================================
**# 6. SUMMARY
**# ==============================================================================

noi di ""
noi di "=== COUNTRY-LEVEL ANALYSIS COMPLETED ==="
noi di ""
noi di "OUTPUTS GENERATED:"
noi di "  1. ${output_path}/24_Country_level_reg.xls"
noi di "     - 5 sheets (Peru, Brazil, Argentina, Dominican_Republic, El_Salvador)"
noi di "     - Each sheet has 4 columns: (1) Into Poverty, (2) Out of Poverty,"
noi di "       (3) Out of Middle Class, (4) Into Middle Class"
noi di "  2. ${output_path}/24_Country_level_graph_data.xlsx"
noi di "     - 5 sheets (one per country)"
noi di "     - Coefficients × 100, SE × 100, and CI for graphs"
noi di ""
noi di "SPECIFICATION:"
noi di "  - Labor transitions: Job entry, Job exit, Skill upgrade, Skill downgrade, Stayed employed"
noi di "  - Reference category: Remained unemployed at both t0 and t1"
noi di "  - Weights: pondera (country survey weights)"
noi di "  - Year fixed effects"
noi di "  - Robust standard errors"
noi di "  - Full demographic controls (adjusted for SLV education)"
noi di ""
noi di "SAMPLE RESTRICTIONS:"
noi di "  - Into poverty: Non-poor at baseline (poor_t0==0)"
noi di "  - Out of poverty: Poor at baseline (poor_t0==1)"
noi di "  - Out of middle class: Non-vulnerable at baseline (vuln_t0==0)"
noi di "  - Into middle class: Vulnerable but not poor at baseline (vuln_t0==1 & poor_t0==0)"
noi di ""
noi di "=== ANALYSIS COMPLETE ==="
