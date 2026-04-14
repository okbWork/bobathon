(*
	Decision Engine - Intelligent decision-making for IBM Host On-Demand automation
	
	This module implements goal-oriented decision making based on parsed screen
	data. It analyzes the current state, determines the best action to achieve
	the goal, and provides reasoning for each decision.
	
	Key capabilities:
	- File navigation decisions
	- NETLOG search strategies
	- File editing operations
	- Error recovery
	- Multi-step planning
	
	Author: Bob (AI Software Engineer)
	Phase: 3 - Intelligence Layer
*)

use AppleScript version "2.4"
use scripting additions

-- ============================================================================
-- MAIN DECISION FUNCTION
-- ============================================================================

(*
	Make intelligent decision based on screen data and goal
	
	@param screenData - Parsed screen data from screen_parser
	@param goal - Record describing the desired outcome: {type, target, parameters}
	@return Record: {action, parameters, reasoning, confidence}
*)
on makeDecision(screenData, goal)
	try
		-- Extract screen type and goal type
		set screenType to screenType of screenData
		set goalType to ""
		
		try
			set goalType to goalType of goal
		on error
			set goalType to "unknown"
		end try
		
		-- Route to appropriate decision handler based on goal type
		if goalType is "navigate_to_file" then
			return decideFileNavigation(screenData, goal)
		else if goalType is "search_netlog" then
			return decideNetlogSearch(screenData, goal)
		else if goalType is "edit_file" then
			return decideFileEdit(screenData, goal)
		else if goalType is "error_recovery" then
			return decideErrorRecovery(screenData)
		else if screenType is "ERROR" then
			-- Auto-detect error and attempt recovery
			return decideErrorRecovery(screenData)
		else
			-- Default: analyze current state and suggest next action
			return analyzeCurrentState(screenData, goal)
		end if
		
	on error errMsg number errNum
		log "Error in makeDecision: " & errMsg & " (" & errNum & ")"
		return {action:"error", parameters:{}, reasoning:"Decision engine error: " & errMsg, confidence:0}
	end try
end makeDecision

-- ============================================================================
-- FILE NAVIGATION DECISIONS
-- ============================================================================

(*
	Decide how to navigate to a specific file
	
	@param screenData - Current screen state
	@param goal - Goal with target file information
	@return Decision record
*)
on decideFileNavigation(screenData, goal)
	try
		set screenType to screenType of screenData
		set targetFile to ""
		set targetType to ""
		
		-- Extract target file information
		try
			set targetFile to filename of target of goal
			set targetType to filetype of target of goal
		end try
		
		-- Decision based on current screen type
		if screenType is "CMS_READY" then
			-- At CMS prompt, need to open FILELIST or directly edit file
			return {action:"type_command", parameters:{command:"FILELIST"}, reasoning:"At CMS prompt, opening FILELIST to locate file " & targetFile & " " & targetType, confidence:0.9}
			
		else if screenType is "FILELIST" then
			-- In FILELIST, search for the file
			set filelistData to content of screenData
			
			-- Check if target file is visible
			set fileFound to false
			try
				repeat with filelistLine in filelistData
					set lineText to filelistLine as text
					if lineText contains targetFile and lineText contains targetType then
						set fileFound to true
						exit repeat
					end if
				end repeat
			end try
			
			if fileFound then
				-- File is visible, select and edit it
				return {action:"select_file", parameters:{filename:targetFile, filetype:targetType}, reasoning:"Target file " & targetFile & " " & targetType & " found in FILELIST, selecting for edit", confidence:0.95}
			else
				-- File not visible, need to search or scroll
				return {action:"search_filelist", parameters:{filename:targetFile, filetype:targetType}, reasoning:"Target file not visible, searching FILELIST for " & targetFile & " " & targetType, confidence:0.85}
			end if
			
		else if screenType is "XEDIT" then
			-- Already in editor, check if it's the right file
			set headerData to header of screenData
			set currentFile to ""
			set currentType to ""
			
			try
				set currentFile to filename of headerData
				set currentType to filetype of headerData
			end try
			
			if currentFile is targetFile and currentType is targetType then
				-- Already editing target file
				return {action:"continue", parameters:{}, reasoning:"Already editing target file " & targetFile & " " & targetType, confidence:1.0}
			else
				-- Wrong file, need to quit and navigate to correct file
				return {action:"quit_editor", parameters:{}, reasoning:"Currently editing " & currentFile & " " & currentType & ", need to quit and navigate to " & targetFile & " " & targetType, confidence:0.9}
			end if
			
		else if screenType is "NETLOG" then
			-- In NETLOG, need to exit and navigate to file
			return {action:"press_pf_key", parameters:{keyNumber:3}, reasoning:"In NETLOG, pressing PF3 to quit and navigate to target file", confidence:0.85}
			
		else
			-- Unknown state, try to get to CMS prompt
			return {action:"press_pf_key", parameters:{keyNumber:3}, reasoning:"Unknown screen state, attempting to return to CMS prompt", confidence:0.6}
		end if
		
	on error errMsg
		log "Error in decideFileNavigation: " & errMsg
		return {action:"error", parameters:{}, reasoning:"Navigation decision error: " & errMsg, confidence:0}
	end try
