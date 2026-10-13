*! datadoc 1.2.7 12oct2026
*! Kenneth Elpus
program define datadoc, rclass
    version 19.0
    syntax [varlist] [if] [in] using/ , [REPLACE TITLE(string) PI(string) ///
        AFFiliation(string) FUNDing(string) ABSTRACT(string) MAXValues(integer 25) ///
        DECimals(integer 2) STRWidth(integer 100) QUANTitative(varlist numeric) ///
        CONTinuous(varlist numeric) DISCrete(varlist numeric) CATegorical(varlist) ///
        NOMinal(varlist) ORDinal(varlist numeric) ID(varlist) DATEvars(varlist numeric) ///
        EXclude(varlist) METAFRAME(name) PAGEbreak MISSHighlight(real 10) ///
        NODISTributions REPORTWarnings SUMMARY(string) MISSINGLABels(string asis) QUIET FONTSize(real 9) FONTName(string)]
    local summary=lower(strtrim("`summary'"))
    if "`summary'"=="" local summary "full"
    if !inlist("`summary'","basic","full") {
        di as err "summary() must be basic or full."
        exit 198
    }
    capture quietly putdocx describe
    if !_rc {
        di as err "A putdocx document is already open in memory."
        di as err "Save it first, or invoke putdocx clear to discard it, then rerun datadoc."
        di as err "The open document has not been changed."
        exit 110
    }
    if "`quiet'"=="" di as text "datadoc 1.2.7"
    if `maxvalues'<1 | `decimals'<0 | `decimals'>10 | `strwidth'<10 {
        di as err "maxvalues() must be positive; decimals() 0-10; strwidth() >=10"
        exit 198
    }
    if `misshighlight'<0 | `misshighlight'>100 exit 198
    if missing(`fontsize') | `fontsize'<4 | `fontsize'>48 {
        di as err "fontsize() must be from 4 through 48 points."
        exit 198
    }
    local headsize=max(12,`fontsize'+3)
    local requested_font=ustrtrim(`"`fontname'"')
    if strpos(`"`requested_font'"',char(34)) | strpos(`"`requested_font'"',char(10)) | ///
        strpos(`"`requested_font'"',char(13)) {
        di as err "fontname() must be a font-family name without quotation marks or line breaks."
        exit 198
    }
    if `"`requested_font'"'=="" {
        local fontname "Arial"
        local font_status "default"
    }
    else {
        local fontname `"`requested_font'"'
        local font_status "specified"
    }
    if lower(substr(`"`using'"',-5,5))!=".docx" local using `"`using'.docx"'
    if "`replace'"=="" {
        capture confirm new file `"`using'"'
        if _rc {
            di as err "Output exists or cannot be created; use replace deliberately."
            exit 602
        }
    }
    if "`metaframe'"!="" {
        capture frame `metaframe': describe
        if !_rc {
            di as err "Frame `metaframe' already exists; choose another name."
            exit 110
        }
    }
    local excluded_variables : word count `exclude'
    local varlist : list varlist - exclude
    if "`varlist'"=="" exit 102
    local assigned
    foreach opt in quantitative continuous discrete categorical nominal ordinal id datevars {
        local overlap : list assigned & `opt'
        if "`overlap'"!="" {
            di as err "Conflicting variable classifications: `overlap'"
            exit 198
        }
        local outside : list `opt' - varlist
        if "`outside'"!="" {
            di as err "Classification variables must be included in report: `outside'"
            exit 198
        }
        local assigned : list assigned | `opt'
    }
    local restricted_sample=(`"`if'"'!="" | `"`in'"'!="")
    marksample touse, novarlist
    quietly count if `touse'
    if r(N)==0 exit 2000
    local sampleN=r(N)
    local excluded_observations=_N-`sampleN'
    local caller=c(frame)
    local sourcefile=c(filename)
    local sourcefile=subinstr(`"`sourcefile'"',char(92),"/",.)
    local sourcefile=ustrregexra(`"`sourcefile'"',"^.*/","")
    if `"`sourcefile'"'=="" local sourcefile "(data in memory)"
    local datalabel : data label
    tempname work meta freq notesframe docframe missingmap misscodes misstext surveyframe surveystages sectionframe idreview
    capture noisily {
    frame create `idreview' str32 variable str80 match
    mata: ddoc127_identifiers("`idreview'", "`caller'")
    frame create `sectionframe' str32 variable strL section_label long section_order long dataset_position
    mata: ddoc127_sections("`sectionframe'", "`caller'")
    _ddoc127_survey, general(`surveyframe') stages(`surveystages')
    local has_survey=r(has_survey)
    frame create `missingmap' double code strL missing_label
    local remaining `"`missinglabels'"'
    local seen_missing
    local miss_row=0
    while ustrtrim(`"`remaining'"')!="" {
        gettoken miss_code remaining : remaining
        if !regexm(`"`miss_code'"', "^\.[a-z]?$") {
            di as err "missinglabels() requires codes . or .a through .z followed by labels."
            exit 198
        }
        local duplicate : list miss_code in seen_missing
        if `duplicate' {
            di as err "Duplicate code in missinglabels(): `miss_code'."
            exit 198
        }
        gettoken miss_text remaining : remaining
        if ustrtrim(`"`miss_text'"')=="" {
            di as err "Each code in missinglabels() requires a nonempty label. Quote multiword labels."
            exit 198
        }
        local seen_missing `seen_missing' `miss_code'
        local ++miss_row
        frame `missingmap': quietly set obs `miss_row'
        frame `missingmap': mata: st_store(strtoreal(st_local("miss_row")), "code", strtoreal(st_local("miss_code")))
        frame `missingmap': mata: st_sstore(strtoreal(st_local("miss_row")), "missing_label", st_local("miss_text"))
    }
    local has_missinglabels=(`miss_row'>0)
    if `has_missinglabels' {
        frame `missingmap': mata: `misscodes' = st_data(., "code")
        frame `missingmap': mata: `misstext' = st_sdata(., "missing_label")
    }
    frame put `varlist' if `touse', into(`work')
    frame create `meta' long position str32 variable str12 storage str24 data_type ///
        str16 classification str16 classification_source strL label ///
        str32 value_label str32 format ///
        double N valid missing pct_missing unique mean sd min p1 p5 p10 ///
        p25 median p75 p90 p95 p99 max skewness kurtosis ///
        min_length mean_length max_length byte all_integer ///
        double unlabeled extended_missing strL warning
    frame change `work'
    _ddoc127_build `varlist' using `"`using'"', ///
        meta(`meta') freq(`freq') notesframe(`notesframe') docframe(`docframe') ///
        originalframe(`caller') maxvalues(`maxvalues') decimals(`decimals') ///
        summary(`summary') excludedvars(`excluded_variables') excludedobs(`excluded_observations') ///
        hasmissinglabels(`has_missinglabels') misscodes(`misscodes') misstext(`misstext') ///
        hassurvey(`has_survey') surveyframe(`surveyframe') surveystages(`surveystages') ///
        hassections(`has_sections') sectionframe(`sectionframe') ///
        idreview(`idreview') restricted(`restricted_sample') ///
        autoidentifiers(`"`automatic_identifiers'"') ///
        strwidth(`strwidth') misshighlight(`misshighlight') ///
        fontsize(`fontsize') headsize(`headsize') fontname(`"`fontname'"') ///
        title(`"`title'"') pi(`"`pi'"') affiliation(`"`affiliation'"') ///
        funding(`"`funding'"') abstract(`"`abstract'"') ///
        sourcefile(`"`sourcefile'"') datalabel(`"`datalabel'"') ///
        classquant(`"`quantitative'"') classcont(`"`continuous'"') ///
        classdisc(`"`discrete'"') classcat(`"`categorical'"') ///
        classnom(`"`nominal'"') classord(`"`ordinal'"') ///
        classid(`"`id'"') classdate(`"`datevars'"') ///
        `replace' `pagebreak' `nodistributions' `reportwarnings' `quiet'
    }
    local rc=_rc
    frame change `caller'
    capture mata: mata drop `misscodes' `misstext'
    capture frame drop `idreview'
    capture frame drop `sectionframe'
    capture frame drop `surveyframe'
    capture frame drop `surveystages'
    capture frame drop `missingmap'
    capture frame drop `freq'
    capture frame drop `notesframe'
    capture frame drop `docframe'
    capture frame drop `work'
    if `rc' {
        capture frame drop `meta'
        di as err "datadoc 1.2.7 failed (return code `rc'); original data/frame retained."
        exit `rc'
    }
    foreach v of local identifier_variables {
        char `v'[doc_section] "Identifiers"
    }
    if "`metaframe'"!="" {
        frame rename `meta' `metaframe'
        return local metaframe "`metaframe'"
    }
    else frame drop `meta'
    return scalar excluded_variables=`excluded_variables'
    return scalar excluded_observations=`excluded_observations'
    return local summary "`summary'"
    return scalar N=`sampleN'
    local k : word count `varlist'
    return scalar k=`k'
    return scalar fontsize=`fontsize'
    return scalar sectionfontsize=`headsize'
    return local fontname `"`fontname'"'
    return local requestedfont `"`requested_font'"'
    return local fontstatus "`font_status'"
    return local filename `"`using'"'
    return local variables "`varlist'"
    return local version "1.2.7"
    if "`quiet'"=="" di as result `"Codebook saved: `using'"'
end

program define _ddoc127_survey, rclass
    version 19.0
    syntax , GENERAL(name) STAGES(name)
    capture quietly svyset
    if _rc {
        return scalar has_survey=0
        exit
    }
    local svy_settings `"`r(settings)'"'
    local svy_stages=r(stages)
    if ustrtrim(`"`svy_settings'"')=="" | missing(`svy_stages') | `svy_stages'<1 {
        return scalar has_survey=0
        exit
    }
    foreach key in wvar wtype wexp vce dofsubpop singleunit mse poststrata postweight ///
        rake regress brrweight bsrweight jkrweight sdrweight jkrstrata jkrfpc jkrmultiplier sdrfpc {
        local svy_`key' `"`r(`key')'"'
    }
    foreach key in dof fay bsn {
        capture local svy_`key'=r(`key')
        if _rc local svy_`key'=.
    }
    forvalues j=1/`svy_stages' {
        foreach key in su strata fpc weight {
            local svy_`key'`j' `"`r(`key'`j')'"'
        }
    }
    local caller=c(frame)
    frame create `general' strL setting strL value strL declaration
    frame create `stages' int stage strL strata strL sampling_unit strL fpc strL weight
    mata: ddoc127_surveyframes("`general'", "`stages'", "`caller'")
    return scalar has_survey=1
end

program define _ddoc127_build
    version 19.0
    syntax varlist using/ , META(name) FREQ(name) NOTESFRAME(name) DOCFRAME(name) ///
        SUMMARY(string) EXCLUDEDVARS(integer) EXCLUDEDOBS(real) ///
        HASMISSINGLABELS(integer) MISSCODES(name) MISSTEXT(name) ///
        HASSURVEY(integer) SURVEYFRAME(name) SURVEYSTAGES(name) ///
        HASSECTIONS(integer) SECTIONFRAME(name) IDREVIEW(name) RESTRICTED(integer) ///
        ORIGINALFRAME(name) MAXValues(integer) DECimals(integer) STRWidth(integer) ///
        MISSHighlight(real) FONTSIZE(real) HEADSIZE(real) FONTNAME(string) ///
        [AUTOIDENTIFIERS(string) TITLE(string) PI(string) AFFiliation(string) FUNDing(string) ///
        ABSTRACT(string) SOURCEFile(string) DATALabel(string) ///
        CLASSQUANT(string) CLASSCONT(string) CLASSDISC(string) CLASSCAT(string) ///
        CLASSNOM(string) CLASSORD(string) CLASSID(string) CLASSDATE(string) ///
        REPLACE PAGEbreak NODISTributions REPORTWarnings QUIET]
    local fontopts `"fontname("`fontname'") fontsize(`fontsize')"'
    local workframe=c(frame)
    local N=_N
    local k : word count `varlist'
    if `"`title'"'=="" local title `"`datalabel'"'
    if `"`title'"'=="" local title "Data Codebook"
    local pos=0
    foreach v of local varlist {
        local ++pos
        local storage : type `v'
        local label : variable label `v'
        local fmt : format `v'
        local vl : value label `v'
        if "`vl'"!="" {
            mata: ddoc127_haslabel("`vl'")
            if !`has_value_label' local vl ""
        }
        capture confirm numeric variable `v'
        local isnum=(_rc==0)
        local dtype "String"
        local classification "text"
        if `isnum' {
            local dtype "Numeric"
            local classification "quantitative"
            if "`vl'"!="" local classification "categorical"
            if substr("`fmt'",1,2)=="%t" {
                local dtype "Numeric (Date/Time)"
                local classification "date"
            }
        }
        local class_source "inferred"
        foreach pair in quant cont disc cat nom ord id date {
            if "`pair'"=="quant" local target "quantitative"
            if "`pair'"=="cont" local target "continuous"
            if "`pair'"=="disc" local target "discrete"
            if "`pair'"=="cat" local target "categorical"
            if "`pair'"=="nom" local target "nominal"
            if "`pair'"=="ord" local target "ordinal"
            if "`pair'"=="id" local target "identifier"
            if "`pair'"=="date" local target "date"
            local hit : list v in class`pair'
            if `hit' {
                local classification "`target'"
                local class_source "option"
            }
        }
        if "`class_source'"!="option" {
            mata: ddoc127_vartype("`v'", "`originalframe'", "`workframe'")
            if `invalid_doc_class' {
                di as err "Invalid doc_vartype for `v'."
                di as err "Allowed: quantitative, continuous, discrete, categorical, nominal, ordinal, identifier."
                exit 198
            }
            if "`doc_class'"!="" {
                local classification "`doc_class'"
                local class_source "characteristic"
            }
        }
        if "`class_source'"=="inferred" {
            local auto_identifier : list v in autoidentifiers
            if `auto_identifier' local classification "identifier"
        }
        if !`isnum' & inlist("`classification'","quantitative","continuous","discrete","ordinal","date") {
            di as err "`v': classification `classification' requires a numeric variable."
            exit 109
        }
        quietly count if !missing(`v')
        local valid=r(N)
        local missing=`N'-`valid'
        local pm=100*`missing'/`N'
        mata: ddoc127_unique("`v'", `isnum')
        local warning ""
        if `isnum' & "`class_source'"=="inferred" & "`classification'"=="quantitative" ///
            local warning "Inferred quantitative; check variable classification."
        if `isnum' & "`class_source'"=="inferred" & "`classification'"=="categorical" ///
            local warning "Inferred categorical; check whether nominal or ordinal."
        foreach s in mean sd min p1 p5 p10 p25 median p75 p90 p95 p99 max skewness kurtosis min_length mean_length max_length {
            local s_`s'=.
        }
        local ai=0
        local ext=0
        local unl=0
        if `isnum' {
            quietly count if `v'>.
            local ext=r(N)
            quietly count if !missing(`v') & `v'!=floor(`v')
            local ai=(r(N)==0 & `valid'>0)
            if inlist("`classification'","quantitative","continuous","discrete","ordinal","date") & `valid'>0 {
                quietly summarize `v', detail
                foreach s in mean sd min p1 p5 p10 p25 p75 p90 p95 p99 max skewness kurtosis {
                    local s_`s'=r(`s')
                }
                local s_median=r(p50)
            }
            if "`vl'"!="" mata: ddoc127_unlabeled("`v'", "`vl'")
            if `unl'>0 local warning `"`warning' `unl' valid observations have codes without labels."'
        }
        else if `valid'>0 & "`classification'"!="identifier" {
            tempvar len
            quietly gen double `len'=ustrlen(`v') if !missing(`v')
            quietly summarize `len'
            local s_min_length=r(min)
            local s_mean_length=r(mean)
            local s_max_length=r(max)
            quietly drop `len'
        }
        frame post `meta' (`pos') ("`v'") ("`storage'") ("`dtype'") ///
            ("`classification'") ("`class_source'") (`"`label'"') ("`vl'") ("`fmt'") ///
            (`N') (`valid') (`missing') (`pm') (`nu') ///
            (`s_mean') (`s_sd') (`s_min') (`s_p1') (`s_p5') (`s_p10') ///
            (`s_p25') (`s_median') (`s_p75') (`s_p90') (`s_p95') ///
            (`s_p99') (`s_max') (`s_skewness') (`s_kurtosis') ///
            (`s_min_length') (`s_mean_length') (`s_max_length') ///
            (`ai') (`unl') (`ext') (`"`warning'"')
        if "`quiet'"=="" di as text "[`pos'/`k'] `v': `classification', `nu' distinct valid values"
    }
    frame `meta' {
        quietly count if classification_source=="inferred" & inlist(classification,"quantitative","categorical")
        if r(N)>0 {
            di as text _n "Variables requiring a classification check:"
            di as text "The variables below have automatically inferred numeric classifications."
            di as text "Check whether each is quantitative, categorical, nominal, ordinal, or an identifier."
            list variable classification if classification_source=="inferred" & ///
                inlist(classification,"quantitative","categorical"), noobs abbreviate(32) separator(0)
        }
        quietly count if unlabeled>0
        if r(N)>0 {
            di as text _n "Variables requiring a value-label check:"
            di as text "Some valid observations have codes absent from the assigned value-label definition."
            list variable unlabeled if unlabeled>0, noobs abbreviate(32) separator(0)
        }
    }
    frame `idreview': local n_auto_identifiers=_N
    if `n_auto_identifiers'>0 {
        di as text _n "Automatically inferred identifiers:"
        frame `idreview': list variable match, noobs abbreviate(32) separator(0)
    }
    if "`quiet'"=="" di as text _n "Starting Word codebook rendering: 0/`k' variable descriptions completed."
    set docx_maxtable 10000
    putdocx begin, font("`fontname'",`fontsize') pagesize(letter) ///
        margin(left,0.5in) margin(right,0.5in) ///
        margin(top,0.6in) margin(bottom,0.6in) footer(ddfooter)
    putdocx paragraph, tofooter(ddfooter) halign(center)
    putdocx text ("- ")
    putdocx pagenumber
    putdocx text (" -")
    putdocx paragraph, halign(center) spacing(after,6pt)
    putdocx text (`"`title'"'), font("`fontname'",14,black) bold
    putdocx table ddtitlebar=(1,1), width(7.25in) layout(fixed) ///
        border(all,nil) cellmargin(top,0pt) cellmargin(bottom,0pt) ///
        cellmargin(left,0pt) cellmargin(right,0pt)
    putdocx table ddtitlebar(1,1)=("")
    putdocx table ddtitlebar(1,1), shading("003399") border(all,nil) font("`fontname'",1,white)
    putdocx table ddtitlebar(1,.), height(4pt,exact) nosplit
    putdocx paragraph, spacing(before,6pt)
    putdocx text ("Data Codebook"), font("`fontname'",`fontsize',black)
    putdocx paragraph
    putdocx text ("Generated: `c(current_date)' `c(current_time)' | datadoc 1.2.7 | Stata `c(stata_version)'")
    foreach field in pi affiliation funding abstract {
        if `"``field''"'!="" {
            local field_label=cond("`field'"=="pi","PI",proper("`field'"))
            putdocx paragraph
            putdocx text ("`field_label': "), bold
            putdocx text (`"``field''"')
        }
    }
    frame create `notesframe' strL note_text
    frame `originalframe': local data_charnames : char _dta[]
    local max_datanote=0
    foreach key of local data_charnames {
        if regexm("`key'","^note[1-9][0-9]*$") {
            local noteindex=real(substr("`key'",5,.))
            local max_datanote=max(`max_datanote',`noteindex')
        }
    }
    mata: ddoc127_notes("_dta", "`notesframe'", "`originalframe'", "`workframe'", `max_datanote')
    if `nnotes'>0 {
        _ddoc127_blank, `fontopts'
        putdocx paragraph, spacing(before,0pt) spacing(after,0pt)
        putdocx text ("Dataset Notes:"), bold font("`fontname'",`fontsize',black)
        forvalues j=1/`nnotes' {
            putdocx paragraph, spacing(before,0pt) spacing(after,0pt)
            frame `notesframe': putdocx text (note_text[`j'])
        }
    }
    putdocx paragraph
    putdocx text (`"Source: `sourcefile' | Selected sample N = `N'; reported variables = `k'"')
    if `excludedvars'>0 | `excludedobs'>0 {
        putdocx paragraph
        local excluded_obs_text : display %18.0f `excludedobs'
        local excluded_obs_text=strtrim("`excluded_obs_text'")
        local variable_word=cond(`excludedvars'==1,"variable","variables")
        local observation_word=cond(`excludedobs'==1,"observation","observations")
        putdocx text ("This codebook excludes `excludedvars' `variable_word' and `excluded_obs_text' `observation_word' present in the original dataset.")
    }
    putdocx paragraph, style(Heading1)
    putdocx text ("Codebook Notes"), font("`fontname'",`headsize',black) bold
    putdocx paragraph
    putdocx text (`"All counts, percentages, and summary statistics in the Variable Descriptions are unweighted. Valid % excludes missing observations; Total % includes all observations in the reported sample. Numeric codes such as −99 that may represent missing values are treated as valid; only values explicitly recorded as missing are treated as missing in the codebook. A dot indicates an unavailable statistic. Bracketed numeric codes show underlying values not fully represented by the displayed format."')

    local T=0
    putdocx paragraph, style(Heading1)
    putdocx text ("Variable Inventory"), font("`fontname'",`headsize',black) bold
    local ++T
    tempvar display_class display_valid display_unique display_pct display_missing display_extended
    frame `meta' {
        quietly gen str16 `display_class'=proper(classification)
        quietly replace `display_class'="Date/Time" if classification=="date"
        quietly gen str24 `display_valid'=strtrim(string(valid,"%18.0f"))
        quietly gen str24 `display_unique'=strtrim(string(unique,"%18.0f"))
        quietly gen str24 `display_pct'=strtrim(string(pct_missing,"%8.2f"))
        quietly gen str24 `display_missing'=strtrim(string(missing,"%18.0f"))
        quietly gen str24 `display_extended'=strtrim(string(extended_missing,"%18.0f"))
        _ddoc127_new t`T', rows(`=`k'+1') cols(7) ///
            data(position variable `display_class' label `display_valid' `display_unique' `display_pct') `fontopts'
        _ddoc127_header t`T', headers("Pos" "Variable" "Variable Type" "Label" "Valid N" "Distinct" "% missing") `fontopts' blue
        forvalues j=1/`k' {
            local row=`j'+1
            local vn=variable[`j']
            putdocx table t`T'(`row',2)=(variable[`j']), bookmarklink(`vn')
        }
    }
    putdocx table t`T'(.,1), width(5%)
    putdocx table t`T'(.,2), width(14%)
    putdocx table t`T'(.,3), width(16%)
    putdocx table t`T'(.,4), width(35%)
    putdocx table t`T'(.,5/7), halign(right)
    putdocx table t`T'(.,5), width(10%)
    putdocx table t`T'(.,6), width(10%)
    putdocx table t`T'(.,7), width(10%)
    if `hassections' {
        tempvar inventory_section_start
        frame `sectionframe': quietly gen long `inventory_section_start'=_n ///
            if section_label!="" & (_n==1 | section_order!=section_order[_n-1])
        frame `sectionframe': quietly levelsof `inventory_section_start', local(inventory_section_starts)
        local inventory_section_count : word count `inventory_section_starts'
        if `inventory_section_count'>0 {
            forvalues h=`inventory_section_count'(-1)1 {
                local section_position : word `h' of `inventory_section_starts'
                local row=`section_position'+1
                putdocx table t`T'(`row',.), addrows(1,before)
                putdocx table t`T'(`row',1)=("")
                frame `sectionframe': putdocx table t`T'(`row',2)=(ustrtitle(section_label[`section_position'])), ///
                    colspan(6) halign(left) bold font("`fontname'",`fontsize',black)
                putdocx table t`T'(`row',.), shading("DEDEDE") border(all,nil) nosplit
                putdocx table t`T'(`row',.), addrows(1,before)
                putdocx table t`T'(`row',.), shading("FFFFFF") border(all,nil) ///
                    font("`fontname'",`fontsize',black) nosplit
            }
        }
        frame `sectionframe': quietly drop `inventory_section_start'
    }
    putdocx pagebreak
    putdocx paragraph, style(Heading1)
    putdocx text ("Variable Descriptions"), font("`fontname'",`headsize',black) bold
    local integer_location_stats "min max p1 p5 p10 p25 median p75 p90 p95 p99"
    local bannerheight=max(16.5,1.2*`fontsize'+4)
    frame create `docframe' str12 heading strL char_text
    local pos=0
    local previous_section=0
    foreach v of local varlist {
        local ++pos
        local section_changed=0
        if `hassections' {
            frame `sectionframe': local current_section=section_order[`pos']
            if `current_section'!=`previous_section' {
                if `pos'>1 putdocx pagebreak
                frame `sectionframe': local has_section_heading=(section_label[`pos']!="")
                if `has_section_heading' {
                    putdocx paragraph, style(Heading2) spacing(before,6pt) spacing(after,6pt)
                    frame `sectionframe': putdocx text (ustrtitle(section_label[`pos'])), ///
                        font("`fontname'",`headsize',black) bold
                }
                local previous_section=`current_section'
                local section_changed=1
            }
        }
        if "`pagebreak'"!="" & `pos'>1 & !`section_changed' putdocx pagebreak
        else putdocx paragraph, spacing(before,10pt) spacing(after,0pt)
        local ++T
        putdocx paragraph, shading("003399") ///
            font("`fontname'",`fontsize',white) ///
            indent(para,5pt) indent(right,0.25in) ///
            spacing(before,0pt) spacing(after,0pt) spacing(line,`bannerheight'pt)
        putdocx text ("`v' - "), bookmark(`v') bold
        frame `meta': putdocx text (label[`pos']), bold
        putdocx paragraph, font("`fontname'",`fontsize',black) ///
            spacing(before,0pt) spacing(after,0pt) spacing(line,`fontsize'pt)
        putdocx text (" "), font("`fontname'",`fontsize',black)
        frame `meta' {
            local dtype=data_type[`pos']
            local classification=classification[`pos']
            local nu=unique[`pos']
            local valid=valid[`pos']
            local fmt=format[`pos']
            local storage=storage[`pos']
            local vl=value_label[`pos']
            local allint=all_integer[`pos']
        }
        _ddoc127_classlabel `classification'
        local displayclass `"`r(label)'"'
        capture confirm numeric variable `v'
        local isnum=(_rc==0)
        putdocx paragraph, spacing(before,0pt) spacing(after,3pt)
        putdocx text ("Variable Type: "), bold
        putdocx text (`"`displayclass'"')
        putdocx paragraph, spacing(before,0pt) spacing(after,0pt)
        putdocx text ("Storage: "), bold
        putdocx text ("`storage' | ")
        putdocx text ("Format: "), bold
        putdocx text ("`fmt' | ")
        putdocx text ("Data Type: "), bold
        putdocx text ("`dtype' | ")
        putdocx text ("Valid "), bold
        putdocx text ("N"), bold italic
        putdocx text (": "), bold
        putdocx text ("`valid' | ")
        putdocx text ("Distinct Valid Values: "), bold
        putdocx text ("`nu'")
        if "`vl'"!="" {
            putdocx text (" | ")
            putdocx text ("Value Label: "), bold
            putdocx text ("`vl'")
        }
        local charnames
        frame `originalframe': local charnames : char `v'[]
        local maxnote=0
        foreach key of local charnames {
            if regexm("`key'","^note[1-9][0-9]*$") {
                local noteindex=real(substr("`key'",5,.))
                local maxnote=max(`maxnote',`noteindex')
            }
        }
        frame `notesframe': quietly drop if _n>0
        mata: ddoc127_notes("`v'", "`notesframe'", "`originalframe'", "`workframe'", `maxnote')
        if `nnotes'>0 {
            _ddoc127_blank, `fontopts'
            putdocx paragraph, spacing(before,0pt) spacing(after,0pt)
            putdocx text ("Notes:"), bold font("`fontname'",`fontsize',black)
            forvalues j=1/`nnotes' {
                putdocx paragraph, spacing(before,0pt) spacing(after,0pt)
                frame `notesframe': putdocx text (note_text[`j'])
            }
        }
        frame `docframe': quietly drop if _n>0
        mata: ddoc127_chars("`v'", "`docframe'", "`originalframe'", "`workframe'", `native_notes_present')
        if `ndocchars'>0 {
            forvalues d=1/`ndocchars' {
                _ddoc127_blank, `fontopts'
                putdocx paragraph, spacing(before,0pt) spacing(after,0pt)
                frame `docframe': putdocx text (heading[`d']+":"), ///
                    bold font("`fontname'",`fontsize',black)
                putdocx paragraph, spacing(before,0pt) spacing(after,0pt)
                frame `docframe': putdocx text (char_text[`d'])
            }
            _ddoc127_blank, `fontopts'
        }
        local stats ""
        if inlist("`classification'","quantitative","continuous","discrete") ///
            local stats "mean sd min p1 p5 p10 p25 median p75 p90 p95 p99 max skewness kurtosis"
        if "`summary'"=="basic" & inlist("`classification'","quantitative","continuous","discrete") ///
            local stats "mean sd min median max"
        if "`classification'"=="ordinal" local stats "min p25 median p75 max"
        if "`classification'"=="date" local stats "min median max"
        if !`isnum' & "`classification'"!="identifier" local stats "min_length mean_length max_length"
        if "`stats'"!="" {
            if `ndocchars'==0 _ddoc127_blank, `fontopts'
            putdocx paragraph, spacing(before,0pt) spacing(after,3pt)
            putdocx text ("Summary Statistics"), bold
            local ns : word count `stats'
            local ++T
            _ddoc127_new t`T', rows(`=`ns'+1') cols(2) width(4.75) `fontopts'
            _ddoc127_header t`T', headers("Statistic" "Value") `fontopts'
            local sr=1
            foreach s of local stats {
                local ++sr
                _ddoc127_statlabel `s'
                local statlabel `"`r(label)'"'
                if "`summary'"=="basic" & inlist("`classification'","quantitative","continuous","discrete") {
                    if "`s'"=="median" local statlabel "Median"
                    if "`s'"=="max" local statlabel "Max"
                }
                putdocx table t`T'(`sr',1)=(`"`statlabel'"')
                if "`s'"=="sd" putdocx table t`T'(`sr',1), italic
                frame `meta': local raw_value=`s'[`pos']
                if "`classification'"=="date" {
                    local value_text : display `fmt' `raw_value'
                }
                else {
                    local nd=`decimals'
                    local is_location : list s in integer_location_stats
                    if `allint' & `is_location' & !missing(`raw_value') {
                        if `raw_value'==floor(`raw_value') local nd=0
                    }
                    local value_text : display %32.`nd'f `raw_value'
                }
                local value_text=strtrim(`"`value_text'"')
                putdocx table t`T'(`sr',2)=(`"`value_text'"'), halign(left)
            }
            putdocx table t`T'(.,1), width(45%) halign(left)
            putdocx table t`T'(.,2), width(55%) halign(left)
            putdocx table t`T'(1,2), halign(left)
        }
        if "`nodistributions'"=="" & "`classification'"!="identifier" & `nu'<=`maxvalues' {
            local show_label=("`vl'"!="" | (`isnum' & `hasmissinglabels'))
            local fcols=4+`show_label'
            local c_freq=2+`show_label'
            local c_valid=3+`show_label'
            local c_total=4+`show_label'
            capture frame drop `freq'
            frame put `v', into(`freq')
            frame `freq' {
                mata: ddoc127_contract("`v'", `isnum')
                local zero_suppressed=0
                if `isnum' & "`vl'"!="" {
                    mata: ddoc127_addcodes("`vl'", "`workframe'", "`freq'")
                    quietly count if frequency==0
                    if r(N)>10 {
                        local zero_suppressed=r(N)
                        quietly drop if frequency==0
                    }
                    quietly sort code
                }
                local nf=_N
                quietly gen double valid_pct=cond(is_missing,.,100*frequency/`valid')
                quietly gen double total_pct=100*frequency/`N'
                quietly gen strL category_label=""
                if `isnum' & "`vl'"!="" {
                    forvalues j=1/`nf' {
                        local code=code[`j']
                        frame `workframe': local text : label `vl' `code', strict
                        quietly replace category_label=`"`text'"' in `j'
                    }
                }
                if `isnum' & `show_label' {
                    quietly replace category_label="(missing)" if is_missing & ustrtrim(category_label)==""
                    if `hasmissinglabels' {
                        quietly count if is_missing
                        if r(N)>0 mata: ddoc127_missinglabels(`misscodes', `misstext')
                    }
                }
                quietly gen strL shown=""
                if `isnum' {
                    quietly replace shown=strtrim(string(code,"`fmt'"))
                    quietly gen double parsed_value=real(subinstr(shown,",","",.))
                    quietly gen byte needs_code=(parsed_value!=code)
                    if "`storage'"=="float" {
                        quietly replace needs_code=(float(parsed_value)!=code)
                    }
                    quietly replace shown=shown+" ["+strtrim(string(code,"%24.17g"))+"]" if needs_code
                }
                else {
                    quietly replace shown=cond(ustrlen(raw)>`strwidth',usubstr(raw,1,`strwidth')+uchar(8230),raw)
                    quietly replace shown="(empty string / missing)" if is_missing
                }
                local fscale=`fontsize'/10
                quietly gen double value_chars=udstrlen(shown)
                quietly summarize value_chars, meanonly
                local w_value=max(0.70,0.18+r(max)*`fscale'/12)
                quietly summarize frequency, meanonly
                local count_text : display %18.0f r(max)
                local count_text=strtrim("`count_text'")
                local w_freq=max(0.95,0.18+max(9,strlen("`count_text'"))*`fscale'/12)
                local w_percent=max(0.95,0.18+7*`fscale'/12)
                local numeric_budget=7.25-0.70-1.25*`show_label'
                local numeric_width=`w_freq'+2*`w_percent'
                if `numeric_width'>`numeric_budget' {
                    local shrink=`numeric_budget'/`numeric_width'
                    local w_freq=`w_freq'*`shrink'
                    local w_percent=`w_percent'*`shrink'
                }
                local available=7.25-`w_freq'-2*`w_percent'
                if `show_label' {
                    quietly gen double label_chars=udstrlen(category_label)
                    quietly summarize label_chars, meanonly
                    local w_value=min(`w_value',`available'-1.25)
                    local w_label=min(max(1.25,0.18+r(max)*`fscale'/12),`available'-`w_value')
                }
                else {
                    local w_value=min(`w_value',`available')
                    local w_label=0
                }
                local tablewidth=`w_value'+`w_label'+`w_freq'+2*`w_percent'
                if "`stats'"=="" & `nnotes'==0 & `ndocchars'==0 _ddoc127_blank, `fontopts'
                putdocx paragraph, spacing(before,5pt) spacing(after,3pt)
                putdocx text ("Distribution and Missing Codes"), bold
                local ++T
                quietly gen str24 frequency_text=strtrim(string(frequency,"%18.0f"))
                quietly gen str24 valid_text=cond(is_missing,"",strtrim(string(valid_pct,"%8.2f")))
                quietly gen str24 total_text=strtrim(string(total_pct,"%8.2f"))
                local distribution_columns "shown frequency_text valid_text total_text"
                if `show_label' local distribution_columns "shown category_label frequency_text valid_text total_text"
                _ddoc127_new t`T', rows(`=`nf'+1') cols(`fcols') ///
                    data(`distribution_columns') width(`tablewidth') `fontopts'
                if `show_label' {
                    _ddoc127_header t`T', headers("Value" "Label" "Frequency" "Valid %" "Total %") `fontopts'
                }
                else {
                    _ddoc127_header t`T', headers("Value" "Frequency" "Valid %" "Total %") `fontopts'
                }
                putdocx table t`T'(.,1), width(`w_value'in) halign(left)
                if `show_label' putdocx table t`T'(.,2), width(`w_label'in) halign(left)
                putdocx table t`T'(.,`c_freq'), width(`w_freq'in) halign(right)
                putdocx table t`T'(.,`c_valid'), width(`w_percent'in) halign(right)
                putdocx table t`T'(.,`c_total'), width(`w_percent'in) halign(right)
                if `zero_suppressed'>0 {
                    putdocx paragraph, spacing(before,3pt) spacing(after,3pt)
                    putdocx text ("`zero_suppressed' defined value-label codes have no observations in the selected sample. Because this exceeds 10, all zero-frequency rows are omitted from this table; counts and percentages are unchanged."), italic
                }
            }
            frame drop `freq'
        }
        else {
            if "`stats'"=="" & `nnotes'==0 & `ndocchars'==0 ///
                _ddoc127_blank, `fontopts'
            putdocx paragraph, spacing(after,5pt)
            local omission "Distribution omitted because there are more than `maxvalues' distinct valid values."
            if "`nodistributions'"!="" local omission "Distribution omitted: nodistributions requested."
            if "`classification'"=="identifier" {
                local identifier_scope "dataset"
                if `restricted' local identifier_scope "selected sample"
                local omission "This identifier does not uniquely identify observations in the `identifier_scope'."
                if `valid'==`N' & `nu'==`N' ///
                    local omission "This identifier uniquely identifies observations in the `identifier_scope'."
            }
            putdocx text ("`omission'"), italic
        }
        if "`quiet'"=="" & `k'>=51 & (mod(`pos',50)==0 | `pos'==`k') ///
            di as text "Rendering variable descriptions: `pos'/`k' completed."
    }
    if `hassurvey' {
        putdocx pagebreak
        putdocx paragraph, style(Heading1)
        putdocx text ("Survey Sampling Characteristics"), font("`fontname'",`headsize',black) bold
        putdocx paragraph
        putdocx text ("These settings describe the survey declaration in the original dataset. Codebook counts, distributions, and summary statistics are unweighted. Listing the settings does not validate the sampling design or its associated variables, including for any selected subset.")
        putdocx paragraph, spacing(before,5pt) spacing(after,3pt)
        putdocx text ("General Settings"), bold
        local ++T
        frame `surveyframe' {
            local surveyrows=_N+1
            _ddoc127_new t`T', rows(`surveyrows') cols(2) data(setting value) `fontopts'
        }
        _ddoc127_header t`T', headers("Setting" "Declared value") `fontopts'
        putdocx table t`T'(.,1), width(35%)
        putdocx table t`T'(.,2), width(65%)
        frame `surveystages': local nsurvey=_N
        if `nsurvey'>0 {
            putdocx paragraph, spacing(before,5pt) spacing(after,3pt)
            putdocx text ("Sampling Stages"), bold
            frame `surveystages': quietly count if weight!=""
            local stageweights=(r(N)>0)
            local stagecolumns "stage strata sampling_unit fpc"
            if `stageweights' local stagecolumns "`stagecolumns' weight"
            local ++T
            frame `surveystages': _ddoc127_new t`T', rows(`=`nsurvey'+1') ///
                cols(`=4+`stageweights'') data(`stagecolumns') `fontopts'
            if `stageweights' {
                _ddoc127_header t`T', headers("Stage" "Strata" "Sampling unit" "FPC variable" "Stage weight") `fontopts'
            }
            else {
                _ddoc127_header t`T', headers("Stage" "Strata" "Sampling unit" "FPC variable") `fontopts'
            }
        }
        putdocx paragraph, spacing(before,5pt) spacing(after,3pt)
        putdocx text ("Declared Survey Settings"), bold
        putdocx paragraph
        frame `surveyframe': putdocx text (declaration[1])
    }
    if "`quiet'"=="" di as text "Rendering missing-data report..."
    putdocx pagebreak
    putdocx paragraph, style(Heading1)
    putdocx text ("Missing-Data Report"), font("`fontname'",`headsize',black) bold
    local ++T
    frame `meta' {
        _ddoc127_new t`T', rows(`=`k'+1') cols(5) ///
            data(variable `display_valid' `display_missing' `display_pct' `display_extended') `fontopts'
        _ddoc127_header t`T', headers("Variable" "Valid N" "Missing N" "% missing" "Extended missing N") `fontopts'
        forvalues j=1/`k' {
            if pct_missing[`j']>`misshighlight' {
                local rr=`j'+1
                putdocx table t`T'(`rr',.), shading("FFE5E5")
            }
        }
        quietly summarize pct_missing
        local avg=r(mean)
        local mx=r(max)
        quietly drop `display_class' `display_valid' `display_unique' `display_pct' `display_missing' `display_extended'
    }
    putdocx table t`T'(.,1), width(28%)
    putdocx table t`T'(.,2), width(14%)
    putdocx table t`T'(.,3), width(14%)
    putdocx table t`T'(.,4), width(16%)
    putdocx table t`T'(.,5), width(28%)
    putdocx table t`T'(.,2/5), halign(right)
    putdocx paragraph
    putdocx text ("Mean variable missingness: ")
    putdocx text (`avg'), nformat(%8.2f)
    putdocx text ("%; maximum: ")
    putdocx text (`mx'), nformat(%8.2f)
    putdocx text ("%.")
    if "`reportwarnings'"!="" {
        frame `meta': quietly count if ustrtrim(warning)!=""
        local nw=r(N)
        putdocx paragraph, style(Heading1)
        putdocx text ("Review Diagnostics"), font("`fontname'",`headsize',black) bold
        if `nw'==0 {
            putdocx paragraph
            putdocx text ("No classification or value-label review diagnostics were generated.")
        }
        else {
            forvalues j=1/`k' {
                frame `meta': local haswarning=(ustrtrim(warning[`j'])!="")
                if `haswarning' {
                    putdocx paragraph
                    frame `meta': putdocx text (variable[`j']+": "+ustrtrim(warning[`j']))
                }
            }
        }
    }
    if "`quiet'"=="" di as text "Saving codebook..."
    if "`replace'"!="" putdocx save `"`using'"', replace
    else putdocx save `"`using'"'
end

program define _ddoc127_new
    version 19.0
    syntax namelist(min=1 max=1), ROWS(integer) COLS(integer) ///
        FONTNAME(string) FONTSIZE(real) [WIDTH(real 7.25) DATA(varlist)]
    local table_source "(`rows',`cols')"
    local table_header
    if "`data'"!="" {
        local table_source "data(`data')"
        local table_header "varnames"
    }
    putdocx table `namelist'=`table_source', `table_header' width(`width'in) ///
        halign(left) layout(fixed) border(all,nil) headerrow(1) ///
        cellmargin(left,4pt) cellmargin(right,4pt) ///
        cellmargin(top,2pt) cellmargin(bottom,2pt)
    putdocx table `namelist'(.,.), border(all,nil) ///
        shading("FFFFFF") font("`fontname'",`fontsize',black) valign(center)
    forvalues r=1/`rows' {
        putdocx table `namelist'(`r',.), nosplit
    }
    if `rows'>=3 {
        forvalues first=3(2000)`rows' {
            local last=min(`rows',`first'+1998)
            putdocx table `namelist'(`first'(2)`last',.), shading("EFEFEF")
        }
    }
end

program define _ddoc127_header
    version 19.0
    syntax namelist(min=1 max=1), HEADERS(string asis) FONTNAME(string) FONTSIZE(real) [BLUE]
    local header_fill "DEDEDE"
    local header_color "black"
    if "`blue'"!="" {
        local header_fill "003399"
        local header_color "white"
    }
    local c=0
    foreach h of local headers {
        local ++c
        if `"`h'"'=="Valid N" {
            putdocx table `namelist'(1,`c')=("Valid "), font("`fontname'",`fontsize',`header_color') bold
            putdocx table `namelist'(1,`c')=("N"), append font("`fontname'",`fontsize',`header_color') bold italic
            putdocx table `namelist'(1,`c'), shading("`header_fill'") border(all,nil)
        }
        else {
            putdocx table `namelist'(1,`c')=(`"`h'"')
            putdocx table `namelist'(1,`c'), ///
                shading("`header_fill'") font("`fontname'",`fontsize',`header_color') bold border(all,nil)
        }
    }
end

program define _ddoc127_blank
    version 19.0
    syntax , FONTNAME(string) FONTSIZE(real)
    putdocx paragraph, spacing(before,0pt) spacing(after,0pt)
    putdocx text (" "), font("`fontname'",`fontsize',black)
end

program define _ddoc127_classlabel, rclass
    version 19.0
    args classification
    local label "`classification'"
    if "`classification'"=="quantitative" local label "Quantitative"
    if "`classification'"=="continuous" local label "Continuous"
    if "`classification'"=="discrete" local label "Discrete"
    if "`classification'"=="categorical" local label "Categorical"
    if "`classification'"=="nominal" local label "Nominal"
    if "`classification'"=="ordinal" local label "Ordinal"
    if "`classification'"=="identifier" local label "Identifier"
    if "`classification'"=="date" local label "Date/Time"
    if "`classification'"=="text" local label "Text"
    return local label "`label'"
end

program define _ddoc127_statlabel, rclass
    version 19.0
    args stat
    local label "`stat'"
    if "`stat'"=="mean" local label "Mean"
    if "`stat'"=="sd" local label "SD"
    if "`stat'"=="min" local label "Minimum"
    if "`stat'"=="max" local label "Maximum"
    if "`stat'"=="p1" local label "1st Percentile"
    if "`stat'"=="p5" local label "5th Percentile"
    if "`stat'"=="p10" local label "10th Percentile"
    if "`stat'"=="p25" local label "25th Percentile (Q1)"
    if "`stat'"=="median" local label "Median (50th Percentile)"
    if "`stat'"=="p75" local label "75th Percentile (Q3)"
    if "`stat'"=="p90" local label "90th Percentile"
    if "`stat'"=="p95" local label "95th Percentile"
    if "`stat'"=="p99" local label "99th Percentile"
    if "`stat'"=="skewness" local label "Skewness"
    if "`stat'"=="kurtosis" local label "Kurtosis"
    if "`stat'"=="min_length" local label "Minimum String Length"
    if "`stat'"=="mean_length" local label "Mean String Length"
    if "`stat'"=="max_length" local label "Maximum String Length"
    return local label "`label'"
end

capture mata: mata drop ddoc127_identifiers()
capture mata: mata drop ddoc127_sections()
capture mata: mata drop ddoc127_surveyframes()
capture mata: mata drop ddoc127_unique()
capture mata: mata drop ddoc127_unlabeled()
capture mata: mata drop ddoc127_contract()
capture mata: mata drop ddoc127_haslabel()
capture mata: mata drop ddoc127_addcodes()
capture mata: mata drop ddoc127_missinglabels()
capture mata: mata drop ddoc127_notes()
capture mata: mata drop ddoc127_chars()
capture mata: mata drop ddoc127_vartype()
mata:
void ddoc127_identifiers(string scalar review_frame, string scalar resume_frame)
{
    string colvector names, assigned, option_ids, identifiers, automatic_ids, reasons
    string scalar declared_type, label, reason
    real scalar i, j, is_identifier, is_automatic, name_match, label_match
    transmorphic scalar option_lookup
    names = tokens(st_local("varlist"))'
    assigned = tokens(st_local("assigned"))'
    option_ids = tokens(st_local("id"))'
    identifiers = J(0, 1, "")
    automatic_ids = J(0, 1, "")
    reasons = J(0, 1, "")
    option_lookup = asarray_create("string", 1)
    for (j = 1; j <= rows(assigned); j++) asarray(option_lookup, assigned[j], 0)
    for (j = 1; j <= rows(option_ids); j++) asarray(option_lookup, option_ids[j], 1)
    for (i = 1; i <= rows(names); i++) {
        is_identifier = 0
        is_automatic = 0
        reason = ""
        if (asarray_contains(option_lookup, names[i])) {
            is_identifier = asarray(option_lookup, names[i])
        }
        else {
            declared_type = strlower(strtrim(st_global(names[i] + "[doc_vartype]")))
            if (declared_type != "") is_identifier = (declared_type == "identifier")
            else {
                label = st_varlabel(st_varindex(names[i]))
                name_match = (ustrregexm(names[i], "id$", 1) > 0)
                label_match = (ustrregexm(label, "\bid\b", 1) > 0)
                is_identifier = (name_match | label_match)
                if (ustrregexm(names[i], "gender", 1) > 0 |
                    ustrregexm(label, "gender", 1) > 0) is_identifier = 0
                is_automatic = is_identifier
                if (name_match) reason = "Name ends in id"
                if (label_match) {
                    if (reason != "") reason = reason + "; "
                    reason = reason + "Label contains standalone ID"
                }
            }
        }
        if (is_identifier) identifiers = identifiers \ names[i]
        if (is_automatic) {
            automatic_ids = automatic_ids \ names[i]
            reasons = reasons \ reason
        }
    }
    if (rows(automatic_ids) > 0) {
        stata("frame change " + review_frame)
        st_addobs(rows(automatic_ids))
        st_sstore(., "variable", automatic_ids)
        st_sstore(., "match", reasons)
        stata("frame change " + resume_frame)
    }
    st_local("identifier_variables", invtokens(identifiers'))
    st_local("automatic_identifiers", invtokens(automatic_ids'))
}

void ddoc127_sections(string scalar section_frame, string scalar resume_frame)
{
    string colvector names, sections, display_sections, identifiers
    real colvector positions, groups, permutation
    real scalar i, j, n_groups, has_sections, show_sections
    transmorphic scalar identifier_lookup
    transmorphic scalar group_lookup
    names = tokens(st_local("varlist"))'
    positions = st_varindex(names')'
    identifiers = tokens(st_local("identifier_variables"))'
    identifier_lookup = asarray_create("string", 1)
    for (j = 1; j <= rows(identifiers); j++) asarray(identifier_lookup, identifiers[j], 1)
    sections = J(rows(names), 1, "")
    for (i = 1; i <= rows(names); i++) {
        sections[i] = strtrim(st_global(names[i] + "[doc_section]"))
        if (asarray_contains(identifier_lookup, names[i])) sections[i] = "Identifiers"
    }
    has_sections = any(sections :!= "")
    show_sections = any((sections :!= "") :& (sections :!= "Identifiers"))
    groups = J(rows(names), 1, 0)
    if (has_sections) {
        permutation = order(positions, 1)
        names = names[permutation]
        sections = sections[permutation]
        positions = positions[permutation]
        group_lookup = asarray_create("string", 1)
        n_groups = 0
        if (any(sections :== "Identifiers")) {
            n_groups = 1
            asarray(group_lookup, "Identifiers", 1)
        }
        for (i = 1; i <= rows(names); i++) {
            if (sections[i] != "") {
                if (!asarray_contains(group_lookup, sections[i])) {
                    n_groups++
                    asarray(group_lookup, sections[i], n_groups)
                }
                groups[i] = asarray(group_lookup, sections[i])
            }
        }
        groups = groups + (sections :== "") :* (n_groups + 1)
        permutation = order((groups, positions), (1, 2))
        names = names[permutation]
        sections = sections[permutation]
        positions = positions[permutation]
        groups = groups[permutation]
        st_local("varlist", invtokens(names'))
    }
    display_sections = sections
    for (i = 1; i <= rows(display_sections); i++) {
        if (display_sections[i] == "") display_sections[i] = "Other variables"
    }
    stata("frame change " + section_frame)
    st_addobs(rows(names))
    st_sstore(., "variable", names)
    st_sstore(., "section_label", display_sections)
    st_store(., "section_order", groups)
    st_store(., "dataset_position", positions)
    stata("frame change " + resume_frame)
    st_local("has_sections", strofreal(show_sections, "%1.0f"))
}

void ddoc127_surveyframes(string scalar general_frame, string scalar stage_frame,
    string scalar resume_frame)
{
    string colvector headings, values, keys, labels, strata, units, fpcs, weights
    string scalar value, key, vce
    real scalar i, j, n_stages, number
    headings = ("Sampling-weight variable" \ "Weight type" \ "Variance estimator" \ "Subpopulation degrees-of-freedom adjustment" \ "Single-unit handling")
    value = st_local("svy_wvar")
    if (value == "") value = "(none)"
    values = value
    value = st_local("svy_wtype")
    if (value == "") value = "(none)"
    values = values \ value
    vce = st_local("svy_vce")
    if (vce == "") vce = "linearized"
    values = values \ vce
    value = "Off"
    if (st_local("svy_dofsubpop") == "dofsubpop") value = "On"
    values = values \ value
    value = st_local("svy_singleunit")
    if (value == "") value = "missing"
    values = values \ value
    keys = ("poststrata" \ "postweight" \ "rake" \ "regress" \ "brrweight" \ "bsrweight" \ "jkrweight" \ "sdrweight" \ "jkrstrata" \ "jkrfpc" \ "jkrmultiplier" \ "sdrfpc")
    labels = ("Poststratification variable" \ "Poststratification population totals" \ "Raking calibration" \ "Regression calibration" \ "BRR replicate weights" \ "Bootstrap replicate weights" \ "Jackknife replicate weights" \ "SDR replicate weights" \ "Jackknife replicate strata" \ "Jackknife replicate FPC" \ "Jackknife replicate multipliers" \ "SDR replicate FPC")
    for (i = 1; i <= rows(keys); i++) {
        value = st_local("svy_" + keys[i])
        if (value != "") {
            headings = headings \ labels[i]
            values = values \ value
        }
    }
    number = strtoreal(st_local("svy_dof"))
    if (number < . & regexm(st_local("svy_settings"), "dof[ ]*\(")) {
        headings = headings \ "Declared design degrees of freedom"
        values = values \ strtrim(strofreal(number, "%18.0g"))
    }
    number = strtoreal(st_local("svy_fay"))
    if (number < . & (vce == "brr" | st_local("svy_brrweight") != "")) {
        headings = headings \ "Fay's adjustment"
        values = values \ strtrim(strofreal(number, "%18.0g"))
    }
    number = strtoreal(st_local("svy_bsn"))
    if (number < . & (vce == "bootstrap" | st_local("svy_bsrweight") != "")) {
        headings = headings \ "Bootstrap mean-weight adjustment"
        values = values \ strtrim(strofreal(number, "%18.0g"))
    }
    if (st_local("svy_mse") != "") {
        headings = headings \ "Mean squared error adjustment"
        values = values \ "On"
    }
    n_stages = strtoreal(st_local("svy_stages"))
    strata = J(n_stages, 1, "")
    units = J(n_stages, 1, "")
    fpcs = J(n_stages, 1, "")
    weights = J(n_stages, 1, "")
    for (j = 1; j <= n_stages; j++) {
        key = strtrim(strofreal(j, "%9.0f"))
        strata[j] = st_local("svy_strata" + key)
        if (strata[j] == "") strata[j] = "<one>"
        units[j] = st_local("svy_su" + key)
        if (units[j] == "" | units[j] == "_n") units[j] = "<observations>"
        fpcs[j] = st_local("svy_fpc" + key)
        if (fpcs[j] == "") fpcs[j] = "(none)"
        weights[j] = st_local("svy_weight" + key)
    }
    stata("frame change " + general_frame)
    st_addobs(rows(headings))
    st_sstore(., "setting", headings)
    st_sstore(., "value", values)
    st_sstore(1, "declaration", "svyset " + st_local("svy_settings"))
    stata("frame change " + stage_frame)
    st_addobs(n_stages)
    st_store(., "stage", (1::n_stages))
    st_sstore(., "strata", strata)
    st_sstore(., "sampling_unit", units)
    st_sstore(., "fpc", fpcs)
    st_sstore(., "weight", weights)
    stata("frame change " + resume_frame)
}

void ddoc127_vartype(string scalar var_name, string scalar original_frame, string scalar resume_frame)
{
    string scalar declared_type
    string colvector allowed
    real scalar invalid
    allowed = ("quantitative" \ "continuous" \ "discrete" \ "categorical" \ "nominal" \ "ordinal" \ "identifier")
    stata("frame change " + original_frame)
    declared_type = strlower(strtrim(st_global(var_name + "[doc_vartype]")))
    stata("frame change " + resume_frame)
    invalid = (declared_type != "" & !any(allowed :== declared_type))
    st_local("invalid_doc_class", strofreal(invalid, "%1.0f"))
    if (invalid) {
        st_local("doc_class", "")
    }
    else {
        st_local("doc_class", declared_type)
    }
}

void ddoc127_haslabel(string scalar label_name)
{
    real colvector label_codes
    string colvector label_text
    st_local("has_value_label", "0")
    if (!st_vlexists(label_name)) return
    st_vlload(label_name, label_codes, label_text)
    st_local("has_value_label", strofreal(rows(label_codes) > 0, "%1.0f"))
}

void ddoc127_addcodes(string scalar label_name, string scalar label_frame,
    string scalar resume_frame)
{
    real colvector label_codes, observed_codes, added_codes, added_rows
    string colvector label_text
    real scalar i, n_added, n_obs
    observed_codes = st_data(., "code")
    stata("frame change " + label_frame)
    st_vlload(label_name, label_codes, label_text)
    stata("frame change " + resume_frame)
    added_codes = J(rows(label_codes), 1, .)
    n_added = 0
    for (i = 1; i <= rows(label_codes); i++) {
        if (!any(observed_codes :== label_codes[i])) {
            n_added++
            added_codes[n_added] = label_codes[i]
        }
    }
    if (n_added == 0) return
    added_codes = added_codes[|1\n_added|]
    n_obs = st_nobs()
    st_addobs(n_added)
    added_rows = (n_obs + 1)::(n_obs + n_added)
    st_store(added_rows, "code", added_codes)
    st_store(added_rows, "frequency", J(n_added, 1, 0))
    st_store(added_rows, "is_missing", added_codes :>= .)
}

void ddoc127_missinglabels(real colvector mapped_codes, string colvector mapped_labels)
{
    real colvector missing_rows, codes
    string colvector labels
    real scalar i, j
    missing_rows = selectindex(st_data(., "is_missing"))
    if (rows(missing_rows) == 0) return
    codes = st_data(missing_rows, "code")
    labels = st_sdata(missing_rows, "category_label")
    for (i = 1; i <= rows(codes); i++) {
        for (j = 1; j <= rows(mapped_codes); j++) {
            if (codes[i] == mapped_codes[j]) labels[i] = mapped_labels[j]
        }
    }
    st_sstore(missing_rows, "category_label", labels)
}

void ddoc127_unique(string scalar var_name, real scalar is_numeric)
{
    real colvector num_values
    string colvector str_values
    real scalar n_unique
    if (is_numeric) {
        num_values = st_data(., var_name)
        num_values = select(num_values, num_values :< .)
        n_unique = rows(uniqrows(num_values))
    }
    else {
        str_values = st_sdata(., var_name)
        str_values = select(str_values, str_values :!= "")
        n_unique = rows(uniqrows(str_values))
    }
    st_local("nu", strofreal(n_unique, "%18.0f"))
}

void ddoc127_unlabeled(string scalar var_name, string scalar label_name)
{
    real colvector num_values, label_codes
    string colvector label_text
    real scalar i, j, n_unlabeled
    num_values = st_data(., var_name)
    num_values = sort(select(num_values, num_values :< .), 1)
    st_vlload(label_name, label_codes, label_text)
    label_codes = sort(label_codes, 1)
    n_unlabeled = 0
    j = 1
    for (i = 1; i <= rows(num_values); i++) {
        while (j <= rows(label_codes)) {
            if (label_codes[j] >= num_values[i]) break
            j++
        }
        if (j > rows(label_codes)) n_unlabeled++
        else if (label_codes[j] != num_values[i]) n_unlabeled++
    }
    st_local("unl", strofreal(n_unlabeled, "%18.0f"))
}

void ddoc127_notes(string scalar var_name, string scalar note_frame,
    string scalar original_frame, string scalar resume_frame, real scalar highest_note)
{
    string colvector note_values
    string scalar note_value, key, doc_note
    real scalar i, native_count
    note_values = J(0, 1, "")
    stata("frame change " + original_frame)
    for (i = 1; i <= highest_note; i++) {
        key = var_name + "[note" + strtrim(strofreal(i, "%9.0f")) + "]"
        note_value = st_global(key)
        if (note_value != "") {
            note_values = note_values \ note_value
        }
    }
    native_count = rows(note_values)
    if (native_count > 0 & var_name != "_dta") {
        doc_note = st_global(var_name + "[doc_notes]")
        if (doc_note != "") {
            note_values = note_values \ doc_note
        }
    }
    stata("frame change " + resume_frame)
    if (rows(note_values) > 0) {
        stata("frame change " + note_frame)
        st_addobs(rows(note_values))
        st_sstore(., "note_text", note_values)
        stata("frame change " + resume_frame)
    }
    st_local("native_notes_present", strofreal(native_count > 0, "%1.0f"))
    st_local("nnotes", strofreal(rows(note_values), "%18.0f"))
}

void ddoc127_chars(string scalar var_name, string scalar doc_frame,
    string scalar original_frame, string scalar resume_frame, real scalar merge_doc_notes)
{
    string colvector keys, heads, collected_heads, collected_text
    string scalar content, item_number, current_heading
    real scalar i
    keys = ("question" \ "units" \ "universe" \ "source" \ "derivation" \ "notes")
    heads = ("Question" \ "Units" \ "Universe" \ "Source" \ "Derivation" \ "Notes")
    collected_heads = J(0, 1, "")
    collected_text = J(0, 1, "")
    stata("frame change " + original_frame)
    item_number = st_global(var_name + "[doc_itemnum]")
    for (i = 1; i <= rows(keys); i++) {
        content = st_global(var_name + "[doc_" + keys[i] + "]")
        current_heading = heads[i]
        if (keys[i] == "question") {
            if (content == "" & item_number != "") {
                content = item_number
                current_heading = "Item Number"
            }
            else if (content != "" & item_number != "") {
                content = item_number + " " + content
            }
        }
        if (keys[i] == "notes" & merge_doc_notes) {
            content = ""
        }
        if (content != "") {
            collected_heads = collected_heads \ current_heading
            collected_text = collected_text \ content
        }
    }
    stata("frame change " + resume_frame)
    if (rows(collected_heads) > 0) {
        stata("frame change " + doc_frame)
        st_addobs(rows(collected_heads))
        st_sstore(., "heading", collected_heads)
        st_sstore(., "char_text", collected_text)
        stata("frame change " + resume_frame)
    }
    st_local("ndocchars", strofreal(rows(collected_heads), "%18.0f"))
}

void ddoc127_contract(string scalar var_name, real scalar is_numeric)
{
    real colvector num_values, frequencies, category_codes, missing_flags
    string colvector str_values, category_strings
    real scalar i, j, n_obs, n_categories
    if (is_numeric) {
        num_values = sort(st_data(., var_name), 1)
        n_obs = rows(num_values)
    }
    else {
        str_values = sort(st_sdata(., var_name), 1)
        n_obs = rows(str_values)
    }
    n_categories = 1
    for (i = 2; i <= n_obs; i++) {
        if (is_numeric) {
            if (num_values[i] != num_values[i-1]) n_categories++
        }
        else {
            if (str_values[i] != str_values[i-1]) n_categories++
        }
    }
    frequencies = J(n_categories, 1, 0)
    category_codes = J(n_categories, 1, .)
    missing_flags = J(n_categories, 1, 0)
    category_strings = J(n_categories, 1, "")
    j = 0
    for (i = 1; i <= n_obs; i++) {
        if (i == 1) {
            j = j + 1
        }
        else if (is_numeric) {
            if (num_values[i] != num_values[i-1]) {
                j = j + 1
            }
        }
        else {
            if (str_values[i] != str_values[i-1]) {
                j = j + 1
            }
        }
        frequencies[j] = frequencies[j] + 1
        if (is_numeric) {
            category_codes[j] = num_values[i]
            missing_flags[j] = (num_values[i] >= .)
        }
        else {
            category_strings[j] = str_values[i]
            missing_flags[j] = (str_values[i] == "")
        }
    }
    frequencies = frequencies[|1\j|]
    category_codes = category_codes[|1\j|]
    missing_flags = missing_flags[|1\j|]
    category_strings = category_strings[|1\j|]
    stata("clear")
    (void) st_addvar("double", "code")
    (void) st_addvar("double", "frequency")
    (void) st_addvar("byte", "is_missing")
    (void) st_addvar("strL", "raw")
    st_addobs(j)
    st_store(., "code", category_codes)
    st_store(., "frequency", frequencies)
    st_store(., "is_missing", missing_flags)
    st_sstore(., "raw", category_strings)
}
end
