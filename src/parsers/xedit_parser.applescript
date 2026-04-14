(*
	XEDIT Parser - Specialized parser for IBM CMS XEDIT editor screens
	
	This module parses XEDIT editor screens which display file content with
	line numbers, command line, and editing status. It extracts structured
	data including line content, current position, and modification state.
	
	Example XEDIT format:
	    USERID   FILENAME FILETYPE FM  V LEN  Trunc=N Size=N Line=N Col=N Alt=N
	    00001 First line of content
	    00002 Second line of content
	    ====> (command line)
	    1=Hlp 2=Add 3=Quit...
	
	Author: Bob (AI Software Engineer)
	Phase: 3 - Intelligence Layer
*)

use AppleScript version "2.4"
use scripting additions

-- ============================================================================
-- MAIN XEDIT PARSING FUNCTION
-- ============================================================================

(*
	Parse XEDIT screen content into structured data
	
	@param screenLines - List of screen lines from XEDIT display
	@return Record: {lines, lineCount, currentLine, commandLine, modified, topOfFile, bottomOfFile}
*)
on parseXeditContent(screenLines)
	try
		set xeditData to {lines:{}, lineCount:0, currentLine:0, commandLine:"", modified:false, topOfFile:false, bottomOfFile:false}
		set parsedLines to {}
		set cmdLine to ""
		
		if (count of screenLines) is 0 then return xeditData
		
		-- Parse each line
		repeat with screenLine in screenLines
			set lineText to screenLine as text
			set trimmedLine to my trimText(lineText)
			
			-- Check for special markers
			if trimmedLine contains "* * * Top of File * * *" then
				set topOfFile of xeditData to true
			else if trimmedLine contains "* * * Bottom of File * * *" or trimmedLine contains "* * * End of File * * *" then
				set bottomOfFile of xeditData to true
			else if trimmedLine starts with "====>" then
				-- Command line
				set cmdLine to text 6 thru -1 of trimmedLine
			else if trimmedLine starts with "====" then
				-- Command line without input
				set cmdLine to ""
			else if trimmedLine is "" then
				-- Empty line, might be content
				set lineData to {lineNum:missing value, content:"", isBlank:true}
				set end of parsedLines to lineData
			else
				-- Try to parse as XEDIT line
				set lineData to parseXeditLine(lineText)
				
				if lineData is not missing value then
					set end of parsedLines to lineData
				end if
			end if
		end repeat
		
		-- Set results
		set lines of xeditData to parsedLines
		set lineCount of xeditData to count of parsedLines
		set commandLine of xeditData to cmdLine
		
		-- Determine current line (usually the line before command line or last line)
		if lineCount of xeditData > 0 then
			try
				set lastLine to item -1 of parsedLines
				if lineNum of lastLine is not missing value then
					set currentLine of xeditData to lineNum of lastLine
				end if
			end try
		end if
		
		return xeditData
		
	on error errMsg number errNum
		log "Error in parseXeditContent: " & errMsg & " (" & errNum & ")"
		return {lines:{}, lineCount:0, currentLine:0, commandLine:"", modified:false, topOfFile:false, bottomOfFile:false, errorMsg:errMsg}
	end try
end parseXeditContent

-- ============================================================================
-- XEDIT LINE PARSING
-- ============================================================================

(*
	Parse a single XEDIT line
	
	Line format: "NNNNN content text here"
	Where NNNNN is a 5-digit line number (may have leading zeros)
	
	@param line - Single line from XEDIT screen
	@return Record with line details or missing value if not parseable
*)
on parseXeditLine(line)
	try
		set trimmedLine to my trimText(line)
		
		if trimmedLine is "" then
			return {lineNum:missing value, content:"", isBlank:true}
		end if
		
		-- Check if line starts with a number (line number)
		-- XEDIT line numbers are typically 5 digits, but can vary
		set lineNumStr to ""
		set contentStart to 1
		
		-- Extract leading digits (line number)
		repeat with i from 1 to length of trimmedLine
			set currentChar to character i of trimmedLine
			if currentChar is in "0123456789" then
				set lineNumStr to lineNumStr & currentChar
			else if currentChar is " " and lineNumStr is not "" then
				-- Found space after line number
				set contentStart to i + 1
				exit repeat
			else
				-- Not a line number format
				exit repeat
			end if
		end repeat
		
		-- If we found a line number, parse it
		if lineNumStr is not "" then
			set lineNum to missing value
			try
				set lineNum to lineNumStr as integer
			end try
			
			-- Extract content (everything after line number)
			set lineContent to ""
			if contentStart ≤ length of trimmedLine then
				set lineContent to text contentStart thru -1 of trimmedLine
			end if
			
			return {lineNum:lineNum, content:lineContent, isBlank:false, rawLine:line}
		else
			-- Not a numbered line, might be a marker or special line
			return {lineNum:missing value, content:trimmedLine, isBlank:false, rawLine:line}
		end if
		
	on error errMsg number errNum
		log "Error in parseXeditLine: " & errMsg & " (" & errNum & ")"
		return missing value
	end try