end decideFileNavigation

-- ============================================================================
-- NETLOG SEARCH DECISIONS
-- ============================================================================

(*
	Decide how to search NETLOG for specific entries
	
	@param screenData - Current screen state
	@param goal - Goal with search criteria
	@return Decision record
*)
on decideNetlogSearch(screenData, goal)
	try
		set screenType to screenType of screenData
		set searchCriteria to {}
		
		try
			set searchCriteria to criteria of goal
		end try
		
		-- Decision based on current screen type
		if screenType is "CMS_READY" then
			-- At CMS prompt, need to open NETLOG
			return {action:"type_command", parameters:{command:"XEDIT NETLOG NETLOG A"}, reasoning:"At CMS prompt, opening NETLOG file for search", confidence:0.9}
			
		else if screenType is "NETLOG" then
			-- Already in NETLOG, analyze content
			set netlogContent to content of screenData
			
			-- Check if we're at top of file
			set atTop to false
			try
				repeat with netlogLine in netlogContent
					if (netlogLine as text) contains "* * * Top of File * * *" then
						set atTop to true
						exit repeat
					end if
				end repeat
			end try
			
			-- Determine search strategy
			if atTop then
				-- At top, start forward search
				return {action:"search_forward", parameters:searchCriteria, reasoning:"At top of NETLOG, initiating forward search for specified criteria", confidence:0.9}
			else
				-- Not at top, go to top first
				return {action:"press_pf_key", parameters:{keyNumber:5}, reasoning:"Not at top of NETLOG, going to beginning before search", confidence:0.85}
			end if
			
		else if screenType is "XEDIT" then
			-- In editor but not NETLOG, check if it's NETLOG
			set headerData to header of screenData
			set currentFile to ""
			
			try
				set currentFile to filename of headerData
			end try
			
			if currentFile is "NETLOG" then
				-- In NETLOG editor, proceed with search
				return {action:"search_forward", parameters:searchCriteria, reasoning:"In NETLOG editor, executing search", confidence:0.9}
			else
				-- Wrong file, need to open NETLOG
				return {action:"quit_editor", parameters:{}, reasoning:"In wrong file, need to quit and open NETLOG", confidence:0.8}
			end if
			
		else
			-- Unknown state, try to get to CMS prompt
			return {action:"press_pf_key", parameters:{keyNumber:3}, reasoning:"Unknown screen state, returning to CMS prompt to open NETLOG", confidence:0.6}
		end if
		
	on error errMsg
		log "Error in decideNetlogSearch: " & errMsg
		return {action:"error", parameters:{}, reasoning:"NETLOG search decision error: " & errMsg, confidence:0}
	end try
