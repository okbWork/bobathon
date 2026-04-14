-- Logger Module
-- Comprehensive logging system for IBM Host On-Demand automation
-- Supports multiple log levels, screen captures, and performance metrics

-- Log Levels
property LOG_DEBUG : "DEBUG"
property LOG_INFO : "INFO"
property LOG_WARN : "WARN"
property LOG_ERROR : "ERROR"

-- Log Configuration
property LOG_DIR : "/Users/okyereboateng/bobathon/logs"
property LOG_FILE : "hod_automation.log"
property SCREEN_CAPTURE_PREFIX : "screen_"
property CURRENT_LOG_LEVEL : LOG_DEBUG -- Set minimum level to log

-- Session tracking
property sessionStartTime : missing value
property operationCounter : 0

-- Initialize logging system
-- Creates log directory and starts new session
-- @return: {success:boolean, logPath:string}
on initializeLogging()
	try
		-- Create logs directory if it doesn't exist
		tell application "Finder"
			if not (exists folder LOG_DIR) then
				do shell script "mkdir -p " & quoted form of LOG_DIR
			end if
		end tell
		
		set sessionStartTime to current date
		set operationCounter to 0
		
		set logPath to LOG_DIR & "/" & LOG_FILE
		set sessionMsg to "=== NEW SESSION STARTED: " & (sessionStartTime as string) & " ==="
		
		-- Write session start marker
		do shell script "echo " & quoted form of sessionMsg & " >> " & quoted form of logPath
		
		log "LOGGER: Initialized - " & logPath
		return {success:true, logPath:logPath, sessionStart:sessionStartTime}
		
	on error errMsg number errNum
		log "LOGGER: Initialization failed - " & errMsg
		return {success:false, message:"Logger init failed: " & errMsg, errorNumber:errNum}
	end try
end initializeLogging

-- Main logging function
-- @param level: Log level (DEBUG, INFO, WARN, ERROR)
-- @param message: Log message
-- @param context: Optional record with additional context
-- @return: {success:boolean}
on logMessage(level, message, context)
	try
		-- Check if level should be logged
		if not shouldLog(level) then
			return {success:true, skipped:true}
		end if
		
		set timestamp to getCurrentTimestamp()
		set logPath to LOG_DIR & "/" & LOG_FILE
		
		-- Format log entry
		set logEntry to timestamp & " [" & level & "] " & message
		
		-- Add context if provided
		if context is not missing value then
			try
				set contextStr to recordToString(context)
				set logEntry to logEntry & " | Context: " & contextStr
			end try
		end if
		
		-- Write to log file
		do shell script "echo " & quoted form of logEntry & " >> " & quoted form of logPath
		
		-- Also log to system log for ERROR level
		if level is LOG_ERROR then
			log "ERROR: " & message
		end if
		
		return {success:true, logged:true}
		
	on error errMsg number errNum
		-- Fallback to system log if file logging fails
		log "LOGGER ERROR: " & errMsg & " - Original message: " & message
		return {success:false, message:"Logging failed: " & errMsg}
	end try
end logMessage

-- Log debug message
-- @param message: Debug message
-- @param context: Optional context record
on logDebug(message, context)
	if context is missing value then
		set context to missing value
	end if
	return logMessage(LOG_DEBUG, message, context)
end logDebug

-- Log info message
-- @param message: Info message
-- @param context: Optional context record
on logInfo(message, context)
	if context is missing value then
		set context to missing value
	end if
	return logMessage(LOG_INFO, message, context)
end logInfo

-- Log warning message
-- @param message: Warning message
-- @param context: Optional context record
on logWarn(message, context)
	if context is missing value then
		set context to missing value
	end if
	return logMessage(LOG_WARN, message, context)
end logWarn

-- Log error message
-- @param message: Error message
-- @param context: Optional context record
on logError(message, context)
	if context is missing value then
		set context to missing value
	end if
	return logMessage(LOG_ERROR, message, context)
end logError

-- Log screen capture to file
-- @param screenText: Screen content to save
-- @param label: Label for the capture (e.g., "cms_prompt", "filelist")
-- @return: {success:boolean, filepath:string}
on logScreenCapture(screenText, label)
	try
		set timestamp to getTimestampForFilename()
		set sanitizedLabel to sanitizeFilename(label)
		set filename to SCREEN_CAPTURE_PREFIX & timestamp & "_" & sanitizedLabel & ".txt"
		set filepath to LOG_DIR & "/" & filename
		
		-- Write screen content to file
		set fileRef to open for access POSIX file filepath with write permission
		set eof fileRef to 0
		write screenText to fileRef
		close access fileRef
		
		-- Log the capture
		logDebug("Screen captured: " & filename, {label:label, length:(length of screenText)})
		
		return {success:true, filepath:filepath, filename:filename}
		
	on error errMsg number errNum
		try
			close access POSIX file filepath
		end try
		logError("Screen capture failed: " & errMsg, {label:label})
		return {success:false, message:"Screen capture failed: " & errMsg}
	end try
end logScreenCapture

