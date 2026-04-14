(*
	FILELIST Parser - Specialized parser for IBM CMS FILELIST screens
	
	This module parses FILELIST screens which display directory listings of
	files with metadata including filename, filetype, filemode, record count,
	and date information.
	
	Example FILELIST format:
	    USERID   FILELIST A0  V 169  Trunc=169 Size=50 Line=1 Col=1 Alt=0
	    Filename Filetype Fm Format Lrecl    Records    Blocks   Date     Time
	    PROFILE  EXEC     A1 V         72         45         1  1/17/25 10:23:45
	    NETLOG   NETLOG   A0 V        255        195         2  4/28/25 12:07:53
	
	Author: Bob (AI Software Engineer)
	Phase: 3 - Intelligence Layer
*)

use AppleScript version "2.4"
use scripting additions

-- ============================================================================
-- MAIN FILELIST PARSING FUNCTION
-- ============================================================================

(*
	Parse FILELIST screen content into structured file entries
	
	@param screenLines - List of screen lines from FILELIST display
	@return Record: {files, fileCount, currentSelection, hasHeader}
*)
on parseFilelistContent(screenLines)
	try
		set filelistData to {files:{}, fileCount:0, currentSelection:missing value, hasHeader:false}
		set parsedFiles to {}
		set headerFound to false
		
		if (count of screenLines) is 0 then return filelistData
		
		-- Parse each line
		repeat with screenLine in screenLines
			set lineText to screenLine as text
			set trimmedLine to my trimText(lineText)
			
			-- Check for column header
			if not headerFound and (trimmedLine contains "Filename" and trimmedLine contains "Filetype") then
				set headerFound to true
				set hasHeader of filelistData to true
			else if trimmedLine starts with "====" then
				-- Command line, skip
			else if trimmedLine is "" then
				-- Empty line, skip
			else if not headerFound then
				-- Skip lines before header
			else
				-- Try to parse as file entry
				set fileEntry to parseFilelistEntry(lineText)
				
				if fileEntry is not missing value then
					set end of parsedFiles to fileEntry
				end if
			end if
		end repeat
		
		-- Set results
		set files of filelistData to parsedFiles
		set fileCount of filelistData to count of parsedFiles
		
		return filelistData
		
	on error errMsg number errNum
		log "Error in parseFilelistContent: " & errMsg & " (" & errNum & ")"
		return {files:{}, fileCount:0, currentSelection:missing value, hasHeader:false, errorMsg:errMsg}
	end try
end parseFilelistContent

-- ============================================================================
-- FILELIST ENTRY PARSING
-- ============================================================================

(*
	Parse a single FILELIST entry line
	
	Entry format: "FILENAME FILETYPE FM FORMAT LRECL RECORDS BLOCKS DATE TIME"
	Example: "PROFILE  EXEC     A1 V         72         45         1  1/17/25 10:23:45"
	
	@param entryLine - Single line from FILELIST
	@return Record with file details or missing value if not parseable
*)
on parseFilelistEntry(entryLine)
	try
		set trimmedLine to my trimText(entryLine)
		
		if trimmedLine is "" then return missing value
		
		-- Initialize file entry record
		set fileEntry to {filename:"", filetype:"", filemode:"", format:"", lrecl:0, records:0, blocks:0, filedate:"", filetime:"", rawLine:entryLine}
		
		-- Parse using column positions (FILELIST has fixed-width columns)
		-- Filename: columns 1-8
		-- Filetype: columns 10-17
		-- Filemode: columns 19-20
		-- Format: columns 22-23
		-- Lrecl: columns 25-34 (right-aligned)
		-- Records: columns 36-45 (right-aligned)
		-- Blocks: columns 47-56 (right-aligned)
		-- Date: columns 58-65
		-- Time: columns 67-74
		
		-- Extract filename (first word)
		set filename of fileEntry to my extractWord(trimmedLine, 1)
		
		-- Extract filetype (second word)
		set filetype of fileEntry to my extractWord(trimmedLine, 2)
		
		-- Extract filemode (third word)
		set filemode of fileEntry to my extractWord(trimmedLine, 3)
		
		-- Extract format (fourth word)
		set format of fileEntry to my extractWord(trimmedLine, 4)
		
		-- Extract lrecl (fifth word)
		set lreclStr to my extractWord(trimmedLine, 5)
		if lreclStr is not "" then
			try
				set lrecl of fileEntry to lreclStr as integer
			end try
		end if
		
		-- Extract records (sixth word)
		set recordsStr to my extractWord(trimmedLine, 6)
		if recordsStr is not "" then
			try
				set records of fileEntry to recordsStr as integer
			end try
		end if
		
		-- Extract blocks (seventh word)
		set blocksStr to my extractWord(trimmedLine, 7)
		if blocksStr is not "" then
			try
				set blocks of fileEntry to blocksStr as integer
			end try
		end if
		
		-- Extract date (eighth word)
		set filedate of fileEntry to my extractWord(trimmedLine, 8)
		
		-- Extract time (ninth word)
		set filetime of fileEntry to my extractWord(trimmedLine, 9)
		
		-- Validate that we have at least filename and filetype
		if filename of fileEntry is "" or filetype of fileEntry is "" then
			return missing value
		end if
		
		return fileEntry
		
	on error errMsg number errNum
		log "Error in parseFilelistEntry: " & errMsg & " (" & errNum & ")"
		return missing value
	end try
