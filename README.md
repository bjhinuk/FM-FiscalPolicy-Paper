# Gender, Ideology, and Fiscal Policy: Evidence from Finance Ministers Across a Global Panel

**Author:** Jhinuk Banerjee  
**Affiliation:** Department of Economics, University of Oklahoma  
**Contact:** jhinuk.ban1@ou.edu  
**Course:** ECON 5253 — Data Science for Economists, Spring 2026  

---

## Overview

This replication package reproduces all tables, figures, and results in the
paper "Gender, Ideology, and Fiscal Policy: Evidence from Finance Ministers
Across a Global Panel." The analysis uses a single master Stata do-file
(`FullWhoGovAll.do`) that loads the pre-merged analysis dataset, constructs
all variables, estimates all models, and exports all LaTeX table files and
figures. A replicator who has access to the analysis dataset and the required
Stata packages should be able to reproduce all results by running the single
do-file and then compiling `main.tex`. Estimated total run time is
approximately 10--15 minutes on a standard laptop.

---

## Data Availability and Provenance

### Statement about Rights

I certify that I have legitimate access to and permission to use all data
used in this paper. The underlying raw datasets (WhoGov, GLID, IMF WEO) are
publicly available at no cost from the sources listed below. The merged
analysis dataset (`WhoGov(w+cs)+GLID_WEO.dta`) was constructed by the
author and is derived entirely from these public sources.

### Summary of Data Availability

The raw source datasets are publicly available but are **not included** in
this repository due to file size (the merged `.dta` file is 56.7 MB). A
replicator must download the raw files from the sources below and run the
data construction section of the do-file, or request the merged analysis
dataset from the author directly at jhinuk.ban1@ou.edu.

### Data Sources

| Dataset | Files Used | Format | Provided | Source / Citation |
|---|---|---|---|---|
| WhoGov (within-country) | `WhoGov-within.dta` | `.dta` | No | Nyrup & Bramwell (2020) |
| WhoGov (cross-sectional) | `WhoGov_cross-sectional.dta` | `.dta` | No | Nyrup & Bramwell (2020) |
| Global Leader Ideology Dataset (GLID) | `global_leader_ideologies.dta` | `.dta` | No | Brast et al. (2023) |
| IMF World Economic Outlook | April 2024 release, downloaded via IMF API | `.dta` | No | IMF (2024) |
| **Analysis dataset (merged)** | `WhoGov(w+cs)+GLID_WEO.dta` | `.dta` | **On request** | Constructed by author |

#### WhoGov
Nyrup, Jacob, and Stuart Bramwell. 2020. "Who Governs? A New Global Dataset
on Members of Cabinets." *American Political Science Review* 114(4):
1366--1374. Data available at: https://whogoverns.eu

#### GLID
Brast, Benjamin, Carl Henrik Knutsen, Tore Wig, and Sirianne Dahlum. 2023.
"The Global Leader Ideology Dataset (GLID)." Working Paper. Data available
at: https://doi.org/10.7910/DVN/YUR6EB (Harvard Dataverse)

#### IMF World Economic Outlook
International Monetary Fund. 2024. *World Economic Outlook Database*, April
2024 edition. Washington, DC: IMF. Available at:
https://www.imf.org/en/Publications/WEO/weo-database/2024/April

### Variable Construction

The Finance Minister ideology variable (`fm_ideology`) was constructed by
the author using AI-assisted (Claude, Anthropic) coding of Wikipedia
biographical pages for each party represented in the sample, in the party's
official language and in English, and then cross-validated against the
head-of-government ideology variable from GLID. Agreement between the two
sources exceeds 87% at the country-year level; discrepancies were resolved
by hand using party platform documents.

The two instrumental variables were constructed as follows:

- **IV1 (`iv10_relative_cabinet`):** Number of women in non-Finance cabinet
  portfolios in country *i*, year *t*, minus the mean for the country's UN
  region and decade group. Constructed from WhoGov's `n_female_minister`
  variable.
- **IV2 (`fm_age`):** Finance Minister age at appointment, calculated as
  the observation year minus the minister's birth year from WhoGov's
  `birthyear` variable.

---

## Computational Requirements

### Software

| Software | Version | Purpose |
|---|---|---|
| Stata | 19.5 SE | All data construction, estimation, and table/figure export |
| pdflatex | TeX Live 2024 | Compilation of written report and presentation |

### Required Stata Packages

The following user-written packages must be installed before running the
do-file. Install all from SSC:

```stata
ssc install ivreghdfe,  replace
ssc install ivreg2,     replace
ssc install ranktest,   replace
ssc install reghdfe,    replace
ssc install ftools,     replace
ssc install estout,     replace
ssc install coefplot,   replace
```

### Hardware

All results were produced on a MacBook Pro with Apple M-series chip, 16 GB
RAM, macOS Sequoia 15. The do-file requires approximately 4 GB of free RAM
and 500 MB of free disk space for the analysis dataset and outputs.

### Estimated Run Time

| Section of do-file | Estimated time |
|---|---|
| Data loading and variable construction | ~1 minute |
| Descriptive statistics tables | ~1 minute |
| First-stage and IV diagnostics | ~3 minutes |
| TWFE and ideology results | ~3 minutes |
| IV main results | ~3 minutes |
| Robustness checks | ~4 minutes |
| Figure generation | ~1 minute |
| **Total** | **~15 minutes** |

---

## Repository Contents

