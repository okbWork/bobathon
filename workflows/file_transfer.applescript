-- File Transfer Workflow
-- Complete workflow for transferring files between users via SENDFILE
-- Demonstrates end-to-end automation with verification

-- Load main API
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"
property logger : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/logger.applescript"
property helpers : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/helpers.applescript"

-- Complete file transfer workflow
-- @param sessionLetter: HOD session letter (A-Z)
-- @param sourceFile: Record with {filename, filetype, filemode}
-- @param targetUser: Target user ID
-- @return: {success:boolean, message:string, transferVerified:boolean}
on workflowFileTransfer(sessionLetter, sourceFile, targetUser)
	try
		logger's logInfo("Starting file transfer workflow", {sessionLetter:sessionLetter, file:sourceFile's filename, target:targetUser})
		set workflowStart to current date
		
		-- Step 1: Initialize session
		logger's logInfo("Step 1: Initializing session", missing value)
		set initResult to mainAPI's initSession(sessionLetter)
		if not initResult's success then
			return {success:false, message:"Session init failed: " & initResult's message, step:"init"}
		end if
		
		set session to initResult's session
		
		-- Step 2: Navigate to source file
		logger's logInfo("Step 2: Navigating to source file", {filename:sourceFile's filename})
		set navResult to mainAPI's navigateToFile(session, sourceFile's filename, sourceFile's filetype, sourceFile's filemode)
		if not navResult's success then
			mainAPI's closeSession(session)
			return {success:false, message:"Navigation failed: " & navResult's message, step:"navigate"}
		end if
		
		-- Step 3: Exit XEDIT back to CMS
		logger's logInfo("Step 3: Returning to CMS prompt", missing value)
		set exitResult to mainAPI's saveAndExit(session)
		if not exitResult's success then
			mainAPI's closeSession(session)
			return {success:false, message:"Exit failed: " & exitResult's message, step:"exit"}
		end if
		
		delay 1.0
		
		-- Step 4: Execute SENDFILE command
		logger's logInfo("Step 4: Executing SENDFILE command", {target:targetUser})
		set sendCommand to "SENDFILE " & sourceFile's filename & " " & sourceFile's filetype & " " & sourceFile's filemode & " TO " & targetUser
		set sendResult to mainAPI's executeCMSCommand(session, sendCommand)
		if not sendResult's success then
			mainAPI's closeSession(session)
			return {success:false, message:"SENDFILE failed: " & sendResult's message, step:"sendfile"}
		end if
		
		delay 2.0
		
		-- Step 5: Navigate to NETLOG to verify transfer
		logger's logInfo("Step 5: Verifying transfer in NETLOG", missing value)
		set searchCriteria to {filename:sourceFile's filename, user:targetUser}
		set searchResult to mainAPI's searchNetlog(session, searchCriteria)
		
		set transferVerified to false
		if searchResult's success then
			if searchResult's totalEntries > 0 then
				set transferVerified to true
				logger's logInfo("Transfer verified in NETLOG", {entries:searchResult's totalEntries})
			else
				logger's logWarn("Transfer not found in NETLOG", missing value)
			end if
		else
			logger's logWarn("NETLOG verification failed", {message:searchResult's message})
		end if
		
		-- Step 6: Close session
		logger's logInfo("Step 6: Closing session", missing value)
		mainAPI's closeSession(session)
		
		-- Calculate workflow duration
		set workflowEnd to current date
		set duration to workflowEnd - workflowStart
		set formattedDuration to helpers's formatDuration(duration)
		
		logger's logInfo("File transfer workflow completed", {duration:formattedDuration, verified:transferVerified})
		
		return {success:true, message:"File transfer completed in " & formattedDuration, transferVerified:transferVerified, duration:duration, sourceFile:sourceFile, targetUser:targetUser}
		
	on error errMsg number errNum
		logger's logError("File transfer workflow failed: " & errMsg, {errorNumber:errNum})
		try
			mainAPI's closeSession(session)
		end try
		return {success:false, message:"Workflow error: " & errMsg, errorNumber:errNum}
	end try
end workflowFileTransfer

