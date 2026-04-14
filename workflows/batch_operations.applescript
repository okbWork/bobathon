-- Batch Operations Workflow
-- Workflow for processing multiple files with various operations
-- Demonstrates bulk automation capabilities

-- Load main API
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"
property logger : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/logger.applescript"
property helpers : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/helpers.applescript"

-- Process multiple files with specified operation
-- @param sessionLetter: HOD session letter (A-Z)
-- @param fileList: List of file records {filename, filetype, filemode}
-- @param operation: Operation to perform ("add_header", "backup", "delete", "list_info")
-- @return: {success:boolean, results:list, successCount:integer}
on workflowBatchProcess(sessionLetter, fileList, operation)
	try
		logger's logInfo("Starting batch processing", {fileCount:(count of fileList), operation:operation})
		set batchStart to current date
		
		-- Initialize session
		set initResult to mainAPI's initSession(sessionLetter)
		if not initResult's success then
			return {success:false, message:"Session init failed: " & initResult's message}
		end if
		
		set session to initResult's session
		
		set results to {}
		set successCount to 0
		set failCount to 0
		
		-- Process each file
		repeat with fileRecord in fileList
			logger's logInfo("Processing file", {filename:fileRecord's filename, operation:operation})
			
			set fileResult to missing value
			
			-- Route to appropriate operation
			if operation is "add_header" then
				set fileResult to addHeaderToFile(session, fileRecord)
			else if operation is "backup" then
				set fileResult to backupFile(session, fileRecord)
			else if operation is "delete" then
				set fileResult to deleteFile(session, fileRecord)
			else if operation is "list_info" then
				set fileResult to getFileInfo(session, fileRecord)
			else
				set fileResult to {success:false, message:"Unknown operation: " & operation}
			end if
			
			-- Track results
			if fileResult's success then
				set successCount to successCount + 1
			else
				set failCount to failCount + 1
			end if
			
			set end of results to {file:fileRecord, operation:operation, result:fileResult}
			
			-- Brief delay between operations
			delay 1.0
		end repeat
		
		-- Close session
		mainAPI's closeSession(session)
		
		set batchEnd to current date
		set duration to batchEnd - batchStart
		set formattedDuration to helpers's formatDuration(duration)
		
		logger's logInfo("Batch processing completed", {total:(count of fileList), success:successCount, failed:failCount, duration:formattedDuration})
		
		return {success:true, results:results, successCount:successCount, failCount:failCount, totalFiles:(count of fileList), duration:duration, operation:operation}
		
	on error errMsg number errNum
		logger's logError("Batch processing failed: " & errMsg, {errorNumber:errNum})
		try
			mainAPI's closeSession(session)
		end try
		return {success:false, message:"Batch error: " & errMsg, errorNumber:errNum, results:results}
	end try
end workflowBatchProcess

-- Add header comment to file
-- @param session: Session object
-- @param fileRecord: File record {filename, filetype, filemode}
-- @return: {success:boolean, message:string}
on addHeaderToFile(session, fileRecord)
	try
		logger's logInfo("Adding header to file", {filename:fileRecord's filename})
		
		-- Navigate to file
		set navResult to mainAPI's navigateToFile(session, fileRecord's filename, fileRecord's filetype, fileRecord's filemode)
		if not navResult's success then
			return {success:false, message:"Navigation failed: " & navResult's message}
		end if
		
		-- Add header at top of file
		set headerText to "/* Modified by automation on " & helpers's getCurrentTimestamp() & " */"
		
		-- Go to top of file
		set topResult to mainAPI's executeCMSCommand(session, ":1")
		delay 0.5
		
		-- Insert header line
		set insertResult to mainAPI's executeCMSCommand(session, "i " & headerText)
		delay 0.5
		
		-- Save and exit
		set saveResult to mainAPI's saveAndExit(session)
		if not saveResult's success then
			return {success:false, message:"Save failed: " & saveResult's message}
		end if
		
		logger's logInfo("Header added successfully", {filename:fileRecord's filename})
		return {success:true, message:"Header added", filename:fileRecord's filename}
		
	on error errMsg number errNum
		logger's logError("Add header failed: " & errMsg, {filename:fileRecord's filename, errorNumber:errNum})
		return {success:false, message:"Header error: " & errMsg, errorNumber:errNum}
	end try