```
FinalProject/
│
├── README.md                              <- This file
├── References.bib                         <- BibTeX bibliography file
├── main.tex                               <- LaTeX source of written report
├── main.pdf                               <- Compiled written report (PDF)
├── presentation.tex                       <- Beamer source (5-slide deck)
├── presentation.pdf                       <- Compiled presentation (PDF)
├── FullWhoGovAll.do                       <- Master Stata do-file
│
├── desc_stats_full.tex                    <- Table A1: Full summary statistics
├── desc_stats_bygender.tex                <- Table A2: By FM gender
├── desc_region_femfm.tex                  <- Table A3: By UN region
├── desc_decade_femfm.tex                  <- Table A4: By decade
├── desc_ideology_femfm.tex                <- Table A5: Ideology by gender
├── iv_firststage_compare.tex              <- Table 6: First-stage comparison
├── table1_instrument_diagnostics.tex      <- Table 7: Preferred first stage
├── table2_twfe_baseline.tex               <- Table 8: TWFE baseline
├── table3a_ideology_main.tex              <- Table 9: Ideology only
├── table3b_gender_ideology.tex            <- Table 10: Gender + ideology
├── table3c_gender_ideology_interaction.tex <- Table 11: Interaction
├── table3d_women_ideology_only.tex        <- Table 12: Women only
├── table4_iv_main.tex                     <- Table 13: Just-identified IV
├── table4_iv_overid.tex                   <- Table 14: Overidentified IV
├── robustness_block1_bal.tex              <- Table 15: Sample restrictions (balance)
├── robustness_block1_prim.tex             <- Table 16: Sample restrictions (primary)
├── robustness_block2_bal.tex              <- Table 17: Spec checks (balance)
├── robustness_block2_prim.tex             <- Table 18: Spec checks (primary)
├── robustness_block3_cumulative.tex       <- Table 19: Cumulative treatment
├── robustness_block3_ideology.tex         <- Table 20: Ideology split treatment
├── robustness_block4_placebo.tex          <- Table 21: Placebo test
│
└── fig1_femfm_trend.pdf                   <- Figure 1: Female FM share by year
```

---

## Replication Instructions

### Step 1: Install required Stata packages

Open Stata and run the `ssc install` commands listed above under
**Required Stata Packages**.

### Step 2: Set the working directory path

Open `FullWhoGovAll.do`. At the top of the file, update the two global
macros to point to your local directories:

```stata
global datapath  "/path/to/your/data/"       // folder containing the .dta file
global outpath   "/path/to/your/FinalProject/" // folder where outputs will be saved
```

No other path edits are needed anywhere in the do-file.

### Step 3: Place the analysis dataset

Place `WhoGov(w+cs)+GLID_WEO.dta` in the folder defined by `$datapath`.

### Step 4: Run the do-file

In Stata, run:

```stata
do "/path/to/your/FinalProject/FullWhoGovAll.do"
```

Or open the file in the Stata do-file editor and click **Run**. The do-file
will automatically produce all `.tex` table files and `fig1_femfm_trend.pdf`
in the folder defined by `$outpath`.

### Step 5: Compile the written report

From the terminal (or your LaTeX editor), run pdflatex twice to resolve
cross-references:

```bash
cd /path/to/FinalProject
pdflatex main.tex
pdflatex main.tex
```

This produces `main.pdf`.

### Step 6: Compile the presentation

```bash
pdflatex presentation.tex
```

This produces `presentation.pdf`.

---

## Description of Do-File Sections

The master do-file `FullWhoGovAll.do` is organized into the following
clearly commented sections:

| Section | Description | Tables/Figures Produced |
|---|---|---|
| **0. Setup** | Load data, install checks, define globals and controls | — |
| **1. Descriptive statistics** | Summary stats full sample, by gender, by region, by decade, ideology distribution | Tables A1--A5 |
| **2. Instrument construction** | Generate IV1 and IV2; run first-stage regressions across FE specifications | Tables 6--7 |
| **3. TWFE baseline** | Two-way FE regressions for fiscal balance, primary balance, structural balance with and without controls | Table 8 |
| **4. Ideology analysis** | Ideology-only, joint gender+ideology, gender×ideology interaction, women-only subsample | Tables 9--12 |
| **5. IV main results** | Just-identified IV (IV1 only) and overidentified IV (IV1+IV2) | Tables 13--14 |
| **6. Robustness** | Sample restrictions, specification checks, alternative treatment definitions, placebo test | Tables 15--21 |
| **7. Figure** | Time-series line plot of female FM appointment share by year | Figure 1 |

---

## Notes on Reproducibility

- The placebo test (Robustness Block 4) uses `set seed 1234` for exact
  reproducibility of the random reassignment.
- All regressions use country-clustered standard errors throughout.
- The preferred IV specification uses region and year fixed effects (not
  country fixed effects) because all instruments lose relevance under
  country FE — this is documented in Table 6 and discussed in Section 4
  of the paper.
- The `ivreghdfe` command requires `ftools`, `reghdfe`, `ivreg2`, and
  `ranktest` as dependencies; ensure all are installed.

---

## References

Brast, Benjamin, Carl Henrik Knutsen, Tore Wig, and Sirianne Dahlum. 2023.
"The Global Leader Ideology Dataset (GLID)." Working Paper.
https://doi.org/10.7910/DVN/YUR6EB

International Monetary Fund. 2024. *World Economic Outlook Database*, April
2024 edition. Washington, DC: IMF.
https://www.imf.org/en/Publications/WEO/weo-database/2024/April

Nyrup, Jacob, and Stuart Bramwell. 2020. "Who Governs? A New Global Dataset
on Members of Cabinets." *American Political Science Review* 114(4):
1366--1374. https://doi.org/10.1017/S0003055420000490
