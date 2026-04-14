-- Error Handler Module
-- Comprehensive error handling and recovery for IBM Host On-Demand automation
-- Handles transient, session, navigation, and fatal errors with automatic recovery

-- Error Categories
property ERROR_TRANSIENT : "transient" -- Temporary issues (retry)
property ERROR_SESSION : "session" -- Session-level issues (reconnect)
property ERROR_NAVIGATION : "navigation" -- Navigation issues (backtrack)
property ERROR_FATAL : "fatal" -- Unrecoverable errors

-- Retry Configuration
property MAX_RETRIES : 3
property INITIAL_BACKOFF : 0.5 -- 500ms
property MAX_BACKOFF : 2.0 -- 2000ms

-- Main error handler routing
-- @param errorType: Type of error (capture_failure, freeze, unexpected_screen, timeout, generic)
-- @param errorDetails: Record with error details
-- @param windowRef: Reference to HOD window
-- @return: {success:boolean, recovered:boolean, message:string}
on handleError(errorType, errorDetails, windowRef)
	try
		log "ERROR HANDLER: Processing " & errorType & " error"
		
		-- Route to appropriate recovery handler
		if errorType is "capture_failure" then
			return recoverFromCaptureFailure(windowRef)
		else if errorType is "freeze" then
			return recoverFromFreeze(windowRef)
		else if errorType is "unexpected_screen" then
			return recoverFromUnexpectedScreen(windowRef, errorDetails's screenData)
		else if errorType is "timeout" then
			return recoverFromTimeout(windowRef)
		else
			return genericRecovery(windowRef)
		end if
		
	on error errMsg number errNum
		log "ERROR HANDLER: Critical failure - " & errMsg
		return {success:false, recovered:false, message:"Error handler failed: " & errMsg, errorNumber:errNum}
	end try
end handleError

-- Recover from screen capture failure with exponential backoff
-- @param windowRef: Reference to HOD window
-- @return: {success:boolean, recovered:boolean, attempts:integer}
on recoverFromCaptureFailure(windowRef)
	try
		log "RECOVERY: Attempting capture failure recovery"
		
		set retryCount to 0
		set backoffDelay to INITIAL_BACKOFF
		
		repeat while retryCount < MAX_RETRIES
			set retryCount to retryCount + 1
			log "RECOVERY: Capture retry attempt " & retryCount & " of " & MAX_RETRIES
			
			-- Wait with exponential backoff
			delay backoffDelay
			
			-- Attempt to capture screen
			try
				tell application "System Events"
					tell process "HOD"
						set windowContent to value of static text 1 of windowRef
						if windowContent is not "" then
							log "RECOVERY: Capture successful on attempt " & retryCount
							return {success:true, recovered:true, attempts:retryCount, message:"Recovered after " & retryCount & " attempts"}
						end if
					end tell
				end tell
			on error
				-- Capture failed, continue retry loop
			end try
			
			-- Increase backoff delay (exponential)
			set backoffDelay to backoffDelay * 2
			if backoffDelay > MAX_BACKOFF then
				set backoffDelay to MAX_BACKOFF
			end if
		end repeat
		
		log "RECOVERY: Capture failure - max retries exceeded"
		return {success:false, recovered:false, attempts:retryCount, message:"Capture failed after " & MAX_RETRIES & " attempts"}
		
	on error errMsg number errNum
		log "RECOVERY: Capture recovery failed - " & errMsg
		return {success:false, recovered:false, message:"Recovery error: " & errMsg, errorNumber:errNum}
	end try
end recoverFromCaptureFailure

-- Recover from system freeze by sending Attn key
-- @param windowRef: Reference to HOD window
-- @return: {success:boolean, recovered:boolean, message:string}
on recoverFromFreeze(windowRef)
	try
		log "RECOVERY: Attempting freeze recovery with Attn key"
		
		-- Send Attn key (Escape in HOD)
		tell application "System Events"
			tell process "HOD"
				set frontmost to true
				delay 0.3
				keystroke "c" using {control down} -- Ctrl+C for Attn
				delay 1.0
			end tell
		end tell
		
		-- Verify recovery by checking for prompt
		delay 0.5
		try
			tell application "System Events"
				tell process "HOD"
					set screenContent to value of static text 1 of windowRef
					if screenContent contains "Ready;" or screenContent contains "VM READ" then
						log "RECOVERY: Freeze recovered - system responsive"
						return {success:true, recovered:true, message:"System recovered from freeze"}
					end if
				end tell
			end tell
		end try
		
		-- If still frozen, try generic recovery
		log "RECOVERY: Attn key insufficient, trying generic recovery"
		return genericRecovery(windowRef)
		
	on error errMsg number errNum
		log "RECOVERY: Freeze recovery failed - " & errMsg
		return {success:false, recovered:false, message:"Freeze recovery error: " & errMsg, errorNumber:errNum}
	end try
end recoverFromFreeze

-- Recover from unexpected screen by navigating back to known state
-- @param windowRef: Reference to HOD window
-- @param screenData: Current screen data
-- @return: {success:boolean, recovered:boolean, message:string}
on recoverFromUnexpectedScreen(windowRef, screenData)
	try
		log "RECOVERY: Attempting unexpected screen recovery"
		
		-- Try PF3 (back) multiple times
		set backAttempts to 0
		repeat while backAttempts < 3
			set backAttempts to backAttempts + 1
			log "RECOVERY: Pressing PF3 (back), attempt " & backAttempts
			
			tell application "System Events"
				tell process "HOD"
					set frontmost to true
					delay 0.2
					key code 99 -- F3
					delay 1.0
				end tell
			end tell
			
			-- Check if we reached a known screen
			delay 0.5
			try
				tell application "System Events"
					tell process "HOD"
						set screenContent to value of static text 1 of windowRef
						if screenContent contains "Ready;" or screenContent contains "FILELIST" or screenContent contains "NETLOG" then
							log "RECOVERY: Reached known screen after " & backAttempts & " back attempts"
							return {success:true, recovered:true, message:"Navigated back to known state", attempts:backAttempts}
						end if
					end tell
				end tell
			end try
		end repeat
		
		-- If PF3 didn't work, try generic recovery
		log "RECOVERY: PF3 navigation insufficient, trying generic recovery"
		return genericRecovery(windowRef)
		
	on error errMsg number errNum
		log "RECOVERY: Unexpected screen recovery failed - " & errMsg
		return {success:false, recovered:false, message:"Navigation recovery error: " & errMsg, errorNumber:errNum}
	end try
end recoverFromUnexpectedScreen

-- Recover from timeout
-- @param windowRef: Reference to HOD window
-- @return: {success:boolean, recovered:boolean, message:string}
on recoverFromTimeout(windowRef)
	try
		log "RECOVERY: Attempting timeout recovery"
		
		-- First try to check if operation actually completed
		delay 1.0
		try
			tell application "System Events"
				tell process "HOD"
					set screenContent to value of static text 1 of windowRef
					if screenContent contains "Ready;" or screenContent contains "More..." then
						log "RECOVERY: Operation completed despite timeout"
						return {success:true, recovered:true, message:"Operation completed (false timeout)"}
					end if
				end tell
			end tell
		end try
		
		-- If still waiting, send Enter to potentially complete
		log "RECOVERY: Sending Enter to complete operation"
		tell application "System Events"
			tell process "HOD"
				set frontmost to true
				delay 0.2
				keystroke return
				delay 1.5
			end tell
		end tell
		
		-- Check again
		try
			tell application "System Events"
				tell process "HOD"
					set screenContent to value of static text 1 of windowRef
					if screenContent contains "Ready;" then
						log "RECOVERY: Timeout recovered with Enter"
						return {success:true, recovered:true, message:"Recovered from timeout"}
					end if
				end tell
			end tell
		end try
		
		-- Last resort: generic recovery
		log "RECOVERY: Timeout persists, trying generic recovery"
		return genericRecovery(windowRef)
		
	on error errMsg number errNum
		log "RECOVERY: Timeout recovery failed - " & errMsg
		return {success:false, recovered:false, message:"Timeout recovery error: " & errMsg, errorNumber:errNum}
	end try
end recoverFromTimeout

-- Generic recovery sequence: Attn → PF3 → Enter
-- Last resort recovery for unknown errors
-- @param windowRef: Reference to HOD window
-- @return: {success:boolean, recovered:boolean, message:string}
on genericRecovery(windowRef)
	try
		log "RECOVERY: Executing generic recovery sequence"
		
		tell application "System Events"
			tell process "HOD"
				set frontmost to true
				delay 0.3
				
				-- Step 1: Send Attn (Ctrl+C)
				log "RECOVERY: Step 1 - Sending Attn"
				keystroke "c" using {control down}
				delay 1.0
				
				-- Step 2: Send PF3 (back)
				log "RECOVERY: Step 2 - Sending PF3"
				key code 99 -- F3
				delay 1.0
				
				-- Step 3: Send Enter
				log "RECOVERY: Step 3 - Sending Enter"
				keystroke return
				delay 1.5
			end tell
		end tell
		
		-- Verify we're at a stable state
		delay 0.5
		try
			tell application "System Events"
				tell process "HOD"
					set screenContent to value of static text 1 of windowRef
					if screenContent contains "Ready;" then
						log "RECOVERY: Generic recovery successful - at CMS prompt"
						return {success:true, recovered:true, message:"Generic recovery successful"}
					else if screenContent contains "FILELIST" or screenContent contains "NETLOG" then
						log "RECOVERY: Generic recovery successful - at known screen"
						return {success:true, recovered:true, message:"Generic recovery successful"}
					else
						log "RECOVERY: Generic recovery completed but state uncertain"
						return {success:true, recovered:true, message:"Recovery attempted, state uncertain", hasWarning:true}
					end if
				end tell
			end tell
		end try
		
		log "RECOVERY: Generic recovery failed to reach stable state"
		return {success:false, recovered:false, message:"Generic recovery failed"}
		
	on error errMsg number errNum
		log "RECOVERY: Generic recovery failed - " & errMsg
		return {success:false, recovered:false, message:"Generic recovery error: " & errMsg, errorNumber:errNum}
	end try
end genericRecovery

-- Execute operation with timeout wrapper
-- @param operation: Handler to execute
-- @param timeoutSeconds: Timeout in seconds
-- @return: Result from operation or timeout error
on executeWithTimeout(operation, timeoutSeconds)
	try
		set startTime to current date
		set timeoutTime to startTime + timeoutSeconds
		
		-- Execute operation
		set result to operation()
		
		-- Check if we exceeded timeout
		set endTime to current date
		set elapsed to endTime - startTime
		
		if elapsed > timeoutSeconds then
			log "TIMEOUT: Operation exceeded " & timeoutSeconds & " seconds"
			return {success:false, timedOut:true, elapsed:elapsed, message:"Operation timed out"}
		end if
		
		return result
		
	on error errMsg number errNum
		log "TIMEOUT WRAPPER: Error - " & errMsg
		return {success:false, hasError:true, message:errMsg, errorNumber:errNum}
	end try
end executeWithTimeout

-- Categorize error type
-- @param errorMsg: Error message
-- @return: Error category (transient, session, navigation, fatal)
on categorizeError(errorMsg)
	set errorMsg to errorMsg as string
	
	-- Transient errors (retry)
	if errorMsg contains "timeout" or errorMsg contains "busy" or errorMsg contains "not responding" then
		return ERROR_TRANSIENT
	end if
	
	-- Session errors (reconnect)
	if errorMsg contains "connection" or errorMsg contains "session" or errorMsg contains "disconnected" then
		return ERROR_SESSION
	end if
	
	-- Navigation errors (backtrack)
	if errorMsg contains "unexpected screen" or errorMsg contains "wrong screen" or errorMsg contains "navigation" then
		return ERROR_NAVIGATION
	end if
	
	-- Default to fatal
	return ERROR_FATAL
end categorizeError

-- Calculate retry delay with exponential backoff
-- @param attemptNumber: Current attempt number (1-based)
-- @return: Delay in seconds
on calculateBackoff(attemptNumber)
	set backoff to INITIAL_BACKOFF * (2 ^ (attemptNumber - 1))
	if backoff > MAX_BACKOFF then
		set backoff to MAX_BACKOFF
	end if
	return backoff
end calculateBackoff

-- Check if error is recoverable
-- @param errorCategory: Error category
-- @return: Boolean indicating if recoverable
on isRecoverable(errorCategory)
	return errorCategory is not ERROR_FATAL
end isRecoverable

log "Error Handler Module Loaded"

-- Made with Bob