end decideNetlogSearch

-- ============================================================================
-- FILE EDIT DECISIONS
-- ============================================================================

(*
	Decide how to perform file editing operations
	
	@param screenData - Current screen state
	@param goal - Goal with edit parameters
	@return Decision record
*)
on decideFileEdit(screenData, goal)
	try
		set screenType to screenType of screenData
		set editParams to {}
		
		try
			set editParams to parameters of goal
		end try
		
		-- Extract edit operation type
		set operation to ""
		try
			set operation to operation of editParams
		end try
		
		-- Decision based on current screen type
		if screenType is "XEDIT" then
			-- In editor, determine specific edit action
			
			if operation is "insert_line" then
				-- Insert new line
				set lineNum to 0
				set content to ""
				try
					set lineNum to lineNumber of editParams
					set content to content of editParams
				end try
				
				return {action:"insert_line", parameters:{lineNumber:lineNum, content:content}, reasoning:"Inserting line " & lineNum & " in editor", confidence:0.9}
				
			else if operation is "delete_line" then
				-- Delete line
				set lineNum to 0
				try
					set lineNum to lineNumber of editParams
				end try
				
				return {action:"delete_line", parameters:{lineNumber:lineNum}, reasoning:"Deleting line " & lineNum & " in editor", confidence:0.9}
				
			else if operation is "replace_text" then
				-- Replace text
				set searchText to ""
				set replaceText to ""
				try
					set searchText to searchText of editParams
					set replaceText to replaceText of editParams
				end try
				
				return {action:"replace_text", parameters:{searchText:searchText, replaceText:replaceText}, reasoning:"Replacing '" & searchText & "' with '" & replaceText & "'", confidence:0.85}
				
			else if operation is "save" then
				-- Save file
				return {action:"save_file", parameters:{}, reasoning:"Saving file changes", confidence:0.95}
				
			else
				-- Unknown operation
				return {action:"wait", parameters:{}, reasoning:"Unknown edit operation: " & operation, confidence:0.3}
			end if
			
		else
			-- Not in editor, need to navigate to file first
			return {action:"navigate_to_file", parameters:editParams, reasoning:"Not in editor, need to navigate to file before editing", confidence:0.8}
		end if
		
	on error errMsg
		log "Error in decideFileEdit: " & errMsg
		return {action:"error", parameters:{}, reasoning:"File edit decision error: " & errMsg, confidence:0}
	end try
end decideFileEdit

-- ============================================================================
-- ERROR RECOVERY DECISIONS
-- ============================================================================

(*
	Decide how to recover from error state
	
	@param screenData - Current screen state (with error)
	@return Decision record
*)
on decideErrorRecovery(screenData)
	try
		set screenType to screenType of screenData
		set contentLines to {}
		
		try
			set contentLines to content of screenData
		end try
		
		-- Analyze error message
		set errorType to "unknown"
		set errorMsg to ""
		
		repeat with errorLine in contentLines
			set lineText to errorLine as text
			
			-- Check for common error patterns
			if lineText contains "DMSABE" then
				set errorType to "file_not_found"
				set errorMsg to lineText
				exit repeat
			else if lineText contains "Invalid" then
				set errorType to "invalid_command"
				set errorMsg to lineText
				exit repeat
			else if lineText contains "not found" then
				set errorType to "not_found"
				set errorMsg to lineText
				exit repeat
			end if
		end repeat
		
		-- Decide recovery action based on error type
		if errorType is "file_not_found" then
			return {action:"return_to_prompt", parameters:{}, reasoning:"File not found error detected, returning to CMS prompt to try alternative approach", confidence:0.8}
			
		else if errorType is "invalid_command" then
			return {action:"return_to_prompt", parameters:{}, reasoning:"Invalid command error, returning to CMS prompt to retry with correct syntax", confidence:0.85}
			
		else if errorType is "not_found" then
			return {action:"return_to_prompt", parameters:{}, reasoning:"Resource not found, returning to CMS prompt", confidence:0.8}
			
		else
			-- Unknown error, try generic recovery
			return {action:"press_pf_key", parameters:{keyNumber:3}, reasoning:"Unknown error detected, attempting to exit current screen with PF3", confidence:0.6}
		end if
		
	on error errMsg
		log "Error in decideErrorRecovery: " & errMsg
		return {action:"error", parameters:{}, reasoning:"Error recovery decision failed: " & errMsg, confidence:0}
	end try
