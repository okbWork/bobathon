-- Main API Module
-- High-level user-friendly API for IBM Host On-Demand automation
-- Provides simple functions for common operations

-- Load dependencies
property windowManager : load script POSIX file "/Users/okyereboateng/bobathon/src/core/window_manager.scpt"
property screenCapture : load script POSIX file "/Users/okyereboateng/bobathon/src/core/screen_capture.scpt"
property keyboardController : load script POSIX file "/Users/okyereboateng/bobathon/src/core/keyboard_controller.scpt"
property screenParser : load script POSIX file "/Users/okyereboateng/bobathon/src/parsers/screen_parser.scpt"
property decisionEngine : load script POSIX file "/Users/okyereboateng/bobathon/src/engine/decision_engine.scpt"
property workflowExecutor : load script POSIX file "/Users/okyereboateng/bobathon/src/engine/workflow_executor.scpt"
property errorHandler : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/error_handler.scpt"
property logger : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/logger.scpt"
property helpers : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/helpers.scpt"

-- Constants
property MAX_NAVIGATION_STEPS : 20
property MAX_SEARCH_PAGES : 50
property DEFAULT_TIMEOUT : 30

-- Initialize HOD session
-- @param sessionLetter: Session letter (A-Z)
-- @return: {success:boolean, session:record, message:string}
on initSession(sessionLetter)
	try
		logger's logInfo("Initializing session " & sessionLetter, missing value)
		set startTime to current date
		
		-- Initialize logging
		logger's initializeLogging()
		
		-- Get window reference
		set windowResult to windowManager's getHODWindow(sessionLetter)
		if not windowResult's success then
			logger's logError("Failed to get HOD window", {sessionLetter:sessionLetter})
			return {success:false, message:"Failed to get HOD window: " & windowResult's message}
		end if
		
		set windowRef to windowResult's windowRef
		
		-- Capture initial screen
		delay 0.5
		set captureResult to screenCapture's captureScreen(windowRef)
		if not captureResult's success then
			logger's logError("Failed to capture initial screen", {sessionLetter:sessionLetter})
			return {success:false, message:"Failed to capture screen: " & captureResult's message}
		end if
		
		-- Parse initial screen
		set parseResult to screenParser's parseScreen(captureResult's screenText)
		
		-- Create session object
		set sessionObj to {windowRef:windowRef, sessionLetter:sessionLetter, currentScreen:parseResult, lastOperation:"init", operationCount:0, startTime:startTime}
		
		set endTime to current date
		logger's logOperationTiming("initSession", startTime, endTime)
		logger's logInfo("Session initialized successfully", {sessionLetter:sessionLetter, screenType:parseResult's screenType})
		
		return {success:true, session:sessionObj, screenType:parseResult's screenType, message:"Session initialized"}
		
	on error errMsg number errNum
		logger's logError("Session initialization failed: " & errMsg, {sessionLetter:sessionLetter, errorNumber:errNum})
		return {success:false, message:"Init error: " & errMsg, errorNumber:errNum}
	end try
end initSession

-- Close session and return to CMS prompt
-- @param session: Session object from initSession or missing value
-- @return: {success:boolean, message:string}
on closeSession(session)
	try
		if session is missing value then
			return {success:true, message:"No session to close"}
		end if
		
		if class of session is text then
			return {success:true, message:"Close skipped for session letter only"}
		end if
		
		logger's logInfo("Closing session " & session's sessionLetter, missing value)
		set startTime to current date
		
		-- Navigate back to CMS prompt
		set maxAttempts to 5
		set attempts to 0
		
		repeat while attempts < maxAttempts
			set attempts to attempts + 1
			
			-- Capture current screen
			set captureResult to screenCapture's captureScreen(session's windowRef)
			if captureResult's success then
				set parseResult to screenParser's parseScreen(captureResult's screenText)
				
				-- Check if already at CMS prompt
				if parseResult's screenType is "cms_prompt" then
					logger's logInfo("Already at CMS prompt", missing value)
					exit repeat
				end if
				
				-- Send PF3 to go back
				keyboardController's sendPFKey(session's windowRef, 3)
				delay 1.0
			end if
		end repeat
		
		-- Log session summary
		logger's logSessionSummary()
		
		set endTime to current date
		logger's logOperationTiming("closeSession", startTime, endTime)
		
		return {success:true, message:"Session closed", attempts:attempts}
		
	on error errMsg number errNum
		logger's logError("Session close failed: " & errMsg, {errorNumber:errNum})
		return {success:false, message:"Close error: " & errMsg, errorNumber:errNum}
	end try
