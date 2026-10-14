# datadoc

Version 1.2.7 

A Stata Command to export a nice looking data dictionary/codebook to Microsoft Word docx, aestheticallly inspired by the codebooks distributed by ICPSR with their datasets.

## Contents
- [Description](#description)
- [Installation](#installation)
- [Quick Start](#quickstart)
- [Syntax](#syntax)
- [Options and defaults](#options)
- [Data representation and variable type](#classification)
- [Identifier detection and status](#identifiers)
- [Variable metadata and documentation](#metadata)
- [Sections and report ordering](#sections)
- [Dataset notes](#datasetnotes)
- [Counts, missing values, and distributions](#reporting)
- [Survey sampling characteristics](#survey)
- [Progress and diagnostic output](#progress)
- [Word document appearance](#appearance)
- [Examples](#examples)
- [Stored results](#results)
- [Metadata frame](#metadata)
- [Document handling, limits, and requirements](#requirements)

<a id="description"></a>

## Description

`datadoc` creates a Microsoft Word `.docx` codebook from the current Stata frame. By default and with no additional preparation needed, the codebook reports a variable inventory table and in-depth variable descriptions that include the variable name and label, value labels, counts of valid observations, data missingness, applicable summary statistics, and observation distributions. If the data have been `svyset` before datadoc is run, the codebook will also include the survey sampling information declared to `svyset`. Whether data are `svyset` or not, all counts, percentages, and summary statistics are reported unweighted.

Additional information about the study (such as P.I. or funder) can be optionally provided to datadoc as command options for inclusion in the codebook. Stata `notes:` appended to the dataset or to individual variables are included in the report by default. 

Users may use Stata to save variable metadata using Stata `characteristics`. Metadata, such as the original item number or verbatim question wording, will be included in the codebook if set prior to executing `datadoc`. See [Variable metadata](#metadata) below for an overview. 

Metadata calculated and read for the codebook can optionally be saved in a new Stata data frame for further review after `datadoc` completes.

A complete `datadoc` codebook will generally include:
 
- Study information, codebook generation date/time, Stata version, and datadoc version.
- Native dataset notes when present, followed by source filename and selected-sample information if the user restricted datadoc using `if` or `in`.
- A summary of the codebook’s conventions
- A data inventory table, with variable names hyperlinked to their detailed codebook entries
- Detailed variable descriptions documenting variable contents plus as much or as little optional metadata as desired. Most metadata should be set in advance using Stata's `characteristics` feature; an Excel template to quickly generate Stata code to set the variable metadata characteristics is included in the datadoc distribution.
- Survey sampling information reported to `svyset` when data have been `svyset`.
- A missing-data report

<a id="installation"></a>

## Installation

Stata 19 or later is required. 

**Install directly from GitHub:**
```stata
net from "https://raw.githubusercontent.com/elpus/datadoc/main/"
net install datadoc
```

No additional community-contributed Stata packages are required.

<a id="quickstart"></a>

## Quick start

```stata
sysuse auto, clear
datadoc using "auto_codebook.docx", replace
```

Default output includes full quantitative summary statistics, distributions/value label dictionaries for variables with a user-configurable number of distinct values or fewer, a missing-data report, and a summary of Survey sampling/weighting (when the data have been `svyset`). 

<a id="syntax"></a>

## Syntax

```text
datadoc [varlist] [if] [in] using filename [, options]
```

`using filename` is required. No options are required as each has a reasonable default. If the `varlist` is omitted, all variables in the current data frame are included. `if` and `in` select subsets of observations which affects all distributions and summary statistics. Use double quotes around `using` filenames containing spaces. A `.docx` extension is appended when absent; an existing extension is recognized case-insensitively.

At least one report variable and one selected observation are required. If an output file of the same name as given in `using` exists, `datadoc` will not overwrite the document unless the `replace` option is specified.

<a id="options"></a>

## Options and defaults

### Selection and output

| Option | Default and function |
|---|---|
| `replace` | Default: Off. Allow overwriting the Word output file. |
| `exclude(varlist)` | Default: None. Used to omit variables from the codebook and metadata. |
| `metaframe(name)` | Default: None. If specified, metadata are retained one row per reported variable in a new Stata data frame. |

When `exclude()` is specified, at least one variable must not be excluded for `datadoc` to run. Existing `metaframe()` names are rejected, including with `replace`. Without the `metaframe()` option, metadata are discarded after successful completion. `replace` applies only to the Word file.

### Study information

| Option | Default and function |
|---|---|
| `title(string)` | Default: Dataset label; otherwise Data codebook. Set the centered report title. |
| `pi(string)` | Default: Omitted. Set principal investigator information. |
| `affiliation(string)` | Default: Omitted. Set institutional affiliation. |
| `funding(string)` | Default: Omitted. Set funding information. |
| `abstract(string)` | Default: Omitted. Set a study abstract. |

If no title is specified, the title defaults to the Stata dataset label (if present) or to “Data codebook” when the dataset does not have a label. When no PI, affiliation, funding, or abstract options are set, these blocks are excluded from the codebook.

<a id="variable-type"></a>

### Variable-type overrides

| Option | Default and function |
|---|---|
| `quantitative(varlist)` | Declare variables to be Quantitative; must be numeric |
| `continuous(varlist)` | Declare variables to be Continuous; must be numeric |
| `discrete(varlist)` | Declare variables to be Discrete; must be numeric (can have fractional values) |
| `categorical(varlist)` | Declare variables to be Categorical; may be numeric or string |
| `nominal(varlist)` | Declare variables to be Nominal; may be numeric or string |
| `ordinal(varlist)` | Declare variables to be Ordinal; numeric variables only. |
| `id(varlist)` | Declare variables to be an Identifier; numeric or string variables. |
| `datevars(varlist)` | Declare variables to be Date/Time; numeric variables only; does not assign formats or convert codes. |

Variable type classifications, whether user-specified or detected, affect which summary statistics are computed and shown in the detailed entry for the variable in the created codebook. `datadoc` will automatically detect a variable type, but the detection will occasionally be incorrect. When these options are used, automatic detection is overriden. 

Variable type can also be set using a [Metadata](#metadata) `doc_vartype` characteristic, however, declaring the options when calling `datadoc` overrides the metadata.


### Summary and distribution controls

| Option | Default and function |
|---|---|
| `summary(mode)` | Can be `basic` or `full`. Use `basic` for fewer summary statistics; default is full |
| `maxvalues(#)` | Set the max number of distinct valid values for a distribution table to be included in the codebook; distribution tables are suppressed for variables exceeding the max; default is 25 |
| `missinglabels(code "label" ...)` | Set labels for missing values . and .a-.z.; does not change the labels in the dataset, only in the codebook |
| `nodistributions` | Omits all distribution tables; default is off|

`summary()` only accepts `basic` or `full`. It controls output for variables that are Quantitative, Continuous, and Discrete output, not other types. Both modes retain the full statistics calculated for the classification in metadata.

`maxvalues()` considers observed nonmissing values only. Observed missing categories and unobserved defined codes do not count toward this eligibility limit. A fixed rule suppresses all zero-frequency defined rows when their count exceeds 10; this threshold is not currently configurable. This means the distribution table will not act as a value label dictionary if 10 or more of the defined labeled values have no observations.

`missinglabels()` accepts any subset of `.`, `.a`–`.z`, with one nonempty label per code. Quote multiword labels. Duplicate codes, nonmissing codes, and empty labels are rejected. Overrides apply to the specified code across all reported numeric variables. Unspecified codes retain any nonblank active labels; otherwise missing-code labels display `(missing)` when a Label column is present.

```stata
datadoc using "missing_codes.docx", replace ///
    missinglabels(. "Not recorded" .a "Not applicable" .b "Refused" .z "Other reason")
```

`nodistributions` omits frequency tables. Separate defined-values dictionaries are not generated if `nodistributions` is set.

### Appearance and pagination

| Option | Default and function |
|---|---|
| `fontsize(#)` | Default: 9. Normal text size in points; real values from 4 through 48. |
| `fontname(string)` | Default: Arial. Set the font choice |
| `decimals(#)` | Default: 2. Statistic decimals; integer values from 0 through 10. |
| `strwidth(#)` | Default: 100. Unicode-character limit for string-value displays; integer of at least 10. |
| `pagebreak` | Default: Off. Start every variable description on a new page. |
| `misshighlight(#)` | Default: 10. Highlight missing-data rows strictly above this percentage; real values from 0 through 100. |

Normal size applies to body text, tables, variable banners, and documentation headings. Major headings and description-section headings use `max(12, fontsize + 3)` points. The title uses 14 points. Inventory section names use bold normal-size text. Multiword font names should be quoted with double quotes. Empty or whitespace-only `fontname()` selects Arial.

Percentages use two decimals. All-integer numeric variables display integer minima, maxima, percentiles, and medians without decimals. Fractional results, means, SDs, skewness, and kurtosis use the number of decimal places specified in `decimals()`. Date/Time summaries use the existing format. `strwidth()` shortens string-value displays with an ellipsis; full values determine frequencies and distinct counts. It does not shorten notes, section names, units, or other documentation.

If using codebook sections to group variables, there is a page break after the final variable in a section. A section boundary and `pagebreak` do not create duplicate breaks before the same variable. The first variable follows Variable descriptions on its starting page. `misshighlight()` colors rows that exceed the given percentage threshold of missingness in the missing-data report at the end of the codebook.

### Messages and review diagnostics

| Option | Default and function |
|---|---|
| `quiet` | Suppress calculation/rendering progress and completion messages; still produces diagnostic tables; this is different behavior than Stata's `quietly` prefix; default is off. |
| `reportwarnings` | Adds Review diagnostics to the Word document; default is off. |

`quiet` suppresses the version banner, calculation progress, rendering progress, saving message, and final saved-file message. Classification reviews, the inferred-Identifier review, and undefined-code diagnostics notices remain visible even under `quiet`. Stata may print its own save confirmation. Stata’s `quietly` prefix suppresses Results output separately from datadoc’s `quiet` option.

`reportwarnings` appends Review diagnostics after the missing-data report in the generated Word docx. It includes inferred numeric Quantitative/Categorical warnings and valid observations with codes absent from active label definitions. If none are generated, the section states this. The separate inferred-Identifier matching-rule table is shown in the Stata Results window only and is not added to the docx codebook by this option.

<a id="classification"></a>

## Data representation and variable type

In the DOCX codebook created, `Data Type` is used to identify whether the data are numeric, string, or date/time and `Variable Type` is used to distinguish between quantitative and categorical variables. The `Variable type` affects the choice of summary statistics displayed in the codebook. 

| Representation | Data Type |
|---|---|
| String storage | String |
| Numeric storage | Numeric |
| Numeric with format beginning `%t` | Numeric (Date/Time) |

Storage reports how Stata is storing the data in the variable: `byte`, `int`, `long`, `float`, `double`, `str#`, or `strL`; Format reports the existing Stata display format. Classification overrides do not change either field or Data Type. For example, a numeric variable with value labels (thus making the variable categorical) still reports the underlying Numeric data representation.

### Variable type assignment

The logic behind variable type assignment uses the following priority order: (1) `datadoc` [command option](#variable-type), (2) nonempty `doc_vartype` [characteristic metadata](#metadata) set in the Stata data file, (3) `datadoc` automatic Identifier detection searching for observation ID variables, and finally (4) the remaining representation/format/value-label rules examining the data contained in the variable. If the metadata frame is saved, the inference used to classify the variable is saved as metadata.

| Automatic condition | Variable Type |
|---|---|
| Eligible name/label Identifier match | Identifier |
| Otherwise string | Text |
| Otherwise numeric with `%t` format | Date/Time |
| Otherwise numeric with an active label definition | Categorical |
| Otherwise numeric | Quantitative |

An active value label is an attached definition available in the working data frame with at least one defined code. 


### Summaries employed by variable type

| Variable Type | Summary statistics in the codebook |
|---|---|
| Quantitative, Continuous, Discrete; full | Mean, SD, minimum, p1, p5, p10, p25, median, p75, p90, p95, p99, maximum, skewness, kurtosis. |
| Quantitative, Continuous, Discrete; basic | Mean, SD, Minimum, Median, Max, in that order; SD is italicized. |
| Ordinal | Minimum, p25, median, p75, maximum. |
| Date/Time | Minimum, median, maximum in the existing format. |
| Non-Identifier strings | Minimum, mean, maximum Unicode character length among nonmissing strings. |
| Numeric Categorical or Nominal | No numeric quantitative summary. |
| Identifier | No summary or distribution table; a uniqueness statement is shown. |

Eligible distributions remain available for all types except Identifier. Quantiles follow `summarize, detail`. A dot in a summary value means the statistic is unavailable. Fractional values are accepted under Discrete classification.

<a id="identifiers"></a>

## Identifier detection and status

Unless a variable is listed in a classification option or has a metadata `doc_vartype` set, numeric and string variables are evaluated as possible identifier variables. Variables are automatically classified as identifiers when their names end in `id`, case-insensitively, or their labels contain the standalone word `id`, case-insensitively. 

Automatic inference is excluded if `gender` occurs anywhere in the name or label, case-insensitively, so as not to misclassify a variable containing gender identity data. This exception does not override an explicit `id()` or `doc_vartype="identifier"` assignment.

| Example | Automatically assigned as an Identifier |
|---|---|
| Name `stuid`m `schid`, or `reference_ID` | Yes. |
| Name `idea` | No, unless its label matches. |
| Label `Student ID`, `ID number`, or `(ID)` | Yes. |
| Label `identifier or idea` | No. |
| Label `student_id` | No (“ID” is not a complete word in the label); however, the varname rule is evaluated separately. |
| Name `genderid` or label `Gender id` | No automatic Identifier inference. |

The suffix rule is literal: names such as `paid` and `grid` also end in `id`. Supply an appropriate classification override for such variables when needed either using [metadata](#metadata) or a `datadoc` option.

A compact table printed only to Stata’s results window (and not to the codebook) lists automatically inferred identifiers and their reason: Name ends in id, Label contains standalone ID, or both. No table appears when none are inferred. It remains visible with datadoc’s `quiet` option.

### Uniqueness statement

Each Identifier description contains one of these sentences instead of a distribution table:

- This identifier uniquely identifies observations in the dataset.
- This identifier does not uniquely identify observations in the dataset.

Uniqueness requires a nonmissing identifier for every included observation and no repeated values. Variables with missing identifiers, including all-missing variables, do not satisfy this condition. When higher-level cluster identifiers are used to group observations, the statement that the identifier “does not uniquely idenitfy observations in the dataset” is reported and should be manually edited in the codebook.

When `if` or `in` is supplied, `dataset` is replaced by `selected sample`, even when the restriction retains all observations. The statement remains with `nodistributions`. 

### Identifier section assignments

Every included effective Identifier, whether assigned through `id()`, `doc_vartype`, or automatic rules, is reported in a section called “Identifiers.” After a successful Word save, its metadata characteristic `doc_section` is set to `Identifiers`, replacing any prior value. Excluded/unselected variables are not updated. Failed builds do not apply these updates. Save the dataset separately, after running `datadoc` to retain the changed `doc_section` variable characteristic.

A stored Identifiers section assignment is not erased by a later classification override or exception. Clear or reassign `doc_section` explicitly when needed. Data values, variable order, and observation order are not changed.

<a id="metadata"></a>

## Variable metadata and documentation

The following variable-level characteristics are read from the original Stata data frame. No command options are needed to display them. If any of these characteristics are empty or absent, they are silently omitted from the DOCX codebook with no blank space left for them. Setting these variable characteristics in advance of running `datadoc` will allow `datadoc` to include rich variable metadata in the Word output.

| Characteristic | Function and header in the docx output |
|---|---|
| `doc_vartype` | Stored variable type; see accepted values listed below. |
| `doc_section` | Named variable grouping/section; ordering and display rules below. |
| `doc_question` | Question text, reported under Question:. |
| `doc_itemnum` | Survey/test item number, reported as Question prefix or as a standalone Item Number:. |
| `doc_units` | Variable measurement units text, reported under Units:. |
| `doc_universe` | Subset of sample members responding to the item, reported under Universe:. |
| `doc_source` | Source of the variable data or question, reported under Source:. |
| `doc_derivation` | Derivation of the variable values, reported under Derivation:. |
| `doc_notes` | Additional documentation, reported under Notes: or appended to native Stata variable notes. |
| `note1`, `note2`, … | Native numbered variable notes, normally managed with the Stata `notes` command. |

In order for `datadoc` to read and use these characteristics, they must be set in the Stata data prior to executing `datadoc`. To set them, use the Stata char command:

```stata
char varname[doc_characteristicname] "characteristic text"
```

For example,

```stata
sysuse auto, clear
char price[doc_units] "1978 U.S. dollars"
char price[doc_vartype] "quantitative"
char price[doc_question] "What was the purchase price of the vehicle?"
```

### Variable type

`doc_vartype` accepts `quantitative`, `continuous`, `discrete`, `categorical`, `nominal`, `ordinal`, and `identifier`. Values are case-insensitive with surrounding spaces removed. Quantitative, Continuous, Discrete, and Ordinal require numeric storage; Categorical, Nominal, and Identifier accept numeric or string storage. Invalid active values cause an error. `date` and `text` are not accepted characteristic values; Date/Time can be inferred from formats or requested with `datevars()`. An empty characteristic leaves the automatic rules described above in effect.

```stata
sysuse auto, clear
char rep78[doc_vartype] "ordinal"
gen carid = _n
char carid[doc_vartype] "identifier"
```

### Question and item number

With both `doc_itemnum` and `doc_question` set, the codebook lists Question:, followed by the item number, one inserted space, and the question text. With `doc_question` alone, only the question text appears after Question:. With `doc_itemnum` set alone, an Item Number: block appears. No automatic brackets or punctuation are added.

```stata
sysuse auto, clear
char price[doc_itemnum] "Q12"
char price[doc_question] "What was the purchase price of the vehicle?"
```

### Units and other metadata

Text blocks follow native Stata variable Notes (from the `notes:` command) in this order: Question or Item Number, Units, Universe, Source, Derivation, and unmerged Notes. Empty blocks add no documentation text or blank lines.

```stata
char income[doc_units] "USD per year"
char height[doc_units] "Centimeters"
char price[doc_universe] "Vehicles with a recorded price"
char price[doc_source] "Purchase record"
char price[doc_derivation] "Recorded purchase price in US dollars"
char price[doc_notes] "Values refer to the original purchase."
```

`doc_units` is descriptive text only; units are not parsed, converted, or validated. Units and other documentation remain visible for Identifier variables. Stored text is not macro-interpolated or shortened by `strwidth()`. Documentation fields are read without rewriting them, except the successful Identifier update to `doc_section` described above.

### Native variable notes

Native variable notes appear under Notes: after Data Type and the representation/count line, before summaries. They are read in note-number order, with deleted-note gaps skipped. Each stored note begins a new paragraph, without added numbering or macro interpolation. When native notes and `doc_notes` characteristics both exist, `doc_notes` follows in the same block and is not repeated. With `doc_notes` alone, it appears as a documentation Notes block.

```stata
notes price: Original source note.
char price[doc_notes] "Additional documentation."
```

Save the dataset to retain characteristics and notes between sessions. They are not added as extra fields in the metadata frame if that frame is retained by invoking the option.

### Easier setting of `doc_` characteristics

An Excel template called `datadoc_metadata_prep.xltx` is available to ease the creation of variable characteristics for use in a `datadoc` execution. By default, it is installed in the same directory as the `datadoc.ado` file. On Sheet 1 of the Excel file, copy the varnames of the dataset variables, one per row, into input Column B. Input the desired data characteristics (including setting automatic sections of the Codebook in Column A, described below) and leave blank undesired characteristics. As metadata are input, Sheet 2 will update with a running list of Stata code that can be copied and pasted into a .do file to prep data by setting characteristics before executing `datadoc`. Blank columns will be skipped in the Stata code output on the second sheet. 

<a id="sections"></a>

## Sections and report ordering

Codebooks for datasets with a large number of variables may be made more reader-friendly by grouping variables into sections. To use this feature, set the `doc_section` characteristic of each variable to a section name. Names are case-sensitive and leading/trailing spaces are removed for grouping. Absent or empty values are skipped with no error. Multiple variables must have the exact same `doc_section` text in order to be grouped together. 

```stata
char income[doc_section] "Household finances"
char income[doc_section] ""
```

When variables are set by `doc_vartype`, by command option, or by automatic detection as Identifiers, these are placed in a section called “Identifiers” and ordered first in the codebook. Other named sections follow the first appearance of their included variables in original dataset variable order. Variables within each group follow dataset variable order, despite the order of any varlist options. Variables unassigned to a section form a separate final group, displayed as “Other variables” when sections are active. Sections are active when at least one included variable has a named section **other** than Identifiers. A codebook with only the Identifiers section will appear without sections, but variables denoted or detected as Identifiers will be listed first.

Section Descriptions are reported in the docx codebook with “Heading 2” text style. The first variable section heading follows the codebook heading “Variable descriptions” on its starting page; subsequent groups begin on a new page. Other variables follows the same heading and boundary rules. An explicit `pagebreak` option continues to work and does not create duplicate page breaks at variable section breaks.

If no included variable has a section assignment or effective Identifier classification, explicit report-varlist order is retained.

Regardless of report order, the variable and observation order in the dataset remain unchanged.

### Inventory section rows

The summary variable inventory table includes clickable links on variable names that lead directly to the detail section for the clicked variable. Variable section markers and breaks are included in the inventory table when sections are active.

<a id="datasetnotes"></a>

## Dataset notes

Native dataset notes are shown automatically in a Dataset notes: block near the study information, before the source/sample summary. With no native dataset notes, no heading, note text, or note-related blank line appears.

Notes are read from the original data frame’s numbered `_dta[note1]`, `_dta[note2]`, and subsequent characteristics, in note-number order with deleted gaps skipped. Each starts a paragraph without added numbering or macro interpolation. `strwidth()` does not shorten them. Dataset-level `doc_notes` and other dataset `doc_*` text characteristics are **not** included. Variable notes remain in their own descriptions. Notes are not changed.

```stata
notes: Release 3 includes corrections to employment variables.
```

<a id="reporting"></a>

## Counts, missing values, and distributions

### Counts and denominators

All counts, percentages, and summary statistics use the included observations and are unweighted, including when survey settings are documented. Valid _N_ counts all nonmissing observations. Distinct counts different nonmissing values. Missingness is handled separately for each variable.

Numeric `.`, `.a`–`.z`, and empty strings are missing. Whitespace-only strings are counted as valid. Special codes such as `-99` or `9999` remain counted as a valid value unless recoded to system missing values before `datadoc` is run. Value labels alone do not make a code missing.

Valid % uses the variable’s nonmissing count as denominator; Total % uses all selected observations as denominator. Valid % is blank for missing-code rows. Numeric standard and extended missing codes appear separately. Blank missing-code labels display `(missing)` when a Label column exists, unless custom overrides supply text to label missing values in the codebook.

### Observed and defined categories

Eligible numeric distributions combine observed values with all codes in an active definition. Unobserved defined codes have Frequency 0 and Total % 0.00. A nonmissing zero-frequency code has Valid % 0.00 when valid N is positive; when valid N is zero, Stata missing notation is shown. Missing-code Valid % remains blank. Observed nonmissing codes without a defined label retain blank labels.

If more than 10 defined value label codes have no observations in the dataset, all zero-frequency rows are suppressed, including unobserved but defined missing codes. An italic note reports the number omitted and the reason. Observed missing codes remain. Suppression changes neither observed frequencies nor denominators, distinct counts, or statistics.

Numeric rows follow underlying-code order. String distributions use complete stored values, including `strL`. Label columns appear for active definitions or numeric variables with `missinglabels()`; otherwise distributions contain Value, Frequency, Valid %, and Total %. No separate defined-values dictionary is produced.

### Display conventions and omissions

Displayed numbers may be rounded; dates use their recorded formats. Bracketed codes show an underlying numeric value not fully represented by the formatted display, with float precision taken into account. An ellipsis marks shortened text; complete stored values determine distinct counts and frequencies. A dot in a summary value indicates an unavailable statistic.

When the distinct-value limit is exceeded, the sentence reads “Distribution omitted because there are more than 25 distinct valid values.” The configured `maxvalues()` replaces 25. `nodistributions` omissions identify the option. Identifier descriptions show uniqueness statements instead. A blank line separates directly adjacent representation/count information and a distribution heading or omission/status sentence when no documentation or summary intervenes.

### Missing-data report

The report shows Valid _N_, Missing _N_, percentage missing, and extended numeric missing _N_ for every reported variable. Extended missing _N_ counts `.a`–`.z` only. Rows strictly above `misshighlight()` are shaded. Mean variable missingness averages percentages across reported variables; maximum missingness is also reported.

<a id="survey"></a>

## Survey sampling characteristics

When the original dataset has been `svyset` prior to calling `datadoc`, a summary of the Survey sampling characteristics appears after variable descriptions and before the missing-data report, starting on a new page. It includes General settings, Sampling stages, and Declared survey settings. No option is required. If the data are not `svyset`, the entire survey output section is silently skipped.

General settings report sampling-weight variable, weight type, variance estimator, subpopulation degrees-of-freedom adjustment, and single-unit handling. Applicable returned information also includes poststratification variables/totals, raking or regression calibration, replicate weights and replicate adjustments, explicit design degrees of freedom, Fay’s adjustment, bootstrap mean-weight adjustment, and MSE adjustment. The declaration returned by `svyset` is displayed as well.

Sampling stages report Stage, Strata, Sampling unit, and FPC variable. A Stage weight column appears when stage weights are returned. Empty strata display `<one>`, observation-level units display `<observations>`, and absent FPC displays `(none)`. Survey variables need not be in the report varlist.

The survey declaration is read without changing it. **Codebook calculations remain unweighted even when the data are `svyset`**. The section describes the original dataset, not a recalculated design for an `if`/`in` subset, and does not validate design variables or eligibility. If querying survey settings is unavailable or fails, the section is omitted. There is **no** weighted-summary or survey-display option for the generated codebook.

<a id="progress"></a>

## Progress and diagnostic output

### Rendering progress

Without `quiet`, Word rendering begins with an initial update at 0 completed variable descriptions. With at least 51 reported variables, further updates appear after every 50 completed descriptions and at the final variable when it is not already a multiple of 50. With fewer than 51 variables, no further variable-rendering updates are emitted. Existing per-variable calculation messages are unchanged.

| Reported variables | Additional rendering updates |
|---|---|
| 1–50 | None; initial update only. |
| 51 | 50/51 and 51/51. |
| 100 | 50/100 and 100/100. |
| 101 | 50/101, 100/101, and 101/101. |

Separate messages announce rendering the missing-data report and saving the codebook. `quiet` suppresses these and the initial/incremental rendering updates. Stata may still emit its own save confirmation.

### Review tables

Because some of the default detection methods in `datadoc` may misclassify your variables, a series of review tables are sent to the Stata Results window to guide a manual review of the choices `datadoc` made with your data. These include:

- Inferred numeric Quantitative/Categorical variables are listed for classification review.
- Variables with valid codes absent from active definitions are listed for value-label review.
- Automatically inferred identifiers are listed with their matching rule.

The first two diagnostics are represented in metadata warnings and included in the Word output when the option `reportwarnings` is specified. The inferred-Identifier matching-rule table is Results-only and will never print in the Word docx. It is omitted when no automatic identifiers exist. Diagnostic tables remain visible with datadoc’s `quiet`; Stata’s external `quietly` prefix suppresses output independently of the `datadoc` option `quiet`.

<a id="appearance"></a>

## Word document appearance

The aesthetic appearance of the codebook is inspired by the aesthetic of codebooks distributed with data from the ICPSR data archive at the University of Michigan.

Pages are letter-sized with margins 0.5 inch left, 0.5 inch right, and 0.6 inch top/bottom. The dataset title is centered and followed by a single full-width blue bar. The centered footer shows the page number between hyphens.

Variable banners and the inventory’s main header use dark blue `003399`; banner text and the inventory header text are white. Inventory section rows remain gray and are separated by blank white rows. Other table headers remain gray; body rows alternate white and light gray. Borders are not visible. Header rows repeat across pages; rows are marked not to split.

In variable details, Data Type is bold. Storage, Format, Variable Type, Valid N, Distinct Valid Values, and Value Label labels are bold while their associated values are unbolded. N in Valid N is bold and italic. Value Label is omitted without an active definition. The inventory column is named Variable Type; metadata still uses `classification`.

Summary tables are 4.75 inches wide, with 45% for Statistic and 55% for Value; values and their header are left-aligned without numeric padding. SD is italicized. Distribution tables size columns from display widths and stay within the usable width. Notes, Units, and other documentation use consistent bold headings and normal-text content.

There are no user options for page size, margins, table colors, arbitrary table widths, inventory separator height, or the zero-frequency suppression threshold. As a Word docx, the entire generated document is of course editable after creation.

<a id="examples"></a>

## Example Usage

### Classifications and basic summaries

```stata
sysuse auto, clear
char rep78[doc_vartype] "ordinal"
char foreign[doc_vartype] "nominal"
datadoc using "classified.docx", replace ///
    id(make) quantitative(price mpg) summary(basic) metaframe(check_meta)
```

### Sections, units, and documentation

```stata
sysuse auto, clear
char price[doc_section] "Vehicle cost"
char mpg[doc_section] "Vehicle measurements"
char foreign[doc_section] "Vehicle origin"
char price[doc_itemnum] "Q2"
char price[doc_question] "What was the purchase price?"
char price[doc_units] "1978 U.S. dollars"
char price[doc_universe] "Vehicles with a recorded price"
char price[doc_source] "Purchase record"
char price[doc_derivation] "Self-reported by respondent"
notes price: Original source note.
char price[doc_notes] "Additional documentation."
notes: This dataset contains vehicle-level observations.
datadoc price foreign mpg make using "sections.docx", replace id(make)
```

### Selection, missing labels, printed warnings in the codebook, and typography

```stata
datadoc price mpg foreign if foreign==1 using "foreign.docx", replace
datadoc using "selected.docx", replace exclude(turn trunk) pagebreak
datadoc using "missing_labels.docx", replace ///
    missinglabels(. "Not recorded" .a "Not applicable" .b "Refused")
datadoc using "serif.docx", replace ///
    fontname("Times New Roman") fontsize(10) misshighlight(20) reportwarnings
```

### Identifier overrides

In a dataset containing the following variables, stored or command classifications can override automatic inference:

```stata
char genderid[doc_vartype] "nominal"
char person_code[doc_vartype] "identifier"
datadoc using "overrides.docx", replace quantitative(paid)
```

### Survey documentation

In a dataset with the corresponding design variables, declare the design before generating the codebook. Its characteristics are included automatically:

```stata
webuse highschool
svyset 
datadoc outcome using "survey_codebook.docx", replace
```

<a id="results"></a>

## Stored results

Use `return list` immediately after successful completion. `datadoc` is r-class and does not post estimation results in e().

| Scalar | Meaning |
|---|---|
| `r(N)` | Selected sample observations. |
| `r(k)` | Reported variables. |
| `r(excluded_variables)` | Distinct variables specified in exclude(). |
| `r(excluded_observations)` | Original observations minus selected observations. |
| `r(fontsize)` | Normal text size. |
| `r(sectionfontsize)` | Major and description-section heading size. |

| Macro | Meaning |
|---|---|
| `r(filename)` | Word output filename. |
| `r(variables)` | Final report varlist in output order. |
| `r(metaframe)` | Retained frame name, when requested. |
| `r(version)` | Generator version. |
| `r(summary)` | basic or full. |
| `r(fontname)` | Resolved family. |
| `r(requestedfont)` | Requested family; empty when omitted. |

<a id="metadata"></a>

## Metadata frame

`metaframe()` contains one row per reported variable in report order. Variable position excludes inventory section/separator rows. Temporary display columns are removed before the frame is returned.

| Field | Meaning |
|---|---|
| `position` | Report position. |
| `variable` | Variable name. |
| `storage` | Stata storage type. |
| `data_type` | Numeric, String, or Numeric (Date/Time). |
| `classification` | Lowercase variable-type code. |
| `classification_source` | option, characteristic, or inferred. |
| `label` | Variable label. |
| `value_label` | Active value-label name; empty when unavailable. |
| `format` | Display format. |
| `N` | Selected sample observations. |
| `valid` | Nonmissing observations. |
| `missing` | Missing observations. |
| `pct_missing` | Missing percentage. |
| `unique` | Distinct nonmissing values. |
| `mean, sd` | Mean and standard deviation. |
| `min, max` | Minimum and maximum. |
| `p1, p5, p10` | 1st, 5th, and 10th percentiles. |
| `p25, median, p75` | Quartiles and median. |
| `p90, p95, p99` | 90th, 95th, and 99th percentiles. |
| `skewness, kurtosis` | Distribution shape. |
| `min_length` | Minimum nonmissing Unicode string length. |
| `mean_length` | Mean nonmissing Unicode string length. |
| `max_length` | Maximum nonmissing Unicode string length. |
| `all_integer` | Valid numeric values are all integral. |
| `unlabeled` | Valid observations absent from active label codes. |
| `extended_missing` | Numeric .a-.z observation count. |
| `warning` | Diagnostic text. |

Classification codes are `quantitative`, `continuous`, `discrete`, `categorical`, `nominal`, `ordinal`, `identifier`, `date`, and `text`. Full numeric statistics are calculated for quantitative, continuous, discrete, ordinal, and date; Word shows the applicable subset. Uncalculated fields are missing, not zero. All-missing variables have valid and unique counts of zero. `all_integer` is true only for numeric variables with at least one valid observation and no fractional valid values.

`unlabeled` is checked only for numeric variables with an active definition and is zero otherwise. Identifier classification does not disable this diagnostic. Dataset/variable notes, documentation including units, section labels, survey settings, uniqueness sentences, inference reasons, and frequency rows are not additional metadata fields.

<a id="requirements"></a>

## Document handling, limits, and requirements

Before copying data or calculating statistics, `datadoc` checks for an active putdocx document. If one is open, it exits with return code 110 and instructions to save the active putdocx document or explicitly discard it using `putdocx clear`. It does not change or clear the existing document as this may cause unintended docx data loss of the earlier open document. `replace` does not bypass this check.

```stata
putdocx clear
datadoc using "codebook.docx", replace
```

Use `putdocx clear` only to discard an unwanted active docx document; save work you need first. A failed `datadoc` build may leave a partial active document and prevent a second call to `datadoc` until a manual `putdocx clear` command has been issued. Captured setup/build failures restore the caller frame and remove temporary frames. Inspect the output file after a failed save. Identifier characteristic updates occur only after a successful Word save.

Before creating a document, datadoc sets `docx_maxtable` to 10,000 regardless of its previous setting. This remains in effect for the current Stata session and is not made permanent. A single document remains subject to the 10,000-table limit and available system memory.

`datadoc` codebooks contain unweighted descriptive documentation. `datadoc` does not perform survey estimation, recode special missing values, convert measurement units, embed fonts, validate a DDI schema, or certify confidentiality of the underlying data. Identifier classification retains counts and documentation; `exclude()` removes variables from the Word output and the saved metadata.