end parseXeditLine

-- ============================================================================
-- XEDIT CONTENT SEARCH
-- ============================================================================

(*
	Search XEDIT lines for specific text
	
	@param lines - List of parsed XEDIT lines
	@param searchText - Text to search for
	@param caseSensitive - Boolean for case-sensitive search
	@return List of matching line records
*)
on searchXeditLines(linesList, searchText, caseSensitive)
	try
		set matchingLinesList to {}
		
		set searchTarget to searchText
		if not caseSensitive then
			set searchTarget to my toLowerCase(searchText)
		end if
		
		repeat with lineData in linesList
			try
				set lineContent to content of lineData
				set compareContent to lineContent
				
				if not caseSensitive then
					set compareContent to my toLowerCase(lineContent)
				end if
				
				if compareContent contains searchTarget then
					set end of matchingLinesList to lineData
				end if
			end try
		end repeat
		
		return matchingLinesList
		
	on error errMsg
		log "Error in searchXeditLines: " & errMsg
		return {}
	end try
end searchXeditLines

(*
	Get line by line number
	
	@param lines - List of parsed XEDIT lines
	@param targetLineNum - Line number to find
	@return Line record or missing value
*)
on getLineByNumber(linesList, targetLineNum)
	try
		repeat with lineData in linesList
			try
				if lineNum of lineData is targetLineNum then
					return lineData
				end if
			end try
		end repeat
		
		return missing value
		
	on error errMsg
		log "Error in getLineByNumber: " & errMsg
		return missing value
	end try
end getLineByNumber

(*
	Get line range
	
	@param lines - List of parsed XEDIT lines
	@param startLine - Starting line number
	@param endLine - Ending line number
	@return List of line records in range
*)
on getLineRange(linesList, startLine, endLine)
	try
		set rangeLines to {}
		
		repeat with lineData in linesList
			try
				set currentLineNum to lineNum of lineData
				if currentLineNum is not missing value then
					if currentLineNum ≥ startLine and currentLineNum ≤ endLine then
						set end of rangeLines to lineData
					end if
				end if
			end try
		end repeat
		
		return rangeLines
		
	on error errMsg
		log "Error in getLineRange: " & errMsg
		return {}
	end try
end getLineRange

-- ============================================================================
-- XEDIT COMMAND HELPERS
-- ============================================================================

(*
	Parse XEDIT command from command line
	
	@param commandLine - Text from command line
	@return Record: {command, parameters}
*)
on parseXeditCommand(commandLine)
	try
		set trimmedCmd to my trimText(commandLine)
		
		if trimmedCmd is "" then
			return {command:"", parameters:{}}
		end if
		
		-- Extract command (first word)
		set cmdWord to my extractWord(trimmedCmd, 1)
		
		-- Extract parameters (remaining words)
		set params to {}
		set wordCount to my countWords(trimmedCmd)
		
		if wordCount > 1 then
			repeat with i from 2 to wordCount
				set end of params to my extractWord(trimmedCmd, i)
			end repeat
		end if
		
		return {command:cmdWord, parameters:params}
		
	on error errMsg
		log "Error in parseXeditCommand: " & errMsg
		return {command:"", parameters:{}}
	end try
end parseXeditCommand

(*
	Detect if file has been modified
	
	@param headerData - Header record from screen parser
	@return Boolean
*)
on isFileModified(headerData)
	try
		-- Check alteration count
		try
			if alteration of headerData > 0 then
				return true
			end if
		end try
		
		return false
		
	on error
		return false
	end try
end isFileModified

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

(*
	Extract word from text by position
	
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
	Count words in text
	
	@param sourceText - Text to count words in
	@return Integer word count
*)
on countWords(sourceText)
	try
		set AppleScript's text item delimiters to " "
		set wordList to text items of sourceText
		set AppleScript's text item delimiters to ""
		
		-- Filter out empty items
		set wordCount to 0
		repeat with w in wordList
			if w is not "" then
				set wordCount to wordCount + 1
			end if
		end repeat
		
		return wordCount
	on error
		return 0
	end try
end countWords

(*
	Convert text to lowercase
	
	@param sourceText - Text to convert
	@return Lowercase text
*)
on toLowerCase(sourceText)
	try
		set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		set lowerChars to "abcdefghijklmnopqrstuvwxyz"
		set resultText to ""
		
		repeat with i from 1 to length of sourceText
			set currentChar to character i of sourceText
			set charOffset to offset of currentChar in upperChars
			
			if charOffset > 0 then
				set resultText to resultText & character charOffset of lowerChars
			else
				set resultText to resultText & currentChar
			end if
		end repeat
		
		return resultText
	on error
		return sourceText
	end try
end toLowerCase

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
return {parseXeditContent:parseXeditContent, parseXeditLine:parseXeditLine, searchXeditLines:searchXeditLines, getLineByNumber:getLineByNumber, getLineRange:getLineRange, parseXeditCommand:parseXeditCommand, isFileModified:isFileModified}

-- Made with Bob
