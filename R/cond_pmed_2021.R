# -----------------------------------------------------------------------------
#
# MEPS-HC: Prescribed medicine utilization and expenditures for the treatment 
# of hyperlipidemia
# 
# This example code shows how to link the MEPS-HC Medical Conditions file to 
# the Prescribed Medicines (PMED) file for data year 2021 in order to estimate 
# the following:
#   
# National totals:
#   - Total number of people w/ at least one PMED fill for hyperlipidemia (HL)
#   - Total number of PMED fills for HL
#   - Total PMED expenditures for HL 
# 
# Percent of people with a PMED fill
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
#   - h231.sas7bdat         (2021 Medical Conditions file)
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

# install.packages("survey")     # for analysis of data from complex surveys
# install.packages("haven")      # for loading Stata (.dta) files
# install.packages("tidyverse")  # for data manipulation
# install.packages("devtools")   # for loading "MEPS" package from GitHub
# install.packages("labelled")   # for applying variable labels
# install.packages("broom")      # for making model output cleaner

# Note: if you previously installed the MEPS package and get an error about 
# the LONG file, you will need to uninstall and re-install the MEPS package 
# due to updates made to the package: 

# remove.packages("MEPS")

# To (re)install MEPS package, un-comment below and run

# library(devtools)
# install_github("e-mitchell/meps_r_pkg/MEPS")


# Load libraries

library(MEPS)     
library(survey)
library(tidyverse)
library(haven)
library(labelled)
library(broom)


# Set survey option for lonely PSUs

options(survey.lonely.psu="adjust")

# Note - there is also an option to adjust lonely PSUs *within domains*. We are
# not using it here because Stata and SAS do not have this option.  
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

pmed21 <- read_MEPS(year = 2021, type = "RX") %>% rename(EVNTIDX=LINKIDX)
cond21 <- read_MEPS(year = 2021, type = "Conditions")
clnk21 <- read_MEPS(year = 2021, type = "CLNK")
fyc21 <- read_MEPS(year = 2021, type = "FYC")


### Option 2 - load Stata data files using read_dta from the haven package 

# Replace "C:/MEPS" below with the directory you saved the files to.
# For PMED file, rename LINKIDX to EVNTIDX to merge with Conditions

# pmed21 <- read_dta("C:/MEPS/h229a.dta") %>% rename(EVNTIDX=LINKIDX)
# cond21 <- read_dta("C:/MEPS/h231.dta")
# clnk21 <- read_dta("C:/MEPS/h229if1.dta")
# fyc21  <- read_dta("C:/MEPS/h233.dta")


# Select only needed variables ------------------------------------------------

pmed21x <- pmed21 %>% select(DUPERSID, DRUGIDX, RXRECIDX, EVNTIDX, 
                             RXDRGNAM, RXXP21X)
cond21x <- cond21 %>% select(DUPERSID, CONDIDX, ICD10CDX, CCSR1X:CCSR3X)
fyc21x  <- fyc21  %>% select(DUPERSID, SEX, RACETHX, INSURC21, POVCAT21,
                             CHOLDX, VARSTR, VARPSU, PERWT21F)


# OPTIONAL: Look at table of ICD10s and CCSRs. 

cond_counts <- cond21x %>% 
  count(ICD10CDX, CCSR1X, CCSR2X, CCSR3X) 

View(cond_counts)


# Prepare data for estimation -------------------------------------------------

# Subset condition records to hyperlipidemia (any CCSR = "END010") 

hl <- cond21x %>% 
  filter(CCSR1X == "END010" | CCSR2X == "END010" | CCSR3X == "END010")


# Example to show someone with 'duplicate' hyperlipidemia conditions with
# different CONDIDXs.  This usually happens when the collapsed 3-digit 
# ICD10s are the same but the fully-specified ICD10s are different 
# (e.g., one person has different condition records for both E78.1 and 
# E78.5, which both map to END010 and collapse to E78 on the PUF).

dup_hl <- hl[duplicated(hl$DUPERSID), ]


# Using the first DUPERSID from dup_hl as an example 

hl %>% filter(DUPERSID == '2320134102')


# Merge hyperlipidemia conditions with PMED file, using CLNK as crosswalk
# Note that this can be a many-to-many merge due to the 'duplicates'! 

hl_merged <- hl %>%
  inner_join(clnk21, by = c("DUPERSID", "CONDIDX"), 
             relationship = "many-to-many") %>% 
  inner_join(pmed21x, by = c("DUPERSID", "EVNTIDX"), 
             relationship = "many-to-many") 


# Due to the potential for 'duplicate' hyperlipidemia records for the same
# person, it is necessary to de-duplicate on the unique fill identifier 
# RXRECIDX within a person.  For example, atorvastatin can be used to treat 
# BOTH high triglycerides AND high cholesterol (which are both hyperlipidemia!)
# for the same person. 

# An example illustrating the above issue. 

hl_merged %>% 
  filter(DUPERSID == "2320134102") %>% 
  select(DUPERSID, CONDIDX, RXRECIDX, RXDRGNAM, ICD10CDX, CCSR1X) 


# De-duplicate 'duplicate' fills 

hl_dedup <- hl_merged %>% 
  distinct(DUPERSID, RXRECIDX, .keep_all=T)


