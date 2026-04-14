-- NETLOG Analysis Workflow
-- Workflow for analyzing NETLOG patterns and generating insights
-- Demonstrates data analysis and reporting capabilities

-- Load main API
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"
property logger : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/logger.applescript"
property helpers : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/helpers.applescript"

-- Analyze NETLOG patterns
-- @param sessionLetter: HOD session letter (A-Z)
-- @param analysisType: Type of analysis ("file_frequency", "user_activity", "recent_transfers", "all")
-- @return: {success:boolean, analysis:record, totalEntries:integer}
on workflowNetlogAnalysis(sessionLetter, analysisType)
	try
		logger's logInfo("Starting NETLOG analysis", {analysisType:analysisType})
		set analysisStart to current date
		
		-- Initialize session
		set initResult to mainAPI's initSession(sessionLetter)
		if not initResult's success then
			return {success:false, message:"Session init failed: " & initResult's message}
		end if
		
		set session to initResult's session
		
		-- Collect all NETLOG entries
		logger's logInfo("Collecting NETLOG entries", missing value)
		set searchResult to mainAPI's searchNetlog(session, {})
		
		if not searchResult's success then
			mainAPI's closeSession(session)
			return {success:false, message:"NETLOG search failed: " & searchResult's message}
		end if
		
		set allEntries to searchResult's entries
		set totalEntries to count of allEntries
		
		logger's logInfo("Entries collected", {entryCount:totalEntries})
		
		-- Perform requested analysis
		set analysisResults to {}
		
		if analysisType is "file_frequency" or analysisType is "all" then
			set fileFreqResult to analyzeFileFrequency(allEntries)
			set analysisResults's fileFrequency to fileFreqResult
		end if
		
		if analysisType is "user_activity" or analysisType is "all" then
			set userActivityResult to analyzeUserActivity(allEntries)
			set analysisResults's userActivity to userActivityResult
		end if
		
		if analysisType is "recent_transfers" or analysisType is "all" then
			set recentResult to analyzeRecentTransfers(allEntries)
			set analysisResults's recentTransfers to recentResult
		end if
		
		-- Close session
		mainAPI's closeSession(session)
		
		set analysisEnd to current date
		set duration to analysisEnd - analysisStart
		set formattedDuration to helpers's formatDuration(duration)
		
		logger's logInfo("NETLOG analysis completed", {totalEntries:totalEntries, duration:formattedDuration})
		
		return {success:true, analysis:analysisResults, totalEntries:totalEntries, duration:duration, analysisType:analysisType}
		
	on error errMsg number errNum
		logger's logError("NETLOG analysis failed: " & errMsg, {errorNumber:errNum})
		try
			mainAPI's closeSession(session)
		end try
		return {success:false, message:"Analysis error: " & errMsg, errorNumber:errNum}
	end try
end workflowNetlogAnalysis

-- Analyze file transfer frequency
-- @param entries: List of NETLOG entries
-- @return: {topFiles:list, totalFiles:integer, statistics:record}
on analyzeFileFrequency(entries)
	try
		logger's logInfo("Analyzing file frequency", {entryCount:(count of entries)})
		
		-- Count occurrences of each file
		set fileCountMap to {}
		
		repeat with entry in entries
			set filename to entry's filename
			set found to false
			
			-- Check if file already in map
			repeat with i from 1 to count of fileCountMap
				set mapEntry to item i of fileCountMap
				if mapEntry's filename is filename then
					set mapEntry's |count| to mapEntry's |count| + 1
					set found to true
					exit repeat
				end if
			end repeat
			
			-- Add new file to map
			if not found then
				set end of fileCountMap to {filename:filename, |count|:1}
			end if
		end repeat
		
		-- Sort by count (bubble sort for simplicity)
		set sortedFiles to fileCountMap
		repeat with i from 1 to (count of sortedFiles) - 1
			repeat with j from 1 to (count of sortedFiles) - i
				set item1 to item j of sortedFiles
				set item2 to item (j + 1) of sortedFiles
				if item1's |count| < item2's |count| then
					-- Swap
					set temp to item1
					set item j of sortedFiles to item2
					set item (j + 1) of sortedFiles to temp
				end if
			end repeat
		end repeat
		
		-- Get top 10 files
		set topFiles to {}
		set maxFiles to 10
		if (count of sortedFiles) < maxFiles then
			set maxFiles to count of sortedFiles
		end if
		
		repeat with i from 1 to maxFiles
			set end of topFiles to item i of sortedFiles
		end repeat
		
		-- Calculate statistics
		set totalUniqueFiles to count of fileCountMap
		set avgTransfersPerFile to 0
		if totalUniqueFiles > 0 then
			set avgTransfersPerFile to (count of entries) / totalUniqueFiles
		end if
		
		set statistics to {totalUniqueFiles:totalUniqueFiles, totalTransfers:(count of entries), avgTransfersPerFile:avgTransfersPerFile}
		
		logger's logInfo("File frequency analysis complete", {uniqueFiles:totalUniqueFiles})
		
		return {topFiles:topFiles, totalFiles:totalUniqueFiles, statistics:statistics}
		
	on error errMsg
		logger's logError("File frequency analysis failed: " & errMsg, missing value)
		return {topFiles:{}, totalFiles:0, errorMsg:errMsg}
	end try
end analyzeFileFrequency

-- Analyze user activity patterns
-- @param entries: List of NETLOG entries
-- @return: {topSenders:list, topReceivers:list, userPairs:list, statistics:record}
on analyzeUserActivity(entries)
	try
		logger's logInfo("Analyzing user activity", {entryCount:(count of entries)})
		
		-- Count sends per user
		set senderMap to {}
		set receiverMap to {}
		set pairMap to {}
		
		repeat with entry in entries
			set fromUser to entry's fromUser
			set toUser to entry's toUser
			
			-- Count senders
			set found to false
			repeat with i from 1 to count of senderMap
				if (item i of senderMap)'s username is fromUser then
					set (item i of senderMap)'s |count| to ((item i of senderMap)'s |count|) + 1
					set found to true
					exit repeat
				end if
			end repeat
			if not found then
				set end of senderMap to {username:fromUser, |count|:1}
			end if
			
			-- Count receivers
			set found to false
			repeat with i from 1 to count of receiverMap
				if (item i of receiverMap)'s username is toUser then
					set (item i of receiverMap)'s |count| to ((item i of receiverMap)'s |count|) + 1
					set found to true
					exit repeat
				end if
			end repeat
			if not found then
				set end of receiverMap to {username:toUser, |count|:1}
			end if
			
			-- Count user pairs
			set pairKey to fromUser & "->" & toUser
			set found to false
			repeat with i from 1 to count of pairMap
				if (item i of pairMap)'s pair is pairKey then
					set (item i of pairMap)'s |count| to ((item i of pairMap)'s |count|) + 1
					set found to true
					exit repeat
				end if
			end repeat
			if not found then
				set end of pairMap to {pair:pairKey, fromUser:fromUser, toUser:toUser, |count|:1}
			end if
		end repeat
		
		-- Sort and get top users
		set topSenders to getTopItems(senderMap, 5)
		set topReceivers to getTopItems(receiverMap, 5)
		set topPairs to getTopItems(pairMap, 5)
		
		-- Calculate statistics
		set statistics to {totalSenders:(count of senderMap), totalReceivers:(count of receiverMap), totalPairs:(count of pairMap)}
		
		logger's logInfo("User activity analysis complete", {senders:(count of senderMap), receivers:(count of receiverMap)})
		
		return {topSenders:topSenders, topReceivers:topReceivers, userPairs:topPairs, statistics:statistics}
		
	on error errMsg
		logger's logError("User activity analysis failed: " & errMsg, missing value)
		return {topSenders:{}, topReceivers:{}, userPairs:{}, errorMsg:errMsg}
	end try
