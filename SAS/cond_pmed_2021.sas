
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
		> By race/ethnicity

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

libname meps "C:\MEPS";


/* Conditions file -------------------------- */
/*  row = medical condition for a person      */

title "COND file";

data cond21;
	set meps.h231;
	keep dupersid condidx icd10cdx ccsr1x ccsr2x ccsr3x;
run;

proc print data = cond21 (obs=5);
run;


/* Conditions-event link file ----------------------------- */
/*   crosswalk between conditions and medical events, PMEDs */

title "CLNK file";

data clnk21;
	set meps.h229if1;
run;

proc print data = clnk21 (obs=5);
run;


/* PMED file ----------------------------- */
/*  row = rx fill or refill for a person   */

title "PMED file";

data pmed21;
	set meps.h229a;
	keep dupersid drugidx rxrecidx linkidx rxdrgnam rxxp21x;
run;

proc print data = pmed21 (obs=5);
run;


/* !! Need to rename LINKIDX to EVNTIDX to merge to conditions !! */

title2 "Renaming LINKIDX => EVNTIDX";

data pmed21;
	set pmed21;
	rename linkidx = evntidx;
run;

proc print data = pmed21 (obs=5);
run;



/* Full-year consolidated (FYC) file --------- */
/*  row = MEPS sample person                   */

title "FYC file";

data fyc21;
	set meps.h233;
	keep dupersid choldx agelast sex racethx povcat: insurc:  perwt: varpsu varstr;
run;

proc print data = fyc21 (obs=5);
run;


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

data hl;
	set cond21;  
	where ccsr1x = 'END010' 
       or ccsr2x = 'END010' 
       or ccsr3x = 'END010';
run; 


/* Example of 'duplicate' HL conditions. This can happen when the fully-  */
/* specified ICD10s are different, but the 3-digit codes are the same     */
/*  e.g. E78.1 and E78.5 are both E78 on PUF                              */

title "COND file: 'Duplicate' ICD10s";
proc print data = hl;
	where dupersid = '2320134102'; 
run;


/* 2 - Merge files: HL <=> CLNK  ---------------------------------------- */
/*     Remember that our hl file still contains duplicates!               */ 

proc sort data = hl;     by dupersid condidx; run;
proc sort data = clnk21; by dupersid condidx; run;

data clnk_hl;
	merge hl (in=A) clnk21 (in=B);
	by dupersid condidx;
	if A and B; /* only keep records that are in both files */ 
run;


/* Revisit duplicate example after merging to CLNK. Note that the         */
/* 'duplicate' ICD10s linked to the same PMED event!                      */        

title "CLNK-HL: Duplicate ICD10s, CONDIDX, EVNTIDX";
proc print data = clnk_hl;
	where dupersid = '2320134102'; 
run;



/* 3 - De-duplicate PMED 'events' (aka fills) --------------------------- */

proc sort data = clnk_hl nodupkey out = clnk_hl_dedup;
	by dupersid evntidx;
run;


/* Revisit duplicate example after de-duplicating */

title "CLNK-HL-DEDUP: no duplicate EVNTIDX!";
proc print data=clnk_hl_dedup;
	where dupersid = '2320134102'; 
run;


/* 4 - Merge files: HL-CLNK <=> PMED  ----------------------------------- */

proc sort data = clnk_hl_dedup; by dupersid evntidx; run;
proc sort data = pmed21;        by dupersid evntidx; run;

/* Each row will be a single PMED fill (or refill!) for HL */
/* RXRECIDX = unique identifier for fill/refill */

title "hl_merged";

data hl_merged;
	merge clnk_hl_dedup (in=a) pmed21 (in=b);
	by dupersid evntidx;
	if a and b;  /* only keep records in both files */ 
run;

proc print data = hl_merged ;
	where dupersid = '2320134102'; 
run; 



/* QC: Look at top PMEDs for hyperlipidemia to see if they make sense */

proc freq data = hl_merged order = freq;
	tables rxdrgnam / nocum maxlevels=5;
run;



/* 5 - Roll up to person level ------------------------------------------ */


/* Create dummy variable for each unique fill/refill */
/*  so we can count how many fills per person        */

title "Person-level file: PMED fills and expenses for HL";

data hl_merged;
	set hl_merged;
	hl_fill = 1;
run;

proc sort data = hl_merged; by dupersid; run;
proc means data = hl_merged noprint; 
	by dupersid;  
	var  hl_fill /* fill indicator */ 
         rxxp21x /* expenditures   */;  
	output 
      out = drugs_by_pers  
      sum = n_hl_fills  /* number of fills */
            hl_drug_exp /* expenditures */; 
run;

proc print data = drugs_by_pers;
	where dupersid = '2320134102'; 
run;

* QC: check min and max of new vars ;
proc means data = drugs_by_pers min max;
	var n_hl_fills  hl_drug_exp;
run;


/* 6 - Merge onto Full-Year (FYC) file ---------------------------------- */
/*     FYC has: VARSTR, VARPSU, PERWT for everyone in sample              */
/*              CHOLDX (ever diagnosed with High Cholesterol)             */
/*              demographic variables (for regression later)              */

title "FYC file with HL PMED vars";

proc sort data = fyc21;         by dupersid; run;
proc sort data = drugs_by_pers; by dupersid; run;

data fyc_hl;
	merge fyc21  drugs_by_pers (drop = _TYPE_ _FREQ_);
	by dupersid;
	
	if n_hl_fills > 0 then hl_pmed_flag = 1;  /* create flag for anyone with PMED fill for HL     */
	else hl_pmed_flag = 0;                    /* set flag to 0 for people with no rx fills for HL */ 

	/* Set system missings caused by merging to zeroes - these are true zeroes */
	n_hl_fills0  = n_hl_fills;  if n_hl_fills  = . then n_hl_fills0 = 0;
    hl_drug_exp0 = hl_drug_exp; if hl_drug_exp = . then hl_drug_exp0 = 0; 