end closeSession

-- Navigate to a specific file
-- @param session: Session object
-- @param filename: File name (e.g., "PROFILE")
-- @param filetype: File type (e.g., "EXEC")
-- @param filemode: File mode (e.g., "A1")
-- @return: {success:boolean, steps:integer, message:string}
on navigateToFile(session, filename, filetype, filemode)
	try
		logger's logInfo("Navigating to file", {filename:filename, filetype:filetype, filemode:filemode})
		set startTime to current date
		
		-- Build goal
		set goal to {action:"navigate_to_file", filename:filename, filetype:filetype, filemode:filemode}
		
		-- Execute workflow with step limit
		set steps to 0
		repeat while steps < MAX_NAVIGATION_STEPS
			set steps to steps + 1
			
			-- Capture and parse screen
			set captureResult to screenCapture's captureScreen(session's windowRef)
			if not captureResult's success then
				set recovery to errorHandler's handleError("capture_failure", {}, session's windowRef)
				if not recovery's recovered then
					return {success:false, message:"Screen capture failed", steps:steps}
				end if
				-- Retry after recovery
				set captureResult to screenCapture's captureScreen(session's windowRef)
			end if
			
			set parseResult to screenParser's parseScreen(captureResult's screenText)
			set session's currentScreen to parseResult
			
			-- Check if we reached the file
			if parseResult's screenType is "xedit" then
				if parseResult's metadata's filename is filename and parseResult's metadata's filetype is filetype then
					logger's logInfo("Successfully navigated to file", {steps:steps})
					set endTime to current date
					logger's logOperationTiming("navigateToFile", startTime, endTime)
					return {success:true, steps:steps, screenType:"xedit", message:"File opened"}
				end if
			end if
			
			-- Make decision
			set decision to decisionEngine's makeDecision(parseResult, goal)
			logger's logDecision(parseResult's screenType, goal's action, decision's action)
			
			-- Execute action
			set execResult to workflowExecutor's executeAction(session's windowRef, decision, parseResult)
			if not execResult's success then
				logger's logWarn("Action execution failed", {action:decision's action, step:steps})
			end if
			
			delay 1.0
			
			-- Update operation count
			set session's operationCount to session's operationCount + 1
		end repeat
		
		logger's logError("Navigation exceeded max steps", {maxSteps:MAX_NAVIGATION_STEPS})
		return {success:false, message:"Max navigation steps exceeded", steps:steps}
		
	on error errMsg number errNum
		logger's logError("Navigate to file failed: " & errMsg, {filename:filename, errorNumber:errNum})
		return {success:false, message:"Navigation error: " & errMsg, errorNumber:errNum}
	end try
end navigateToFile

