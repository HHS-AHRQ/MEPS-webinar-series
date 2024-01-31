# -----------------------------------------------------------------------------
#
# MEPS-HC: Prescribed medicine utilization and expenditures for the treatment 
# of hyperlipidemia
# 
# This example code shows how to link the MEPS-HC Medical Conditions file to 
# the Prescribed Medicines file for data year 2021 in order to estimate the 
# following:
#   
# National totals:
#   - Total number of people w/ at least one PMED fill for hyperlipidemia (HL)
#   - Total number of PMED fills for HL
#   - Total PMED expenditures for HL 
# 
# Percent of people with PMED fill
# - Among people ever diagnosed with HL (CHOLDX = 1)
#     > By race/ethnicity
# 
# Per-person averages:
#   - Avg number of PMED fills for HL
#     > Among people ever diagnosed with HL (CHOLDX = 1)
#     > Among people with any PMED fill for HL
# 
#   - Avg PMED expenditures for HL
#     > Among people ever diagnosed with HL (CHOLDX = 1)
#     > Among people with any PMED fill for HL
# 
# Logistic Regression:
#   - (Any PMED for HL) = RACE + SEX + INSURANCE + POVERTY
# 
# ----------------------------------------------------------
#   
# Input files:
#   - h229a.sas7bdat        (2021 Prescribed Medicines file)
#   - h231.sas7bdat         (2021 Conditions file)
#   - h229if1.sas7bdat      (2021 CLNK: Condition-Event Link file)
#   - h233.sas7bdat         (2021 Full-Year Consolidated file)
# 
# Resources:
#   - CCSR codes: 
#   https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv
# 
#   - MEPS-HC Public Use Files: 
#   https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp
# 
#   - MEPS-HC online data tools: 
#   https://datatools.ahrq.gov/meps-hc
# 
# 
# -----------------------------------------------------------------------------*/


# Install/load packages and set global options --------------------------------

# For each package that you don't already have installed, un-comment
# and run.  Skip this step if all packages below are already installed.

# install.packages("survey")     # for survey analysis
# install.packages("haven")      # for loading Stata (.dta) files
# install.packages("tidyverse")  # for data manipulation
# install.packages("devtools")   # for loading "MEPS" package from GitHub
# install.packages("labelled")   # for applying variable labels
# install.packages("broom")      # for making model output cleaner

# Note: if you previously installed the MEPS package and get an error about 
# the LONG file, you need to uninstall and reinstall the MEPS package 
# due to updates made to the package: 

# remove.packages("MEPS")

# To (re)install MEPS package, un-comment below and run

# library(devtools)
# install_github("e-mitchell/meps_r_pkg/MEPS")


# Load libraries





# Set survey option for lonely PSUs





# Note - there is also an option to adjust lonely PSUs within domains
# More info: https://r-survey.r-forge.r-project.org/survey/exmample-lonely.html

# options(survey.adjust.domain.lonely=TRUE)


# Load datasets ---------------------------------------------------------------

# RX = Prescribed medicines (PMED) file (record = rx fill or refill)
# Conditions = Medical conditions file (record = medical condition)
# CLNK = Conditions-event link file (crosswalk between conditions and 
#        events, including PMED events)
# FYC = Full year consolidated file (record = MEPS sample person)


### Option 1 - load data files using read_MEPS from the MEPS package

# For PMED file, rename LINKIDX to EVNTIDX to merge with Conditions





### Option 2 - load Stata data files using read_dta from the haven package 

# Replace "C:/MEPS" below with the directory you saved the files to.
# For PMED file, rename LINKIDX to EVNTIDX to merge with Conditions

# pmed20 <- read_dta("C:/MEPS/h229a.dta") %>% rename(EVNTIDX=LINKIDX)
# cond20 <- read_dta("C:/MEPS/h231.dta")
# clnk20 <- read_dta("C:/MEPS/h229if1.dta")
# fyc20  <- read_dta("C:/MEPS/h233.dta")


# Select only needed variables ------------------------------------------------






# OPTIONAL: Look at table of ICD10s and CCSRs. 





# Prepare data for estimation -------------------------------------------------

# Subset condition records to hyperlipidemia (any CCSR = "END010") 





# Example to show someone with 'duplicate' hyperlipidemia conditions with
# different CONDIDXs.  





# Using the first DUPERSID (2320134102) from dup_hl as an example 





# Merge hyperlipidemia conditions with PMED file, using CLNK as crosswalk
# Note that this is a many-to-many merge due to the 'duplicates'! 





# Due to the potential for 'duplicate' hyperlipidemia records for the same
# person, it is necessary to de-duplicate on the unique fill identifier 
# RXRECIDX within a person.  An example of the issue (DUPERSID=2320134102):





# De-duplicate 'duplicate' fills 





# Revisiting the example (DUPERSID = 2320134102)to show effect of 
# de-duplicating





# QC: View top PMEDS for hyperlipidemia to see if they make sense





# For each person, count the number of PMED fills and sum PMED expenditures for 
# treating hyperlipidemia. Make a flag for people with a PMED fill for
# hyperlipidemia (hl_pmed_flag)





# Revisiting 'duplicate' fill example (DUPERSID = 2320134102) at the person 
# level to show that we counted their fills and expenses only once 




# Merge onto FYC file to capture all Strata (VARSTR) and PSUs (VARPSU) for 
# all MEPS sample persons for correct variance estimation





# A slight tangent/example about applying and using variable labels with the
# labelled package (completely optional)





# QC: check counts of hl_pmed_flag=1 and compare to the number of rows in
# drugs_by_pers.  Confirm all NAs were overwritten to zeroes. 




# QC: There should be no records where hl_pmed_flag=0 and 
# (hl_drug_exp > 0 or number_hl_fills > 0)




# A look at CHOLDX (*ever* diagnosed with hyperlipidemia) vs. hl_pmed_flag
# (treated  for hyperlipidemia with prescribed medicines in 2021)





# Define survey design object  ------------------------------------------







# ESTIMATION ------------------------------------------------------------

### National Totals:
    



    
# Proportion of population with any PMED fills for HL 




    
### Per-person averages for people with at least one PMED fill for 
### hyperlipidemia (hl_pmed_flag = 1)

# Subset survey design object to those with at least one PMED fill
# for hyperlipidemia





# Estimation of means among people with at least one PMED fill for
# hyperlipidemia 





### Per-person averages for people ever diagnosed with high cholesterol
### (CHOLDX = 1)

# Subset survey design to only people ever diagnosed with high cholesterol





# Estimation of means among people who have ever been diagnosed with
# high cholesterol





# Proportion of people with a PMED fill for HL in 2021 among those with a 
# lifetime diagnosis of high cholesterol, BY RACE 
# Using the to_factor option outputs the labels for the variable's values.
# You can also use just factor() if you don't have labels available 





# Logistic regression for (Any PMED for HL) = RACE + SEX + INSURANCE + POVERTY





# Optional: Tidy the model output and convert to odds ratios for
# easier interpretation 