run;

proc print data = fyc_hl (obs = 5);
	where hl_pmed_flag = 0;
run;

proc print data = fyc_hl (obs = 5);
	where hl_pmed_flag = 1;
run;


/* Compare:                                                    */
/*   people ever-diagnosed with high cholesterol (CHOLDX = 1)  */
/*   people with PMED fill for HL                              */
    

/* Note: this is unweighted! Just to get a look at the data.  */
/*       Need to use survey procedures for actual estimates   */

title "CHOLDX vs HL_PMED";
proc freq data = fyc_hl;
	tables hl_pmed_flag*CHOLDX / missing nopercent norow nocol;
run; 


proc format;
 value gtzero
  0        = "0"
  0 - high = ">0";
run;

proc freq data = fyc_hl;
	format hl_drug_exp hl_drug_exp0 n_hl_fills n_hl_fills0 gtzero.;
	tables  hl_pmed_flag*CHOLDX*n_hl_fills*n_hl_fills0
			hl_pmed_flag*CHOLDX*hl_drug_exp*hl_drug_exp0 / list missing;
run;



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
ods graphics off; 


/* 1 - National Totals --------------------------------------------------- */

title "National Totals";
proc surveymeans data = fyc_hl sum; 
	stratum varstr;  /* stratum */ 
	cluster varpsu;  /* PSU */ 
	weight perwt21f; /* person weight */ 

	var hl_pmed_flag /* Total number of people w/ PMED fills for HL */

		n_hl_fills0  /* Total number of PMED fills for HL           */
		n_hl_fills   /*  - with missings (BAD!)                     */

		hl_drug_exp0 /* Total PMED expenditures for HL              */
		hl_drug_exp; /*  - with missings (BAD!)                     */

run;



/* 2 - Percent of people with PMED fill ---------------------------------- */
/*     Among people ever diagnosed with HL (CHOLDX = 1)                    */

title  "Percent of people with PMED fill for HL";
title2 "Among those ever-diagnosed with HL (CHOLDX = 1)";


/* Don't do this! WHERE statement removes observations from dataset, so SEs are wrong */
title3 "BAD: Using WHERE statement";
proc surveymeans data = fyc_hl mean; 
	where CHOLDX = 1; /* Among ppl ever-diagnosed with High Cholesterol   */
	stratum varstr; 
	cluster varpsu; 
	weight perwt21f; 
	var hl_pmed_flag; /* Percent of ppl with PMED fill for HL             */
run;

/* Do this instead: DOMAIN statement */
title3 "GOOD: Using DOMAIN statement";
proc surveymeans data=fyc_hl mean; 
	stratum varstr; 
	cluster varpsu; 
	weight perwt21f; 
	var hl_pmed_flag;   /* Percent of ppl with PMED fill for HL           */
	domain CHOLDX('1'); /* Among ppl ever-diagnosed with High Cholesterol */
run;



/*  3 - Per-person averages --------------------------------------------- */
/*      - Avg number of PMED fills for HL                                 */
/*      - Avg PMED expenditures for HL                                    */

/* Note that there can be some PMED fills with $0 expenditures */
proc print data = fyc_hl ;
	where hl_pmed_flag = 1 and hl_drug_exp = 0;
run;


title "Avg number of PMED fills and avg expenditures for HL";
proc surveymeans data = fyc_hl mean; 
	stratum varstr; 
	cluster varpsu; 
	weight perwt21f; 
	var n_hl_fills0  /* Number of fills per person */
        hl_drug_exp0 /* Expenditures per person    */; 

	domain CHOLDX('1')        /* Among people ever diagnosed with HL (CHOLDX = 1) */
           hl_pmed_flag('1'); /* Among people with any PMED fill for HL           */
run;



/* 4 - Regression --------------------------------------------------------------- */
/*     - Percent of people with PMED fill by RACE                                 */
 /*    - P(Any PMED for HL) = RACE + SEX + INSURANCE + POVERTY                    */


proc format;
	value racef 
		1 = "1 Hispanic"
		2 = "2 NH White" 
		3 = "3 NH Black" 
		4 = "4 NH Asian"
		5 = "5 NH Other or Mult race"
		;
run;

title "Percent of ppl with PMED fills for HL";
title2 "Among those with CHOLDX = 1";
title3 "By Race";
proc surveymeans data = fyc_hl mean; 
	format RACETHX racef.;
	stratum varstr; 
	cluster varpsu; 
	weight perwt21f; 
	var hl_pmed_flag;  
	domain CHOLDX('1')*RACETHX;
run;


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

proc surveylogistic data = fyc_hl ; 
	format RACETHX  racef. 
           sex      sexf. 
           insurc21 insurc21f. 
           povcat21 povcat21f.;

	class RACETHX(ref = '1 Hispanic')
			SEX(ref = '1 Male')
			INSURC21(ref = '1 <65 Any Private')
			POVCAT21(ref = '1 Poor/Negative') / param = ref;

	stratum varstr; 
	cluster varpsu; 
	weight perwt21f; 

	model hl_pmed_flag(event = '1') = racethx sex insurc21 povcat21; 

	domain CHOLDX('1');

	ods output ParameterEstimates = coef; /* Optional to get regression coefficeints */
run;


title "Regression coefficients";
proc print data = coef;
	where CHOLDX = 1;
	var Variable ClassVal0 Estimate StdErr tvalue ProbT;
run;

