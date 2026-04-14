(*
	NETLOG Parser - Specialized parser for IBM CMS NETLOG screens
	
	This module parses NETLOG file listings which track file transfers and
	system messages. It extracts structured data from numbered entries including
	file information, transfer details, and timestamps.
	
	Example NETLOG format:
	    0 * * * Top of File * * *
	    1 File PROFILE  EXEC     A1 recv from CADEC    at GDLVM7   on 2025-03-21 14:21:03
	    2 Note SUCCESS  NOTE     A0 recv from SUCCESS  at GDLVM7   on 2025-04-28 12:07:53
	
	Author: Bob (AI Software Engineer)
	Phase: 3 - Intelligence Layer
*)

use AppleScript version "2.4"
use scripting additions

-- ============================================================================
-- MAIN NETLOG PARSING FUNCTION
-- ============================================================================

(*
	Parse NETLOG screen content into structured entries
	
	@param screenLines - List of screen lines from NETLOG display
	@return Record: {entries, entryCount, hasMore, topOfFile, bottomOfFile}
*)
on parseNetlogContent(screenLines)
	try
		set netlogData to {entries:{}, entryCount:0, hasMore:false, topOfFile:false, bottomOfFile:false}
		set parsedEntries to {}
		
		if (count of screenLines) is 0 then return netlogData
		
		-- Parse each line
		repeat with screenLine in screenLines
			set lineText to screenLine as text
			set trimmedLine to my trimText(lineText)
			
			-- Check for special markers
			if trimmedLine contains "* * * Top of File * * *" then
				set topOfFile of netlogData to true
			else if trimmedLine contains "* * * Bottom of File * * *" or trimmedLine contains "* * * End of File * * *" then
				set bottomOfFile of netlogData to true
			else if trimmedLine starts with "====" then
				-- Command line, skip
			else if trimmedLine is "" then
				-- Empty line, skip
			else
				-- Try to parse as NETLOG entry
				set entryData to parseNetlogEntry(lineText)
				
				if entryData is not missing value and lineNum of entryData is not missing value then
					set end of parsedEntries to entryData
				end if
			end if
		end repeat
		
		-- Set results
		set entries of netlogData to parsedEntries
		set entryCount of netlogData to count of parsedEntries
		
		-- Determine if there are more entries (not at bottom)
		if bottomOfFile of netlogData is false and entryCount of netlogData > 0 then
			set hasMore of netlogData to true
		end if
		
		return netlogData
		
	on error errMsg number errNum
		log "Error in parseNetlogContent: " & errMsg & " (" & errNum & ")"
		return {entries:{}, entryCount:0, hasMore:false, topOfFile:false, bottomOfFile:false, errorMsg:errMsg}
	end try
end parseNetlogContent

-- ============================================================================
-- NETLOG ENTRY PARSING
-- ============================================================================

(*
	Parse a single NETLOG entry line
	
	Entry formats:
	1. File entry: "N File FILENAME FILETYPE FM recv/sent from/to USER at SYSTEM on YYYY-MM-DD HH:MM:SS"
	2. Note entry: "N Note FILENAME FILETYPE FM recv/sent from/to USER at SYSTEM on YYYY-MM-DD HH:MM:SS"
	3. Special: "N * * * Top of File * * *"
	
	@param entryLine - Single line from NETLOG
	@return Record with entry details or missing value if not parseable
*)
on parseNetlogEntry(entryLine)
	try
		set trimmedLine to my trimText(entryLine)
		
		if trimmedLine is "" then return missing value
		
		-- Initialize entry record
		set entryData to {lineNum:missing value, entryType:"", filename:"", filetype:"", filemode:"", action:"", direction:"", remoteUser:"", remoteSystem:"", timestamp:"", rawLine:entryLine}
		
		-- Extract line number (first token)
		set lineNumStr to my extractWord(trimmedLine, 1)
		
		-- Validate line number is numeric
		if not my isNumeric(lineNumStr) then
			return missing value
		end if
		
		try
			set lineNum of entryData to lineNumStr as integer
		on error
			return missing value
		end try
		
		-- Extract entry type (second token: "File", "Note", "*")
		set typeToken to my extractWord(trimmedLine, 2)
		
		if typeToken is "*" then
			-- Special marker line
			set entryType of entryData to "MARKER"
			return entryData
		end if
		
		set entryType of entryData to typeToken
		
		-- Extract filename (third token)
		set filename of entryData to my extractWord(trimmedLine, 3)
		
		-- Extract filetype (fourth token)
		set filetype of entryData to my extractWord(trimmedLine, 4)
		
		-- Extract filemode (fifth token)
		set filemode of entryData to my extractWord(trimmedLine, 5)
		
		-- Determine action and direction
		-- Look for "recv from" or "sent to" patterns
		if trimmedLine contains "recv from" then
			set action of entryData to "recv"
			set direction of entryData to "from"
			
			-- Extract remote user (after "from")
			set remoteUser of entryData to my extractAfterKeyword(trimmedLine, "from", 1)
			
		else if trimmedLine contains "sent to" then
			set action of entryData to "sent"
			set direction of entryData to "to"
			
			-- Extract remote user (after "to")
			set remoteUser of entryData to my extractAfterKeyword(trimmedLine, "to", 1)
		end if
		
		-- Extract remote system (after "at")
		if trimmedLine contains " at " then
			set remoteSystem of entryData to my extractAfterKeyword(trimmedLine, "at", 1)
		end if
		
		-- Extract timestamp (after "on")
		if trimmedLine contains " on " then
			set timestamp of entryData to my extractTimestamp(trimmedLine)
		end if
		
		return entryData
		
	on error errMsg number errNum
		log "Error in parseNetlogEntry: " & errMsg & " (" & errNum & ")"
		return missing value
	end try
