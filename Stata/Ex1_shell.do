/* ------------------------------------------------------------

MEPS-HC: Prescribed medicine utilization and expenditures for the treatment of hyperlipidemia


This example code shows how to link the MEPS-HC Medical Conditions file to the 
Prescribed Medicines file for data year 2021 in order to estimate the following:

National totals:
   - Total number of people w/ at least one PMED fill for hyperlipidemia (HL)
   - Total number of PMED fills for HL
   - Total PMED expenditures for HL 

Percent of people with PMED fill
   - Among people ever diagnosed with HL (CHOLDX = 1)

Per-person averages:
   - Avg number of PMED fills for HL
        > Among people ever diagnosed with HL (CHOLDX = 1)
		> Among people with any PMED fill for HL

   - Avg PMED expenditures for HL
        > Among people ever diagnosed with HL (CHOLDX = 1)
		> Among people with any PMED fill for HL

Logitistic Regression:
   - (Any PMED for HL) = RACE + SEX + INSURANCE + POVERTY

----------------------------------------------------------

Input files:
  - h229a.sas7bdat        (2021 Prescribed Medicines file)
  - h231.sas7bdat         (2021 Conditions file)
  - h229if1.sas7bdat      (2021 CLNK: Condition-Event Link file)
  - h233.sas7bdat         (2021 Full-Year Consolidated file)

Resources:
  - CCSR codes: 
    https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv

  - MEPS-HC Public Use Files: 
    https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp

  - MEPS-HC online data tools: 
    https://datatools.ahrq.gov/meps-hc

	
-----------------------------------------------------------------------------*/


clear
set more off
capture log close
cd C:\MEPS
log using Ex1, replace 

****************************
/* condition linkage file */
****************************
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h229i/h229if1dta.zip" "h229if1dta.zip", replace
unzipfile "h229if1dta.zip", replace 
use h229if1, clear
rename *, lower
save CLNK_2021, replace

********************************
/* PMED file, person-Rx-level */
********************************
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h229a/h229adta.zip" "h229adta.zip", replace
unzipfile "h229adta.zip", replace
use DUPERSID DRUGIDX RXRECIDX LINKIDX RXDRGNAM RXXP21X using h229a, clear
rename *, lower
rename linkidx evntidx
save PM_2021, replace

****************************************
/* FY condolidated file, person-level */
****************************************
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h233/h233dta.zip" "h233dta.zip", replace
unzipfile "h233dta.zip", replace 
use DUPERSID SEX RACETHX CHOLDX INSURC21 POVCAT21 VARSTR VARPSU PERWT21F using h233, clear
rename *, lower
save FY_2021, replace

**********************************************************************
/* Conditions file, person-condition-level, subset to hyperlipidemia */
**********************************************************************
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h231/h231dta.zip" "h231dta.zip", replace
unzipfile "h231dta.zip", replace

use DUPERSID CONDIDX ICD10CDX CCSR1X-CCSR3X using h231, clear
rename *, lower
keep if ccsr1x == "END010" | ccsr2x == "END010" | ccsr3x == "END010"
// inspect conditions file
sort dupersid condidx
list dupersid condidx icd10cdx if _n<20

****************************************************************
/* merge to CLNK file by dupersid and condidx, drop unmatched */
****************************************************************

// inspect file


// drop observations for that do not match

*******************************************************************************************
/* merge to prescribed meds file by dupersid and evntidx, drop unmatched, drop duplicates */
*******************************************************************************************

// inspect file


// drop observations for that do not match


// drop duplicates 


// inspect file 

*************************************************************************************
/* collapse to person-level (DUPERSID), sum to get number of fills and expenditures */
*************************************************************************************
collapse
/* merge to FY file, create flag for any Rx fill for HL */

*******************************************
/* Analysis                         */
*******************************************
/* Set survey options */


/* total number of people with 1+ Rx fills for HL */


/* Total rx fills for the treatment of hyperlipidemia */


/* Total rx expenditures for the treatment of hyperlipidemia */


/* percent of people with PMED fills for HL */


/* mean number of Rx fills for hyperlipidemia per person */


/* mean expenditures on Rx fills for hyperlipidemia per person, among those with any */


/* percent of people with PMED fills for HL */


/* logistic regression coefficients on any Rx fills for hyperlipidemia, among those with any */