end parseFilelistEntry

-- ============================================================================
-- FILELIST SEARCH AND FILTER
-- ============================================================================

(*
	Search file entries for specific criteria
	
	@param files - List of parsed file entries
	@param searchCriteria - Record with search parameters: {filename, filetype, filemode}
	@return List of matching file entries
*)
on searchFilelistEntries(filesList, searchCriteria)
	try
		set matchingFilesList to {}
		
		-- Extract search criteria
		set searchFilename to ""
		set searchFiletype to ""
		set searchFilemode to ""
		
		try
			set searchFilename to filename of searchCriteria
		end try
		try
			set searchFiletype to filetype of searchCriteria
		end try
		try
			set searchFilemode to filemode of searchCriteria
		end try
		
		-- Filter files
		repeat with fileEntry in filesList
			set matches to true
			
			-- Check filename match (supports wildcards)
			if searchFilename is not "" then
				try
					if not my matchesPattern(filename of fileEntry, searchFilename) then
						set matches to false
					end if
				end try
			end if
			
			-- Check filetype match (supports wildcards)
			if matches and searchFiletype is not "" then
				try
					if not my matchesPattern(filetype of fileEntry, searchFiletype) then
						set matches to false
					end if
				end try
			end if
			
			-- Check filemode match
			if matches and searchFilemode is not "" then
				try
					if filemode of fileEntry is not searchFilemode then
						set matches to false
					end if
				end try
			end if
			
			-- Add to results if matches
			if matches then
				set end of matchingFilesList to fileEntry
			end if
		end repeat
		
		return matchingFilesList
		
	on error errMsg
		log "Error in searchFilelistEntries: " & errMsg
		return {}
	end try
end searchFilelistEntries

(*
	Find specific file by name and type
	
	@param files - List of parsed file entries
	@param targetFilename - Filename to find
	@param targetFiletype - Filetype to find
	@return File entry record or missing value
*)
on findFile(filesList, targetFilename, targetFiletype)
	try
		repeat with fileEntry in filesList
			try
				if filename of fileEntry is targetFilename and filetype of fileEntry is targetFiletype then
					return fileEntry
				end if
			end try
		end repeat
		
		return missing value
		
	on error errMsg
		log "Error in findFile: " & errMsg
		return missing value
	end try
end findFile

(*
	Sort files by specified field
	
	@param files - List of parsed file entries
	@param sortField - Field to sort by: "filename", "filetype", "date", "records"
	@param ascending - Boolean for sort direction
	@return Sorted list of file entries
*)
on sortFiles(filesList, sortField, ascending)
	try
		-- Simple bubble sort implementation
		set sortedFiles to filesList
		set fileCount to count of sortedFiles
		
		if fileCount ≤ 1 then return sortedFiles
		
		repeat with i from 1 to fileCount - 1
			repeat with j from 1 to fileCount - i
				set file1 to item j of sortedFiles
				set file2 to item (j + 1) of sortedFiles
				
				set shouldSwap to false
				
				-- Compare based on sort field
				if sortField is "filename" then
					try
						if ascending then
							set shouldSwap to (filename of file1 > filename of file2)
						else
							set shouldSwap to (filename of file1 < filename of file2)
						end if
					end try
				else if sortField is "filetype" then
					try
						if ascending then
							set shouldSwap to (filetype of file1 > filetype of file2)
						else
							set shouldSwap to (filetype of file1 < filetype of file2)
						end if
					end try
				else if sortField is "records" then
					try
						if ascending then
							set shouldSwap to (records of file1 > records of file2)
						else
							set shouldSwap to (records of file1 < records of file2)
						end if
					end try
				end if
				
				-- Swap if needed
				if shouldSwap then
					set temp to item j of sortedFiles
					set item j of sortedFiles to item (j + 1) of sortedFiles
					set item (j + 1) of sortedFiles to temp
				end if
			end repeat
		end repeat
		
		return sortedFiles
		
	on error errMsg
		log "Error in sortFiles: " & errMsg
		return files
	end try
end sortFiles

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
	Check if text matches pattern (supports * wildcard)
	
	@param text - Text to check
	@param pattern - Pattern with optional * wildcard
	@return Boolean
*)
on matchesPattern(text, pattern)
	try
		-- If no wildcard, do exact match
		if pattern does not contain "*" then
			return text is pattern
		end if
		
		-- Handle wildcard patterns
		if pattern is "*" then
			return true
		end if
		
		if pattern starts with "*" and pattern ends with "*" then
			-- *text* - contains
			set searchText to text 2 thru -2 of pattern
			return text contains searchText
		else if pattern starts with "*" then
			-- *text - ends with
			set searchText to text 2 thru -1 of pattern
			return text ends with searchText
		else if pattern ends with "*" then
			-- text* - starts with
			set searchText to text 1 thru -2 of pattern
			return text starts with searchText
		end if
		
		-- Default to exact match
		return text is pattern
		
	on error
		return false
	end try
end matchesPattern

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
return {parseFilelistContent:parseFilelistContent, parseFilelistEntry:parseFilelistEntry, searchFilelistEntries:searchFilelistEntries, findFile:findFile, sortFiles:sortFiles}

-- Made with Bob
