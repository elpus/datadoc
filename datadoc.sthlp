{smcl}
{* *! version 1.2.7 12oct2026}{...}
{vieweralsosee "codebook" "help codebook"}{...}
{vieweralsosee "describe" "help describe"}{...}
{vieweralsosee "putdocx" "help putdocx"}{...}
{vieweralsosee "frames" "help frames"}{...}
{vieweralsosee "char" "help char"}{...}
{vieweralsosee "notes" "help notes"}{...}
{vieweralsosee "svyset" "help svyset"}{...}
{viewerjumpto "Syntax" "datadoc##syntax"}{...}
{viewerjumpto "Description" "datadoc##description"}{...}
{viewerjumpto "Options" "datadoc##options"}{...}
{viewerjumpto "Remarks" "datadoc##remarks"}{...}
{viewerjumpto "Examples" "datadoc##examples"}{...}
{viewerjumpto "Stored results" "datadoc##results"}{...}
{viewerjumpto "Author" "datadoc##author"}{...}

{title:Title}

{pstd}
{cmd:datadoc} {hline 2} Create a Microsoft Word data dictionary/codebook

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:datadoc} [{varlist}] {ifin} {cmd:using} {it:filename}
[{cmd:,} {it:options}]

{synoptset 33 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Selection and output}
{synopt:{opt replace}}overwrite an existing Word file{p_end}
{synopt:{opt exclude(varlist)}}omit specified variables{p_end}
{synopt:{opt metaframe(name)}}retain metadata in a new frame{p_end}

{syntab:Study information}
{synopt:{opt title(string)}}report title; default dataset label{p_end}
{synopt:{opt pi(string)}}principal investigator{p_end}
{synopt:{opt affiliation(string)}}institutional affiliation{p_end}
{synopt:{opt funding(string)}}funding information{p_end}
{synopt:{opt abstract(string)}}study abstract{p_end}

{syntab:Variable type}
{synopt:{opt quantitative(varlist)}}numeric Quantitative variables{p_end}
{synopt:{opt continuous(varlist)}}numeric Continuous variables{p_end}
{synopt:{opt discrete(varlist)}}numeric Discrete variables{p_end}
{synopt:{opt categorical(varlist)}}numeric or string Categorical variables{p_end}
{synopt:{opt nominal(varlist)}}numeric or string Nominal variables{p_end}
{synopt:{opt ordinal(varlist)}}numeric Ordinal variables{p_end}
{synopt:{opt id(varlist)}}numeric or string Identifier variables{p_end}
{synopt:{opt datevars(varlist)}}numeric Date/Time variables{p_end}