# Revisiting the example to show effect of de-duplicating

hl_dedup %>% 
  filter(DUPERSID == "2320134102") %>%
  select(DUPERSID, CONDIDX, RXRECIDX, RXDRGNAM, ICD10CDX, CCSR1X) 


# QC: View top PMEDS for hyperlipidemia to see if they make sense

hl_merged %>% 
  count(RXDRGNAM) %>% 
  arrange(-n)


# For each person, count the number of PMED fills and sum PMED expenditures for 
# treating hyperlipidemia. Make a flag for people with a PMED fill for
# hyperlipidemia (hl_pmed_flag)

drugs_by_pers <- hl_dedup %>% 
  group_by(DUPERSID) %>% 
  summarize(
    n_hl_fills = n_distinct(RXRECIDX),
    hl_drug_exp = sum(RXXP21X)) %>% 
  mutate(hl_pmed_flag = 1)


# Revisiting 'duplicate' fill example at the person level to show
# that we counted their fills and expenses only once 

drugs_by_pers %>% 
  filter(DUPERSID == "2320134102")


# Merge onto FYC file to capture all Strata (VARSTR) and PSUs (VARPSU) for 
# all MEPS sample persons for correct variance estimation

fyc_hl <- fyc21x %>% 
  left_join(drugs_by_pers, by="DUPERSID") %>% 
  replace_na(
    list(n_hl_fills = 0,
         hl_pmed_flag = 0,
         hl_drug_exp = 0))


# A slight tangent/example about applying and using variable labels with the
# labelled package (completely optional)

glimpse(fyc_hl)  # no labels applies
glimpse(to_factor(fyc_hl)) # labels applied


# QC: check counts of hl_pmed_flag=1 and compare to the number of rows in
# drugs_by_pers.  Confirm all NAs were overwritten to zeroes. 

table(fyc_hl$hl_pmed_flag, useNA="always")


# QC: There should be no records where hl_pmed_flag=0 and 
# (hl_drug_exp > 0 or n_hl_fills > 0)

fyc_hl %>% 
    filter(hl_pmed_flag==0 & (hl_drug_exp > 0 | n_hl_fills > 0))


# A look at CHOLDX (*ever* diagnosed with hyperlipidemia) vs. hl_pmed_flag
# (treated  for hyperlipidemia with prescribed medicines in 2021)

fyc_hl %>% 
  filter(CHOLDX >= 0) %>% # remove missing and inapplicable
  count(CHOLDX, hl_pmed_flag)


# Define survey design object  ------------------------------------------

meps_dsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT21F,
  data = fyc_hl,
  nest = TRUE) 


# ESTIMATION ------------------------------------------------------------

### National Totals:
    
svytotal(~hl_pmed_flag +    # Total people treated for HL w/ rx drugs
           n_hl_fills + # Total rx fills for hyperlipidemia
           hl_drug_exp,      # Total rx expenditures for hyperlipidemia
           design=meps_dsgn)

    
# Proportion of population with any PMED fills for HL 

svymean(~hl_pmed_flag, design=meps_dsgn)

    
### Per-person averages for people with at least one PMED fill for 
### hyperlipidemia (hl_pmed_flag = 1)

# Subset survey design object to only those with at least one PMED fill
# for hyperlipidemia

hl_pmed_dsgn <- subset(meps_dsgn, hl_pmed_flag == 1)


# Estimation of means among people with at least one PMED fill for
# hyperlipidemia 

svymean(~n_hl_fills +    # Avg # of fills for HL per person w/ HL fills
          hl_drug_exp,        # Avg PMED exp for HL per person w/ HL fills
          design = hl_pmed_dsgn) 


### Per-person averages for people ever diagnosed with high cholesterol
### (CHOLDX = 1)

# Subset survey design to only people ever diagnosed with high cholesterol

choldx_dsgn <- subset(meps_dsgn, CHOLDX == 1)


# Estimation of means among people who have ever been diagnosed with
# high cholesterol (includes people with no PMEDs for HL in 2021!)

svymean(~hl_pmed_flag + # Prop. of people with a PMED fill for HL in 2021
          n_hl_fills +  # Avg # of fills for HL per person 
          hl_drug_exp,  # Avg PMED exp for HL per person 
        design = choldx_dsgn) 


# Proportion of people with a PMED fill for HL in 2021 among those with a 
# lifetime diagnosis of high cholesterol, BY RACE 
# Using the to_factor option outputs the labels for the variable's values.
# You can also use just factor() if you don't have labels available 

svyby(~hl_pmed_flag, ~to_factor(RACETHX), design=choldx_dsgn, svymean)


# Logistic regression for (Any PMED for HL) = RACE + SEX + INSURANCE + POVERTY
# among people with a lifetime diagnosis of high cholesterol

logit <- svyglm(hl_pmed_flag ~ to_factor(RACETHX) + to_factor(SEX) + 
                to_factor(INSURC21) + to_factor(POVCAT21), 
            family="quasibinomial",
               design = choldx_dsgn)

summary(logit)


# Optional: Tidy the model output and convert to odds ratios for
# easier interpretation 

tidy_logit <- tidy(logit, exponentiate = TRUE, conf.int = TRUE)

View(tidy_logit)





