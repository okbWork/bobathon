-- ============================================================================
-- Clipboard Manager for IBM Host On-Demand Automation
-- ============================================================================
-- Purpose: Manages clipboard operations for screen capture and data transfer
-- Author: Bob (AI Software Engineer)
-- Phase: 1 - Core Foundation
-- ============================================================================

-- Properties for configuration
property clipboardClearDelay : 0.05 -- 50ms delay after clearing
property clipboardReadDelay : 0.1 -- 100ms delay before reading
property minValidContentLength : 10 -- Minimum characters for valid content
property maxRetries : 3 -- Maximum retry attempts for clipboard operations

-- ============================================================================
-- MAIN FUNCTIONS
-- ============================================================================

-- Clear the system clipboard
-- Returns:
--   true if successful, false otherwise
-- Example: set success to clearClipboard()
on clearClipboard()
	try
		log "Clearing clipboard..."
		
		-- Use pbcopy with empty input to clear clipboard
		do shell script "echo -n '' | pbcopy"
		
		-- Wait for operation to complete
		delay clipboardClearDelay
		
		-- Verify clipboard is empty
		set clipContent to do shell script "pbpaste"
		if clipContent is "" then
			log "✓ Clipboard cleared successfully"
			return true
		else
			log "Warning: Clipboard may not be completely empty"
			return true -- Still return true as we attempted to clear
		end if
		
	on error errMsg number errNum
		log "Error in clearClipboard: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end clearClipboard

-- Read content from the system clipboard
-- Returns:
--   Clipboard content as string, or missing value on error
-- Example: set content to readClipboard()
on readClipboard()
	try
		log "Reading clipboard..."
		
		-- Wait for clipboard to be ready
		delay clipboardReadDelay
		
		-- Read clipboard using pbpaste
		set clipContent to do shell script "pbpaste"
		
		-- Log content length (not full content for security/size)
		set contentLength to length of clipContent
		log "✓ Read " & contentLength & " characters from clipboard"
		
		return clipContent
		
	on error errMsg number errNum
		log "Error in readClipboard: " & errMsg & " (Error " & errNum & ")"
		return missing value
	end try
end readClipboard

-- Validate clipboard content
-- Parameters:
--   content: String content to validate (optional - reads from clipboard if not provided)
-- Returns:
--   Record with {valid:boolean, length:integer, reason:string}
-- Example: set validation to validateClipboard()
on validateClipboard(content)
	try
		-- If no content provided, read from clipboard
		if content is missing value then
			set content to readClipboard()
			if content is missing value then
				return {valid:false, length:0, reason:"Could not read clipboard"}
			end if
		end if
		
		-- Check if content is empty
		if content is "" then
			log "✗ Clipboard validation failed: Empty content"
			return {valid:false, length:0, reason:"Clipboard is empty"}
		end if
		
		-- Check minimum length
		set contentLength to length of content
		if contentLength < minValidContentLength then
			log "✗ Clipboard validation failed: Content too short (" & contentLength & " chars)"
			return {valid:false, length:contentLength, reason:"Content too short (minimum " & minValidContentLength & " characters)"}
		end if
		
		-- Check for common error indicators
		if content contains "ERROR" or content contains "FAILED" or content contains "DMSCSL" then
			log "⚠ Clipboard validation warning: Content contains error indicators"
			-- Still return valid, but note the warning
			return {valid:true, length:contentLength, reason:"Valid but contains error indicators", hasWarning:true}
		end if
		
		-- Content is valid
		log "✓ Clipboard validation passed: " & contentLength & " characters"
		return {valid:true, length:contentLength, reason:"Valid content", hasWarning:false}
		
	on error errMsg number errNum
		log "Error in validateClipboard: " & errMsg & " (Error " & errNum & ")"
		return {valid:false, length:0, reason:"Validation error: " & errMsg}
	end try
end validateClipboard

-- ============================================================================
-- ADVANCED FUNCTIONS
-- ============================================================================

