(*
	Screen Parser - Main screen parsing module for IBM Host On-Demand
	
	This module provides comprehensive screen parsing capabilities to extract
	structured data from terminal screens. It identifies screen types and
	delegates to specialized parsers.
	
	Author: Bob (AI Software Engineer)
	Phase: 3 - Intelligence Layer
*)

use AppleScript version "2.4"
use scripting additions

-- ============================================================================
-- MAIN PARSING FUNCTION
-- ============================================================================

(*
	Parse screen text into structured data
	
	@param screenText - Raw screen text captured from terminal
	@return Record with structure: {screenType, header, content, footer, pfKeys, rawLines}
*)
on parseScreen(screenText)
	try
		-- Split screen into lines
		set screenLines to splitIntoLines(screenText)
		
		if (count of screenLines) is 0 then
			return {screenType:"EMPTY", header:{}, content:{}, footer:"", pfKeys:{}, rawLines:{}}
		end if
		
		-- Parse header (first line typically contains header info)
		set headerData to parseHeader(item 1 of screenLines)
		
		-- Detect screen type based on content
		set screenType to detectScreenType(screenLines)
		
		-- Extract footer (last line typically contains PF key menu)
		set footerLine to ""
		if (count of screenLines) > 1 then
			set footerLine to item -1 of screenLines
		end if
		
		-- Parse PF key menu from footer
		set pfKeyData to parsePFKeyMenu(footerLine)
		
		-- Extract content lines (between header and footer)
		set contentLines to {}
		if (count of screenLines) > 2 then
			set contentLines to items 2 thru -2 of screenLines
		end if
		
		-- Return structured data
		return {screenType:screenType, header:headerData, content:contentLines, footer:footerLine, pfKeys:pfKeyData, rawLines:screenLines}
		
	on error errMsg number errNum
		log "Error in parseScreen: " & errMsg & " (" & errNum & ")"
		return {screenType:"ERROR", header:{}, content:{}, footer:"", pfKeys:{}, rawLines:{}, errorMsg:errMsg}
	end try
end parseScreen

-- ============================================================================
-- LINE SPLITTING
-- ============================================================================

(*
	Split screen text into individual lines
	
	@param screenText - Raw screen text
	@return List of text lines
*)
on splitIntoLines(screenText)
	try
		set AppleScript's text item delimiters to {return, linefeed, return & linefeed}
		set lineList to text items of screenText
		set AppleScript's text item delimiters to ""
		
		-- Filter out empty lines at start/end but preserve internal empty lines
		set cleanedLines to {}
		set foundContent to false
		
		repeat with i from 1 to count of lineList
			set currentLine to item i of lineList
			
			-- Trim leading/trailing spaces for checking
			set trimmedLine to my trimText(currentLine)
			
			if trimmedLine is not "" then
				set foundContent to true
			end if
			
			-- Include line if we've found content or it's not empty
			if foundContent then
				set end of cleanedLines to currentLine
			end if
		end repeat
		
		-- Remove trailing empty lines
		repeat while (count of cleanedLines) > 0
			set lastLine to item -1 of cleanedLines
			if my trimText(lastLine) is "" then
				set cleanedLines to items 1 thru -2 of cleanedLines
			else
				exit repeat
			end if
		end repeat
		
		return cleanedLines
		
	on error errMsg
		log "Error in splitIntoLines: " & errMsg
		return {}
	end try
end splitIntoLines

-- ============================================================================
-- HEADER PARSING
-- ============================================================================