end parseNetlogEntry

-- ============================================================================
-- NETLOG SEARCH AND FILTER
-- ============================================================================

(*
	Search NETLOG entries for specific criteria
	
	@param entries - List of parsed NETLOG entries
	@param searchCriteria - Record with search parameters: {filename, filetype, user, action, dateFrom, dateTo}
	@return List of matching entries
*)
on searchNetlogEntries(entries, searchCriteria)
	try
		set matchingEntries to {}
		
		-- Extract search criteria
		set searchFilename to ""
		set searchFiletype to ""
		set searchUser to ""
		set searchAction to ""
		
		try
			set searchFilename to filename of searchCriteria
		end try
		try
			set searchFiletype to filetype of searchCriteria
		end try
		try
			set searchUser to remoteUser of searchCriteria
		end try
		try
			set searchAction to action of searchCriteria
		end try
		
		-- Filter entries
		repeat with entry in entries
			set matches to true
			
			-- Check filename match
			if searchFilename is not "" then
				try
					if filename of entry does not contain searchFilename then
						set matches to false
					end if
				end try
			end if
			
			-- Check filetype match
			if matches and searchFiletype is not "" then
				try
					if filetype of entry does not contain searchFiletype then
						set matches to false
					end if
				end try
			end if
			
			-- Check user match
			if matches and searchUser is not "" then
				try
					if remoteUser of entry does not contain searchUser then
						set matches to false
					end if
				end try
			end if
			
			-- Check action match
			if matches and searchAction is not "" then
				try
					if action of entry is not searchAction then
						set matches to false
					end if
				end try
			end if
			
			-- Add to results if matches
			if matches then
				set end of matchingEntries to entry
			end if
		end repeat
		
		return matchingEntries
		
	on error errMsg
		log "Error in searchNetlogEntries: " & errMsg
		return {}
	end try
end searchNetlogEntries

(*
	Get most recent entry for a specific file
	
	@param entries - List of parsed NETLOG entries
	@param targetFilename - Filename to search for
	@param targetFiletype - Filetype to search for
	@return Entry record or missing value
*)
on getMostRecentEntry(entries, targetFilename, targetFiletype)
	try
		set mostRecent to missing value
		set highestLineNum to -1
		
		repeat with entry in entries
			try
				if filename of entry is targetFilename and filetype of entry is targetFiletype then
					if lineNum of entry > highestLineNum then
						set highestLineNum to lineNum of entry
						set mostRecent to entry
					end if
				end if
			end try
		end repeat
		
		return mostRecent
		
	on error errMsg
		log "Error in getMostRecentEntry: " & errMsg
		return missing value
	end try
end getMostRecentEntry

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
	Extract text after a keyword
	
	@param sourceText - Text to search in
	@param keyword - Keyword to find
	@param wordOffset - Number of words after keyword to extract (1 = next word)
	@return Extracted text or empty string
*)
on extractAfterKeyword(sourceText, keyword, wordOffset)
	try
		if sourceText does not contain keyword then return ""
		
		-- Find position after keyword
		set keywordPos to offset of keyword in sourceText
		set afterKeyword to text (keywordPos + (length of keyword)) thru -1 of sourceText
		
		-- Extract word at offset position
		return my extractWord(afterKeyword, wordOffset)
		
	on error
		return ""
	end try
end extractAfterKeyword

(*
	Extract timestamp from NETLOG line
	
	Format: "on YYYY-MM-DD HH:MM:SS"
	
	@param sourceText - Text containing timestamp
	@return Timestamp string or empty string
*)
on extractTimestamp(sourceText)
	try
		if sourceText does not contain " on " then return ""
		
		-- Find position after "on "
		set onPos to offset of " on " in sourceText
		set afterOn to text (onPos + 4) thru -1 of sourceText
		
		-- Extract date and time (next 19 characters: "YYYY-MM-DD HH:MM:SS")
		if length of afterOn ≥ 19 then
			return text 1 thru 19 of afterOn
		else
			return afterOn
		end if
		
	on error
		return ""
	end try
end extractTimestamp

(*
	Check if string is numeric
	
	@param testString - String to test
	@return Boolean
*)
on isNumeric(testString)
	try
		set testString to testString as text
		if testString is "" then return false
		
		repeat with i from 1 to length of testString
			set currentChar to character i of testString
			if currentChar is not in "0123456789" then
				return false
			end if
		end repeat
		
		return true
	on error
		return false
	end try
end isNumeric

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
return {parseNetlogContent:parseNetlogContent, parseNetlogEntry:parseNetlogEntry, searchNetlogEntries:searchNetlogEntries, getMostRecentEntry:getMostRecentEntry}

-- Made with Bob
