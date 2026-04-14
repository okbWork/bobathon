-- Helpers Module
-- Utility functions for IBM Host On-Demand automation
-- Provides common operations for string manipulation, data structures, and formatting

-- Get current timestamp in formatted string
-- @return: Timestamp string (YYYY-MM-DD HH:MM:SS)
on getCurrentTimestamp()
	set now to current date
	set y to year of now as string
	set m to text -2 thru -1 of ("0" & (month of now as integer))
	set d to text -2 thru -1 of ("0" & (day of now))
	set h to text -2 thru -1 of ("0" & (hours of now))
	set min to text -2 thru -1 of ("0" & (minutes of now))
	set s to text -2 thru -1 of ("0" & (seconds of now))
	
	return y & "-" & m & "-" & d & " " & h & ":" & min & ":" & s
end getCurrentTimestamp

-- Format duration for human-readable display
-- @param seconds: Duration in seconds (can be decimal)
-- @return: Formatted string (e.g., "2.5s", "1m 30s", "1h 15m")
on formatDuration(seconds)
	try
		if seconds < 0 then
			return "0s"
		else if seconds < 1 then
			-- Milliseconds for very short durations
			return (round (seconds * 1000)) & "ms"
		else if seconds < 60 then
			-- Seconds with one decimal place
			return (round (seconds * 10) / 10) & "s"
		else if seconds < 3600 then
			-- Minutes and seconds
			set mins to seconds div 60
			set secs to round (seconds mod 60)
			if secs = 0 then
				return mins & "m"
			else
				return mins & "m " & secs & "s"
			end if
		else
			-- Hours, minutes, and seconds
			set hrs to seconds div 3600
			set remainingSeconds to seconds mod 3600
			set mins to remainingSeconds div 60
			set secs to round (remainingSeconds mod 60)
			
			set result to hrs & "h"
			if mins > 0 then
				set result to result & " " & mins & "m"
			end if
			if secs > 0 then
				set result to result & " " & secs & "s"
			end if
			return result
		end if
	on error
		return seconds & "s"
	end try
end formatDuration

-- Sanitize filename for filesystem compatibility
-- Removes or replaces invalid characters
-- @param filename: Original filename
-- @return: Sanitized filename safe for filesystem
on sanitizeFilename(filename)
	try
		set filename to filename as string
		
		-- Replace invalid characters with underscore
		set invalidChars to {"/", "\\", ":", "*", "?", "\"", "<", ">", "|", " ", tab, return, linefeed}
		repeat with char in invalidChars
			set AppleScript's text item delimiters to char
			set parts to text items of filename
			set AppleScript's text item delimiters to "_"
			set filename to parts as string
		end repeat
		set AppleScript's text item delimiters to ""
		
		-- Remove leading/trailing underscores
		repeat while filename starts with "_"
			set filename to text 2 thru -1 of filename
		end repeat
		repeat while filename ends with "_"
			set filename to text 1 thru -2 of filename
		end repeat
		
		-- Collapse multiple underscores
		repeat while filename contains "__"
			set AppleScript's text item delimiters to "__"
			set parts to text items of filename
			set AppleScript's text item delimiters to "_"
			set filename to parts as string
		end repeat
		set AppleScript's text item delimiters to ""
		
		-- Limit length to 100 characters
		if length of filename > 100 then
			set filename to text 1 thru 100 of filename
		end if
		
		-- Ensure not empty
		if filename is "" then
			set filename to "unnamed"
		end if
		
		return filename
		
	on error errMsg
		log "HELPERS: Sanitize filename error - " & errMsg
		return "unnamed"
	end try
end sanitizeFilename