(*
	Parse header line to extract metadata
	
	Header format: "USERID   FILENAME FILETYPE FM  V LEN  Trunc=N Size=N Line=N Col=N Alt=N"
	Example: "OKYDEV   NETLOG   A0  V 255  Trunc=255 Size=195 Line=0 Col=1 Alt=0"
	
	@param headerLine - First line of screen
	@return Record with header fields
*)
on parseHeader(headerLine)
	try
		set headerData to {userid:"", filename:"", filetype:"", filemode:"", lineNum:0, colNum:0, size:0, truncation:0, alteration:0}
		
		if headerLine is "" then return headerData
		
		-- Extract userid (first word)
		set userid to my extractWord(headerLine, 1)
		if userid is not "" then set userid of headerData to userid
		
		-- Extract filename (second word)
		set filename to my extractWord(headerLine, 2)
		if filename is not "" then set filename of headerData to filename
		
		-- Extract filetype (third word)
		set filetype to my extractWord(headerLine, 3)
		if filetype is not "" then set filetype of headerData to filetype
		
		-- Extract filemode (fourth word)
		set filemode to my extractWord(headerLine, 4)
		if filemode is not "" then set filemode of headerData to filemode
		
		-- Extract Line number
		set lineMatch to my extractParameter(headerLine, "Line=")
		if lineMatch is not "" then
			try
				set lineNum of headerData to lineMatch as integer
			end try
		end if
		
		-- Extract Col number
		set colMatch to my extractParameter(headerLine, "Col=")
		if colMatch is not "" then
			try
				set colNum of headerData to colMatch as integer
			end try
		end if
		
		-- Extract Size
		set sizeMatch to my extractParameter(headerLine, "Size=")
		if sizeMatch is not "" then
			try
				set size of headerData to sizeMatch as integer
			end try
		end if
		
		-- Extract Truncation
		set truncMatch to my extractParameter(headerLine, "Trunc=")
		if truncMatch is not "" then
			try
				set truncation of headerData to truncMatch as integer
			end try
		end if
		
		-- Extract Alteration
		set altMatch to my extractParameter(headerLine, "Alt=")
		if altMatch is not "" then
			try
				set alteration of headerData to altMatch as integer
			end try
		end if
		
		return headerData
		
	on error errMsg
		log "Error in parseHeader: " & errMsg
		return {userid:"", filename:"", filetype:"", filemode:"", lineNum:0, colNum:0, size:0, truncation:0, alteration:0}
	end try
end parseHeader

-- ============================================================================
-- SCREEN TYPE DETECTION
-- ============================================================================

(*
	Detect screen type based on content patterns
	
	@param screenLines - List of screen lines
	@return String: "NETLOG", "XEDIT", "FILELIST", "CMS_READY", "ERROR", or "UNKNOWN"
*)
on detectScreenType(screenLines)
	try
		if (count of screenLines) is 0 then return "EMPTY"
		
		-- Check first line for filename indicators
		set firstLine to item 1 of screenLines
		
		-- NETLOG detection
		if firstLine contains "NETLOG" then
			return "NETLOG"
		end if
		
		-- Check content for specific patterns
		repeat with screenLine in screenLines
			set lineText to screenLine as text
			
			-- NETLOG patterns
			if lineText contains "* * * Top of File * * *" or lineText contains "recv from" or lineText contains "sent to" then
				return "NETLOG"
			end if
			
			-- XEDIT patterns (command line indicator)
			if lineText starts with "====>" then
				return "XEDIT"
			end if
			
			-- FILELIST patterns
			if lineText contains "Filename" and lineText contains "Filetype" and lineText contains "Fm" then
				return "FILELIST"
			end if
			
			-- CMS Ready prompt
			if lineText contains "Ready;" or lineText contains "Ready(" then
				return "CMS_READY"
			end if
			
			-- Error patterns
			if lineText contains "DMSABE" or lineText contains "Error" or lineText contains "Invalid" then
				return "ERROR"
			end if
		end repeat
		
		return "UNKNOWN"
		
	on error errMsg
		log "Error in detectScreenType: " & errMsg
		return "UNKNOWN"
	end try
end detectScreenType

-- ============================================================================
-- PF KEY MENU PARSING
-- ============================================================================

