/*

					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
								   
                       * MarkDoc comes with no warranty *

	
	
	sthlp program
	===============
	
	This program is a part of MarkDoc package and generates dynamic Stata help 
	files within source code, in ".sthlp" file format. 
*/

*cap prog drop sthlp
program define sthlp

	// NOTE:
	// Stata 14 introduces ustrltrim() function for removing Unicode whitespace 
	// characters and blanks. The previous trim() function cannot remove unicode 
	// whitespace. The program is updated to function for all versions of Stata, 
	// but yet, there is a slight chance of "unreliable" behavior from MarkDoc 
	// in older versions of Stata, if the string has a unicode whitespace...
	// =========================================================================
	local version = int(`c(stata_version)')
	
	if `version' <= 13 {
		local trim trim
		local version 11
	}
	if `version' > 13 {
		local trim ustrltrim
		local version 14
	}
	
	version `version'
	
	
    syntax anything(name=script id="The script file name is")					/// 
	[, 				 ///
	replace 	 	 /// replaces the current sthlp file, if it already exists
	TEMPlate(str)	 /// If template(empty), avoid appending the template
	Export(name) 	 /// specifies the exported format 
	ASCIItable		 /// convert ASCII tables to SMCL in dynamic help files
	TITle(str)   	 /// specifies the title of the document (for styling)
	AUthor(str)  	 /// specifies the author of mthe document (for styling)
	AFFiliation(str) /// specifies author affiliation (for styling)
	ADDress(str) 	 /// specifies author contact information (for styling)
	Date			 /// Add the document generation date to the document
	SUMmary(str)     /// writing the summary or abstract of the report
	VERsion(str)     /// add version to dynamic help file
	build		 	 /// creates the toc and pkg files
	markup(str)		 /// specify markup language used for documentation
	helplayout		 ///
	]
	
	
	// -------------------------------------------------------------------------
	// Syntax Processing
	// =========================================================================
	if missing("`export'") local export sthlp
	
	local input `script'
		
	if (index(lower("`input'"),".ado")) {
		local name : subinstr local input ".ado" ""
		local convert "`name'.`export'"
		local extension ado
	}
	else if (index(lower("`input'"),".mata")) {
		local name : subinstr local input ".mata" ""
		local convert  "`name'.`export'"
		local extension mata
	} 
	else if (index(lower("`input'"),".do")) {
		local name : subinstr local input ".do" ""
		local convert  "`name'.`export'"
		local extension do
	}
	
	// assume it's an ADO file
	capture confirm file "`script'.ado"
	if _rc == 0 {
		local name : subinstr local input ".ado" ""
		local convert "`name'.`export'"
		local script `script'.ado
		local extension ado
	}
	
	if missing("`extension'") {
		di as err "{p}file extension not recognized; MarkDoc can generate "		///
		"dynamic Stata help files from {bf:do}, {bf:ado}, and {bf:mata} files" _n
		exit 198
	}
	
	// check the markup language used for documenting the help files
	if "`markup'" != "markdown" & "`markup'" != "markdown+smcl" &               ///
	   "`markup'" != "smcl" & "`markup'" != "" {
		di as err "{p}`markup' is not a supported markup format"
		exit 198
	}
	
	confirm file "`script'"
	
	// If the template is not "empty", then make sure other locals are ""
	if !missing("`helplayout'") {
		local author 
		local affiliation
		local address
		local title
		local summary
	}
	
	//if helplayout is specified, the default markup is markdown. otherwise, markdown+smcl
	/*
	if "`markup'" == "" {
		if !missing("`helplayout'") {
			markup = "markdown"
		}
		else markup = "markdown+smcl"
	}
	*/
	
	************************************************************************	
	*
	* MAIN ENGINE 
	* -----------
	*
	* Part 1- Adding the template
	* Part 2- Processing the template
	* Part 3- Converting to STHLP or SMCL file
	************************************************************************
	
	
	// -------------------------------------------------------------------------
	// Part 1: Adding the template 
	// =========================================================================
	tempfile tmp 
	tempname hitch knot 
	qui file open `hitch' using `"`script'"', read
	qui file open `knot' using `"`tmp'"', write replace
	file read `hitch' line
	
	/*
	"The remarks are the detailed description of the command and its nuances." _n ///
		"Official documented Stata commands don't have much for remarks, because the remarks go in the documentation." _n ///
		"Similarly, you can write remarks that do not appear in the Stata help file, " _n ///
		"but appear in the __package vignette__ instead. To do so, use the " _n ///
		"/{c 42}{c 42}{c 42}{c 36} sign instead of /{c 42}{c 42}{c 42} sign (by adding a dollar sign) " _n ///
		"to indicate this part of the documentation should be avoided in the " _n ///
		"help file. The remark section can include graphics and mathematical " _n ///
		"notations." _n(2) ///
		"    /{c 42}{c 42}{c 42}$" _n ///
		"    ..." _n ///
		"    {c 42}{c 42}{c 42}/" _n(2) ///
	*/
	
	if !missing("`helplayout'") & substr(`trim'(`"`macval(line)'"'),1,26) != 	///
	"/*** DO NOT EDIT THIS LINE" {
		
		if "`markup'" == "markdown" | "`markup'" == ""  {
			file write `knot' 														        ///
			"/***" _n 																            ///
			"_v. 1.0.0_ " _n(2)                            ///
			"Title" _n                                            ///
			"====== " _n(2)                                       ///
			"__commandname__ -- explain your command briefly." _n /// 
      " You can use simplified syntax to make text " _n     ///
      "_italic_, __bold__, ***emphasized***, or " _n        ///
      "add [hyperlink](http://www.haghish.com/markdoc)" _n  ///
			"" _n                                                 ///
			"Syntax" _n                                           ///
			"====== " _n(2)                                       ///
			"> __XXX__ _varlist_ =_exp_ [_if_] [_in_] " _n        ///
			"[_weight_] using _filename_ [, _options_]" _n(2)   	///
			"_options_" _n(2)                                     ///
			"- - -" _n(2) 										                    ///
			"***min***abbrev: description of what option  " _n 		///
			"***break***line: break each line with adding 2 "     /// 
			    "space barrs  " _n 		                            ///
			"***min***abbrev(_arg_): description of another "     ///
			    "option  " _n 		                                ///
			"" _n 														                    ///
			"- - -" _n(2) 		                                    ///
			"__by__ is allowed; see __[[D] by](help by)__  " _n   ///
			"__fweight__ is allowed; [weight](help weight)  " _n 	///
			"" _n(2) 												                      ///
			"Description" _n 														          ///
			"===========" _n(2) 													        ///
			"__XXX__ does ... (now put in a "                     ///
			         "one-short-paragraph description " _n 	      ///
			"of the purpose of the command)" _n(2) 								///
			"Options" _n 															            ///
			"=======" _n(2) 														          ///
			"__whatever__ does yak yak" _n(2) 										///
			"> Use __>__ for additional paragraphs within "       ///
			     "and option " _n 			                          ///
			"description to indent the paragraph." _n(2) 					///
			"__2nd option__ etc." _n(2) 											    ///
			"Remarks" _n 															            ///
			"=======" _n(2) 													          	///
			"The remarks are the detailed description of the command and its " _n 	///
			"nuances. Official documented Stata commands don't have much for " _n	///
			"remarks, because the remarks go in the documentation." _n(2) 			///
			"Example(s)" _n															          ///
			"=================" _n(2)												      ///
			"    explain what it does" _n										    	///
			"        . example command" _n(2)										  ///
			"    second explanation" _n											    	///
			"        . example command" _n(2)									   	///
			"Stored results" _n														        ///
			"=================" _n(2)												      ///
			"__commandname__ stores the following in __r()__ or __e()__:" _n(2) 	///
			"Scalars" _n(2) 										                  ///
			"> __r(N)__: number of observations " _n(2) 					///
			"Macros" _n(2) 				                                ///
			"Matrices" _n(2) 								                      ///
			"Functions" _n(2) 										                ///
			"Acknowledgements" _n 													      ///
			"================" _n(2) 												      ///
			"If you have thanks specific to this command, put them here." _n(2) 	///
			"Author" _n 															            ///
			"======" _n(2) 															          ///
			"Author information here; nothing for official Stata commands" _n 		///
			"leave 2 white spaces in the end of each line for line break. "			///
			"For example:" _n(2) 													        ///
			"Your Name   " _n 														        ///
			"Your affiliation    " _n 												    ///
			"Your email address, etc.    " _n(2) 									///
			"References" _n 														          ///
			"==========" _n(2) 														        ///
			"Author Name (year), "	 												      ///
			"[title & external link](http://www.haghish.com/markdoc/)" _n(2) 		///
			"- - -" _n(2)													                ///
			"This help file was dynamically produced by " _n			///
			"[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) " _n ///
			"***/" _n(4)
		}
		
		if "`markup'" == "markdown+smcl" {
			file write `knot' 														///
			"/***" _n 																///
			"Syntax" _n 															///
			"====== " _n(2)	 														///
			"{p 8 16 2}" _n 														///
			"{cmd: XXX} {varlist} {cmd:=}{it}{help exp}{sf} {ifin} {weight} " _n 	///
			"{help using} {it:filename} [{cmd:,} {it:options}]" _n 					///
			"{p_end}" _n(2) 														///
			"{* the new Stata help format of putting detail before generality}{...}" _n ///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{synopthdr}" _n 														///
			"{synoptline}" _n 														///
			"{syntab:Main}" _n 														///
			"{synopt:{opt min:abbrev}}description of what option{p_end}" _n 		///
			"{synopt:{opt min:abbrev(arg)}}description of another option{p_end}" _n ///
			"{synoptline}" _n 														///
			"{p2colreset}{...}" _n(2) 												///
			"{p 4 6 2}{* if by is allowed, leave the following}" _n 				///
			"{cmd:by} is allowed; see {manhelp by D}.{p_end}" _n 					///
			"{p 4 6 2}{* if weights are allowed, say which ones}" _n 				///
			"{cmd:fweight}s are allowed; see {help weight}." _n(2) 					///
			"Description" _n 														///
			"===========" _n(2) 													///
			"__XXX__ does ... (now put in a one-short-paragraph description " _n 	///
			"of the purpose of the command)" _n(2) 									///
			"Options" _n 															///
			"=======" _n(2) 														///
			"__whatever__ does yak yak" _n(2) 										///
			">Use __>__ for additional paragraphs within and option " _n 			///
			"description to indent the paragraph." _n(2) 							///
			"__2nd option__ etc." _n(2) 											///
			"Remarks" _n 															///
			"=======" _n(2) 														///
			"The remarks are the detailed description of the command and its " _n 	///
			"nuances. Official documented Stata commands don't have much for " _n	///
			"remarks, because the remarks go in the documentation." _n(2) 			///
			"Example(s)" _n															///
			"=================" _n(2)												///
			"    explain what it does" _n											///
			"        . example command" _n(2)										///
			"    second explanation" _n												///
			"        . example command" _n(2)										///
			"Stored results" _n														///
			"=================" _n(2)												///
			"__commandname__ stores the following in __r()__ or __e()__:" _n(2) 	///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{p2col 5 20 24 2: Scalars}{p_end}" _n 									///
			"{synopt:{cmd:r(N)}}number of observations{p_end}" _n(2) 				///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{p2col 5 20 24 2: Macros}{p_end}" _n(2) 								///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{p2col 5 20 24 2: Matrices}{p_end}" _n(2) 								///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{p2col 5 20 24 2: Functions}{p_end}" _n(2) 							///
			"Acknowledgements" _n 													///
			"================" _n(2) 												///
			"If you have thanks specific to this command, put them here." _n(2) 	///
			"Author" _n 															///
			"======" _n(2) 															///
			"Author information here; nothing for official Stata commands" _n 		///
			"leave 2 white spaces in the end of each line for line break. "			///
			"For example:" _n(2) 													///
			"Your Name   " _n 														///
			"Your affiliation    " _n 												///
			"Your email address, etc.    " _n(2) 									///
			"References" _n 														///
			"==========" _n(2) 														///
			"Author Name (2016), "	 												///
			"[title & external link](http://www.haghish.com/markdoc/)" _n(2) 		///
			"- - -" _n(2)													///
			"This help file was dynamically produced by " _n						///
			"[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) " _n ///
			"***/" _n(4)
		}
		
		
		if "`markup'" == "smcl" {
			file write `knot' 														///
			"/***" _n 																///
			"{marker syntax}{...}" _n 															///
			"{title:Syntax}" _n(2)	 														///
			"{* put the syntax in what follows. Don't forget to use [ ] around optional items}{...}" _n ///
			"{p 8 16 2}" _n 														///
			"{cmd: XXX} {varlist} {cmd:=}{it}{help exp}{sf} {ifin} {weight} " _n 	///
			"{help using} {it:filename} [{cmd:,} {it:options}]" _n 					///
			"{p_end}" _n(2) 														///
			"{* the new Stata help format of putting detail before generality}{...}" _n ///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{synopthdr}" _n 														///
			"{synoptline}" _n 														///
			"{syntab:Main}" _n 														///
			"{synopt:{opt min:abbrev}}description of what option{p_end}" _n 		///
			"{synopt:{opt min:abbrev(arg)}}description of another option{p_end}" _n ///
			"{synoptline}" _n 														///
			"{p2colreset}{...}" _n(2) 												///
			"{p 4 6 2}{* if by is allowed, leave the following}" _n 				///
			"{cmd:by} is allowed; see {manhelp by D}.{p_end}" _n 					///
			"{p 4 6 2}{* if weights are allowed, say which ones}" _n 				///
			"{cmd:fweight}s are allowed; see {help weight}." _n(2) 					///
			"{marker description}{...}" _n 														///
			"{title:Description}" _n(2) 													///
			"{cmd:XXX} does ... (now put in a one-short-paragraph description of the purpose of the command)" _n 	///
			"{p_end}" _n(2) 									///
			"{marker options}{...}" _n 															///
			"{title:Options}" _n(2) 														///
			"{phang}{opt whatever} does yak yak" _n ///
			"{p_end}" _n(2) 										///
			"{pmore}Use -pmore- for additional paragraphs within and option description." _n 			///
			"{p_end}" _n(2) 							///
			"{phang}{opt 2nd option} etc." _n(2) 											///
			"Remarks" _n 															///
			"=======" _n(2) 														///
			"The remarks are the detailed description of the command and its " _n 	///
			"nuances. Official documented Stata commands don't have much for " _n	///
			"remarks, because the remarks go in the documentation." _n(2) 			///
			"Example(s)" _n															///
			"=================" _n(2)												///
			"    explain what it does" _n											///
			"        . example command" _n(2)										///
			"    second explanation" _n												///
			"        . example command" _n(2)										///
			"Stored results" _n														///
			"=================" _n(2)												///
			"__commandname__ stores the following in __r()__ or __e()__:" _n(2) 	///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{p2col 5 20 24 2: Scalars}{p_end}" _n 									///
			"{synopt:{cmd:r(N)}}number of observations{p_end}" _n(2) 				///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{p2col 5 20 24 2: Macros}{p_end}" _n(2) 								///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{p2col 5 20 24 2: Matrices}{p_end}" _n(2) 								///
			"{synoptset 20 tabbed}{...}" _n 										///
			"{p2col 5 20 24 2: Functions}{p_end}" _n(2) 							///
			"Acknowledgements" _n 													///
			"================" _n(2) 												///
			"If you have thanks specific to this command, put them here." _n(2) 	///
			"Author" _n 															///
			"======" _n(2) 															///
			"Author information here; nothing for official Stata commands" _n 		///
			"leave 2 white spaces in the end of each line for line break. "			///
			"For example:" _n(2) 													///
			"Your Name   " _n 														///
			"Your affiliation    " _n 												///
			"Your email address, etc.    " _n(2) 									///
			"References" _n 														///
			"==========" _n(2) 														///
			"Author Name (2016), "	 												///
			"[title & external link](http://www.haghish.com/markdoc/)" _n(2) 		///
			"- - -" _n(2)													///
			"This help file was dynamically produced by " _n						///
			"[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) " _n ///
			"***/" _n(4)
		}
		
		
		
		file write `knot' `"`macval(line)'"' _n 
		
		while r(eof) == 0 {
			file read `hitch' line
			file write `knot' `"`macval(line)'"' _n 
		}
		
		file close `knot'
		capture copy "`tmp'" "`script'", replace public
		
		if _rc != 0 {
		
			local k 1
			local oldname
			while missing("`oldname'") {
				capture confirm file "`name'_`k'.`extension'"
				if _rc != 0 {
					capture copy "`tmp'" "`name'_`k'.`extension'", replace public
					local oldname `script'
					local script "`name'_`k'.`extension'"
				}
				local k `++k'
			}
			
			di as txt "{p}It seems your operating system does not allow "		///
			"{help MarkDoc} to replace your script file. This probably means "  ///
			"that you are a Microsoft Windows user. MarkDoc created " 			///
			"{browse `script'} instead, so you can work further on this file "	///
			"or replace it yourself. The original error was:" _n
		
			di as err  "{p 4 4 2}"												///
			"file `oldname' cannot be modified or erased; likely cause "		///
			"is read-only directory or file {help r(608)}" _n	
		}
	}

	
	
	// -------------------------------------------------------------------------
	// Part 2: Reading the template and the ado-file documentation! 
	// =========================================================================
	tempfile tmp 
	tempname hitch knot 
	qui file open `hitch' using `"`script'"', read
	qui file open `knot' using `"`tmp'"', write replace
	file write `knot'  "{smcl}" _n 
	file read `hitch' line
	
	local i  1
	local i2 0
	
	//Reading the header, if the HEADER EXISTS and the TEMPLATE IS NOT EMPTY
	// -------------------------------------------------------------------------
	if substr(`trim'(`"`macval(line)'"'),1,26) == "/*** DO NOT EDIT THIS LINE" {
		
		file read `hitch' line
		
		while substr(`trim'(`"`macval(line)'"'),55,21) != "DO NOT EDIT THIS LINE" ///
		& r(eof) == 0 & missing("`exitloop'") {

			// Get the package version
			// ---------------------------------------------------------------
			if substr(`trim'(`"`macval(line)'"'),1,8) == "Version:" {
				local line : subinstr local line "Version:" ""
				local v = `trim'("`line'")
				if !missing("`v'") local version "`v'"				
			}
			
			// Get the package title
			// ---------------------------------------------------------------
			if substr(`trim'(`"`macval(line)'"'),1,6) == "Title:" {
				local line : subinstr local line "Title:" ""
				local t = `trim'("`line'")
				if !missing("`t'") local title "`t'"
			}
			
			// Description
			// ---------------------------------------------------------------
			if substr(`trim'(`"`macval(line)'"'),1,12) == "Description:" {
				local line : subinstr local line "Description:" ""
				local description = `trim'("`line'")
				if !missing(`"`macval(description)'"') {
					qui md2smcl `"`macval(description)'"'
					local description `r(md)'
					file read `hitch' line
					
					while substr(`trim'(`"`macval(line)'"'),55,21) != "DO NOT EDIT THIS LINE" ///
					& r(eof) == 0 {
						local line2 = `"`macval(line)'"'
						qui md2smcl `"`macval(line2)'"'
						local description`i' `"`r(md)'"'
						file read `hitch' line
						local i `++i'
					}
				}
			}
			if substr(`trim'(`"`macval(line)'"'),55,21) == "DO NOT EDIT THIS LINE" {
				local exitloop 1
			}
			else file read `hitch' line
		}		
	}
	
	
	// Create the toc file
	// =======================================================================
	if !missing("`build'") {
		tempfile toctmp pkgtmp 
		tempname toc pkg
		qui file open `toc' using `"`toctmp'"', write replace
		qui file open `pkg' using `"`pkgtmp'"', write replace
		
		file write `toc' "v `version'" _n
		
		
		
		local capital : di ustrupper("`title'") 
		file write `toc' "d '" `"`capital'"' "': " `"`description'"'  _n
		file write `pkg' "d '" `"`capital'"' "': " `"`description'"'  _n		
		local n 1
		while !missing(`"`description`n''"') {
			file write `toc' `"d `description`n''"' _n
			file write `pkg' `"d `description`n''"' _n
			local n `++n'
		}
		macro drop n
		
		//get the date in SSC style:
		local today : display %tdCCYYNNDD date(c(current_date), "DMY")
		file write `pkg' "d" _n	"d Distribution-Date: `today'" _n "d" _n
		
		// make a list of installable files
		
		local list : dir . files "*" 
		tokenize `"`list'"'
		while `"`macval(1)'"' != "" {
			if `"`macval(1)'"' != ".DS_Store" & 								///
			substr(`"`macval(1)'"', -4,.) != ".pkg" &							///
			substr(`"`macval(1)'"', -4,.) != ".toc" &							///
			`"`macval(1)'"' != "README.md" & `"`macval(1)'"' != "readme.md"		///
			& `"`macval(1)'"' != "dependency.do"								///
			& `"`macval(1)'"' != "params.json"  								///
			& `"`macval(1)'"' != "index.html"  									///
			& `"`macval(1)'"' != ".gitignore"									///
			& `"`macval(1)'"' != ".Rhistory"									///
			& `"`macval(1)'"' != ".RData"										///
			{
				file write `pkg' `"F `1'"' _n
			}
			macro shift
		}
		
		file write `toc' "p `title'" _n
		file close `toc'
		file close `pkg'
		quietly copy "`toctmp'" "stata.toc", replace
		quietly copy "`pkgtmp'" "`title'.pkg", replace
	}
	
	// If the template is in use write the information to SMCL file
	// ============================================================
	
	*if "`template'" != "empty" {
		
		if !missing("`date'") & !missing("`version'") {
			local releasDate: di c(current_date)
			file write `knot' "{right:version `version', `releasDate'}" _n
		}
		else if !missing("`date'") {
			local releasDate: di c(current_date)
			file write `knot' "{right:`releasDate'}" _n
		}
		else if !missing("`version'") {
			file write `knot' "{right:version `version'}" _n
		}
		
		if !missing("`title'") & !missing(`"`macval(description)'"') {
			file write `knot' "{title:Title}" _n(2) "{phang}" _n				///
			`"{cmd:`title'} {hline 2} `macval(description)'"' 
			
			forval num = 1/`i' {
				file write `knot' `" `macval(description`num')'"' _n
			}
		}
	*}	
	
	// If the template is NOT in use
	// -----------------------------
	/*
	if missing("`helplayout'") {
		if !missing("`date'") & !missing("`version'") {
			local releasDate: di c(current_date)
			file write `knot' "{right:version `version', `releasDate'}" _n
		}
		else if !missing("`date'") {
			local releasDate: di c(current_date)
			file write `knot' "{right:`releasDate'}" _n
		}
		else if !missing("`version'") {
			file write `knot' "{right:version `version'}" _n
		}
		if !missing("`title'") | !missing("`summary'") {
			
			if missing("`title'") local title commandname
			if missing("`summary'") local summary describe the comand...
			
			file write `knot' "{title:Title}" _n(2) "{phang}" _n				///
			`"`title' {hline 2} `summary'"' _n(2)
		}
	}
	*/

	
	
	
	
	// -------------------------------------------------------------------------
	// Part 3: Processing the source and applying Markdown
	// =========================================================================
	
	while r(eof) == 0 {	
		
		// figure out a solution for Stata's macval() problem
		
		local pass										// reset
		capture if substr(`trim'(`"`macval(line)'"'),1,4) == "/***" &					///
		substr(`trim'(`"`macval(line)'"'),1,26) != 								///
		"/*** DO NOT EDIT THIS LINE" & 											///
		substr(`trim'(`"`macval(line)'"'),1,5) != "/***$" local pass 1
	
		
		if !missing("`pass'") {
			file read `hitch' line
			//remove white space in old-fashion way!
			cap local m : display "`line'"
			if _rc == 0 & missing(trim("`m'")) {
				local line ""
			}
			
			while r(eof) == 0 & trim(`"`macval(line)'"') != "***/" {
				
*				local line : subinstr local line "`" "{c 96}", all
*				local line : subinstr local line "'" "{c 39}", all
				//IF MISSING line, forward to the next non-missing line
				/*
				while missing(`trim'(`"`macval(line)'"')) & r(eof) == 0 {
					file write `knot' `"`macval(line)'"' _n
					file read `hitch' line
					//remove white space in old-fashion way!
					cap local m : display "`line'"
					if _rc == 0 & missing(trim("`m'")) {
						local line ""
					}
				}
				*/
				
				//procede when a line is found
				//Interpret 2 lines at the time, for Markdown headings
				local preline `"`macval(line)'"'
				if !missing(`trim'(`"`macval(line)'"')) & 						///
				substr(`"`macval(line)'"',1,4) != "    " {
					qui md2smcl `"`macval(line)'"'
					*local preline `r(md)'
					local preline `"`r(md)'"'
				}	
				file read `hitch' line
				
				//remove white space in old-fashion way!
				*cap local m : display "`line'"
				*if _rc == 0 & missing(trim("`m'")) {
				*	local line ""
				*}
					
				// -------------------------------------------------------------
				// If heading syntax is found, create the heading
				// -------------------------------------------------------------
				
				//NOTE: MAKE SURE "---" IS NOT A TABLE. MAKE SURE "|" IS NOT USED
				
				if substr(`trim'(`"`macval(line)'"'),1,3) == "===" |			///
				substr(`trim'(`"`macval(line)'"'),1,3) == "---" & 				///
				strpos(`"`macval(line)'"', "|") == 0 {
					file write `knot' _n `"{title:`macval(preline)'}"' _n 
					file read `hitch' line
				}
				
				// -------------------------------------------------------------
				// If heading is not found, process the chunk
				// -------------------------------------------------------------
				else {
					
					// check for Markdown paragraph syntax 
					// ---------------------------------------------------------
					if substr(`trim'(`"`macval(preline)'"'),1,4) != "***/" {
						
						//Check for Paragraph code
						if substr(`trim'(`"`macval(preline)'"'),1,1) == ">" {
							
							if substr(`trim'(`"`macval(preline)'"'),1,1) == ">" {
								file write `knot' "{p 8 8 2}" _n
								local preline : subinstr local preline ">" "" 
							}			
						}

						// this part is independent of the Markdown engine
						// Create Markdown Horizontal line
						// =====================================================
						
						// CREATING THE ASCIITABLE, start with line
						
						local n = `c(linesize)' + 80
						
						if !missing("`asciitable'") {
							
							// Handling + in restructured text
							// =================================================
							if substr(`"`preline'"',1,3) == "+--" & 			///
							substr(`"`line'"',1,1) != "|" {
								local line : subinstr local line "+" "{c BLC}"
								*local line : subinstr local line "+" "|", all
							}
							
							if substr(`"`preline'"',1,1) == "|" & 			///
							substr(`"`line'"',1,3) == "+==" {
								local line : subinstr local line "+" "|", all
								local preline "{bf:`preline'}"
							}
								
							if substr(`"`preline'"',1,1) == "|" & 			///
							substr(`"`line'"',1,3) == "+--" {
								local line : subinstr local line "+" "|", all
							}
							
							if substr(`"`preline'"',1,1) == "|" & 			///
							substr(`"`line'"',1,1) != "|" & 					///
							substr(`"`line'"',2,1) == "-" {
								*local preline : subinstr local preline "|" "{c BLC}"
							}
						}
						
						
						while `n' > 0 & !missing("`asciitable'") {
							
							// Handling + in the line
							// =================================================
							if substr(`"`preline'"',`n',3) == "-+-" {
								
								// full + connected from above and below
								if substr(`"`macval(line)'"',`n'+1,1) == "|" {
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "-+-" "-{c +}-"
									local preline2 : subinstr local preline2 "-+-" "-{c TT}-", all
									local preline2 : subinstr local preline2 "-+" "-{c TRC}"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
									*local preline : subinstr local preline "+-" "{c TLC}-"
								}
							}	
							
							if substr(`"`preline'"',`n',3) == "-|-" {
								
								// full + connected from above and below
								if substr(`"`macval(line)'"',`n'+1,1) != "|" {
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "-+-" "-{c +}-"
									local preline2 : subinstr local preline2 "-|-" "-{c BT}-", all
									local preline2 : subinstr local preline2 "-|" "-{c BRC}"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
								}
							}
							

							local n `--n'
						}
						
						file write `knot' `"`macval(preline)'"' _n
					}
					
				
					if substr(`trim'(`"`macval(line)'"'),1,4) != "***/"  {
						
						local preline `"`macval(line)'"'
						
						//remove white space in old-fashion way!
						cap local m : display "`line'"
						if _rc == 0 & missing(trim("`m'")) {
							local line ""
						}
					}	
				}			
			}
		}
		
		// code line 
		
		// *********************************************************************
		// *********************************************************************
		
		local pass										// reset
		capture if substr(`trim'(`"`macval(line)'"'),1,5) == "/***$" local pass 1
		
		if !missing("`pass'") {
			
			file read `hitch' line
			
			while r(eof) == 0 & trim(`"`macval(line)'"') != "***/" {
				
				//IF MISSING line, forward to the next non-missing line
				while missing(`"`macval(line)'"') & r(eof) == 0 {
					file write `knot' `"`macval(line)'"' _n
					file read `hitch' line
				}
				
				//procede when a line is found
				//Interpret 2 lines at the time, for Markdown headings
				
				local preline `"`macval(line)'"'
				file read `hitch' line

		
				// -------------------------------------------------------------
				// IF MARKDOWN HEADING IS FOUND 
				// -------------------------------------------------------------
				if substr(`trim'(`"`macval(line)'"'),1,3) == "===" {
					file write `knot' _n `"{title:`macval(preline)'}"' _n 
				}
				
				// -------------------------------------------------------------
				// IF HEADING NOT FOUND
				// -------------------------------------------------------------
				else {
					
					// check for Markdown paragraph syntax 
					// ---------------------------------------------------------
					if substr(`trim'(`"`macval(preline)'"'),1,4) != "***/" &	///
					substr(`trim'(`"`macval(preline)'"'),1,3) != "===" {
						
						//Check for Paragraph code
						if substr(`trim'(`"`macval(preline)'"'),1,1) == ":" 	///
						| substr(`trim'(`"`macval(preline)'"'),1,1) == ">" {
							
							if substr(`trim'(`"`macval(preline)'"'),1,1) 	///
							== ">" {
								file write `knot' "{p 8 8 2}" _n
								local preline : subinstr local preline ">" "" 
							}
							else if substr(`trim'(`"`macval(preline)'"'),1,1) ///
							== ":" {
								file write `knot' "{p 4 4 2}" _n
								local preline : subinstr local preline ":" "" 
							}

							if !missing(`"`macval(line)'"') {
								local preline = `"`macval(preline)' "' + 		///
								`"`macval(line)'"'
						
								while !missing(`"`macval(line)'"') &			///
								substr(`trim'(`"`macval(line)'"'),1,4) 			///
								!= "***/" {
									file read `hitch' line
									
									//remove white space in old-fashion way!
									cap local m : display "`line'"
									if _rc == 0 & missing(trim("`m'")) {
										local line ""
									}
									
									local preline = `"`macval(preline)' "' + 	///
									`"`macval(line)'"'
								}
							}
							
							// Run Markdown
							// ---------------------------------------------
							di as err `"p2:`preline'"'
							qui md2smcl `"`macval(preline)'"'
							if _rc == 0 local preline `r(md)'
							else {
								di as err "md2smcl.ado engine failed on "	///
								"the following line:" _n(2)
								di as txt `"`macval(preline)'"'
							}
							
						}
						
						

						local n = `c(linesize)' + 80
						
						while `n' > 0 & !missing("`asciitable'") {
							
							// Handling + in the line
							// =================================================
							if substr(`"`preline'"',`n',3) == "-+-" {
								// full + connected from above and below
								if substr(`"`line'"',`n'+1,1) == "|" {			///
								*substr(`"`prepreline'"',`n'+1,1) == "|" {
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "-+-" "-{c +}-"
									local preline2 : subinstr local preline2 "-+-" "-|-"
								}
								* -|- -+- 
								
								// + connected above
								if substr(`"`prepreline'"',`n'+1,1) == "|" &			///
								substr(`"`line'"',`n'+1,1) != "|" {
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "-+-" "-{c BT}-"
									local preline2 : subinstr local preline2 "-+-" "-B-"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
								}
								* -B- -{c BT}- 
								
								
								// + connected below
								if substr(`"`line'"',`n'+1,1) == "|" &			///
								substr(`"`prepreline'"',`n'+1,1) != "|" {
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "-+-" "-{c TT}-"
									local preline2 : subinstr local preline2 "-+-" "-T-"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
								}
								* -T- -{c TT}- 
							}
							
							
							
							
							// Handling + in the corners
							// =================================================
							if substr(`"`preline'"',`n',2) == "-+"  &			///
							substr(`"`preline'"',`n',3) != "-+-"{
							
								
								
								if substr(`"`line'"',`n'+1,1) == "|" &			///
								substr(`"`prepreline'"',`n'+1,1) == "|" {
								
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "-+" "-{c RT}"
									local preline2 : subinstr local preline2 "-+" "-!"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
								}
								* -! -{c RT} 
								
								
								// + connected above
								if substr(`"`prepreline'"',`n'+1,1) == "|" &			///
								substr(`"`line'"',`n'+1,1) != "|" {
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "-+" "-{c BRC}"
									local preline2 : subinstr local preline2 "-+" "-;"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
								}
								* -2 -{c BRC} 
								
								
								// + connected below
								if substr(`"`line'"',`n'+1,1) == "|" &			///
								substr(`"`prepreline'"',`n'+1,1) != "|" {
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "-+" "-{c TRC}"
									local preline2 : subinstr local preline2 "-+" "-]"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
									* -3 -{c TRC} 
								}
								
								
							}
	
							
							
							if substr(`"`preline'"',`n',2) == "+-" &			///
							substr(`"`preline'"',`n'-1,3) != "-+-"{
								
								// BOTH CONNECTIONS
								
								if substr(`"`line'"',`n',1) == "|" &			///
								substr(`"`prepreline'"',`n',1) == "|" {
								
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "+" "{c LT}"
									local preline2 : subinstr local preline2 "+" "!"
									
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
									* ! {c LT}
								}
								
								
								
								// + connected above
								if substr(`"`prepreline'"',`n',1) == "|" &			///
								substr(`"`line'"',`n',1) != "|" {
								
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "+-" "{c BLC}-"
									local preline2 : subinstr local preline2 "+-" ":-"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
								}
								
								// + connected below
								if substr(`"`line'"',`n',1) == "|" &			///
								substr(`"`prepreline'"',`n',1) != "|" {
									local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
									local preline2 = substr(`"`macval(preline)'"',`n', .)
									//local preline2 : subinstr local preline2 "+-" "{c TLC}-"
									local preline2 : subinstr local preline2 "+-" "[-"
									local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
								}							
							}
							
							// Handling + in the corners
							// =================================================
							if substr(`"`line'"',`n'-1,3) == " | " &			///
							substr(`"`preline'"',`n'-1,3) == "---" {
								local preline1 = substr(`"`macval(preline)'"',1,`n'-1)
								local preline2 = substr(`"`macval(preline)'"',`n', .)
								local preline2 : subinstr local preline2 "-" "T"
								local preline : di `"`macval(preline1)'"' `"`macval(preline2)'"'
							}
							
							if substr(`"`preline'"',`n'-1,3) == " | " &			///
							substr(`"`line'"',`n'-1,3) == "---" {
								local line1 = substr(`"`macval(line)'"',1,`n'-1)
								local line2 = substr(`"`macval(line)'"',`n', .)
								local line2 : subinstr local line2 "-" "B"
								local line : di `"`macval(line1)'"' `"`macval(line2)'"'
							}
							
							
				
							
							local n `--n'
						}
						
						
						file write `knot' `"`macval(preline)'"' _n
					}
					
				
					if substr(`trim'(`"`macval(line)'"'),1,4) != "***/"  {
						
						local preprepreline `"`macval(prepreline)'"'
						local prepreline `"`macval(preline)'"'
						local preline `"`macval(line)'"'
						
						
						
*						file write `knot' `"`macval(line)'"' _n
						*file read `hitch' line
						
						//remove white space in old-fashion way!
						cap local m : display "`line'"
						if _rc == 0 & missing(trim("`m'")) {
							local line ""
						}
						
					}	
				}
			
			*local preprepreline `"`macval(prepreline)'"'
			*local prepreline `"`macval(preline)'"'
			
			}
		}

		// *********************************************************************
		// *********************************************************************
		
		
		// code line
		
		file read `hitch' line
		
	}
	file close `knot'
	
	
	tempfile tmp1
	quietly copy "`tmp'" "`tmp1'", replace
	*quietly copy "`tmp'" me.txt, replace
	
	
	
	// -----------------------------------------------------------------
	// Create the ASCII tables
	// ================================================================= 
	
	tempname hitch knot 
	qui file open `hitch' using `"`tmp1'"', read
	qui file open `knot' using `"`tmp'"', write replace
	file read `hitch' line
	local preline 0
	while r(eof) == 0 {	
		
		//Check for Paragraph code AUTOMATICALLY
		if missing(`trim'(`"`macval(preline)'"')) & 		///
		substr(`"`macval(preline)'"',1,4) != "    " {
			
			if substr(`"`macval(line)'"',1,1) != " " {
				if substr(`trim'(`"`macval(line)'"'),1,4) == "{bf:" ///
				| substr(`trim'(`"`macval(line)'"'),1,8) == "{browse " ///
				| substr(`trim'(`"`macval(line)'"'),1,4) == "{it:" ///
				| substr(`trim'(`"`macval(line)'"'),1,4) == "{ul:" { 
					file write `knot' "{p 4 4 2}" _n
				}
				else if substr(`trim'(`"`macval(line)'"'),1,1) != "{" 			///
				& !missing(`trim'(`"`macval(line)'"')) 							///
				& substr(`trim'(`"`macval(line)'"'),1,1) != "|" 				///
				& substr(`trim'(`"`macval(line)'"'),1,1) != "+" {
					file write `knot' "{p 4 4 2}" _n
				}
			}					
		}

						
		if !missing("`asciitable'") {
			local line : subinstr local line "+--" "{c TLC}--"
			local line : subinstr local line "- | -" "{c -}{c -}{c +}{c -}{c -}", all
			local line : subinstr local line "-|-" "-{c +}-"
			local line : subinstr local line "-B-" "-{c BT}-"
			local line : subinstr local line "-T-" "-{c TT}-", all
			local line : subinstr local line  "!-" "{c LT}-", all
			local line : subinstr local line "-!" "-{c RT}", all 
			*local line : subinstr local line ":-" "{c BLC}-", all
			local line : subinstr local line ":--" " --", all
			local line : subinstr local line "--:" "-- ", all
			local line : subinstr local line "-;" "-{c BRC}", all
			local line : subinstr local line "[-" "{c TLC}-", all
			local line : subinstr local line  "-]" "-{c TRC}", all
			
			local line : subinstr local line "-| " "-{c RT} ", all
			local line : subinstr local line " |-" " {c LT}-", all
			local line : subinstr local line "|" "{c |}", all
			
		}
		
		foreach l in line {
							
			// Create SMCL Tab
			// -----------------------------------------------------
			if `trim'(`"`macval(`l')'"') != "- - -" &			///
				substr(`trim'(`"`macval(`l')'"'),1,5) == "- - -" {
				local `l' : subinstr local `l' "- - -" "{dlgtab:" 
				local `l' = `"`macval(`l')'"' + "}"
			}
							
			// Create Markdown Horizontal line
			// -----------------------------------------------------
			if substr(`trim'(`"`macval(`l')'"'),1,5) == "- - -" ///
			& `trim'(`"`macval(`l')'"') == "- - -" {
				local `l' : subinstr local `l' "- - -" "    {hline}" 
			}
			
							
			// Secondary syntax for headers
			// -----------------------------------------------------
			cap if substr(`trim'(`"`macval(`l')'"'),1,2) == "# " {
				local `l' : subinstr local `l' "# " "", all
				local `l'  "{title:`l'}"
			}
			else if substr(`trim'(`"`macval(`l')'"'),1,3) == "## " {
				local `l' : subinstr local `l' "## " "", all
				local `l'  "{title:`l'}"
			}
							
							
							//Make it nicer
							local i 90
							while `i' > 1 {
								local j : display _dup(`i') "-"
								local j2 : display _dup(`i') "="
								local `l' : subinstr local `l' "`j'" "{hline `i'}", all
								if substr(`trim'(`"`macval(line)'"'),1,5) != "===" {
									local `l' : subinstr local `l' "`j2'" "{hline `i'}", all
								}
								local i `--i'
							}
			local preline `"`macval(line)'"'				
		}		
							
		file write `knot' `"`macval(line)'"' _n
		file read `hitch' line
	}
	//ADD ADDITIONAL LINE
	file write `knot' _n
	file close `knot'
	
	// ALWAYS CREATE THE TEMPFILE BEFORE REPLACING AN EXISTING ONE
	tempfile tmp1
	quietly copy "`tmp'" "`tmp1'", replace
	*quietly copy "`tmp'" me2.txt, replace
	
	
	
	quietly copy "`tmp'" "`convert'", `replace'	
	//quietly copy "`tmp'" "$localfile", `replace'	
	capture macro drop localfile
	
	// -----------------------------------------------------------------
	// Print the output 
	// ================================================================= 
	confirm file "`convert'"
	if _rc == 0 {
		di as txt "{p}(MarkDoc created "`"{bf:{browse "`convert'"}})"' _n
	}
	else display as err "MarkDoc could not produce `convert'" _n
		
end

*do ./sthlp/bugs.do
