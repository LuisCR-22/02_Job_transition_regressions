/*====================================================================
Project:		Country-Level Labor Transitions Analysis - 5 LAC Countries
Author:			Luis Castellanos (lcastellanosrodr@worldbank.org)
Creation Date:	2025/01/15
Modified:       2025/01/15 - Country-level version of pooled analysis
====================================================================
PURPOSE: Country-by-country analysis implementing same methodology as pooled
         analysis. Each country generates 4 Excel files (one per specification)
         with 4 outcomes per file.
         
STRUCTURE:
- Specification 1: WITH same_skill + base skill → 20_CCC_reg_1.xls
- Specification 2: WITHOUT same_skill + base skill → 20_CCC_reg_2.xls
- Specification 3: WITH same_skill, NO base skill → 20_CCC_reg_3.xls
- Specification 4: WITHOUT same_skill, NO base skill → 20_CCC_reg_4.xls

Each file contains 4 columns:
1. Fall into Poverty
2. Escape Poverty
3. Going out Middle Class (falling into vulnerability)
4. Going in Middle Class (escaping vulnerability)
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
noi di "=== COUNTRY-LEVEL LABOR TRANSITIONS ANALYSIS: 5 LAC COUNTRIES ==="
noi di "Data path: $data_path"
noi di "Output: $output_path"
noi di ""

**# ==============================================================================
**# 1. DEFINE COUNTRY LOOP PARAMETERS
**# ==============================================================================

* Define countries, file numbers, and corresponding periods
local countries "PER BRA ARG DOM SLV"
local file_numbers "01 02 03 04 05"
local periods "2021-2023 2022-2023 2021-2023 2021-2023 2022-2023"

* Define variables to keep (all necessary for analysis)
local keep_vars "id* peri* ano region_est1_t0 pondera same_skill entered_job exited_job skill_increased skill_decreased poor_t0 vuln_t0 fell_into_poverty escaped_poverty fell_into_vulnerability escaped_vulnerability urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ* hh_members_t0 hh_children_t0 n_workers_t0 skill_level_2_t0 skill_level_3_t0"

**# ==============================================================================
**# 2. DEFINE REGRESSION SPECIFICATIONS (SAME AS POOLED)
**# ==============================================================================

* Control variables
local controls "urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 educ_2 educ_3 hh_members_t0 hh_children_t0 n_workers_t0"

* Main labor transition variables - 4 specifications
local spec1_vars "entered_job exited_job skill_increased same_skill skill_decreased skill_level_2_t0 skill_level_3_t0"
local spec2_vars "entered_job exited_job skill_increased skill_decreased skill_level_2_t0 skill_level_3_t0"
local spec3_vars "entered_job exited_job skill_increased same_skill skill_decreased"
local spec4_vars "entered_job exited_job skill_increased skill_decreased"

noi di "=== REGRESSION SPECIFICATIONS ==="
noi di "Spec 1 (WITH same_skill + base skill): `spec1_vars'"
noi di "Spec 2 (WITHOUT same_skill + base skill): `spec2_vars'"
noi di "Spec 3 (WITH same_skill, NO base skill): `spec3_vars'"
noi di "Spec 4 (WITHOUT same_skill, NO base skill): `spec4_vars'"
noi di "Controls: `controls'"
noi di "Fixed effects: Period + Region (within country)"
noi di "Clustering: Region level (region_est1_t0)"
noi di "Weight: pondera"
noi di ""

**# ==============================================================================
**# 3. LOOP THROUGH COUNTRIES
**# ==============================================================================

forvalues c = 1/5 {
    local country : word `c' of `countries'
    local file_num : word `c' of `file_numbers'
    local period_range : word `c' of `periods'
    
    noi di ""
    noi di "=========================================================================="
    noi di "=== PROCESSING COUNTRY: `country' (Period: `period_range') ==="
    noi di "=========================================================================="
    noi di ""
    
    * Load country data
    noi di "Loading `country' data..."
    use "${data_path}/`file_num'_`country'_reg_data_`period_range'.dta", clear
    
    * Keep only necessary variables
    keep `keep_vars'
    
    noi di "Observations loaded: " _N
    
    **# =========================================================================
    **# 3A. HANDLE COUNTRY-SPECIFIC VARIABLE TRANSFORMATIONS
    **# =========================================================================
    
    * Handle SLV variable transformations
    if "`country'" == "SLV" {
        noi di "Processing SLV-specific variables..."
        local controls "urbano_t0 gedad_25_40 gedad_41_64 gedad_65plus hombre_t0 partner_t0 hh_members_t0 hh_children_t0 n_workers_t0"
        * Create idp_h if needed
        cap confirm variable idp_h
        if _rc {
            cap confirm variable idh
            if !_rc {
                encode idh, gen(idp_h)
                noi di "  - Created idp_h from idh"
            }
        }
        
        * Create idp_i if needed
        cap confirm variable idp_i
        if _rc {
            cap confirm variable idi
            if !_rc {
                encode idi, gen(idp_i)
                noi di "  - Created idp_i from idi"
            }
        }
        
        * Create period if needed
        cap confirm variable period
        if _rc {
            cap confirm variable ano
            if !_rc {
                gen period = ano
                noi di "  - Created period from ano"
            }
        }
    }
    
    * Handle BRA variable transformations
    if "`country'" == "BRA" {
        noi di "Processing BRA-specific variables..."
        
        * Create period if needed
        cap confirm variable period
        if _rc {
            cap confirm variable ano
            if !_rc {
                gen period = ano
                noi di "  - Created period from ano"
            }
        }
    }
    
    **# =========================================================================
    **# 3B. VERIFY VARIABLES AND DISPLAY SUMMARY
    **# =========================================================================
    
    noi di ""
    noi di "=== VARIABLE VERIFICATION FOR `country' ==="
    
    * Verify key variables exist
    cap confirm variable same_skill
    if _rc {
        noi di "ERROR: same_skill not found in `country'!"
        continue
    }
    
    cap confirm variable poor_t0
    if _rc {
        noi di "ERROR: poor_t0 not found in `country'!"
        continue
    }
    
    cap confirm variable vuln_t0
    if _rc {
        noi di "ERROR: vuln_t0 not found in `country'!"
        continue
    }
    
    noi di "✓ All required variables present"
    
    * Display sample sizes
    noi di ""
    noi di "=== SAMPLE SIZES BY OUTCOME FOR `country' ==="
    count if poor_t0 == 0 & !missing(fell_into_poverty)
    noi di "  Fall into poverty (poor_t0==0): " r(N)
    count if poor_t0 == 1 & !missing(escaped_poverty)
    noi di "  Escape poverty (poor_t0==1): " r(N)
    count if vuln_t0 == 0 & !missing(fell_into_vulnerability)
    noi di "  Going out middle class (vuln_t0==0): " r(N)
    count if vuln_t0 == 1 & poor_t0 == 0 & !missing(escaped_vulnerability)
    noi di "  Going in middle class (vuln_t0==1 & poor_t0==0): " r(N)
    
    * Display transition categories
    noi di ""
    noi di "=== LABOR TRANSITIONS FOR `country' ==="
    count if entered_job == 1
    noi di "  Entered job: " r(N)
    count if exited_job == 1
    noi di "  Exited job: " r(N)
    count if skill_increased == 1
    noi di "  Skill increased: " r(N)
    count if same_skill == 1
    noi di "  Same skill: " r(N)
    count if skill_decreased == 1
    noi di "  Skill decreased: " r(N)
    count if entered_job==0 & exited_job==0 & skill_increased==0 & skill_decreased==0 & same_skill==0 & !missing(entered_job)
    noi di "  Remained unemployed (reference): " r(N)
    
    **# =========================================================================
    **# 3C. RUN REGRESSIONS - SPECIFICATION 1
    **# =========================================================================
    
    noi di ""
    noi di "=== SPECIFICATION 1: WITH same_skill + base skill ==="
    
    * Outcome 1: Fall into Poverty (poor_t0==0)
    count if poor_t0 == 0 & !missing(fell_into_poverty)
    if r(N) > 0 {
        noi di "Running: Fall into Poverty (N=" r(N) ")"
        qui reg fell_into_poverty `spec1_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if poor_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s1_fall_pov
    }
    else {
        noi di "Skipping: Fall into Poverty (N=0)"
    }
    
    * Outcome 2: Escape Poverty (poor_t0==1)
    count if poor_t0 == 1 & !missing(escaped_poverty)
    if r(N) > 0 {
        noi di "Running: Escape Poverty (N=" r(N) ")"
        qui reg escaped_poverty `spec1_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if poor_t0 == 1, cluster(region_est1_t0)
        estimates store `country'_s1_esc_pov
    }
    else {
        noi di "Skipping: Escape Poverty (N=0)"
    }
    
    * Outcome 3: Going out Middle Class (vuln_t0==0)
    count if vuln_t0 == 0 & !missing(fell_into_vulnerability)
    if r(N) > 0 {
        noi di "Running: Going out Middle Class (N=" r(N) ")"
        qui reg fell_into_vulnerability `spec1_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if vuln_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s1_out_mc
    }
    else {
        noi di "Skipping: Going out Middle Class (N=0)"
    }
    
    * Outcome 4: Going in Middle Class (vuln_t0==1 & poor_t0==0)
    count if vuln_t0 == 1 & poor_t0 == 0 & !missing(escaped_vulnerability)
    if r(N) > 0 {
        noi di "Running: Going in Middle Class (N=" r(N) ")"
        qui reg escaped_vulnerability `spec1_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if vuln_t0 == 1 & poor_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s1_in_mc
    }
    else {
        noi di "Skipping: Going in Middle Class (N=0)"
    }
    
    **# =========================================================================
    **# 3D. RUN REGRESSIONS - SPECIFICATION 2
    **# =========================================================================
    
    noi di ""
    noi di "=== SPECIFICATION 2: WITHOUT same_skill + base skill ==="
    
    * Outcome 1: Fall into Poverty
    count if poor_t0 == 0 & !missing(fell_into_poverty)
    if r(N) > 0 {
        noi di "Running: Fall into Poverty (N=" r(N) ")"
        qui reg fell_into_poverty `spec2_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if poor_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s2_fall_pov
    }
    
    * Outcome 2: Escape Poverty
    count if poor_t0 == 1 & !missing(escaped_poverty)
    if r(N) > 0 {
        noi di "Running: Escape Poverty (N=" r(N) ")"
        qui reg escaped_poverty `spec2_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if poor_t0 == 1, cluster(region_est1_t0)
        estimates store `country'_s2_esc_pov
    }
    
    * Outcome 3: Going out Middle Class
    count if vuln_t0 == 0 & !missing(fell_into_vulnerability)
    if r(N) > 0 {
        noi di "Running: Going out Middle Class (N=" r(N) ")"
        qui reg fell_into_vulnerability `spec2_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if vuln_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s2_out_mc
    }
    
    * Outcome 4: Going in Middle Class
    count if vuln_t0 == 1 & poor_t0 == 0 & !missing(escaped_vulnerability)
    if r(N) > 0 {
        noi di "Running: Going in Middle Class (N=" r(N) ")"
        qui reg escaped_vulnerability `spec2_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if vuln_t0 == 1 & poor_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s2_in_mc
    }
    
    **# =========================================================================
    **# 3E. RUN REGRESSIONS - SPECIFICATION 3
    **# =========================================================================
    
    noi di ""
    noi di "=== SPECIFICATION 3: WITH same_skill, NO base skill ==="
    
    * Outcome 1: Fall into Poverty
    count if poor_t0 == 0 & !missing(fell_into_poverty)
    if r(N) > 0 {
        noi di "Running: Fall into Poverty (N=" r(N) ")"
        qui reg fell_into_poverty `spec3_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if poor_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s3_fall_pov
    }
    
    * Outcome 2: Escape Poverty
    count if poor_t0 == 1 & !missing(escaped_poverty)
    if r(N) > 0 {
        noi di "Running: Escape Poverty (N=" r(N) ")"
        qui reg escaped_poverty `spec3_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if poor_t0 == 1, cluster(region_est1_t0)
        estimates store `country'_s3_esc_pov
    }
    
    * Outcome 3: Going out Middle Class
    count if vuln_t0 == 0 & !missing(fell_into_vulnerability)
    if r(N) > 0 {
        noi di "Running: Going out Middle Class (N=" r(N) ")"
        qui reg fell_into_vulnerability `spec3_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if vuln_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s3_out_mc
    }
    
    * Outcome 4: Going in Middle Class
    count if vuln_t0 == 1 & poor_t0 == 0 & !missing(escaped_vulnerability)
    if r(N) > 0 {
        noi di "Running: Going in Middle Class (N=" r(N) ")"
        qui reg escaped_vulnerability `spec3_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if vuln_t0 == 1 & poor_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s3_in_mc
    }
    
    **# =========================================================================
    **# 3F. RUN REGRESSIONS - SPECIFICATION 4
    **# =========================================================================
    
    noi di ""
    noi di "=== SPECIFICATION 4: WITHOUT same_skill, NO base skill ==="
    
    * Outcome 1: Fall into Poverty
    count if poor_t0 == 0 & !missing(fell_into_poverty)
    if r(N) > 0 {
        noi di "Running: Fall into Poverty (N=" r(N) ")"
        qui reg fell_into_poverty `spec4_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if poor_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s4_fall_pov
    }
    
    * Outcome 2: Escape Poverty
    count if poor_t0 == 1 & !missing(escaped_poverty)
    if r(N) > 0 {
        noi di "Running: Escape Poverty (N=" r(N) ")"
        qui reg escaped_poverty `spec4_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if poor_t0 == 1, cluster(region_est1_t0)
        estimates store `country'_s4_esc_pov
    }
    
    * Outcome 3: Going out Middle Class
    count if vuln_t0 == 0 & !missing(fell_into_vulnerability)
    if r(N) > 0 {
        noi di "Running: Going out Middle Class (N=" r(N) ")"
        qui reg fell_into_vulnerability `spec4_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if vuln_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s4_out_mc
    }
    
    * Outcome 4: Going in Middle Class
    count if vuln_t0 == 1 & poor_t0 == 0 & !missing(escaped_vulnerability)
    if r(N) > 0 {
        noi di "Running: Going in Middle Class (N=" r(N) ")"
        qui reg escaped_vulnerability `spec4_vars' `controls' i.period i.region_est1_t0 [pweight=pondera] if vuln_t0 == 1 & poor_t0 == 0, cluster(region_est1_t0)
        estimates store `country'_s4_in_mc
    }
    
    **# =========================================================================
    **# 3G. EXPORT RESULTS FOR THIS COUNTRY
    **# =========================================================================
    
    noi di ""
    noi di "=== EXPORTING RESULTS FOR `country' ==="
    
    * EXPORT SPECIFICATION 1 (4 outcomes in one file)
    cap estimates dir `country'_s1_*
    if _rc == 0 {
        noi di "Exporting: 20_`country'_reg_1.xls (Spec 1: WITH same_skill + base skill)"
        
        estimates restore `country'_s1_fall_pov
        outreg2 using "${output_path}/20_`country'_reg_1.xls", ///
            replace excel label ///
            title("`country': WITH same_skill + base skill controls") ///
            ctitle("Fall into Poverty") ///
            addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
            addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, Yes, Base Skill, Yes, Sample, "poor_t0==0")
        
        cap estimates restore `country'_s1_esc_pov
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_1.xls", ///
                append excel label ctitle("Escape Poverty") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, Yes, Base Skill, Yes, Sample, "poor_t0==1")
        }
        
        cap estimates restore `country'_s1_out_mc
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_1.xls", ///
                append excel label ctitle("Going out Middle Class") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, Yes, Base Skill, Yes, Sample, "vuln_t0==0")
        }
        
        cap estimates restore `country'_s1_in_mc
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_1.xls", ///
                append excel label ctitle("Going in Middle Class") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, Yes, Base Skill, Yes, Sample, "vuln_t0==1 & poor_t0==0")
        }
    }
    
    * EXPORT SPECIFICATION 2 (4 outcomes in one file)
    cap estimates dir `country'_s2_*
    if _rc == 0 {
        noi di "Exporting: 20_`country'_reg_2.xls (Spec 2: WITHOUT same_skill + base skill)"
        
        estimates restore `country'_s2_fall_pov
        outreg2 using "${output_path}/20_`country'_reg_2.xls", ///
            replace excel label ///
            title("`country': WITHOUT same_skill + base skill controls") ///
            ctitle("Fall into Poverty") ///
            addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
            addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, No, Base Skill, Yes, Sample, "poor_t0==0")
        
        cap estimates restore `country'_s2_esc_pov
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_2.xls", ///
                append excel label ctitle("Escape Poverty") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, No, Base Skill, Yes, Sample, "poor_t0==1")
        }
        
        cap estimates restore `country'_s2_out_mc
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_2.xls", ///
                append excel label ctitle("Going out Middle Class") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, No, Base Skill, Yes, Sample, "vuln_t0==0")
        }
        
        cap estimates restore `country'_s2_in_mc
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_2.xls", ///
                append excel label ctitle("Going in Middle Class") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, No, Base Skill, Yes, Sample, "vuln_t0==1 & poor_t0==0")
        }
    }
    
    * EXPORT SPECIFICATION 3 (4 outcomes in one file)
    cap estimates dir `country'_s3_*
    if _rc == 0 {
        noi di "Exporting: 20_`country'_reg_3.xls (Spec 3: WITH same_skill, NO base skill)"
        
        estimates restore `country'_s3_fall_pov
        outreg2 using "${output_path}/20_`country'_reg_3.xls", ///
            replace excel label ///
            title("`country': WITH same_skill, NO base skill controls") ///
            ctitle("Fall into Poverty") ///
            addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
            addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, Yes, Base Skill, No, Sample, "poor_t0==0")
        
        cap estimates restore `country'_s3_esc_pov
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_3.xls", ///
                append excel label ctitle("Escape Poverty") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, Yes, Base Skill, No, Sample, "poor_t0==1")
        }
        
        cap estimates restore `country'_s3_out_mc
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_3.xls", ///
                append excel label ctitle("Going out Middle Class") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, Yes, Base Skill, No, Sample, "vuln_t0==0")
        }
        
        cap estimates restore `country'_s3_in_mc
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_3.xls", ///
                append excel label ctitle("Going in Middle Class") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, Yes, Base Skill, No, Sample, "vuln_t0==1 & poor_t0==0")
        }
    }
    
    * EXPORT SPECIFICATION 4 (4 outcomes in one file)
    cap estimates dir `country'_s4_*
    if _rc == 0 {
        noi di "Exporting: 20_`country'_reg_4.xls (Spec 4: WITHOUT same_skill, NO base skill)"
        
        estimates restore `country'_s4_fall_pov
        outreg2 using "${output_path}/20_`country'_reg_4.xls", ///
            replace excel label ///
            title("`country': WITHOUT same_skill, NO base skill controls") ///
            ctitle("Fall into Poverty") ///
            addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
            addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, No, Base Skill, No, Sample, "poor_t0==0")
        
        cap estimates restore `country'_s4_esc_pov
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_4.xls", ///
                append excel label ctitle("Escape Poverty") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, No, Base Skill, No, Sample, "poor_t0==1")
        }
        
        cap estimates restore `country'_s4_out_mc
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_4.xls", ///
                append excel label ctitle("Going out Middle Class") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, No, Base Skill, No, Sample, "vuln_t0==0")
        }
        
        cap estimates restore `country'_s4_in_mc
        if _rc == 0 {
            outreg2 using "${output_path}/20_`country'_reg_4.xls", ///
                append excel label ctitle("Going in Middle Class") ///
                addstat(Adjusted R-squared, e(r2_a), N, e(N)) ///
                addtext(Period FE, Yes, Region FE, Yes, Clustering, Region, Weight, pondera, Same_Skill, No, Base Skill, No, Sample, "vuln_t0==1 & poor_t0==0")
        }
    }
    
    noi di ""
    noi di "✓ Completed `country'"
    noi di ""
    
    * Clear estimates for next country
    estimates clear
}

**# ==============================================================================
**# 4. FINAL SUMMARY
**# ==============================================================================

noi di ""
noi di "=========================================================================="
noi di "=== COUNTRY-LEVEL ANALYSIS COMPLETED ==="
noi di "=========================================================================="
noi di ""
noi di "COUNTRIES PROCESSED: PER, BRA, ARG, DOM, SLV"
noi di ""
noi di "OUTPUT FILES GENERATED (4 per country = 20 total):"
noi di "  20_CCC_reg_1.xls - WITH same_skill + base skill controls"
noi di "  20_CCC_reg_2.xls - WITHOUT same_skill + base skill controls"
noi di "  20_CCC_reg_3.xls - WITH same_skill, NO base skill controls"
noi di "  20_CCC_reg_4.xls - WITHOUT same_skill, NO base skill controls"
noi di ""
noi di "Each file contains 4 columns:"
noi di "  Column 1: Fall into Poverty (poor_t0==0)"
noi di "  Column 2: Escape Poverty (poor_t0==1)"
noi di "  Column 3: Going out Middle Class (vuln_t0==0)"
noi di "  Column 4: Going in Middle Class (vuln_t0==1 & poor_t0==0)"
noi di ""
noi di "SPECIFICATIONS:"
noi di "  - Fixed Effects: Period + Region (within each country)"
noi di "  - Clustering: Region level (region_est1_t0)"
noi di "  - Weight: pondera"
noi di "  - Reference category: Remained unemployed"
noi di ""
noi di "=== ANALYSIS COMPLETE ==="