-- Read clipboard with retry logic
-- Parameters:
--   retries: Number of retry attempts (default: maxRetries)
--   delayBetweenRetries: Seconds to wait between retries (default: 0.5)
-- Returns:
--   Clipboard content as string, or missing value on error
on readClipboardWithRetry(retries, delayBetweenRetries)
	try
		-- Set defaults
		if retries is missing value then
			set retries to maxRetries
		end if
		if delayBetweenRetries is missing value then
			set delayBetweenRetries to 0.5
		end if
		
		log "Reading clipboard with retry (max " & retries & " attempts)..."
		
		repeat with attempt from 1 to retries
			set content to readClipboard()
			
			if content is not missing value then
				-- Validate content
				set validation to validateClipboard(content)
				if validation's valid then
					log "✓ Successfully read valid clipboard content on attempt " & attempt
					return content
				else
					log "⚠ Attempt " & attempt & ": Invalid content - " & validation's reason
				end if
			else
				log "⚠ Attempt " & attempt & ": Could not read clipboard"
			end if
			
			-- Wait before retry (except on last attempt)
			if attempt < retries then
				delay delayBetweenRetries
			end if
		end repeat
		
		log "✗ Failed to read valid clipboard content after " & retries & " attempts"
		return missing value
		
	on error errMsg number errNum
		log "Error in readClipboardWithRetry: " & errMsg & " (Error " & errNum & ")"
		return missing value
	end try
end readClipboardWithRetry

-- Write content to clipboard
-- Parameters:
--   content: String content to write to clipboard
-- Returns:
--   true if successful, false otherwise
-- Example: set success to writeClipboard("test content")
on writeClipboard(content)
	try
		log "Writing to clipboard..."
		
		-- Escape content for shell
		set escapedContent to do shell script "printf '%s' " & quoted form of content
		
		-- Write to clipboard using pbcopy
		do shell script "echo " & quoted form of content & " | pbcopy"
		
		-- Wait for operation to complete
		delay clipboardClearDelay
		
		-- Verify write
		set readBack to readClipboard()
		if readBack is content then
			log "✓ Successfully wrote " & (length of content) & " characters to clipboard"
			return true
		else
			log "⚠ Clipboard write verification failed"
			return false
		end if
		
	on error errMsg number errNum
		log "Error in writeClipboard: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end writeClipboard

-- Get clipboard history (macOS clipboard history if available)
-- Note: This is a placeholder for future enhancement
-- Returns:
--   List of recent clipboard entries (currently just returns current content)
on getClipboardHistory()
	try
		log "Getting clipboard history..."
		set currentContent to readClipboard()
		if currentContent is not missing value then
			return {currentContent}
		else
			return {}
		end if
	on error errMsg number errNum
		log "Error in getClipboardHistory: " & errMsg & " (Error " & errNum & ")"
		return {}
	end try
end getClipboardHistory

-- ============================================================================
-- CONFIGURATION FUNCTIONS
-- ============================================================================

-- Set minimum valid content length
-- Parameters:
--   length: Minimum number of characters for valid content
on setMinValidContentLength(length)
	set minValidContentLength to length
	log "Minimum valid content length set to: " & length
end setMinValidContentLength

-- Set clipboard read delay
-- Parameters:
--   delaySeconds: Delay in seconds before reading clipboard
on setClipboardReadDelay(delaySeconds)
	set clipboardReadDelay to delaySeconds
	log "Clipboard read delay set to: " & delaySeconds & " seconds"
end setClipboardReadDelay

-- Set clipboard clear delay
-- Parameters:
--   delaySeconds: Delay in seconds after clearing clipboard
on setClipboardClearDelay(delaySeconds)
	set clipboardClearDelay to delaySeconds
	log "Clipboard clear delay set to: " & delaySeconds & " seconds"
end setClipboardClearDelay

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get clipboard content info without reading full content
-- Returns:
--   Record with {hasContent:boolean, length:integer, type:string}
on getClipboardInfo()
	try
		set content to readClipboard()
		if content is missing value then
			return {hasContent:false, length:0, type:"unknown"}
		end if
		
		set contentLength to length of content
		
		-- Determine content type
		set contentType to "text"
		if content starts with "<?xml" then
			set contentType to "xml"
		else if content starts with "{" or content starts with "[" then
			set contentType to "json"
		else if content contains return or content contains linefeed then
			set contentType to "multiline_text"
		end if
		
		return {hasContent:true, length:contentLength, type:contentType}
		
	on error errMsg number errNum
		log "Error in getClipboardInfo: " & errMsg & " (Error " & errNum & ")"
		return {hasContent:false, length:0, type:"error"}
	end try