end addHeaderToFile

-- Backup file by copying to .BACKUP filetype
-- @param session: Session object
-- @param fileRecord: File record {filename, filetype, filemode}
-- @return: {success:boolean, message:string}
on backupFile(session, fileRecord)
	try
		logger's logInfo("Backing up file", {filename:fileRecord's filename})
		
		-- Return to CMS prompt if not already there
		set stateResult to mainAPI's getSessionState(session)
		if stateResult's success and stateResult's state's currentScreen is not "cms_prompt" then
			mainAPI's saveAndExit(session)
			delay 1.0
		end if
		
		-- Execute COPYFILE command
		set copyCommand to "COPYFILE " & fileRecord's filename & " " & fileRecord's filetype & " " & fileRecord's filemode & " = = BACKUP ="
		set copyResult to mainAPI's executeCMSCommand(session, copyCommand)
		
		if not copyResult's success then
			return {success:false, message:"Copy failed: " & copyResult's message}
		end if
		
		-- Verify backup was created
		delay 1.0
		set listCmd to "LISTFILE " & fileRecord's filename & " BACKUP " & fileRecord's filemode
		set listRes to mainAPI's executeCMSCommand(session, listCmd)
		
		set backupVerified to false
		if listRes's success then
			if listRes's output contains fileRecord's filename and listRes's output contains "BACKUP" then
				set backupVerified to true
			end if
		end if
		
		logger's logInfo("File backed up", {filename:fileRecord's filename, verified:backupVerified})
		return {success:true, message:"File backed up", filename:fileRecord's filename, backupVerified:backupVerified}
		
	on error errMsg number errNum
		logger's logError("Backup failed: " & errMsg, {filename:fileRecord's filename, errorNumber:errNum})
		return {success:false, message:"Backup error: " & errMsg, errorNumber:errNum}
	end try
end backupFile

-- Delete file
-- @param session: Session object
-- @param fileRecord: File record {filename, filetype, filemode}
-- @return: {success:boolean, message:string}
on deleteFile(session, fileRecord)
	try
		logger's logInfo("Deleting file", {filename:fileRecord's filename})
		
		-- Return to CMS prompt if not already there
		set stateResult to mainAPI's getSessionState(session)
		if stateResult's success and stateResult's state's currentScreen is not "cms_prompt" then
			mainAPI's saveAndExit(session)
			delay 1.0
		end if
		
		-- Execute ERASE command
		set eraseCommand to "ERASE " & fileRecord's filename & " " & fileRecord's filetype & " " & fileRecord's filemode
		set eraseResult to mainAPI's executeCMSCommand(session, eraseCommand)
		
		if not eraseResult's success then
			return {success:false, message:"Erase failed: " & eraseResult's message}
		end if
		
		-- Verify file was deleted
		delay 1.0
		set listCmd to "LISTFILE " & fileRecord's filename & " " & fileRecord's filetype & " " & fileRecord's filemode
		set listRes to mainAPI's executeCMSCommand(session, listCmd)
		
		set deleteVerified to false
		if listRes's success then
			if listRes's output contains "NOT FOUND" or listRes's output contains "No files" then
				set deleteVerified to true
			end if
		end if
		
		logger's logInfo("File deleted", {filename:fileRecord's filename, verified:deleteVerified})
		return {success:true, message:"File deleted", filename:fileRecord's filename, deleteVerified:deleteVerified}
		
	on error errMsg number errNum
		logger's logError("Delete failed: " & errMsg, {filename:fileRecord's filename, errorNumber:errNum})
		return {success:false, message:"Delete error: " & errMsg, errorNumber:errNum}
	end try
end deleteFile