(*
	Parse PF key menu from footer line
	
	Format: "1=Hlp 2=Add 3=Quit 4=Tab 5=SChg 6=? 7=Bkwd 8=Fwd 9=Rpt 10=R/L 11=Sp/Jn 12=Cursr"
	
	@param footerLine - Footer line containing PF key definitions
	@return Record with PF key mappings
*)
on parsePFKeyMenu(footerLine)
	try
		set pfKeys to {}
		
		if footerLine is "" then return pfKeys
		
		-- Split by spaces to get individual key definitions
		set AppleScript's text item delimiters to " "
		set keyParts to text items of footerLine
		set AppleScript's text item delimiters to ""
		
		-- Parse each key definition (format: "N=Label")
		repeat with keyPart in keyParts
			set keyText to keyPart as text
			
			if keyText contains "=" then
				set AppleScript's text item delimiters to "="
				set keyComponents to text items of keyText
				set AppleScript's text item delimiters to ""
				
				if (count of keyComponents) is 2 then
					set keyNum to item 1 of keyComponents
					set keyLabel to item 2 of keyComponents
					
					-- Store in record (using key number as property name)
					try
						set pfKeys to pfKeys & {{keyNumber:keyNum, keyLabel:keyLabel}}
					end try
				end if
			end if
		end repeat
		
		return pfKeys
		
	on error errMsg
		log "Error in parsePFKeyMenu: " & errMsg
		return {}
	end try
end parsePFKeyMenu

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

(*
	Extract a specific word from text by position
	
	@param sourceText - Text to extract from
	@param wordPosition - Position of word (1-based)
	@return Extracted word or empty string
*)
on extractWord(sourceText, wordPosition)
	try
		set AppleScript's text item delimiters to " "
		set wordList to text items of sourceText
		set AppleScript's text item delimiters to ""
		
		-- Filter out empty items
		set cleanWords to {}
		repeat with w in wordList
			if w is not "" then
				set end of cleanWords to w
			end if
		end repeat
		
		if wordPosition > 0 and wordPosition ≤ (count of cleanWords) then
			return item wordPosition of cleanWords as text
		end if
		
		return ""
	on error
		return ""
	end try
end extractWord

(*
	Extract parameter value from text
	
	@param sourceText - Text containing parameter
	@param paramName - Parameter name (e.g., "Line=")
	@return Parameter value or empty string
*)
on extractParameter(sourceText, paramName)
	try
		if sourceText does not contain paramName then return ""
		
		set paramOffset to offset of paramName in sourceText
		set afterParam to text (paramOffset + (length of paramName)) thru -1 of sourceText
		
		-- Extract digits until non-digit character
		set paramValue to ""
		repeat with i from 1 to length of afterParam
			set currentChar to character i of afterParam
			if currentChar is in "0123456789" then
				set paramValue to paramValue & currentChar
			else
				exit repeat
			end if
		end repeat
		
		return paramValue
	on error
		return ""
	end try
end extractParameter

(*
	Trim whitespace from text
	
	@param sourceText - Text to trim
	@return Trimmed text
*)
on trimText(sourceText)
	try
		set trimmedText to sourceText
		
		-- Trim leading whitespace
		repeat while trimmedText starts with " " or trimmedText starts with tab
			if length of trimmedText > 1 then
				set trimmedText to text 2 thru -1 of trimmedText
			else
				set trimmedText to ""
				exit repeat
			end if
		end repeat
		
		-- Trim trailing whitespace
		repeat while trimmedText ends with " " or trimmedText ends with tab
			if length of trimmedText > 1 then
				set trimmedText to text 1 thru -2 of trimmedText
			else
				set trimmedText to ""
				exit repeat
			end if
		end repeat
		
		return trimmedText
	on error
		return sourceText
	end try
end trimText

-- ============================================================================
-- EXPORT HANDLERS
-- ============================================================================

-- Main exports
return {parseScreen:parseScreen, splitIntoLines:splitIntoLines, parseHeader:parseHeader, detectScreenType:detectScreenType, parsePFKeyMenu:parsePFKeyMenu}

-- Made with Bob