{syntab:Summaries and distributions}
{synopt:{opt summary(mode)}}basic or full; default full{p_end}
{synopt:{opt maxvalues(#)}}distinct-value limit; default 25{p_end}
{synopt:{opt missinglabels(code "label" ...)}}report-only numeric missing-value labels{p_end}
{synopt:{opt nodistributions}}omit distribution tables{p_end}

{syntab:Appearance and pagination}
{synopt:{opt fontsize(#)}}normal font size; default 9{p_end}
{synopt:{opt fontname(string)}}font family; default Arial{p_end}
{synopt:{opt decimals(#)}}statistic decimal places; default 2{p_end}
{synopt:{opt strwidth(#)}}string display limit; default 100{p_end}
{synopt:{opt pagebreak}}start each variable on a new page{p_end}
{synopt:{opt misshighlight(#)}}missingness highlight threshold; default 10{p_end}

{syntab:Messages and diagnostics}
{synopt:{opt quiet}}suppress progress and completion messages{p_end}
{synopt:{opt reportwarnings}}include review diagnostics in the Word file{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Omitting {varlist} includes all variables in the current frame, subject to {opt exclude()}. {cmd:if} and {cmd:in} select observations for all calculations. At least one reported variable and one selected observation are required. Quote filenames containing spaces. A {cmd:.docx} extension is appended if absent; an existing extension is recognized case-insensitively.

{marker description}{...}
{title:Description}

{pstd}
{cmd:datadoc} writes a {cmd:.docx} codebook from the current Stata frame. It includes a linked variable inventory, variable descriptions, counts, summaries, eligible distributions, and a missing-data report. Dataset and variable notes are included automatically. Setting study information (by option) or variable characteristics (by prior Stata commands) can optionally increase the documentation generated. All statistics are unweighted, including when the data are {cmd:svyset}.

{marker options}{...}
{title:Options}

{dlgtab:Selection and output}

{marker opt_replace}{...}
{phang}
{opt replace} allows an existing output Word file to be overwritten. The default is not to overwrite. This option does not replace existing metadata frames or discard an active {cmd:putdocx} document.{p_end}
{marker opt_exclude}{...}
{phang}
{opt exclude(varlist)} omits the specified variables from the codebook and metadata. The default is no exclusions. At least one reported variable must remain. Exclusion counts include distinct names supplied here even if absent from an explicit report varlist; omission solely by a report varlist is not counted. Observation exclusions count original minus selected observations. An exclusion statement appears only when one of these counts is positive.{p_end}
{marker opt_metaframe}{...}
{phang}
{opt metaframe(name)} retains one metadata row per reported variable in a new frame named {it:name}, in report order. The default is to discard temporary metadata after successful completion. Existing frame names are rejected, even with {opt replace}. See {help datadoc##metadataframe:Metadata frame} under Stored results for the fields retained.{p_end}

{dlgtab:Study information}

{marker opt_title}{...}
{phang}
{opt title(string)} sets the report title. If omitted or empty, the dataset label is used; without a dataset label, the title is {it:Data codebook}. Quote a multiword title.{p_end}
{marker opt_pi}{...}
{phang}
{opt pi(string)} supplies principal investigator information. The default is to omit this block; an empty string also omits it. Quote multiword text.{p_end}
{marker opt_affiliation}{...}
{phang}
{opt affiliation(string)} supplies institutional affiliation. The default is to omit this block; an empty string also omits it. Quote multiword text.{p_end}
{marker opt_funding}{...}
{phang}
{opt funding(string)} supplies funding information. The default is to omit this block; an empty string also omits it. Quote multiword text.{p_end}
{marker opt_abstract}{...}
{phang}
{opt abstract(string)} supplies a study abstract. The default is to omit this block; an empty string also omits it. Quote multiword text.{p_end}

{dlgtab:Variable type}

{pstd}
These options override {cmd:doc_vartype} and automatic classification for the specified variables, without changing values, formats, storage, or the stored characteristic. The default is no command-level override. Classification option varlists cannot overlap.

{marker opt_quantitative}{...}
{phang}
{opt quantitative(varlist)} classifies the specified variables as Quantitative. Numeric storage is required.{p_end}
{marker opt_continuous}{...}
{phang}
{opt continuous(varlist)} classifies the specified variables as Continuous. Numeric storage is required.{p_end}
{marker opt_discrete}{...}
{phang}
{opt discrete(varlist)} classifies the specified variables as Discrete. Numeric storage is required; fractional values are accepted.{p_end}
{marker opt_categorical}{...}
{phang}
{opt categorical(varlist)} classifies the specified variables as Categorical. Numeric or string storage is allowed.{p_end}
{marker opt_nominal}{...}
{phang}
{opt nominal(varlist)} classifies the specified variables as Nominal. Numeric or string storage is allowed.{p_end}
{marker opt_ordinal}{...}
{phang}
{opt ordinal(varlist)} classifies the specified variables as Ordinal. Numeric storage is required.{p_end}
{marker opt_id}{...}
{phang}
{opt id(varlist)} classifies the specified variables as Identifier, overriding automatic matching rules and the gender exception. Numeric or string storage is allowed. Summaries and distributions are replaced by a uniqueness statement. Included effective Identifiers are ordered first and receive {cmd:doc_section = Identifiers} after a successful Word save.{p_end}
{marker opt_datevars}{...}
{phang}
{opt datevars(varlist)} classifies numeric variables as Date/Time. It does not assign date formats or convert stored codes. Minimum, median, and maximum are displayed in the existing format.{p_end}

{dlgtab:Summaries and distributions}

{marker opt_summary}{...}
{phang}
{opt summary(mode)} selects {cmd:basic} or {cmd:full} summaries for Quantitative, Continuous, and Discrete variables; the default is {cmd:full}. The argument is case-insensitive and surrounding spaces are trimmed. Basic reports mean, SD, minimum, median, and maximum. Full adds p1, p5, p10, p25, p75, p90, p95, p99, skewness, and kurtosis. Other types are unaffected. Full statistics calculated for each classification remain in retained metadata in either mode.{p_end}
{marker opt_maxvalues}{...}
{phang}
{opt maxvalues(#)} sets the largest distinct nonmissing-value count eligible for a distribution table. Supply a positive integer; the default is 25. Observed missing categories and unobserved defined codes do not count toward this limit. Exceeding the limit suppresses the distribution, not the applicable summaries or documentation. The separate suppression of more than 10 unobserved defined codes is not configurable.{p_end}
{marker opt_missinglabels}{...}
{phang}
{opt missinglabels(code "label" ...)} supplies report-only labels for any subset of numeric {cmd:.} and {cmd:.a} through {cmd:.z}, with one nonempty label per code. The default is no overrides. Quote multiword labels. Duplicate codes, nonmissing codes, and empty labels are rejected. Each override applies to that code across all reported numeric variables; dataset labels and values are unchanged. Unspecified codes keep nonblank active labels, otherwise displaying {it:(missing)} when a Label column is present.{p_end}
{p 8 8 2}
These overrides add a Label column to numeric distributions even without an active definition. Nonmissing labels then remain blank unless defined. They do not change classification, counts, or percentages, and do not create a row for a code absent from both the selected sample and the active definition. String distributions are unaffected.{p_end}
{marker opt_nodistributions}{...}
{phang}
{opt nodistributions} omits all distribution tables. The default is to include eligible distributions. Applicable omission text or Identifier uniqueness statements remain. It does not suppress summaries, documentation, or the missing-data report; no separate defined-values dictionaries are generated.{p_end}

{dlgtab:Appearance and pagination}

{marker opt_fontsize}{...}
{phang}
{opt fontsize(#)} sets normal text size in points for body text, tables, variable headings, and documentation. Supply a real number from 4 through 48; the default is 9. Major headings and the report title are sized separately.{p_end}
{marker opt_fontname}{...}
{phang}
{opt fontname(string)} sets the font family; the default is Arial. Quote multiword names. Empty or whitespace-only strings select Arial. Fonts are not embedded, and availability of the chosen font is not checked.{p_end}
{marker opt_decimals}{...}
{phang}
{opt decimals(#)} sets statistic decimal places. Supply an integer from 0 through 10; the default is 2. Means, SDs, fractional results, skewness, and kurtosis use this setting. All-integer numeric variables show integer minima, maxima, percentiles, and medians without decimals. Percentages always use two decimals; Date/Time summaries use existing display formats.{p_end}
{marker opt_strwidth}{...}
{phang}
{opt strwidth(#)} sets the maximum Unicode character count displayed for a string value. Supply an integer of at least 10; the default is 100. Longer displays end in an ellipsis. Frequencies and distinct counts use complete values. Notes, sections, units, and other documentation are not shortened.{p_end}
{marker opt_pagebreak}{...}
{phang}
{opt pagebreak} starts each variable description after the first on a new page. The default is off. Active section boundaries also start new pages; overlapping section and variable breaks do not create duplicate breaks. The first variable follows the Variable descriptions heading on its starting page.{p_end}
{marker opt_misshighlight}{...}
{phang}
{opt misshighlight(#)} sets the missing-percentage threshold for highlighting rows in the missing-data report. Supply a real number from 0 through 100; the default is 10. Only rows strictly above the threshold are highlighted.{p_end}

{dlgtab:Messages and diagnostics}

{marker opt_quiet}{...}
{phang}
{opt quiet} suppresses the version banner, calculation/rendering progress, saving message, and final completion message. The default is off. Classification, inferred-Identifier, and undefined-code review tables and font-fallback notices remain visible. Stata may still print its own save confirmation. Stata's {cmd:quietly} prefix suppresses Results output independently of this option.{p_end}
{marker opt_reportwarnings}{...}
{phang}
{opt reportwarnings} adds Review diagnostics after the missing-data report in the Word file. The default is off. It includes inferred numeric Quantitative/Categorical classification warnings and valid observations whose codes are absent from active value-label definitions. If none occur, this is stated. The inferred-Identifier matching-rule table remains Results-only and is never added by this option.{p_end}

{marker remarks}{...}
{title:Remarks}

{marker characteristics}{...}
{dlgtab:Variable Characteristics and Notes}

{pstd}
Set variable characteristics before running {cmd:datadoc}, using {cmd:char} {it:varname}{cmd:[}{it:characteristic}{cmd:] "}{it:text}{cmd:"}. The following are read; empty entries are omitted.

{synoptset 20}{...}
{synopt:{cmd:doc_vartype}}stored variable classification{p_end}
{synopt:{cmd:doc_section}}variable group or section{p_end}
{synopt:{cmd:doc_question}}question wording{p_end}
{synopt:{cmd:doc_itemnum}}item number or question prefix{p_end}
{synopt:{cmd:doc_units}}measurement units{p_end}
{synopt:{cmd:doc_universe}}responding population/subset{p_end}
{synopt:{cmd:doc_source}}source of data or question{p_end}
{synopt:{cmd:doc_derivation}}derivation of values{p_end}
{synopt:{cmd:doc_notes}}additional variable notes{p_end}
{p2colreset}{...}

{pstd}
{cmd:doc_vartype} accepts {cmd:quantitative}, {cmd:continuous}, {cmd:discrete}, {cmd:categorical}, {cmd:nominal}, {cmd:ordinal}, and {cmd:identifier}, case-insensitively with surrounding spaces removed. Quantitative, Continuous, Discrete, and Ordinal require numeric storage; Categorical, Nominal, and Identifier also allow strings. Invalid active values cause an error. Empty values leave automatic classification in effect. {cmd:date} and {cmd:text} are not accepted; use date formats or {opt datevars()} for Date/Time.

{pstd}
Set {cmd:doc_section} to group variables by section in the output codebook. Section names are case-sensitive and trimmed; empty names are ignored. A section for Identifiers is first, followed by named sections in order of first appearance in dataset variable order, then unassigned variables. Variables within groups follow dataset order. Section headings and boundary page breaks appear only when a named section other than Identifiers is present; unassigned variables then form Other variables. If only Identifiers is named, identifiers are still first but section headings are omitted.

{pstd}
With both {cmd:doc_itemnum} and {cmd:doc_question}, the question is prefixed by the item number and one space, with no added punctuation. An item number alone is shown separately. Documentation follows native variable notes in this order: Question or Item Number, Units, Universe, Source, Derivation, and unmerged Notes. Units are descriptive only; no conversion is performed.

{pstd}
Native dataset and variable notes are read in note-number order, skipping deleted notes. Variable {cmd:doc_notes} is appended to native variable notes without repetition, or shown separately if no native notes exist. Dataset-level {cmd:doc_notes} and other dataset {cmd:doc_*} characteristics are not included. Notes and documentation are neither macro-interpolated nor truncated by {opt strwidth()}; they remain visible for Identifiers. Save the dataset to retain notes and characteristics.

{pstd}
The installed Excel template {cmd:datadoc_metadata_prep.xltx}, in the same directory as {cmd:datadoc.ado}, can generate characteristic-setting commands. On Sheet 1, enter variable names in Column B, sections in Column A, and desired metadata in the other input columns. Copy the generated Stata commands from Sheet 2 into a do-file; blank entries are skipped.

{marker reporting}{...}
{dlgtab:Counts and distributions}

{pstd}
Valid counts and distinct counts exclude numeric {cmd:.} and {cmd:.a} through {cmd:.z}, and empty strings. Whitespace-only strings are valid. Special numeric codes remain valid unless recoded to Stata missing values; value labels do not make codes missing. Valid percentages use nonmissing observations; total percentages use all selected observations. Missing-code valid percentages are blank. Extended missing counts include {cmd:.a} through {cmd:.z} only.

{pstd}
Eligible numeric distributions combine observed values with codes in active value-label definitions. Defined but unobserved codes have zero frequency. If more than 10 defined codes are unobserved, all zero-frequency rows are omitted, including unobserved defined missing codes; observed missing codes remain. Nonmissing zero-frequency rows show valid percent 0.00 when valid N is positive, and a dot otherwise. Observed valid codes absent from active definitions have blank labels and are reported for review. Numeric rows follow code order; string frequencies use full stored values, including {cmd:strL}. No separate value-label dictionary is produced.

{marker survey}{...}
{dlgtab:Survey settings}

{pstd}
When the original data are {cmd:svyset}, the codebook automatically includes the declared design, weights, sampling stages, and applicable calibration or replicate-weight settings. Design variables need not be reported variables. Settings are read without alteration and describe the original dataset, not a recalculated design for an {cmd:if}/{cmd:in} subset. Calculations remain unweighted. No weighted-summary or survey-display option is provided. The section is omitted if the data are not {cmd:svyset} or the settings cannot be queried.

{marker examples}{...}
{title:Examples}

{pstd}
Create a codebook for all variables

{phang2}
{cmd:. sysuse auto, clear}

{phang2}
{cmd:. datadoc using "auto_codebook.docx", replace}

{pstd}
Select observations and omit variables

{phang2}
{cmd:. datadoc price mpg foreign if foreign==1 using "foreign.docx", replace}

{phang2}
{cmd:. datadoc using "selected.docx", replace exclude(turn trunk)}

{pstd}
Set stored classifications and retain metadata

{phang2}
{cmd:. char rep78[doc_vartype] "ordinal"}

{phang2}
{cmd:. char foreign[doc_vartype] "nominal"}

{phang2}
{cmd:. datadoc using "classified.docx", replace id(make) quantitative(price mpg) summary(basic) metaframe(check_meta)}

{pstd}
Add sections, question metadata, units, and notes

{phang2}
{cmd:. char price[doc_section] "Vehicle cost"}

{phang2}
{cmd:. char mpg[doc_section] "Vehicle measurements"}

{phang2}
{cmd:. char price[doc_itemnum] "Q2"}

{phang2}
{cmd:. char price[doc_question] "What was the purchase price?"}

{phang2}
{cmd:. char price[doc_units] "1978 U.S. dollars"}

{phang2}
{cmd:. notes price: Original source note.}

{phang2}
{cmd:. char price[doc_notes] "Additional documentation."}

{phang2}
{cmd:. notes: This dataset contains vehicle-level observations.}

{phang2}
{cmd:. datadoc using "sections.docx", replace id(make)}

{pstd}
Supply report-only missing-value labels

{phang2}
{cmd:. datadoc using "missing_labels.docx", replace missinglabels(. "Not recorded" .a "Not applicable" .b "Refused")}

{pstd}
Change typography and include diagnostics

{phang2}
{cmd:. datadoc using "serif.docx", replace fontname("Times New Roman") fontsize(10) decimals(3) strwidth(80) pagebreak misshighlight(20) reportwarnings}

{pstd}
Declare any survey design with {cmd:svyset} before calling {cmd:datadoc}; survey settings are then included automatically. A new {opt metaframe()} name is required for a further call if the earlier frame still exists.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:datadoc} is r-class. Use {cmd:return list} immediately after successful completion. It stores the following in {cmd:r()}:

{dlgtab:Scalars}

{synoptset 29}{...}
{synopt:{cmd:r(N)}}Selected sample observations.{p_end}
{synopt:{cmd:r(k)}}Reported variables.{p_end}
{synopt:{cmd:r(excluded_variables)}}Distinct variables specified in exclude().{p_end}
{synopt:{cmd:r(excluded_observations)}}Original observations minus selected observations.{p_end}
{synopt:{cmd:r(fontsize)}}Normal text size.{p_end}
{synopt:{cmd:r(sectionfontsize)}}Major and description-section heading size.{p_end}
{p2colreset}{...}

{dlgtab:Macros}

{synoptset 29}{...}
{synopt:{cmd:r(filename)}}Word output filename.{p_end}
{synopt:{cmd:r(variables)}}Final report varlist in output order.{p_end}
{synopt:{cmd:r(metaframe)}}Retained frame name, when requested.{p_end}
{synopt:{cmd:r(version)}}Generator version.{p_end}
{synopt:{cmd:r(summary)}}basic or full.{p_end}
{synopt:{cmd:r(fontname)}}Resolved family.{p_end}
{synopt:{cmd:r(requestedfont)}}Requested family; empty when omitted.{p_end}
{synopt:{cmd:r(fontstatus)}}default, verified-local, or fallback.{p_end}
{p2colreset}{...}

{marker metadataframe}{...}
{dlgtab:Metadata frame}

{pstd}
{opt metaframe()} retains one row per reported variable in output order. Inventory section/separator rows are not counted as positions. The following fields are retained:

{synoptset 26}{...}
{synopt:{cmd:position}}Report position.{p_end}
{synopt:{cmd:variable}}Variable name.{p_end}
{synopt:{cmd:storage}}Stata storage type.{p_end}
{synopt:{cmd:data_type}}Numeric, String, or Numeric (Date/Time).{p_end}
{synopt:{cmd:classification}}Lowercase variable-type code.{p_end}
{synopt:{cmd:classification_source}}option, characteristic, or inferred.{p_end}
{synopt:{cmd:label}}Variable label.{p_end}
{synopt:{cmd:value_label}}Active value-label name; empty when unavailable.{p_end}
{synopt:{cmd:format}}Display format.{p_end}
{synopt:{cmd:N}}Selected sample observations.{p_end}
{synopt:{cmd:valid}}Nonmissing observations.{p_end}
{synopt:{cmd:missing}}Missing observations.{p_end}
{synopt:{cmd:pct_missing}}Missing percentage.{p_end}
{synopt:{cmd:unique}}Distinct nonmissing values.{p_end}
{synopt:{cmd:mean, sd}}Mean and standard deviation.{p_end}
{synopt:{cmd:min, max}}Minimum and maximum.{p_end}
{synopt:{cmd:p1, p5, p10}}1st, 5th, and 10th percentiles.{p_end}
{synopt:{cmd:p25, median, p75}}Quartiles and median.{p_end}
{synopt:{cmd:p90, p95, p99}}90th, 95th, and 99th percentiles.{p_end}
{synopt:{cmd:skewness, kurtosis}}Distribution shape.{p_end}
{synopt:{cmd:min_length}}Minimum nonmissing Unicode string length.{p_end}
{synopt:{cmd:mean_length}}Mean nonmissing Unicode string length.{p_end}
{synopt:{cmd:max_length}}Maximum nonmissing Unicode string length.{p_end}
{synopt:{cmd:all_integer}}Valid numeric values are all integral.{p_end}
{synopt:{cmd:unlabeled}}Valid observations absent from active label codes.{p_end}
{synopt:{cmd:extended_missing}}Numeric .a-.z observation count.{p_end}
{synopt:{cmd:warning}}Diagnostic text.{p_end}
{p2colreset}{...}

{pstd}
Classification codes are {cmd:quantitative}, {cmd:continuous}, {cmd:discrete}, {cmd:categorical}, {cmd:nominal}, {cmd:ordinal}, {cmd:identifier}, {cmd:date}, and {cmd:text}. Classification sources are {cmd:option}, {cmd:characteristic}, and {cmd:inferred}. Full numeric statistics are calculated for quantitative, continuous, discrete, ordinal, and date classifications; the Word file shows the applicable subset. Uncalculated statistics are missing, not zero. All-missing variables have valid and unique counts of zero. {cmd:all_integer} is true only for numeric variables with at least one valid observation and no fractional valid values.

{pstd}
{cmd:unlabeled} counts valid numeric observations absent from an active definition; it is zero otherwise, including when no active definition exists. This diagnostic also applies to Identifiers. Notes, documentation, units, section labels, survey settings, uniqueness statements, inference reasons, and frequency rows are not retained as additional metadata fields.

{marker author}{...}
{title:Author}

{pstd}
Kenneth Elpus
{break}Version 1.2.7