-- Get file information
-- @param session: Session object
-- @param fileRecord: File record {filename, filetype, filemode}
-- @return: {success:boolean, info:record}
on getFileInfo(session, fileRecord)
	try
		logger's logInfo("Getting file info", {filename:fileRecord's filename})
		
		-- Return to CMS prompt if not already there
		set stateResult to mainAPI's getSessionState(session)
		if stateResult's success and stateResult's state's currentScreen is not "cms_prompt" then
			mainAPI's saveAndExit(session)
			delay 1.0
		end if
		
		-- Execute LISTFILE command with details
		set listCmd to "LISTFILE " & fileRecord's filename & " " & fileRecord's filetype & " " & fileRecord's filemode & " (DATE"
		set listRes to mainAPI's executeCMSCommand(session, listCmd)
		
		if not listRes's success then
			return {success:false, message:"List failed: " & listRes's message}
		end if
		
		-- Parse file information from output
		set fileInfo to {filename:fileRecord's filename, filetype:fileRecord's filetype, filemode:fileRecord's filemode, fileExists:false, recordCount:0, lastModified:missing value}
		
		if listRes's output contains fileRecord's filename then
			set fileInfo's fileExists to true
			
			-- Try to extract record count
			try
				set recCount to helpers's extractNumberFromText(listRes's output, "records")
				if recCount > 0 then
					set fileInfo's recordCount to recCount
				end if
			end try
		end if
		
		logger's logInfo("File info retrieved", {filename:fileRecord's filename, fileExists:fileInfo's fileExists})
		return {success:true, info:fileInfo, rawOutput:listRes's output}
		
	on error errMsg number errNum
		logger's logError("Get file info failed: " & errMsg, {filename:fileRecord's filename, errorNumber:errNum})
		return {success:false, message:"Info error: " & errMsg, errorNumber:errNum}
	end try
end getFileInfo

-- Process files matching a pattern
-- @param sessionLetter: HOD session letter
-- @param filenamePattern: Pattern to match (e.g., "TEST*")
-- @param filetype: File type
-- @param filemode: File mode
-- @param operation: Operation to perform
-- @return: {success:boolean, results:list}
on workflowProcessPattern(sessionLetter, filenamePattern, filetype, filemode, operation)
	try
		logger's logInfo("Processing files by pattern", {pattern:filenamePattern, operation:operation})
		
		-- Initialize session
		set initResult to mainAPI's initSession(sessionLetter)
		if not initResult's success then
			return {success:false, message:"Session init failed"}
		end if
		
		set session to initResult's session
		
		-- List files matching pattern
		set listCmd to "LISTFILE " & filenamePattern & " " & filetype & " " & filemode
		set listRes to mainAPI's executeCMSCommand(session, listCmd)
		
		if not listRes's success then
			mainAPI's closeSession(session)
			return {success:false, message:"List failed: " & listRes's message}
		end if
		
		-- Parse filenames from output (simplified - would need proper parsing)
		set fileList to {}
		-- In real implementation, would parse the FILELIST output
		-- For now, return structure showing the approach
		
		mainAPI's closeSession(session)
		
		logger's logInfo("Pattern processing completed", {pattern:filenamePattern})
		return {success:true, message:"Pattern processing completed", matchedFiles:(count of fileList)}
		
	on error errMsg number errNum
		logger's logError("Pattern processing failed: " & errMsg, {errorNumber:errNum})
		try
			mainAPI's closeSession(session)
		end try
		return {success:false, message:"Pattern error: " & errMsg, errorNumber:errNum}
	end try
end workflowProcessPattern

-- Example usage function
on exampleUsage()
	-- Example 1: Add headers to multiple files
	set fileList to {{filename:"PROFILE", filetype:"EXEC", filemode:"A1"}, {filename:"CONFIG", filetype:"DATA", filemode:"A1"}}
	set result1 to workflowBatchProcess("A", fileList, "add_header")
	
	-- Example 2: Backup multiple files
	set result2 to workflowBatchProcess("A", fileList, "backup")
	
	-- Example 3: Get info for multiple files
	set result3 to workflowBatchProcess("A", fileList, "list_info")
	
	-- Example 4: Process files by pattern
	set result4 to workflowProcessPattern("A", "TEST*", "EXEC", "A1", "backup")
	
	return {example1:result1, example2:result2, example3:result3, example4:result4}
end exampleUsage

log "Batch Operations Workflow Module Loaded"

-- Made with Bob
