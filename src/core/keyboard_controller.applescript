-- ============================================================================
-- Keyboard Controller for IBM Host On-Demand Automation
-- ============================================================================
-- Purpose: Handles all keyboard input to HOD windows including PF keys
-- Author: Bob (AI Software Engineer)
-- Phase: 2 - Screen Interaction
-- ============================================================================

-- Note: This script requires window_manager.applescript to be loaded separately
-- In production, use: set windowManager to load script (path to window_manager)

-- Properties for configuration
property keystrokeDelay : 0.05 -- 50ms delay between keystrokes
property postEnterDelay : 0.5 -- 500ms delay after Enter (command processing)
property postPFKeyDelay : 0.2 -- 200ms delay after PF keys (screen transition)
property postTabDelay : 0.1 -- 100ms delay after Tab
property postClearDelay : 0.3 -- 300ms delay after Clear
property activationDelay : 0.1 -- 100ms delay after window activation

-- PF Key mappings (Fn+F1 through Fn+F12)
-- These are the key codes for function keys on macOS
property pfKeyMap : {¬
	{pfKey:1, keyCode:122, name:"PF1 (F1)"}, ¬
	{pfKey:2, keyCode:120, name:"PF2 (F2)"}, ¬
	{pfKey:3, keyCode:99, name:"PF3 (F3)"}, ¬
	{pfKey:4, keyCode:118, name:"PF4 (F4)"}, ¬
	{pfKey:5, keyCode:96, name:"PF5 (F5)"}, ¬
	{pfKey:6, keyCode:97, name:"PF6 (F6)"}, ¬
	{pfKey:7, keyCode:98, name:"PF7 (F7)"}, ¬
	{pfKey:8, keyCode:100, name:"PF8 (F8)"}, ¬
	{pfKey:9, keyCode:101, name:"PF9 (F9)"}, ¬
	{pfKey:10, keyCode:109, name:"PF10 (F10)"}, ¬
	{pfKey:11, keyCode:103, name:"PF11 (F11)"}, ¬
	{pfKey:12, keyCode:111, name:"PF12 (F12)"}}

-- Special key codes
property enterKeyCode : 36
property tabKeyCode : 48
property escapeKeyCode : 53
property deleteKeyCode : 51

-- ============================================================================
-- MAIN FUNCTIONS
-- ============================================================================

-- Type text into HOD window
-- Parameters:
--   windowRef: Window reference record from window_manager
--   text: String to type
-- Returns:
--   true if successful, false otherwise
-- Example: set success to typeText(windowRef, "FILELIST")
on typeText(windowRef, text)
	try
		-- Validate inputs
		if windowRef is missing value then
			log "Error: Invalid window reference"
			return false
		end if
		
		if text is "" then
			log "Warning: Empty text provided"
			return true
		end if
		
		log "Typing text: \"" & text & "\""
		
		-- Activate window (requires window_manager functions)
		-- In production, this would call windowManager's activateHODWindow
		-- For now, we assume the window is already active
		-- set activated to activateHODWindow(windowRef)
		-- if not activated then
		-- 	log "Error: Could not activate window"
		-- 	return false
		-- end if
		
		delay activationDelay
		
		-- Type the text
		tell application "System Events"
			keystroke text
		end tell
		
		-- Wait for text to be processed
		delay keystrokeDelay
		
		log "✓ Text typed successfully"
		return true
		
	on error errMsg number errNum
		log "Error in typeText: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end typeText

-- Press Enter key
-- Parameters:
--   windowRef: Window reference record from window_manager
-- Returns:
--   true if successful, false otherwise
-- Example: set success to pressEnter(windowRef)
on pressEnter(windowRef)
	try
		log "Pressing Enter key..."
		
		-- Activate window (requires window_manager functions)
		-- In production, this would call windowManager's activateHODWindow
		
		delay activationDelay
		
		-- Press Enter
		tell application "System Events"
			key code enterKeyCode
		end tell
		
		-- Wait for command processing
		delay postEnterDelay
		
		log "✓ Enter key pressed"
		return true
		
	on error errMsg number errNum
		log "Error in pressEnter: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end pressEnter

-- Press Tab key
-- Parameters:
--   windowRef: Window reference record from window_manager
-- Returns:
--   true if successful, false otherwise
-- Example: set success to pressTab(windowRef)
on pressTab(windowRef)
	try
		log "Pressing Tab key..."
		
		-- Activate window (requires window_manager functions)
		
		delay activationDelay
		
		-- Press Tab
		tell application "System Events"
			key code tabKeyCode
		end tell
		
		-- Wait for tab processing
		delay postTabDelay
		
		log "✓ Tab key pressed"
		return true
		
	on error errMsg number errNum
		log "Error in pressTab: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end pressTab

