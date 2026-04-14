-- ============================================================================
-- Window Manager for IBM Host On-Demand Automation
-- ============================================================================
-- Purpose: Manages HOD window detection, activation, and state management
-- Author: Bob (AI Software Engineer)
-- Phase: 1 - Core Foundation
-- ============================================================================

-- Properties for configuration
property windowTitlePrefix : "GDLVM7 - "
property hodProcessName : "IBM Host On-Demand.app" -- IBM Host On-Demand process name
property activationDelay : 0.1 -- 100ms delay after activation
property windowSearchTimeout : 5 -- seconds to search for window

-- ============================================================================
-- MAIN FUNCTIONS
-- ============================================================================

-- Find HOD window by session letter (A, B, C, etc.)
-- Parameters:
--   sessionLetter: Single character string (e.g., "A", "B")
-- Returns:
--   Window reference or missing value if not found
-- Example: set windowRef to findHODWindow("A")
on findHODWindow(sessionLetter)
	try
		-- Construct the expected window title
		set targetTitle to windowTitlePrefix & sessionLetter
		
		-- Log the search attempt
		log "Searching for HOD window: " & targetTitle
		
		tell application "System Events"
			-- Check if process is running
			if not (exists process hodProcessName) then
				log "Error: " & hodProcessName & " process is not running"
				return missing value
			end if
			
			-- Get process reference first
			set hodProcess to process hodProcessName
			
			tell hodProcess
				-- Get all windows
				set windowCount to count of windows
				
				if windowCount is 0 then
					log "Error: " & hodProcessName & " has no windows"
					return missing value
				end if
				
				-- Method 1: Try direct title match first (fastest)
				try
					set win to window targetTitle
					log "Found HOD window (direct match): " & targetTitle
					return {windowRef:win, processRef:hodProcess, title:targetTitle}
				on error
					-- Direct match failed, try other methods
				end try
				
				-- Method 2: Search using "whose name contains" (most reliable)
				try
					set matchingWindows to (every window whose name contains sessionLetter)
					if (count of matchingWindows) > 0 then
						set win to item 1 of matchingWindows
						set winTitle to name of win
						if winTitle is equal to targetTitle then
							log "Found HOD window (contains match): " & targetTitle
							return {windowRef:win, processRef:hodProcess, title:winTitle}
						end if
					end if
				on error errMsg
					log "Warning: 'whose name contains' method failed - " & errMsg
				end try
				
				-- Method 3: Iterate through all windows (fallback)
				repeat with i from 1 to windowCount
					try
						set win to window i
						set winTitle to name of win
						if winTitle is equal to targetTitle then
							log "Found HOD window (iteration): " & targetTitle
							return {windowRef:win, processRef:hodProcess, title:winTitle}
						end if
					on error errMsg
						log "Warning: Could not access window " & i & " - " & errMsg
					end try
				end repeat
			end tell
		end tell
		
		-- Window not found
		log "Error: HOD window not found: " & targetTitle
		return missing value
		
	on error errMsg number errNum
		log "Error in findHODWindow: " & errMsg & " (Error " & errNum & ")"
		return missing value
	end try
end findHODWindow
-- Get HOD window with success/error format
-- Parameters:
--   sessionLetter: Single character string (e.g., "A", "B")
-- Returns:
--   {success:boolean, windowRef:record, message:string}
on getHODWindow(sessionLetter)
	try
		set windowRef to findHODWindow(sessionLetter)
		if windowRef is not missing value then
			return {success:true, windowRef:windowRef, message:"Window found"}
		else
			return {success:false, message:"Window not found for session " & sessionLetter}
		end if
	on error errMsg
		return {success:false, message:"Error finding window: " & errMsg}
	end try
end getHODWindow