end analyzeUserActivity

-- Analyze recent transfer patterns
-- @param entries: List of NETLOG entries
-- @return: {recentTransfers:list, timeDistribution:record, statistics:record}
on analyzeRecentTransfers(entries)
	try
		logger's logInfo("Analyzing recent transfers", {entryCount:(count of entries)})
		
		-- Get most recent transfers (first 20)
		set recentTransfers to {}
		set maxRecent to 20
		if (count of entries) < maxRecent then
			set maxRecent to count of entries
		end if
		
		repeat with i from 1 to maxRecent
			set end of recentTransfers to item i of entries
		end repeat
		
		-- Analyze time distribution (simplified - would need actual timestamps)
		set timeDistribution to {morning:0, afternoon:0, evening:0, night:0}
		
		-- Count file types in recent transfers
		set filetypeMap to {}
		repeat with entry in recentTransfers
			set filetype to entry's filetype
			set found to false
			
			repeat with i from 1 to count of filetypeMap
				if (item i of filetypeMap)'s filetype is filetype then
					set (item i of filetypeMap)'s |count| to ((item i of filetypeMap)'s |count|) + 1
					set found to true
					exit repeat
				end if
			end repeat
			
			if not found then
				set end of filetypeMap to {filetype:filetype, |count|:1}
			end if
		end repeat
		
		-- Calculate statistics
		set statistics to {recentCount:(count of recentTransfers), filetypeDistribution:filetypeMap}
		
		logger's logInfo("Recent transfers analysis complete", {recentCount:(count of recentTransfers)})
		
		return {recentTransfers:recentTransfers, timeDistribution:timeDistribution, statistics:statistics}
		
	on error errMsg
		logger's logError("Recent transfers analysis failed: " & errMsg, missing value)
		return {recentTransfers:{}, timeDistribution:{}, errorMsg:errMsg}
	end try
end analyzeRecentTransfers

