-- ============================================================================
-- Screen Capture Engine for IBM Host On-Demand Automation
-- ============================================================================
-- Purpose: Captures screen content from HOD windows using mouse selection
-- Author: Bob (AI Software Engineer)
-- Phase: 2 - Screen Interaction
-- ============================================================================

-- Note: This script requires window_manager.applescript and clipboard_manager.applescript
-- In production, use: set windowManager to load script (path to window_manager)
-- In production, use: set clipboardManager to load script (path to clipboard_manager)

-- Properties for configuration
property toolbarCopyButtonX : 100 -- X offset from window left edge
property toolbarCopyButtonY : 30 -- Y offset from window top edge
property selectionMarginTop : 60 -- Top margin to skip toolbar
property selectionMarginLeft : 5 -- Left margin
property selectionMarginRight : 5 -- Right margin
property selectionMarginBottom : 5 -- Bottom margin
property mouseClickDelay : 0.2 -- 200ms delay after mouse clicks
property dragDelay : 0.1 -- 100ms delay during drag operation
property captureRetries : 3 -- Number of retry attempts
property minScreenContentLength : 50 -- Minimum characters for valid screen

-- ============================================================================
-- MAIN FUNCTIONS
-- ============================================================================

-- Capture screen content from HOD window
-- Parameters:
--   windowRef: Window reference record from window_manager
-- Returns:
--   Record {success:boolean, screenText:string, message:string}
-- Example: set captureResult to captureScreen(windowRef)
on captureScreen(windowRef)
	try
		log "=========================================="
		log "Starting screen capture..."
		log "=========================================="
		
		if windowRef is missing value then
			log "Error: Invalid window reference"
			return {success:false, message:"Invalid window reference", screenText:""}
		end if
		
		log "Step 1: Activating HOD window..."
		tell application "System Events"
			set frontmost of (windowRef's processRef) to true
			delay 0.3
		end tell
		
		log "Step 2: Clearing clipboard..."
		do shell script "printf '' | pbcopy"
		
		log "Step 3: Getting window bounds..."
		set boundsRecord to missing value
		try
			set win to windowRef's windowRef
			tell application "System Events"
				set winPosition to position of win
				set xPos to item 1 of winPosition
				set yPos to item 2 of winPosition
				set winSize to size of win
				set winWidth to item 1 of winSize
				set winHeight to item 2 of winSize
			end tell
			set boundsRecord to {x:xPos, y:yPos, width:winWidth, height:winHeight}
		on error
			log "Warning: Could not read live window bounds, using fallback bounds"
			set boundsRecord to {x:0, y:0, width:800, height:600}
		end try
		
		log "Step 4: Clicking in window to ensure focus..."
		-- Click in the middle of the window to ensure it has focus
		set midX to (boundsRecord's x) + ((boundsRecord's width) / 2)
		set midY to (boundsRecord's y) + ((boundsRecord's height) / 2)
		try
			do shell script "cliclick c:" & midX & "," & midY
			delay 0.3
		on error
			log "Warning: Could not click to focus window"
		end try
		
		log "Step 5: Selecting all with Ctrl+A..."
		tell application "System Events"
			keystroke "a" using control down
		end tell
		delay 0.3
		
		log "Step 6: Copying with Ctrl+C..."
		tell application "System Events"
			keystroke "c" using control down
		end tell
		delay 0.5
		
		log "Step 7: Reading clipboard content..."
		set screenText to do shell script "pbpaste"
		log "Clipboard length: " & (length of screenText) & " characters"
		
		log "Step 8: Validating capture..."
		set validation to validateCapture(screenText)
		if not validation's valid then
			log "Error: Capture validation failed - " & validation's reason
			return {success:false, message:validation's reason, screenText:screenText}
		end if
		
		log "✓ Screen capture successful: " & (length of screenText) & " characters"
		log "=========================================="
		
		return {success:true, screenText:screenText, message:"Screen captured"}
		
	on error errMsg number errNum
		log "Error in captureScreen: " & errMsg & " (Error " & errNum & ")"
		return {success:false, message:errMsg, errorNumber:errNum, screenText:""}
	end try
end captureScreen

-- Validate captured screen content
-- Parameters:
--   screenText: String content to validate
-- Returns:
--   Record with {valid:boolean, length:integer, reason:string}
-- Example: set validation to validateCapture(screenText)
on validateCapture(screenText)
	try
		-- Check if content exists
		if screenText is missing value then
			return {valid:false, length:0, reason:"Screen text is missing value"}
		end if
		
		-- Check if content is empty
		if screenText is "" then
			return {valid:false, length:0, reason:"Screen text is empty"}
		end if
		
		-- Check minimum length
		set contentLength to length of screenText
		if contentLength < minScreenContentLength then
			return {valid:false, length:contentLength, reason:"Content too short (minimum " & minScreenContentLength & " characters)"}
		end if
		
		-- Check for common capture errors
		if screenText contains "pbpaste" or screenText contains "command not found" then
			return {valid:false, length:contentLength, reason:"Clipboard command error detected"}
		end if
		
		-- Check if content looks like screen text (has multiple lines)
		if screenText does not contain return and screenText does not contain linefeed then
			return {valid:false, length:contentLength, reason:"Content appears to be single line (expected multi-line screen)"}
		end if
		
		-- Content is valid
		log "✓ Screen capture validation passed: " & contentLength & " characters"
		return {valid:true, length:contentLength, reason:"Valid screen content"}
		
	on error errMsg number errNum
		log "Error in validateCapture: " & errMsg & " (Error " & errNum & ")"
		return {valid:false, length:0, reason:"Validation error: " & errMsg}
	end try
end validateCapture

-- ============================================================================
-- MOUSE AUTOMATION FUNCTIONS
-- ============================================================================

-- Perform mouse selection from top-left to bottom-right
-- Parameters:
--   bounds: Window bounds record {x, y, width, height}
-- Returns:
--   true if successful, false otherwise
on performMouseSelection(bounds)
	try
		-- Calculate selection coordinates
		set startX to (bounds's x) + selectionMarginLeft
		set startY to (bounds's y) + selectionMarginTop
		set endX to (bounds's x) + (bounds's width) - selectionMarginRight
		set endY to (bounds's y) + (bounds's height) - selectionMarginBottom
		
		log "Selection coordinates: (" & startX & "," & startY & ") to (" & endX & "," & endY & ")"
		
		tell application "System Events"
			-- Move to start position
			set mouseLocation to {startX, startY}
			
			-- Perform mouse drag (click and hold, move, release)
			-- Note: AppleScript doesn't have native drag, so we use cliclick or similar
			-- For now, we'll use a shell script approach
		end tell
		
		-- Use Python mouse control script
		try
			set scriptPath to (do shell script "cd " & quoted form of (POSIX path of (path to me)) & "/../.. && pwd") & "/src/utils/mouse_control.py"
			set dragCommand to "python3 " & quoted form of scriptPath & " drag " & startX & " " & startY & " " & endX & " " & endY
			do shell script dragCommand
			log "✓ Mouse selection performed using Python script"
		on error errMsg
			log "Error with Python mouse control: " & errMsg
			
			-- Try cliclick as fallback
			try
				do shell script "which cliclick"
				set dragCommand to "cliclick m:" & startX & "," & startY & " dd:" & startX & "," & startY & " w:100 m:" & endX & "," & endY & " du:" & endX & "," & endY
				do shell script dragCommand
				log "✓ Mouse selection performed using cliclick"
			on error
				log "Error: No mouse control method available"
				return false
			end try
		end try
		
		-- Wait for selection to complete
		delay mouseClickDelay
		
		return true
		
	on error errMsg number errNum
		log "Error in performMouseSelection: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end performMouseSelection

-- Click toolbar copy button
-- Parameters:
--   bounds: Window bounds record {x, y, width, height}
-- Returns:
--   true if successful, false otherwise
on clickToolbarCopyButton(bounds)
	try
		-- Calculate button coordinates
		set buttonX to (bounds's x) + toolbarCopyButtonX
		set buttonY to (bounds's y) + toolbarCopyButtonY
		
		log "Clicking copy button at: (" & buttonX & "," & buttonY & ")"
		
		-- Try cliclick first
		try
			set clickCommand to "cliclick c:" & buttonX & "," & buttonY
			do shell script clickCommand
			log "✓ Toolbar copy button clicked using cliclick"
		on error
			-- Try keyboard shortcut as fallback (Ctrl+C for HOD)
			log "Attempting keyboard shortcut fallback (Ctrl+C for HOD)..."
			tell application "System Events"
				keystroke "c" using control down
			end tell
			log "✓ Used keyboard shortcut fallback"
		end try
		
		-- Wait for copy operation to complete
		delay mouseClickDelay
		
		return true
		
	on error errMsg number errNum
		log "Error in clickToolbarCopyButton: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end clickToolbarCopyButton

-- ============================================================================
-- ADVANCED CAPTURE FUNCTIONS
-- ============================================================================

-- Capture screen with retry logic
-- Parameters:
--   windowRef: Window reference record
--   retries: Number of retry attempts (default: captureRetries)
-- Returns:
--   Screen text as string, or missing value on error
on captureScreenWithRetry(windowRef, retries)
	try
		if retries is missing value then
			set retries to captureRetries
		end if
		
		log "Capturing screen with retry (max " & retries & " attempts)..."
		
		repeat with attempt from 1 to retries
			log "Capture attempt " & attempt & " of " & retries
			
			set screenText to captureScreen(windowRef)
			
			if screenText is not missing value then
				log "✓ Screen capture successful on attempt " & attempt
				return screenText
			end if
			
			-- Wait before retry (exponential backoff)
			if attempt < retries then
				set waitTime to attempt * 0.5
				log "Waiting " & waitTime & " seconds before retry..."
				delay waitTime
			end if
		end repeat
		
		log "✗ Screen capture failed after " & retries & " attempts"
		return missing value
		
	on error errMsg number errNum
		log "Error in captureScreenWithRetry: " & errMsg & " (Error " & errNum & ")"
		return missing value
	end try
end captureScreenWithRetry

-- Capture specific region of screen
-- Parameters:
--   windowRef: Window reference record
--   region: Record with {top, left, bottom, right} margins
-- Returns:
--   Screen text as string, or missing value on error
on captureScreenRegion(windowRef, region)
	try
		-- Save current margins
		set savedTop to selectionMarginTop
		set savedLeft to selectionMarginLeft
		set savedRight to selectionMarginRight
		set savedBottom to selectionMarginBottom
		
		-- Set custom margins
		set selectionMarginTop to |top| of region
		set selectionMarginLeft to |left| of region
		set selectionMarginRight to |right| of region
		set selectionMarginBottom to |bottom| of region
		
		-- Perform capture
		set screenText to captureScreen(windowRef)
		
		-- Restore original margins
		set selectionMarginTop to savedTop
		set selectionMarginLeft to savedLeft
		set selectionMarginRight to savedRight
		set selectionMarginBottom to savedBottom
		
		return screenText
		
	on error errMsg number errNum
		log "Error in captureScreenRegion: " & errMsg & " (Error " & errNum & ")"
		
		-- Restore original margins on error
		set selectionMarginTop to savedTop
		set selectionMarginLeft to savedLeft
		set selectionMarginRight to savedRight
		set selectionMarginBottom to savedBottom
		
		return missing value
	end try
end captureScreenRegion

-- ============================================================================
-- CONFIGURATION FUNCTIONS
-- ============================================================================

-- Set toolbar copy button coordinates
-- Parameters:
--   x: X offset from window left edge
--   y: Y offset from window top edge
on setToolbarCopyButtonCoordinates(x, y)
	set toolbarCopyButtonX to x
	set toolbarCopyButtonY to y
	log "Toolbar copy button coordinates set to: (" & x & "," & y & ")"
end setToolbarCopyButtonCoordinates

-- Set selection margins
-- Parameters:
--   margins: Record with {top, left, right, bottom}
on setSelectionMargins(margins)
	set selectionMarginTop to |top| of margins
	set selectionMarginLeft to |left| of margins
	set selectionMarginRight to |right| of margins
	set selectionMarginBottom to |bottom| of margins
	log "Selection margins set to: top=" & (|top| of margins) & ", left=" & (|left| of margins) & ", right=" & (|right| of margins) & ", bottom=" & (|bottom| of margins)
end setSelectionMargins

-- Set mouse click delay
-- Parameters:
--   delaySeconds: Delay in seconds after mouse clicks
on setMouseClickDelay(delaySeconds)
	set mouseClickDelay to delaySeconds
	log "Mouse click delay set to: " & delaySeconds & " seconds"
end setMouseClickDelay

-- Set minimum screen content length
-- Parameters:
--   length: Minimum number of characters for valid screen
on setMinScreenContentLength(length)
	set minScreenContentLength to length
	log "Minimum screen content length set to: " & length
end setMinScreenContentLength

-- ============================================================================
-- CALIBRATION FUNCTIONS
-- ============================================================================

-- Calibrate toolbar copy button position
-- Interactive function to help user find correct button coordinates
-- Parameters:
--   windowRef: Window reference record
-- Returns:
--   Record with {x, y} coordinates
on calibrateToolbarButton(windowRef)
	try
		log "=========================================="
		log "Starting toolbar button calibration..."
		log "=========================================="
		
		-- Get window bounds
		set bounds to windowManager's getWindowBounds(windowRef)
		if bounds is missing value then
			log "Error: Could not get window bounds"
			return missing value
		end if
		
		-- Try different positions
		set testPositions to {{x:80, y:30}, {x:100, y:30}, {x:120, y:30}, {x:100, y:40}, {x:100, y:50}}
		
		repeat with pos in testPositions
			log "Testing position: x=" & (pos's x) & ", y=" & (pos's y)
			
			-- Set test position
			set toolbarCopyButtonX to pos's x
			set toolbarCopyButtonY to pos's y
			
			-- Try capture
			set screenText to captureScreen(windowRef)
			
			if screenText is not missing value then
				log "✓ Calibration successful at: x=" & (pos's x) & ", y=" & (pos's y)
				return pos
			end if
			
			delay 1
		end repeat
		
		log "✗ Calibration failed - could not find working position"
		return missing value
		
	on error errMsg number errNum
		log "Error in calibrateToolbarButton: " & errMsg & " (Error " & errNum & ")"
		return missing value
	end try
end calibrateToolbarButton

-- ============================================================================
-- TESTING FUNCTIONS
-- ============================================================================

-- Test screen capture functionality
-- Parameters:
--   sessionLetter: Session letter to test (e.g., "A")
-- Returns: true if all tests pass
on runTests(sessionLetter)
	log "=========================================="
	log "Running Screen Capture Tests"
	log "=========================================="
	
	set testsPassed to 0
	set testsFailed to 0
	
	-- Test 1: Find window
	log "Test 1: Finding HOD window..."
	-- set windowRef to findHODWindow(sessionLetter)
	set windowRef to missing value -- Placeholder for compilation
	if windowRef is not missing value then
		log "✓ Test 1 PASSED: Found window"
		set testsPassed to testsPassed + 1
		
		-- Test 2: Capture screen
		log "Test 2: Capturing screen..."
		set screenText to captureScreen(windowRef)
		if screenText is not missing value then
			log "✓ Test 2 PASSED: Screen captured (" & (length of screenText) & " chars)"
			set testsPassed to testsPassed + 1
			
			-- Test 3: Validate capture
			log "Test 3: Validating capture..."
			set validation to validateCapture(screenText)
			if validation's valid then
				log "✓ Test 3 PASSED: Validation successful"
				set testsPassed to testsPassed + 1
			else
				log "✗ Test 3 FAILED: " & validation's reason
				set testsFailed to testsFailed + 1
			end if
		else
			log "✗ Test 2 FAILED: Could not capture screen"
			set testsFailed to testsFailed + 1
		end if
	else
		log "✗ Test 1 FAILED: Could not find window"
		set testsFailed to testsFailed + 1
	end if
	
	log "=========================================="
	log "Test Results: " & testsPassed & " passed, " & testsFailed & " failed"
	log "=========================================="
	
	return testsFailed = 0
end runTests

-- ============================================================================
-- END OF SCREEN CAPTURE ENGINE
-- ============================================================================

-- Made with Bob