-- Activate HOD window and bring it to front
-- Parameters:
--   windowRef: Window reference record from findHODWindow
-- Returns:
--   true if successful, false otherwise
-- Example: set success to activateHODWindow(windowRef)
on activateHODWindow(windowRef)
	try
		-- Validate input
		if windowRef is missing value then
			log "Error: Cannot activate - window reference is missing value"
			return false
		end if
		
		-- Extract window and process references
		set win to windowRef's windowRef
		set proc to windowRef's processRef
		
		tell application "System Events"
			-- Bring process to front
			set frontmost of proc to true
			
			-- Ensure window is visible and not minimized
			if value of attribute "AXMinimized" of win is true then
				set value of attribute "AXMinimized" of win to false
			end if
			
			-- Raise window to front
			perform action "AXRaise" of win
		end tell
		
		-- Wait for activation to complete
		delay activationDelay
		
		log "Successfully activated window: " & (windowRef's title)
		return true
		
	on error errMsg number errNum
		log "Error in activateHODWindow: " & errMsg & " (Error " & errNum & ")"
		return false
	end try
end activateHODWindow

-- Get window bounds (position and size)
-- Parameters:
--   windowRef: Window reference record from findHODWindow
-- Returns:
--   Record with {x, y, width, height} or missing value on error
-- Example: set bounds to getWindowBounds(windowRef)
on getWindowBounds(windowRef)
	try
		-- Validate input
		if windowRef is missing value then
			log "Error: Cannot get bounds - window reference is missing value"
			return missing value
		end if
		
		-- Extract window reference
		set win to windowRef's windowRef
		
		tell application "System Events"
			-- Get position (top-left corner)
			set winPosition to position of win
			set xPos to item 1 of winPosition
			set yPos to item 2 of winPosition
			
			-- Get size
			set winSize to size of win
			set winWidth to item 1 of winSize
			set winHeight to item 2 of winSize
		end tell
		
		-- Create bounds record
		set bounds to {x:xPos, y:yPos, width:winWidth, height:winHeight}
		
		log "Window bounds: x=" & xPos & ", y=" & yPos & ", width=" & winWidth & ", height=" & winHeight
		
		return bounds
		
	on error errMsg number errNum
		log "Error in getWindowBounds: " & errMsg & " (Error " & errNum & ")"
		return missing value
	end try
end getWindowBounds

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Check if window still exists and is valid
-- Parameters:
--   windowRef: Window reference record from findHODWindow
-- Returns:
--   true if window exists, false otherwise
on isWindowValid(windowRef)
	try
		if windowRef is missing value then
			return false
		end if
		
		set win to windowRef's windowRef
		
		tell application "System Events"
			-- Try to access window title - will fail if window is gone
			set winTitle to name of win
		end tell
		
		return true
		
	on error
		return false
	end try
end isWindowValid

-- Get list of all available HOD sessions
-- Returns:
--   List of session letters (e.g., {"A", "B", "C"})
on getAllHODSessions()
	try
		set sessionList to {}
		
		tell application "System Events"
			-- Check if WSCachedLoader process is running
			if not (exists process hodProcessName) then
				log "Warning: " & hodProcessName & " process is not running"
				return {}
			end if
			
			tell process hodProcessName
				set windowCount to count of windows
				
				if windowCount is 0 then
					log "Warning: " & hodProcessName & " has no windows"
					return {}
				end if
				
				repeat with i from 1 to windowCount
					try
						set win to window i
						set winTitle to name of win
						-- Check if title matches HOD pattern
						if winTitle starts with windowTitlePrefix then
							-- Extract session letter
							set sessionLetter to text ((length of windowTitlePrefix) + 1) of winTitle
							if sessionLetter is not in sessionList then
								set end of sessionList to sessionLetter
							end if
						end if
					on error errMsg
						log "Warning: Could not access window " & i & " - " & errMsg
					end try
				end repeat
			end tell
		end tell
		
		log "Found HOD sessions: " & (sessionList as string)
		return sessionList
		
	on error errMsg number errNum
		log "Error in getAllHODSessions: " & errMsg & " (Error " & errNum & ")"
		return {}
	end try
end getAllHODSessions

-- Wait for window to appear (useful for new sessions)
-- Parameters:
--   sessionLetter: Single character string (e.g., "A")
--   timeoutSeconds: Maximum seconds to wait (default: windowSearchTimeout)
-- Returns:
--   Window reference or missing value if timeout
on waitForHODWindow(sessionLetter, timeoutSeconds)
	try
		if timeoutSeconds is missing value then
			set timeoutSeconds to windowSearchTimeout
		end if
		
		set startTime to current date
		
		repeat
			set windowRef to findHODWindow(sessionLetter)
			if windowRef is not missing value then
				return windowRef
			end if
			
			-- Check timeout
			set elapsedTime to (current date) - startTime
			if elapsedTime ≥ timeoutSeconds then
				log "Timeout waiting for HOD window: " & sessionLetter
				return missing value
			end if
			
			-- Wait before retry
			delay 0.5
		end repeat
		
	on error errMsg number errNum
		log "Error in waitForHODWindow: " & errMsg & " (Error " & errNum & ")"
		return missing value
	end try
end waitForHODWindow

-- ============================================================================
-- CONFIGURATION FUNCTIONS
-- ============================================================================

-- Set custom window title prefix (for different HOD configurations)
-- Parameters:
--   prefix: New window title prefix (e.g., "MYHOST - ")
on setWindowTitlePrefix(prefix)
	set windowTitlePrefix to prefix
	log "Window title prefix set to: " & prefix
end setWindowTitlePrefix

-- Set activation delay (for slower systems)
-- Parameters:
--   delaySeconds: Delay in seconds (e.g., 0.2 for 200ms)
on setActivationDelay(delaySeconds)
	set activationDelay to delaySeconds
	log "Activation delay set to: " & delaySeconds & " seconds"
end setActivationDelay

-- ============================================================================
-- TESTING FUNCTIONS
-- ============================================================================

-- Test window manager functionality
-- Returns: true if all tests pass
on runTests()
	log "=========================================="
	log "Running Window Manager Tests"
	log "=========================================="
	
	set testsPassed to 0
	set testsFailed to 0
	
	-- Test 1: Find all HOD sessions
	log "Test 1: Finding all HOD sessions..."
	set sessions to getAllHODSessions()
	if (count of sessions) > 0 then
		log "✓ Test 1 PASSED: Found " & (count of sessions) & " session(s)"
		set testsPassed to testsPassed + 1
	else
		log "✗ Test 1 FAILED: No sessions found"
		set testsFailed to testsFailed + 1
	end if
	
	-- Test 2: Find specific window (if sessions exist)
	if (count of sessions) > 0 then
		log "Test 2: Finding specific window..."
		set testSession to item 1 of sessions
		set windowRef to findHODWindow(testSession)
		if windowRef is not missing value then
			log "✓ Test 2 PASSED: Found window for session " & testSession
			set testsPassed to testsPassed + 1
			
			-- Test 3: Activate window
			log "Test 3: Activating window..."
			set activated to activateHODWindow(windowRef)
			if activated then
				log "✓ Test 3 PASSED: Window activated"
				set testsPassed to testsPassed + 1
			else
				log "✗ Test 3 FAILED: Could not activate window"
				set testsFailed to testsFailed + 1
			end if
			
			-- Test 4: Get window bounds
			log "Test 4: Getting window bounds..."
			set bounds to getWindowBounds(windowRef)
			if bounds is not missing value then
				log "✓ Test 4 PASSED: Got window bounds"
				set testsPassed to testsPassed + 1
			else
				log "✗ Test 4 FAILED: Could not get bounds"
				set testsFailed to testsFailed + 1
			end if
			
			-- Test 5: Validate window
			log "Test 5: Validating window..."
			set valid to isWindowValid(windowRef)
			if valid then
				log "✓ Test 5 PASSED: Window is valid"
				set testsPassed to testsPassed + 1
			else
				log "✗ Test 5 FAILED: Window is not valid"
				set testsFailed to testsFailed + 1
			end if
		else
			log "✗ Test 2 FAILED: Could not find window"
			set testsFailed to testsFailed + 1
		end if
	end if
	
	log "=========================================="
	log "Test Results: " & testsPassed & " passed, " & testsFailed & " failed"
	log "=========================================="
	
	return testsFailed = 0
end runTests

-- ============================================================================
-- END OF WINDOW MANAGER
-- ============================================================================

-- Made with Bob