-- Transfer multiple files to same user
-- @param sessionLetter: HOD session letter
-- @param fileList: List of file records {filename, filetype, filemode}
-- @param targetUser: Target user ID
-- @return: {success:boolean, results:list, successCount:integer}
on workflowBatchFileTransfer(sessionLetter, fileList, targetUser)
	try
		logger's logInfo("Starting batch file transfer", {fileCount:(count of fileList), target:targetUser})
		set batchStart to current date
		
		set results to {}
		set successCount to 0
		set failCount to 0
		
		repeat with fileRecord in fileList
			logger's logInfo("Transferring file", {filename:fileRecord's filename})
			
			set transferResult to workflowFileTransfer(sessionLetter, fileRecord, targetUser)
			
			if transferResult's success then
				set successCount to successCount + 1
			else
				set failCount to failCount + 1
			end if
			
			set end of results to {file:fileRecord, result:transferResult}
			
			-- Brief delay between transfers
			delay 2.0
		end repeat
		
		set batchEnd to current date
		set duration to batchEnd - batchStart
		set formattedDuration to helpers's formatDuration(duration)
		
		logger's logInfo("Batch transfer completed", {total:(count of fileList), success:successCount, failed:failCount, duration:formattedDuration})
		
		return {success:true, results:results, successCount:successCount, failCount:failCount, totalFiles:(count of fileList), duration:duration, message:"Batch transfer completed"}
		
	on error errMsg number errNum
		logger's logError("Batch file transfer failed: " & errMsg, {errorNumber:errNum})
		return {success:false, message:"Batch error: " & errMsg, errorNumber:errNum, results:results}
	end try
end workflowBatchFileTransfer

-- Verify file transfer was successful
-- @param sessionLetter: HOD session letter
-- @param filename: File name to verify
-- @param targetUser: Expected recipient
-- @return: {success:boolean, found:boolean, entry:record}
on verifyFileTransfer(sessionLetter, filename, targetUser)
	try
		logger's logInfo("Verifying file transfer", {filename:filename, target:targetUser})
		
		-- Initialize session
		set initResult to mainAPI's initSession(sessionLetter)
		if not initResult's success then
			return {success:false, message:"Session init failed"}
		end if
		
		set session to initResult's session
		
		-- Search NETLOG
		set searchCriteria to {filename:filename, user:targetUser}
		set searchResult to mainAPI's searchNetlog(session, searchCriteria)
		
		set found to false
		set foundEntry to missing value
		
		if searchResult's success and searchResult's totalEntries > 0 then
			set found to true
			set foundEntry to item 1 of searchResult's entries
			logger's logInfo("Transfer verified", {filename:filename, target:targetUser})
		else
			logger's logWarn("Transfer not found", {filename:filename, target:targetUser})
		end if
		
		-- Close session
		mainAPI's closeSession(session)
		
		return {success:true, found:found, entry:foundEntry, searchedPages:searchResult's pageCount}
		
	on error errMsg number errNum
		logger's logError("Verify transfer failed: " & errMsg, {errorNumber:errNum})
		try
			mainAPI's closeSession(session)
		end try
		return {success:false, message:"Verify error: " & errMsg, errorNumber:errNum}
	end try
end verifyFileTransfer

-- Get transfer history for a file
-- @param sessionLetter: HOD session letter
-- @param filename: File name to search
-- @return: {success:boolean, transfers:list, count:integer}
on getFileTransferHistory(sessionLetter, filename)
	try
		logger's logInfo("Getting transfer history", {filename:filename})
		
		-- Initialize session
		set initResult to mainAPI's initSession(sessionLetter)
		if not initResult's success then
			return {success:false, message:"Session init failed"}
		end if
		
		set session to initResult's session
		
		-- Search NETLOG for all transfers of this file
		set searchCriteria to {filename:filename}
		set searchResult to mainAPI's searchNetlog(session, searchCriteria)
		
		-- Close session
		mainAPI's closeSession(session)
		
		if searchResult's success then
			logger's logInfo("Transfer history retrieved", {filename:filename, entryCount:searchResult's totalEntries})
			return {success:true, transfers:searchResult's entries, entryCount:searchResult's totalEntries, pagesSearched:searchResult's pageCount}
		else
			return {success:false, message:"Search failed: " & searchResult's message}
		end if
		
	on error errMsg number errNum
		logger's logError("Get transfer history failed: " & errMsg, {errorNumber:errNum})
		try
			mainAPI's closeSession(session)
		end try
		return {success:false, message:"History error: " & errMsg, errorNumber:errNum}
	end try
end getFileTransferHistory

-- Example usage function
on exampleUsage()
	-- Example 1: Single file transfer
	set sourceFile to {filename:"PROFILE", filetype:"EXEC", filemode:"A1"}
	set result1 to workflowFileTransfer("A", sourceFile, "USER123")
	
	-- Example 2: Batch transfer
	set fileList to {{filename:"PROFILE", filetype:"EXEC", filemode:"A1"}, {filename:"CONFIG", filetype:"DATA", filemode:"A1"}}
	set result2 to workflowBatchFileTransfer("A", fileList, "USER123")
	
	-- Example 3: Verify transfer
	set result3 to verifyFileTransfer("A", "PROFILE", "USER123")
	
	-- Example 4: Get history
	set result4 to getFileTransferHistory("A", "PROFILE")
	
	return {example1:result1, example2:result2, example3:result3, example4:result4}
end exampleUsage

log "File Transfer Workflow Module Loaded"

-- Made with Bob