-- Log operation timing
-- @param operationName: Name of the operation
-- @param startTime: Start time (date object)
-- @param endTime: End time (date object)
-- @return: {success:boolean, duration:number}
on logOperationTiming(operationName, startTime, endTime)
	try
		set duration to endTime - startTime
		set formattedDuration to formatDuration(duration)
		
		set operationCounter to operationCounter + 1
		
		set message to "TIMING: " & operationName & " completed in " & formattedDuration
		set context to {operation:operationName, duration:duration, operationNumber:operationCounter}
		
		logInfo(message, context)
		
		return {success:true, duration:duration, formatted:formattedDuration}
		
	on error errMsg number errNum
		logError("Timing log failed: " & errMsg, {operation:operationName})
		return {success:false, message:"Timing log failed: " & errMsg}
	end try
end logOperationTiming

-- Log decision path
-- @param screenType: Type of screen detected
-- @param goal: Current goal
-- @param decision: Decision made
-- @return: {success:boolean}
on logDecision(screenType, goal, decision)
	try
		set message to "DECISION: Screen=" & screenType & ", Goal=" & goal & ", Action=" & decision
		set context to {screenType:screenType, goal:goal, decision:decision}
		
		logInfo(message, context)
		
		return {success:true}
		
	on error errMsg number errNum
		logError("Decision log failed: " & errMsg, missing value)
		return {success:false, message:"Decision log failed: " & errMsg}
	end try
end logDecision

-- Get current timestamp in readable format
-- @return: Formatted timestamp string
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

-- Get timestamp for filename (no spaces or colons)
-- @return: Filename-safe timestamp
on getTimestampForFilename()
	set now to current date
	set y to year of now as string
	set m to text -2 thru -1 of ("0" & (month of now as integer))
	set d to text -2 thru -1 of ("0" & (day of now))
	set h to text -2 thru -1 of ("0" & (hours of now))
	set min to text -2 thru -1 of ("0" & (minutes of now))
	set s to text -2 thru -1 of ("0" & (seconds of now))
	
	return y & m & d & "_" & h & min & s
end getTimestampForFilename

-- Format duration for display
-- @param seconds: Duration in seconds
-- @return: Formatted string (e.g., "2.5s", "1m 30s")
on formatDuration(seconds)
	if seconds < 1 then
		return (round (seconds * 1000)) & "ms"
	else if seconds < 60 then
		return (round (seconds * 10) / 10) & "s"
	else
		set mins to seconds div 60
		set secs to seconds mod 60
		return mins & "m " & secs & "s"
	end if
end formatDuration

-- Sanitize filename for filesystem
-- @param filename: Original filename
-- @return: Sanitized filename
on sanitizeFilename(filename)
	set filename to filename as string
	
	-- Replace invalid characters with underscore
	set invalidChars to {"/", "\\", ":", "*", "?", "\"", "<", ">", "|", " "}
	repeat with char in invalidChars
		set AppleScript's text item delimiters to char
		set parts to text items of filename
		set AppleScript's text item delimiters to "_"
		set filename to parts as string
	end repeat
	set AppleScript's text item delimiters to ""
	
	-- Limit length
	if length of filename > 50 then
		set filename to text 1 thru 50 of filename
	end if
	
	return filename
end sanitizeFilename

-- Convert record to string representation
-- @param rec: Record to convert
-- @return: String representation
on recordToString(rec)
	try
		set output to "{"
		set firstItem to true
		
		repeat with i from 1 to count of rec
			try
				set itemKey to item i of (rec's properties)
				set itemValue to item i of (rec's values)
				
				if not firstItem then
					set output to output & ", "
				end if
				set firstItem to false
				
				set output to output & itemKey & ":" & (itemValue as string)
			end try
		end repeat
		
		set output to output & "}"
		return output
		
	on error
		return rec as string
	end try
end recordToString

-- Check if log level should be logged
-- @param level: Log level to check
-- @return: Boolean
on shouldLog(level)
	set levelPriority to {DEBUG:1, INFO:2, WARN:3, ERRORLEVEL:4}
	
	try
		set currentPriority to levelPriority's (CURRENT_LOG_LEVEL)
		set messagePriority to levelPriority's (level)
		return messagePriority ≥ currentPriority
	on error
		return true -- Log if priority check fails
	end try
end shouldLog

-- Get session statistics
-- @return: {sessionDuration:number, operationCount:integer}
on getSessionStats()
	try
		if sessionStartTime is missing value then
			return {success:false, message:"Session not initialized"}
		end if
		
		set now to current date
		set duration to now - sessionStartTime
		
		return {success:true, sessionDuration:duration, operationCount:operationCounter, startTime:sessionStartTime}
		
	on error errMsg
		return {success:false, message:"Stats error: " & errMsg}
	end try
end getSessionStats

-- Log session summary
-- @return: {success:boolean}
on logSessionSummary()
	try
		set stats to getSessionStats()
		
		if stats's success then
			set message to "=== SESSION SUMMARY: Duration=" & formatDuration(stats's sessionDuration) & ", Operations=" & stats's operationCount & " ==="
			logInfo(message, stats)
		end if
		
		return {success:true}
		
	on error errMsg
		return {success:false, message:"Summary log failed: " & errMsg}
	end try
end logSessionSummary

log "Logger Module Loaded"

-- Made with Bob