-- Helper: Get top N items from a map (sorted by count)
-- @param itemMap: List of records with count property
-- @param topN: Number of top items to return
-- @return: List of top N items
on getTopItems(itemMap, topN)
	try
		-- Sort by count (bubble sort)
		set sortedItems to itemMap
		repeat with i from 1 to (count of sortedItems) - 1
			repeat with j from 1 to (count of sortedItems) - i
				set item1 to item j of sortedItems
				set item2 to item (j + 1) of sortedItems
				if item1's |count| < item2's |count| then
					set temp to item1
					set item j of sortedItems to item2
					set item (j + 1) of sortedItems to temp
				end if
			end repeat
		end repeat
		
		-- Get top N
		set topItems to {}
		set maxItems to topN
		if (count of sortedItems) < maxItems then
			set maxItems to count of sortedItems
		end if
		
		repeat with i from 1 to maxItems
			set end of topItems to item i of sortedItems
		end repeat
		
		return topItems
		
	on error
		return {}
	end try
end getTopItems

-- Generate analysis report
-- @param analysisResult: Result from workflowNetlogAnalysis
-- @return: {success:boolean, report:string}
on generateAnalysisReport(analysisResult)
	try
		logger's logInfo("Generating analysis report", missing value)
		
		set report to "=== NETLOG ANALYSIS REPORT ===" & return & return
		
		set report to report & "Total Entries Analyzed: " & analysisResult's totalEntries & return
		set report to report & "Analysis Duration: " & helpers's formatDuration(analysisResult's duration) & return
		set report to report & return
		
		-- File frequency section
		if analysisResult's analysis is not missing value then
			set fileFreq to analysisResult's analysis's fileFrequency
			set report to report & "--- FILE FREQUENCY ---" & return
			set report to report & "Total Unique Files: " & fileFreq's totalFiles & return
			set report to report & "Top Files:" & return
			
			repeat with fileEntry in fileFreq's topFiles
				set report to report & "  " & fileEntry's filename & ": " & fileEntry's |count| & " transfers" & return
			end repeat
			set report to report & return
		end if
		
		-- User activity section
		if analysisResult's analysis contains {userActivity:missing value} is false then
			set userActivity to analysisResult's analysis's userActivity
			set report to report & "--- USER ACTIVITY ---" & return
			set report to report & "Total Senders: " & userActivity's statistics's totalSenders & return
			set report to report & "Total Receivers: " & userActivity's statistics's totalReceivers & return
			set report to report & "Top Senders:" & return
			
			repeat with sender in userActivity's topSenders
				set report to report & "  " & sender's username & ": " & sender's |count| & " sends" & return
			end repeat
			set report to report & return
		end if
		
		-- Recent transfers section
		if analysisResult's analysis contains {recentTransfers:missing value} is false then
			set recentTransfers to analysisResult's analysis's recentTransfers
			set report to report & "--- RECENT TRANSFERS ---" & return
			set report to report & "Recent Count: " & recentTransfers's statistics's recentCount & return
			set report to report & return
		end if
		
		set report to report & "=== END REPORT ===" & return
		
		logger's logInfo("Analysis report generated", missing value)
		
		return {success:true, report:report}
		
	on error errMsg
		logger's logError("Report generation failed: " & errMsg, missing value)
		return {success:false, message:"Report error: " & errMsg}
	end try
end generateAnalysisReport

-- Export analysis to file
-- @param analysisResult: Result from workflowNetlogAnalysis
-- @param outputPath: Path to save report
-- @return: {success:boolean, filepath:string}
on exportAnalysisToFile(analysisResult, outputPath)
	try
		logger's logInfo("Exporting analysis to file", {path:outputPath})
		
		-- Generate report
		set reportResult to generateAnalysisReport(analysisResult)
		if not reportResult's success then
			return {success:false, message:"Report generation failed"}
		end if
		
		-- Write to file
		set fileRef to open for access POSIX file outputPath with write permission
		set eof fileRef to 0
		write reportResult's report to fileRef
		close access fileRef
		
		logger's logInfo("Analysis exported successfully", {path:outputPath})
		
		return {success:true, filepath:outputPath, message:"Analysis exported"}
		
	on error errMsg
		try
			close access POSIX file outputPath
		end try
		logger's logError("Export failed: " & errMsg, {path:outputPath})
		return {success:false, message:"Export error: " & errMsg}
	end try
end exportAnalysisToFile

-- Example usage function
on exampleUsage()
	-- Example 1: File frequency analysis
	set result1 to workflowNetlogAnalysis("A", "file_frequency")
	
	-- Example 2: User activity analysis
	set result2 to workflowNetlogAnalysis("A", "user_activity")
	
	-- Example 3: Recent transfers analysis
	set result3 to workflowNetlogAnalysis("A", "recent_transfers")
	
	-- Example 4: Complete analysis
	set result4 to workflowNetlogAnalysis("A", "all")
	
	-- Example 5: Generate and export report
	if result4's success then
		set reportResult to generateAnalysisReport(result4)
		set exportPath to "/Users/okyereboateng/bobathon/logs/netlog_analysis_report.txt"
		set exportResult to exportAnalysisToFile(result4, exportPath)
	end if
	
	return {example1:result1, example2:result2, example3:result3, example4:result4}
end exampleUsage

log "NETLOG Analysis Workflow Module Loaded"

-- Made with Bob