-- Press Clear key (Cmd+Delete)
-- Parameters:
--   windowRef: Window reference record from window_manager
-- Returns:
--   true if successful, false otherwise
-- Example: set success to pressClear(windowRef)
on pressClear(windowRef)
	try
		log "Pressing Clear key (Cmd+Delete)..."
		
		-- Activate window (requires window_manager functions)
		
		delay activationDelay
		
		-- Press Cmd+Delete
		tell application "System Events"
			key code deleteKeyCode using command down
		end tell
		
		-- Wait for clear processing
		delay postClearDelay
		
		log "✓ Clear key pressed"
		return true
		
	on error errMsg number errNum
		log "Error in pressClear: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end pressClear

-- Press PF key (Fn+F1 through Fn+F12)
-- Parameters:
--   windowRef: Window reference record from window_manager
--   keyNumber: PF key number (1-12)
-- Returns:
--   true if successful, false otherwise
-- Example: set success to pressPFKey(windowRef, 3) -- Press PF3
on pressPFKey(windowRef, keyNumber)
	try
		-- Validate key number
		if keyNumber < 1 or keyNumber > 12 then
			log "Error: Invalid PF key number: " & keyNumber & " (must be 1-12)"
			return false
		end if
		
		-- Get key code for this PF key
		set keyInfo to missing value
		repeat with mapping in pfKeyMap
			if mapping's pfKey = keyNumber then
				set keyInfo to mapping
				exit repeat
			end if
		end repeat
		
		if keyInfo is missing value then
			log "Error: Could not find mapping for PF" & keyNumber
			return false
		end if
		
		log "Pressing " & (keyInfo's name) & "..."
		
		-- Activate window (requires window_manager functions)
		
		delay activationDelay
		
		-- Press the function key (Fn is implicit on Mac keyboards)
		tell application "System Events"
			key code (keyInfo's keyCode)
		end tell
		
		-- Wait for screen transition
		delay postPFKeyDelay
		
		log "✓ " & (keyInfo's name) & " pressed"
		return true
		
	on error errMsg number errNum
		log "Error in pressPFKey: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end pressPFKey

-- Press Attn key (Escape key - placeholder for user configuration)
-- Parameters:
--   windowRef: Window reference record from window_manager
-- Returns:
--   true if successful, false otherwise
-- Example: set success to pressAttn(windowRef)
on pressAttn(windowRef)
	try
		log "Pressing Attn key (Escape)..."
		log "Note: Attn key mapping may need configuration for your HOD setup"
		
		-- Activate window (requires window_manager functions)
		
		delay activationDelay
		
		-- Press Escape (default Attn mapping)
		tell application "System Events"
			key code escapeKeyCode
		end tell
		
		-- Wait for Attn processing
		delay postEnterDelay
		
		log "✓ Attn key pressed"
		return true
		
	on error errMsg number errNum
		log "Error in pressAttn: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end pressAttn

-- ============================================================================
-- ADVANCED FUNCTIONS
-- ============================================================================

-- Type text and press Enter
-- Parameters:
--   windowRef: Window reference record
--   text: String to type
-- Returns:
--   true if successful, false otherwise
on typeTextAndEnter(windowRef, text)
	try
		log "Typing text and pressing Enter: \"" & text & "\""
		
		set typed to typeText(windowRef, text)
		if not typed then
			return false
		end if
		
		set entered to pressEnter(windowRef)
		return entered
		
	on error errMsg number errNum
		log "Error in typeTextAndEnter: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end typeTextAndEnter

-- Type multiple lines of text
-- Parameters:
--   windowRef: Window reference record
--   linesList: List of strings to type (each followed by Enter)
-- Returns:
--   true if successful, false otherwise
on typeMultipleLines(windowRef, linesList)
	try
		log "Typing " & (count of linesList) & " lines..."
		
		repeat with lineText in linesList
			set success to typeTextAndEnter(windowRef, lineText)
			if not success then
				log "Error: Failed to type line: \"" & lineText & "\""
				return false
			end if
		end repeat
		
		log "✓ All lines typed successfully"
		return true
		
	on error errMsg number errNum
		log "Error in typeMultipleLines: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end typeMultipleLines

-- Press multiple PF keys in sequence
-- Parameters:
--   windowRef: Window reference record
--   keyNumbers: List of PF key numbers
-- Returns:
--   true if successful, false otherwise
on pressPFKeySequence(windowRef, keyNumbers)
	try
		log "Pressing PF key sequence: " & (keyNumbers as string)
		
		repeat with keyNum in keyNumbers
			set success to pressPFKey(windowRef, keyNum)
			if not success then
				log "Error: Failed to press PF" & keyNum
				return false
			end if
		end repeat
		
		log "✓ PF key sequence completed"
		return true
		
	on error errMsg number errNum
		log "Error in pressPFKeySequence: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end pressPFKeySequence

-- Send command (type text + Enter)
-- Alias for typeTextAndEnter for better semantics
-- Parameters:
--   windowRef: Window reference record
--   command: Command string to send
-- Returns:
--   true if successful, false otherwise
on sendCommand(windowRef, command)
	return typeTextAndEnter(windowRef, command)
end sendCommand

-- Navigate using PF keys (common navigation patterns)
-- Parameters:
--   windowRef: Window reference record
--   action: String action name ("back", "forward", "quit", "help", etc.)
-- Returns:
--   true if successful, false otherwise
on navigate(windowRef, action)
	try
		log "Navigating: " & action
		
		-- Map common actions to PF keys
		if action is "back" or action is "quit" then
			return pressPFKey(windowRef, 3) -- PF3 = Quit/Back
		else if action is "forward" or action is "next" then
			return pressPFKey(windowRef, 8) -- PF8 = Forward
		else if action is "backward" or action is "previous" then
			return pressPFKey(windowRef, 7) -- PF7 = Backward
		else if action is "help" then
			return pressPFKey(windowRef, 1) -- PF1 = Help
		else if action is "refresh" or action is "retrieve" then
			return pressPFKey(windowRef, 12) -- PF12 = Retrieve
		else
			log "Error: Unknown navigation action: " & action
			return false
		end if
		
	on error errMsg number errNum
		log "Error in navigate: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end navigate

-- ============================================================================
-- CONFIGURATION FUNCTIONS
-- ============================================================================

-- Set keystroke delay
-- Parameters:
--   delaySeconds: Delay in seconds between keystrokes
on setKeystrokeDelay(delaySeconds)
	set keystrokeDelay to delaySeconds
	log "Keystroke delay set to: " & delaySeconds & " seconds"
end setKeystrokeDelay

-- Set post-Enter delay
-- Parameters:
--   delaySeconds: Delay in seconds after Enter key
on setPostEnterDelay(delaySeconds)
	set postEnterDelay to delaySeconds
	log "Post-Enter delay set to: " & delaySeconds & " seconds"
end setPostEnterDelay

-- Set post-PF key delay
-- Parameters:
--   delaySeconds: Delay in seconds after PF keys
on setPostPFKeyDelay(delaySeconds)
	set postPFKeyDelay to delaySeconds
	log "Post-PF key delay set to: " & delaySeconds & " seconds"
end setPostPFKeyDelay

-- Set custom Attn key code
-- Parameters:
--   keyCode: Key code for Attn key
on setAttnKeyCode(keyCode)
	set escapeKeyCode to keyCode
	log "Attn key code set to: " & keyCode
end setAttnKeyCode

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get PF key name from number
-- Parameters:
--   keyNumber: PF key number (1-12)
-- Returns:
--   String name of PF key
on getPFKeyName(keyNumber)
	repeat with mapping in pfKeyMap
		if mapping's pfKey = keyNumber then
			return mapping's name
		end if
	end repeat
	return "Unknown PF Key"
end getPFKeyName

-- Get all available PF keys
-- Returns:
--   List of records with PF key information
on getAllPFKeys()
	return pfKeyMap
end getAllPFKeys

-- Test if key code is valid
-- Parameters:
--   keyCode: Key code to test
-- Returns:
--   true if valid, false otherwise
on isValidKeyCode(keyCode)
	try
		tell application "System Events"
			key code keyCode
		end tell
		return true
	on error
		return false
	end try
end isValidKeyCode

-- ============================================================================
-- TESTING FUNCTIONS
-- ============================================================================

-- Test keyboard controller functionality
-- Parameters:
--   sessionLetter: Session letter to test (e.g., "A")
-- Returns: true if all tests pass
on runTests(sessionLetter)
	log "=========================================="
	log "Running Keyboard Controller Tests"
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
		
		-- Test 2: Type text
		log "Test 2: Typing text..."
		set typed to typeText(windowRef, "TEST")
		if typed then
			log "✓ Test 2 PASSED: Text typed"
			set testsPassed to testsPassed + 1
		else
			log "✗ Test 2 FAILED: Could not type text"
			set testsFailed to testsFailed + 1
		end if
		
		-- Test 3: Press Tab
		log "Test 3: Pressing Tab..."
		set tabbed to pressTab(windowRef)
		if tabbed then
			log "✓ Test 3 PASSED: Tab pressed"
			set testsPassed to testsPassed + 1
		else
			log "✗ Test 3 FAILED: Could not press Tab"
			set testsFailed to testsFailed + 1
		end if
		
		-- Test 4: Press PF3 (safe key that usually goes back)
		log "Test 4: Pressing PF3..."
		set pf3pressed to pressPFKey(windowRef, 3)
		if pf3pressed then
			log "✓ Test 4 PASSED: PF3 pressed"
			set testsPassed to testsPassed + 1
		else
			log "✗ Test 4 FAILED: Could not press PF3"
			set testsFailed to testsFailed + 1
		end if
		
		-- Test 5: Get PF key info
		log "Test 5: Getting PF key info..."
		set keyName to getPFKeyName(3)
		if keyName contains "PF3" then
			log "✓ Test 5 PASSED: Got PF key name: " & keyName
			set testsPassed to testsPassed + 1
		else
			log "✗ Test 5 FAILED: Could not get PF key name"
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
-- END OF KEYBOARD CONTROLLER
-- ============================================================================

-- Made with Bob