-- Search NETLOG for entries matching criteria
-- @param session: Session object
-- @param searchCriteria: Record with search parameters {filename:, user:, date:}
-- @return: {success:boolean, entries:list, pageCount:integer}
on searchNetlog(session, searchCriteria)
	try
		logger's logInfo("Searching NETLOG", searchCriteria)
		set startTime to current date
		
		set allEntries to {}
		set pageCount to 0
		
		-- Navigate to NETLOG first
		set goal to {action:"navigate_to_netlog"}
		set navSteps to 0
		
		repeat while navSteps < 10
			set navSteps to navSteps + 1
			
			set captureResult to screenCapture's captureScreen(session's windowRef)
			if not captureResult's success then
				return {success:false, message:"Screen capture failed"}
			end if
			
			set parseResult to screenParser's parseScreen(captureResult's screenText)
			
			if parseResult's screenType is "netlog" then
				exit repeat
			end if
			
			set decision to decisionEngine's makeDecision(parseResult, goal)
			workflowExecutor's executeAction(session's windowRef, decision, parseResult)
			delay 1.0
		end repeat
		
		-- Search through pages
		repeat while pageCount < MAX_SEARCH_PAGES
			set pageCount to pageCount + 1
			
			-- Capture current page
			set captureResult to screenCapture's captureScreen(session's windowRef)
			if not captureResult's success then
				exit repeat
			end if
			
			set parseResult to screenParser's parseScreen(captureResult's screenText)
			
			if parseResult's screenType is not "netlog" then
				exit repeat
			end if
			
			-- Filter entries based on criteria
			repeat with entry in parseResult's entries
				set matches to true
				
				if searchCriteria is not missing value then
					if entry's filename is not searchCriteria's filename then
						set matches to false
					end if
				end if
				
				if searchCriteria is not missing value then
					if entry's fromUser is not searchCriteria's user and entry's toUser is not searchCriteria's user then
						set matches to false
					end if
				end if
				
				if matches then
					set end of allEntries to entry
				end if
			end repeat
			
			-- Check if more pages available
			if not parseResult's hasMore then
				exit repeat
			end if
			
			-- Go to next page
			keyboardController's sendEnter(session's windowRef)
			delay 1.0
		end repeat
		
		set endTime to current date
		logger's logOperationTiming("searchNetlog", startTime, endTime)
		logger's logInfo("NETLOG search complete", {entriesFound:(count of allEntries), pagesSearched:pageCount})
		
		return {success:true, entries:allEntries, pageCount:pageCount, totalEntries:(count of allEntries)}
		
	on error errMsg number errNum
		logger's logError("NETLOG search failed: " & errMsg, {errorNumber:errNum})
		return {success:false, message:"Search error: " & errMsg, errorNumber:errNum}
	end try
end searchNetlog

-- Edit a specific line in XEDIT
-- @param session: Session object
-- @param lineNumber: Line number to edit
-- @param newContent: New content for the line
-- @return: {success:boolean, message:string}
on editFile(session, lineNumber, newContent)
	try
		logger's logInfo("Editing file line", {lineNumber:lineNumber})
		set startTime to current date
		
		-- Verify we're in XEDIT
		set captureResult to screenCapture's captureScreen(session's windowRef)
		if not captureResult's success then
			return {success:false, message:"Screen capture failed"}
		end if
		
		set parseResult to screenParser's parseScreen(captureResult's screenText)
		if parseResult's screenType is not "xedit" then
			return {success:false, message:"Not in XEDIT mode"}
		end if
		
		-- Navigate to line
		set command to ":" & lineNumber
		keyboardController's sendText(session's windowRef, command)
		keyboardController's sendEnter(session's windowRef)
		delay 0.5
		
		-- Replace line content
		keyboardController's sendText(session's windowRef, "c/" & newContent & "/")
		keyboardController's sendEnter(session's windowRef)
		delay 0.5
		
		set endTime to current date
		logger's logOperationTiming("editFile", startTime, endTime)
		logger's logInfo("Line edited successfully", {lineNumber:lineNumber})
		
		return {success:true, lineNumber:lineNumber, message:"Line edited"}
		
	on error errMsg number errNum
		logger's logError("Edit file failed: " & errMsg, {lineNumber:lineNumber, errorNumber:errNum})
		return {success:false, message:"Edit error: " & errMsg, errorNumber:errNum}
	end try
end editFile