end decideErrorRecovery

-- ============================================================================
-- STATE ANALYSIS
-- ============================================================================

(*
	Analyze current state and suggest next action
	
	@param screenData - Current screen state
	@param goal - Current goal (may be incomplete)
	@return Decision record
*)
on analyzeCurrentState(screenData, goal)
	try
		set screenType to screenType of screenData
		
		-- Provide context-aware suggestions based on screen type
		if screenType is "CMS_READY" then
			return {action:"wait_for_input", parameters:{}, reasoning:"At CMS Ready prompt, awaiting user command or goal specification", confidence:0.9}
			
		else if screenType is "FILELIST" then
			return {action:"wait_for_selection", parameters:{}, reasoning:"In FILELIST, awaiting file selection or search criteria", confidence:0.9}
			
		else if screenType is "XEDIT" then
			set headerData to header of screenData
			set currentFile to ""
			try
				set currentFile to filename of headerData
			end try
			
			return {action:"wait_for_edit", parameters:{}, reasoning:"In XEDIT editing " & currentFile & ", awaiting edit commands", confidence:0.9}
			
		else if screenType is "NETLOG" then
			return {action:"wait_for_search", parameters:{}, reasoning:"In NETLOG, awaiting search criteria or navigation command", confidence:0.9}
			
		else if screenType is "ERROR" then
			return decideErrorRecovery(screenData)
			
		else
			return {action:"analyze_screen", parameters:{}, reasoning:"Unknown screen type, need more information to decide action", confidence:0.5}
		end if
		
	on error errMsg
		log "Error in analyzeCurrentState: " & errMsg
		return {action:"error", parameters:{}, reasoning:"State analysis error: " & errMsg, confidence:0}
	end try
end analyzeCurrentState

-- ============================================================================
-- DECISION VALIDATION
-- ============================================================================

(*
	Validate if a decision is safe to execute
	
	@param decision - Decision record to validate
	@param screenData - Current screen state
	@return Boolean indicating if decision is valid
*)
on validateDecision(decision, screenData)
	try
		set actionType to action of decision
		set confidence to confidence of decision
		
		-- Reject low-confidence decisions
		if confidence < 0.5 then
			log "Decision rejected: confidence too low (" & confidence & ")"
			return false
		end if
		
		-- Validate action type is recognized
		set validActions to {"type_command", "press_pf_key", "select_file", "search_filelist", "search_forward", "insert_line", "delete_line", "replace_text", "save_file", "quit_editor", "navigate_to_file", "return_to_prompt", "wait", "wait_for_input", "wait_for_selection", "wait_for_edit", "wait_for_search", "analyze_screen", "continue", "error"}
		
		set isValid to false
		repeat with validAction in validActions
			if actionType is validAction then
				set isValid to true
				exit repeat
			end if
		end repeat
		
		if not isValid then
			log "Decision rejected: unknown action type '" & actionType & "'"
			return false
		end if
		
		return true
		
	on error errMsg
		log "Error in validateDecision: " & errMsg
		return false
	end try
end validateDecision

-- ============================================================================
-- EXPORT HANDLERS
-- ============================================================================

-- Main exports
return {makeDecision:makeDecision, decideFileNavigation:decideFileNavigation, decideNetlogSearch:decideNetlogSearch, decideFileEdit:decideFileEdit, decideErrorRecovery:decideErrorRecovery, analyzeCurrentState:analyzeCurrentState, validateDecision:validateDecision}

-- Made with Bob
