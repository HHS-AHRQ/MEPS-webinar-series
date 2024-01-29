
*----------------------------------------------------------------------------------------------

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

Regression:
   - Percent of people with PMED fill by RACE
   - P(Any PMED for HL) = RACE + SEX + INSURANCE + POVERTY

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

----------------------------------------------------------------------------;



*--------------------------------------------------------------------------
 LOAD DATA   
 
 1 - Download SAS files from meps.ahrq.gov
 2 - Set libname for where MEPS SAS data files are saved on your computer  
 3 - Read in PUFs and keep only needed variables
*--------------------------------------------------------------------------;






/* Conditions file -------------------------- */
/*  row = medical condition for a person      */

title "COND file";





/* Conditions-event link file ----------------------------- */
/*   crosswalk between conditions and medical events, PMEDs */

title "CLNK file";






/* PMED file ----------------------------- */
/*  row = rx fill or refill for a person   */

title "PMED file";





/* !! Need to rename LINKIDX to EVNTIDX to merge to conditions !! */

title2 "Renaming LINKIDX => EVNTIDX";






/* Full-year consolidated (FYC) file --------- */
/*  row = MEPS sample person                   */

title "FYC file";







*---------------------------------------------------------------------------
 PREPARE DATA 

 1 - Subset COND file to only hyperlipidemia records (COND => HL)
 2 - Merge files: HL <=> CLNK 
 3 - De-duplicate PMED 'events'
 4 - Merge files: HL-CLNK <=> PMED
 5 - Roll up to person-level
 6 - Merge onto Full-Year (FYC) file
 
*---------------------------------------------------------------------------;


/* 1 - Subset COND file to only hyperlipidemia records ------------------ */
/*     Hyperlipidemia: CCSR = "END010"                                    */



/* Example of 'duplicate' HL conditions. This can happen when the fully-  */
/* specified ICD10s are different, but the 3-digit codes are the same     */
/*  e.g. E78.1 and E78.5 are both E78 on PUF                              */

title "COND file: 'Duplicate' ICD10s";
proc print data = hl;
	where dupersid = '2320134102'; 
run;


/* 2 - Merge files: HL <=> CLNK  ---------------------------------------- */
/*     Remember that our hl file still contains duplicates!               */ 





/* Revisit duplicate example after merging to CLNK. Note that the         */
/* 'duplicate' ICD10s linked to the same PMED event!                      */        

title "CLNK-HL: Duplicate ICD10s, CONDIDX, EVNTIDX";
proc print data = clnk_hl;
	where dupersid = '2320134102'; 
run;



/* 3 - De-duplicate PMED 'events' (aka fills) --------------------------- */






/* Revisit duplicate example after de-duplicating */

title "CLNK-HL-DEDUP: no duplicate EVNTIDX!";
proc print data=clnk_hl_dedup;
	where dupersid = '2320134102'; 
run;


/* 4 - Merge files: HL-CLNK <=> PMED  ----------------------------------- */



/* Each row will be a single PMED fill (or refill!) for HL */
/* RXRECIDX = unique identifier for fill/refill */

title "hl_merged";


proc print data = hl_merged ;
	where dupersid = '2320134102'; 
run; 



/* QC: Look at top PMEDs for hyperlipidemia to see if they make sense */






/* 5 - Roll up to person level ------------------------------------------ */


/* Create dummy variable for each unique fill/refill */
/*  so we can count how many fills per person        */



title "Person-level file: PMED fills and expenses for HL";
proc print data = drugs_by_pers;
	where dupersid = '2320134102'; 
run;

* QC: check min and max of new vars ;




/* 6 - Merge onto Full-Year (FYC) file ---------------------------------- */
/*     FYC has: VARSTR, VARPSU, PERWT for everyone in sample              */
/*              CHOLDX (ever diagnosed with High Cholesterol)             */
/*              demographic variables (for regression later)              */

title "FYC file with HL PMED vars";







/* Compare:                                                    */
/*   people ever-diagnosed with high cholesterol (CHOLDX = 1)  */
/*   people with PMED fill for HL                              */
    

/* Note: this is unweighted! Just to get a look at the data.  */
/*       Need to use survey procedures for actual estimates   */

title "CHOLDX vs HL_PMED";







*--------------------------------------------------------------------------
 ESTIMATION   
 
 1 - National totals:
     - Total number of people w/ at least one PMED fill for hyperlipidemia (HL)
     - Total number of PMED fills for HL
     - Total PMED expenditures for HL 

 2 - Percent of people with PMED fill
     - Among people ever diagnosed with HL (CHOLDX = 1)

 3 - Per-person averages:
     - Avg number of PMED fills for HL
        > Among people ever diagnosed with HL (CHOLDX = 1)
		> Among people with any PMED fill for HL

     - Avg PMED expenditures for HL
        > Among people ever diagnosed with HL (CHOLDX = 1)
		> Among people with any PMED fill for HL

 4 - Regression:
     - Percent of people with PMED fill by RACE
     - P(Any PMED for HL) = RACE + SEX + INSURANCE + POVERTY

*--------------------------------------------------------------------------;

/* Optional - suppress graphics */




/* 1 - National Totals --------------------------------------------------- */

title "National Totals";




/* 2 - Percent of people with PMED fill ---------------------------------- */
/*     Among people ever diagnosed with HL (CHOLDX = 1)                    */

title  "Percent of people with PMED fill for HL";
title2 "Among those ever-diagnosed with HL (CHOLDX = 1)";



/* Don't do this! WHERE statement removes observations from dataset, so SEs are wrong */
title3 "BAD: Using WHERE statement";




/* Do this instead: DOMAIN statement */
title3 "GOOD: Using DOMAIN statement";




/*  3 - Per-person averages --------------------------------------------- */
/*      - Avg number of PMED fills for HL                                 */
/*      - Avg PMED expenditures for HL                                    */

/* Note that there can be some PMED fills with $0 expenditures */


title "Avg number of PMED fills and avg expenditures for HL";



/* 4 - Regression --------------------------------------------------------------- */
/*     - Percent of people with PMED fill by RACE                                 */
 /*    - P(Any PMED for HL) = RACE + SEX + INSURANCE + POVERTY                    */


title "Percent of ppl with PMED fills for HL";
title2 "Among those with CHOLDX = 1";
title3 "By Race";






/* Logistic regression ------------------ */

proc format;
	value sexf
		1 = "1 Male"
  		2 = "2 Female";

	value racef 
		1 = "1 Hispanic"
		2 = "2 NH White" 
		3 = "3 NH Black" 
		4 = "4 NH Asian"
		5 = "5 NH Other or Mult race";

	value insurc21f  
		-1 = "-1 Inapplicable"
		1 = "1 <65 Any Private"
		2 = "2 <65 Public Only"
		3 = "3 <65 Uninsured"
		4 = "4 65+ Medicare Only"
		5 = "5 65+ Medicare and Private"
		6 = "6 65+ Medicare and Other Pub Only"
		7 = "7 65+ Uninsured"
		8 = "8 65+ No Medicare and Any Public/Private";

	value povcat21f  
		1 = "1 Poor/Negative"
		2 = "2 Near Poor"
		3 = "3 Low Income"
		4 = "4 Middle Income"
		5 = "5 High Income";  

run;


ods html close; ods html;


title "Regression modeling Pr(hl_pmed_flag = 1)";


title "Regression coefficients";