-- Save file and exit XEDIT
-- @param session: Session object
-- @return: {success:boolean, message:string}
on saveAndExit(session)
	try
		logger's logInfo("Saving and exiting XEDIT", missing value)
		set startTime to current date
		
		-- Send FILE command to save and exit
		keyboardController's sendText(session's windowRef, "FILE")
		keyboardController's sendEnter(session's windowRef)
		delay 1.0
		
		-- Verify we're back at CMS prompt
		set captureResult to screenCapture's captureScreen(session's windowRef)
		if captureResult's success then
			set parseResult to screenParser's parseScreen(captureResult's screenText)
			if parseResult's screenType is "cms_prompt" then
				set endTime to current date
				logger's logOperationTiming("saveAndExit", startTime, endTime)
				return {success:true, message:"File saved and closed"}
			end if
		end if
		
		return {success:true, message:"Save command sent", warningMsg:"Could not verify CMS prompt"}
		
	on error errMsg number errNum
		logger's logError("Save and exit failed: " & errMsg, {errorNumber:errNum})
		return {success:false, message:"Save error: " & errMsg, errorNumber:errNum}
	end try
end saveAndExit

-- Execute CMS command and capture output
-- @param session: Session object
-- @param command: CMS command to execute
-- @return: {success:boolean, output:string, screenType:string}
on executeCMSCommand(session, command)
	try
		logger's logInfo("Executing CMS command", {command:command})
		set startTime to current date
		
		-- Verify we're at CMS prompt
		set captureResult to screenCapture's captureScreen(session's windowRef)
		if not captureResult's success then
			return {success:false, message:"Screen capture failed"}
		end if
		
		set parseResult to screenParser's parseScreen(captureResult's screenText)
		if parseResult's screenType is not "cms_prompt" then
			logger's logWarn("Not at CMS prompt, attempting to navigate", {currentScreen:parseResult's screenType})
			-- Try to get back to CMS prompt
			keyboardController's sendPFKey(session's windowRef, 3)
			delay 1.0
		end if
		
		-- Send command
		keyboardController's sendText(session's windowRef, command)
		keyboardController's sendEnter(session's windowRef)
		delay 1.5
		
		-- Capture result
		set captureResult to screenCapture's captureScreen(session's windowRef)
		if not captureResult's success then
			return {success:false, message:"Failed to capture command output"}
		end if
		
		set parseResult to screenParser's parseScreen(captureResult's screenText)
		
		set endTime to current date
		logger's logOperationTiming("executeCMSCommand", startTime, endTime)
		logger's logInfo("CMS command executed", {command:command, resultScreen:parseResult's screenType})
		
		return {success:true, output:captureResult's screenText, screenType:parseResult's screenType, parsed:parseResult}
		
	on error errMsg number errNum
		logger's logError("CMS command failed: " & errMsg, {command:command, errorNumber:errNum})
		return {success:false, message:"Command error: " & errMsg, errorNumber:errNum}
	end try
end executeCMSCommand

-- Get current session state
-- @param session: Session object
-- @return: {success:boolean, state:record}
on getSessionState(session)
	try
		-- Capture current screen
		set captureResult to screenCapture's captureScreen(session's windowRef)
		if not captureResult's success then
			return {success:false, message:"Screen capture failed"}
		end if
		
		set parseResult to screenParser's parseScreen(captureResult's screenText)
		
		-- Get session statistics
		set stats to logger's getSessionStats()
		
		-- Build state object
		set stateObj to {sessionLetter:session's sessionLetter, currentScreen:parseResult's screenType, operationCount:session's operationCount, lastOperation:session's lastOperation, sessionDuration:missing value}
		
		if stats's success then
			set stateObj's sessionDuration to stats's sessionDuration
		end if
		
		return {success:true, state:stateObj, screenData:parseResult}
		
	on error errMsg number errNum
		logger's logError("Get session state failed: " & errMsg, {errorNumber:errNum})
		return {success:false, message:"State error: " & errMsg, errorNumber:errNum}
	end try
end getSessionState

log "Main API Module Loaded"

-- Made with Bob