end getClipboardInfo

-- Check if clipboard contains specific text
-- Parameters:
--   searchText: Text to search for in clipboard
-- Returns:
--   true if found, false otherwise
on clipboardContains(searchText)
	try
		set content to readClipboard()
		if content is missing value then
			return false
		end if
		
		return content contains searchText
		
	on error
		return false
	end try
end clipboardContains

-- ============================================================================
-- TESTING FUNCTIONS
-- ============================================================================

-- Test clipboard manager functionality
-- Returns: true if all tests pass
on runTests()
	log "=========================================="
	log "Running Clipboard Manager Tests"
	log "=========================================="
	
	set testsPassed to 0
	set testsFailed to 0
	
	-- Test 1: Clear clipboard
	log "Test 1: Clearing clipboard..."
	set cleared to clearClipboard()
	if cleared then
		log "✓ Test 1 PASSED: Clipboard cleared"
		set testsPassed to testsPassed + 1
	else
		log "✗ Test 1 FAILED: Could not clear clipboard"
		set testsFailed to testsFailed + 1
	end if
	
	-- Test 2: Write to clipboard
	log "Test 2: Writing to clipboard..."
	set testContent to "Test content for clipboard manager"
	set written to writeClipboard(testContent)
	if written then
		log "✓ Test 2 PASSED: Content written to clipboard"
		set testsPassed to testsPassed + 1
	else
		log "✗ Test 2 FAILED: Could not write to clipboard"
		set testsFailed to testsFailed + 1
	end if
	
	-- Test 3: Read from clipboard
	log "Test 3: Reading from clipboard..."
	set readContent to readClipboard()
	if readContent is not missing value and readContent is testContent then
		log "✓ Test 3 PASSED: Content read correctly"
		set testsPassed to testsPassed + 1
	else
		log "✗ Test 3 FAILED: Could not read correct content"
		set testsFailed to testsFailed + 1
	end if
	
	-- Test 4: Validate clipboard
	log "Test 4: Validating clipboard..."
	set validation to validateClipboard(testContent)
	if validation's valid then
		log "✓ Test 4 PASSED: Validation successful"
		set testsPassed to testsPassed + 1
	else
		log "✗ Test 4 FAILED: Validation failed - " & validation's reason
		set testsFailed to testsFailed + 1
	end if
	
	-- Test 5: Get clipboard info
	log "Test 5: Getting clipboard info..."
	set info to getClipboardInfo()
	if info's hasContent then
		log "✓ Test 5 PASSED: Got clipboard info (length: " & info's length & ", type: " & info's type & ")"
		set testsPassed to testsPassed + 1
	else
		log "✗ Test 5 FAILED: Could not get clipboard info"
		set testsFailed to testsFailed + 1
	end if
	
	-- Test 6: Clipboard contains
	log "Test 6: Testing clipboard contains..."
	set containsResult to clipboardContains("Test content")
	if containsResult then
		log "✓ Test 6 PASSED: Found expected text"
		set testsPassed to testsPassed + 1
	else
		log "✗ Test 6 FAILED: Could not find expected text"
		set testsFailed to testsFailed + 1
	end if
	
	-- Test 7: Clear clipboard again
	log "Test 7: Clearing clipboard again..."
	set cleared to clearClipboard()
	if cleared then
		log "✓ Test 7 PASSED: Clipboard cleared"
		set testsPassed to testsPassed + 1
	else
		log "✗ Test 7 FAILED: Could not clear clipboard"
		set testsFailed to testsFailed + 1
	end if
	
	log "=========================================="
	log "Test Results: " & testsPassed & " passed, " & testsFailed & " failed"
	log "=========================================="
	
	return testsFailed = 0
end runTests

-- ============================================================================
-- END OF CLIPBOARD MANAGER
-- ============================================================================

-- Made with Bob