-- Deep copy an AppleScript record
-- Creates a new record with copied values (not references)
-- @param sourceRecord: Record to copy
-- @return: New record with copied values
on deepCopyRecord(sourceRecord)
	try
		-- Convert to string and back to create deep copy
		set recordString to sourceRecord as string
		
		-- For simple records, create new record manually
		set newRecord to {}
		
		repeat with i from 1 to count of sourceRecord
			try
				set itemKey to item i of (sourceRecord's properties)
				set itemValue to item i of (sourceRecord's values)
				
				-- Copy the value
				if class of itemValue is record then
					set copiedValue to deepCopyRecord(itemValue)
				else if class of itemValue is list then
					set copiedValue to deepCopyList(itemValue)
				else
					set copiedValue to itemValue
				end if
				
				-- Add to new record
				set newRecord to newRecord & {|itemKey|:copiedValue}
			end try
		end repeat
		
		return newRecord
		
	on error errMsg
		log "HELPERS: Deep copy record error - " & errMsg
		return sourceRecord -- Return original if copy fails
	end try
end deepCopyRecord

-- Deep copy a list
-- @param sourceList: List to copy
-- @return: New list with copied values
on deepCopyList(sourceList)
	try
		set newList to {}
		
		repeat with listItem in sourceList
			if class of listItem is record then
				set copiedItem to deepCopyRecord(listItem)
			else if class of listItem is list then
				set copiedItem to deepCopyList(listItem)
			else
				set copiedItem to listItem
			end if
			
			set end of newList to copiedItem
		end repeat
		
		return newList
		
	on error errMsg
		log "HELPERS: Deep copy list error - " & errMsg
		return sourceList
	end try
end deepCopyList

-- Merge two records (record2 values override record1)
-- @param record1: Base record
-- @param record2: Override record
-- @return: Merged record
on mergeRecords(record1, record2)
	try
		-- Start with copy of record1
		set mergedRecord to deepCopyRecord(record1)
		
		-- Add/override with record2 values
		repeat with i from 1 to count of record2
			try
				set itemKey to item i of (record2's properties)
				set itemValue to item i of (record2's values)
				
				-- Add or override in merged record
				set mergedRecord to mergedRecord & {|itemKey|:itemValue}
			end try
		end repeat
		
		return mergedRecord
		
	on error errMsg
		log "HELPERS: Merge records error - " & errMsg
		return record1
	end try
end mergeRecords

-- Convert record to readable string representation
-- @param rec: Record to convert
-- @return: String representation
on recordToString(rec)
	try
		if rec is missing value then
			return "missing value"
		end if
		
		set output to "{"
		set firstItem to true
		
		repeat with i from 1 to count of rec
			try
				set itemKey to item i of (rec's properties) as string
				set itemValue to item i of (rec's values)
				
				if not firstItem then
					set output to output & ", "
				end if
				set firstItem to false
				
				-- Format value based on type
				if class of itemValue is record then
					set valueStr to recordToString(itemValue)
				else if class of itemValue is list then
					set valueStr to listToString(itemValue)
				else if itemValue is missing value then
					set valueStr to "missing value"
				else
					set valueStr to itemValue as string
				end if
				
				set output to output & itemKey & ":" & valueStr
			end try
		end repeat
		
		set output to output & "}"
		return output
		
	on error errMsg
		log "HELPERS: Record to string error - " & errMsg
		return rec as string
	end try
end recordToString

-- Convert list to readable string representation
-- @param lst: List to convert
-- @return: String representation
on listToString(lst)
	try
		if lst is {} then
			return "[]"
		end if
		
		set output to "["
		set firstItem to true
		
		repeat with listItem in lst
			if not firstItem then
				set output to output & ", "
			end if
			set firstItem to false
			
			if class of listItem is record then
				set output to output & recordToString(listItem)
			else if class of listItem is list then
				set output to output & listToString(listItem)
			else
				set output to output & (listItem as string)
			end if
		end repeat
		
		set output to output & "]"
		return output
		
	on error errMsg
		log "HELPERS: List to string error - " & errMsg
		return lst as string
	end try
end listToString

-- Check if text contains any of the search terms
-- @param text: Text to search in
-- @param searchTerms: List of terms to search for
-- @return: Boolean indicating if any term was found
on stringContainsAny(textToSearch, searchTerms)
	try
		set textToSearch to textToSearch as string
		
		repeat with term in searchTerms
			if textToSearch contains (term as string) then
				return true
			end if
		end repeat
		
		return false
		
	on error errMsg
		log "HELPERS: String contains any error - " & errMsg
		return false
	end try
end stringContainsAny

-- Check if text contains all of the search terms
-- @param text: Text to search in
-- @param searchTerms: List of terms to search for
-- @return: Boolean indicating if all terms were found
on stringContainsAll(textToCheck, searchTerms)
	try
		set textToCheck to textToCheck as string
		
		repeat with term in searchTerms
			if not (textToCheck contains (term as string)) then
				return false
			end if
		end repeat
		
		return true
		
	on error errMsg
		log "HELPERS: String contains all error - " & errMsg
		return false
	end try
end stringContainsAll

-- Extract number from text using pattern
-- @param textToSearch: Text to search in
-- @param pattern: Pattern description (e.g., "after 'Total:'", "before 'items'")
-- @return: Extracted number or 0 if not found
on extractNumberFromText(textToSearch, pattern)
	try
		set textToSearch to textToSearch as string
		
		-- Simple extraction: find first number in text
		set numberChars to "0123456789"
		set foundNumber to ""
		set inNumber to false
		
		repeat with i from 1 to length of textToSearch
			set char to character i of textToSearch
			if numberChars contains char then
				set foundNumber to foundNumber & char
				set inNumber to true
			else if inNumber and char is "." then
				-- Allow decimal point
				set foundNumber to foundNumber & char
			else if inNumber then
				-- End of number
				exit repeat
			end if
		end repeat
		
		if foundNumber is not "" then
			return foundNumber as number
		else
			return 0
		end if
		
	on error errMsg
		log "HELPERS: Extract number error - " & errMsg
		return 0
	end try
end extractNumberFromText

-- Extract text between two delimiters
-- @param text: Source text
-- @param startDelim: Starting delimiter
-- @param endDelim: Ending delimiter
-- @return: Extracted text or empty string
on extractBetween(sourceText, startDelim, endDelim)
	try
		set sourceText to sourceText as string
		
		-- Find start position
		set AppleScript's text item delimiters to startDelim
		set parts to text items of sourceText
		
		if (count of parts) < 2 then
			set AppleScript's text item delimiters to ""
			return ""
		end if
		
		-- Get text after start delimiter
		set afterStart to item 2 of parts
		
		-- Find end position
		set AppleScript's text item delimiters to endDelim
		set parts to text items of afterStart
		
		set AppleScript's text item delimiters to ""
		
		if (count of parts) < 1 then
			return ""
		end if
		
		return item 1 of parts
		
	on error errMsg
		set AppleScript's text item delimiters to ""
		log "HELPERS: Extract between error - " & errMsg
		return ""
	end try
end extractBetween

-- Trim whitespace from string
-- @param textToTrim: Text to trim
-- @return: Trimmed text
on trimWhitespace(textToTrim)
	try
		set textToTrim to textToTrim as string
		
		-- Trim leading whitespace
		repeat while textToTrim starts with " " or textToTrim starts with tab or textToTrim starts with return or textToTrim starts with linefeed
			if length of textToTrim > 1 then
				set textToTrim to text 2 thru -1 of textToTrim
			else
				return ""
			end if
		end repeat
		
		-- Trim trailing whitespace
		repeat while textToTrim ends with " " or textToTrim ends with tab or textToTrim ends with return or textToTrim ends with linefeed
			if length of textToTrim > 1 then
				set textToTrim to text 1 thru -2 of textToTrim
			else
				return ""
			end if
		end repeat
		
		return textToTrim
		
	on error errMsg
		log "HELPERS: Trim whitespace error - " & errMsg
		return textToTrim
	end try
end trimWhitespace

-- Split string by delimiter
-- @param textToSplit: Text to split
-- @param delimiter: Delimiter to split on
-- @return: List of parts
on splitString(textToSplit, delimiter)
	try
		set textToSplit to textToSplit as string
		set AppleScript's text item delimiters to delimiter
		set parts to text items of textToSplit
		set AppleScript's text item delimiters to ""
		return parts
	on error errMsg
		set AppleScript's text item delimiters to ""
		log "HELPERS: Split string error - " & errMsg
		return {textToSplit}
	end try
end splitString

-- Join list items with delimiter
-- @param itemList: List of items to join
-- @param delimiter: Delimiter to join with
-- @return: Joined string
on joinList(itemList, delimiter)
	try
		set AppleScript's text item delimiters to delimiter
		set resultText to itemList as string
		set AppleScript's text item delimiters to ""
		return resultText
	on error errMsg
		set AppleScript's text item delimiters to ""
		log "HELPERS: Join list error - " & errMsg
		return ""
	end try
end joinList

-- Check if value is in list
-- @param value: Value to search for
-- @param lst: List to search in
-- @return: Boolean indicating if value is in list
on isInList(value, lst)
	try
		repeat with listItem in lst
			if listItem is value then
				return true
			end if
		end repeat
		return false
	on error
		return false
	end try
end isInList

-- Get unique items from list
-- @param lst: List with potential duplicates
-- @return: List with unique items only
on uniqueList(lst)
	try
		set uniqueItems to {}
		
		repeat with listItem in lst
			if not isInList(listItem, uniqueItems) then
				set end of uniqueItems to listItem
			end if
		end repeat
		
		return uniqueItems
		
	on error errMsg
		log "HELPERS: Unique list error - " & errMsg
		return lst
	end try
end uniqueList

-- Calculate percentage
-- @param part: Part value
-- @param total: Total value
-- @return: Percentage (0-100)
on calculatePercentage(part, total)
	try
		if total = 0 then
			return 0
		end if
		return round ((part / total) * 100)
	on error
		return 0
	end try
end calculatePercentage

log "Helpers Module Loaded"

-- Made with Bob
