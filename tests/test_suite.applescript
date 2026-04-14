-- ============================================================================
-- Comprehensive Test Suite for IBM Host On-Demand Automation
-- ============================================================================
-- Purpose: Test all components of the automation system
-- Author: Bob (AI Software Engineer)
-- Phase: 8 - Testing & Demo
-- ============================================================================

-- Load all modules
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.scpt"
property windowManager : load script POSIX file "/Users/okyereboateng/bobathon/src/core/window_manager.scpt"
property screenCapture : load script POSIX file "/Users/okyereboateng/bobathon/src/core/screen_capture.scpt"
property keyboardController : load script POSIX file "/Users/okyereboateng/bobathon/src/core/keyboard_controller.scpt"
property clipboardManager : load script POSIX file "/Users/okyereboateng/bobathon/src/core/clipboard_manager.scpt"
property screenParser : load script POSIX file "/Users/okyereboateng/bobathon/src/parsers/screen_parser.scpt"
property decisionEngine : load script POSIX file "/Users/okyereboateng/bobathon/src/engine/decision_engine.scpt"
property workflowExecutor : load script POSIX file "/Users/okyereboateng/bobathon/src/engine/workflow_executor.scpt"
property logger : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/logger.scpt"
property errorHandler : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/error_handler.scpt"

-- Test configuration
property TEST_SESSION : "A" -- Change to your session letter
property TEST_TIMEOUT : 30
property VERBOSE_OUTPUT : true

-- Test results tracking
property totalTests : 0
property passedTests : 0
property failedTests : 0
property skippedTests : 0
property testResults : {}

-- ============================================================================
-- MAIN TEST RUNNER
-- ============================================================================

on runAllTests()
	try
		log "========================================================================"
		log "IBM Host On-Demand Automation - Comprehensive Test Suite"
		log "========================================================================"
		log "Start Time: " & (current date as string)
		log ""
		
		-- Initialize logging
		logger's initializeLogging()
		logger's logInfo("Test suite started", missing value)
		
		-- Reset counters
		set totalTests to 0
		set passedTests to 0
		set failedTests to 0
		set skippedTests to 0
		set testResults to {}
		
		-- Run test categories
		log "Running Core Module Tests..."
		testWindowManager()
		testClipboardManager()
		testScreenCapture()
		testKeyboardController()
		
		log ""
		log "Running Parser Tests..."
		testParsers()
		
		log ""
		log "Running Engine Tests..."
		testDecisionEngine()
		testWorkflowExecutor()
		
		log ""
		log "Running Utility Tests..."
		testLogger()
		testErrorHandler()
		
		log ""
		log "Running Integration Tests..."
		testMainAPI()
		testWorkflows()
		
		-- Print summary
		printTestSummary()
		
		-- Log results
		logger's logInfo("Test suite completed", {total:totalTests, passed:passedTests, failed:failedTests, skipped:skippedTests})
		
		return {success:(failedTests = 0), totalTests:totalTests, passed:passedTests, failed:failedTests, skipped:skippedTests, results:testResults}
		
	on error errMsg number errNum
		log "FATAL ERROR in test suite: " & errMsg & " (" & errNum & ")"
		logger's logError("Test suite fatal error: " & errMsg, {errorNumber:errNum})
		return {success:false, errorMsg:errMsg, errorNumber:errNum}
	end try
end runAllTests

-- ============================================================================
-- WINDOW MANAGER TESTS
-- ============================================================================

on testWindowManager()
	log "--- Testing Window Manager ---"
	
	-- Test 1: Get all HOD sessions
	runTestDirect("Window Manager: Get all sessions", "testGetAllSessions")
	
	-- Test 2: Find specific window
	runTestDirect("Window Manager: Find HOD window", "testFindHODWindow")
	
	-- Test 3: Activate window
	runTestDirect("Window Manager: Activate window", "testActivateWindow")
	
	-- Test 4: Get window bounds
	runTestDirect("Window Manager: Get window bounds", "testGetWindowBounds")
	
	-- Test 5: Validate window
	runTestDirect("Window Manager: Validate window", "testValidateWindow")
end testWindowManager

on testGetAllSessions()
	set sessions to windowManager's getAllHODSessions()
	if (count of sessions) > 0 then
		return {success:true, message:"Found " & (count of sessions) & " session(s)"}
	else
		return {success:false, message:"No sessions found"}
	end if
end testGetAllSessions

on testFindHODWindow()
	set windowRef to windowManager's findHODWindow(TEST_SESSION)
	if windowRef is not missing value then
		return {success:true, message:"Window found for session " & TEST_SESSION}
	else
		return {success:false, message:"Window not found"}
	end if
end testFindHODWindow

on testActivateWindow()
	set windowRef to windowManager's findHODWindow(TEST_SESSION)
	if windowRef is missing value then
		return {success:false, message:"Window not found", skipped:true}
	end if
	
	set activated to windowManager's activateHODWindow(windowRef)
	if activated then
		return {success:true, message:"Window activated"}
	else
		return {success:false, message:"Activation failed"}
	end if
end testActivateWindow

on testGetWindowBounds()
	set windowRef to windowManager's findHODWindow(TEST_SESSION)
	if windowRef is missing value then
		return {success:false, message:"Window not found", skipped:true}
	end if
	
	set bounds to windowManager's getWindowBounds(windowRef)
	if bounds is not missing value then
		return {success:true, message:"Bounds: " & bounds's width & "x" & bounds's height}
	else
		return {success:false, message:"Could not get bounds"}
	end if
end testGetWindowBounds

on testValidateWindow()
	set windowRef to windowManager's findHODWindow(TEST_SESSION)
	if windowRef is missing value then
		return {success:false, message:"Window not found", skipped:true}
	end if
	
	set valid to windowManager's isWindowValid(windowRef)
	if valid then
		return {success:true, message:"Window is valid"}
	else
		return {success:false, message:"Window is not valid"}
	end if
end testValidateWindow

-- ============================================================================
-- CLIPBOARD MANAGER TESTS
-- ============================================================================

on testClipboardManager()
	log "--- Testing Clipboard Manager ---"
	
	runTest("Clipboard: Clear clipboard", testClearClipboard)
	runTest("Clipboard: Write to clipboard", testWriteClipboard)
	runTest("Clipboard: Read from clipboard", testReadClipboard)
	runTest("Clipboard: Validate content", testValidateClipboard)
	runTest("Clipboard: Get clipboard info", testGetClipboardInfo)
end testClipboardManager

on testClearClipboard()
	set cleared to clipboardManager's clearClipboard()
	if cleared then
		return {success:true, message:"Clipboard cleared"}
	else
		return {success:false, message:"Clear failed"}
	end if
end testClearClipboard

on testWriteClipboard()
	set testContent to "Test content for clipboard - " & (current date as string)
	set written to clipboardManager's writeClipboard(testContent)
	if written then
		return {success:true, message:"Content written"}
	else
		return {success:false, message:"Write failed"}
	end if
end testWriteClipboard

on testReadClipboard()
	set content to clipboardManager's readClipboard()
	if content is not missing value and content is not "" then
		return {success:true, message:"Read " & (length of content) & " characters"}
	else
		return {success:false, message:"Read failed"}
	end if
end testReadClipboard

on testValidateClipboard()
	set validation to clipboardManager's validateClipboard(missing value)
	if validation's valid then
		return {success:true, message:"Validation passed"}
	else
		return {success:false, message:validation's reason}
	end if
end testValidateClipboard

on testGetClipboardInfo()
	set info to clipboardManager's getClipboardInfo()
	if info's hasContent then
		return {success:true, message:"Info: " & info's length & " chars, type: " & info's type}
	else
		return {success:false, message:"No content"}
	end if
end testGetClipboardInfo

-- ============================================================================
-- SCREEN CAPTURE TESTS
-- ============================================================================

on testScreenCapture()
	log "--- Testing Screen Capture ---"
	
	runTest("Screen Capture: Validate capture", testValidateCapture)
	runTest("Screen Capture: Get selection margins", testSelectionMargins)
end testScreenCapture

on testValidateCapture()
	set testText to "This is a test screen with multiple lines" & return & "Line 2" & return & "Line 3"
	set validation to screenCapture's validateCapture(testText)
	if validation's valid then
		return {success:true, message:"Validation passed"}
	else
		return {success:false, message:validation's reason}
	end if
end testValidateCapture

on testSelectionMargins()
	-- Just test that we can set margins without error
	try
		set margins to {|top|:60, |left|:5, |right|:5, |bottom|:5}
		screenCapture's setSelectionMargins(margins)
		return {success:true, message:"Margins set successfully"}
	on error errMsg
		return {success:false, message:"Margin setting failed: " & errMsg}
	end try
end testSelectionMargins

-- ============================================================================
-- KEYBOARD CONTROLLER TESTS
-- ============================================================================

on testKeyboardController()
	log "--- Testing Keyboard Controller ---"
	
	runTest("Keyboard: Get PF key name", testGetPFKeyName)
	runTest("Keyboard: Get all PF keys", testGetAllPFKeys)
	runTest("Keyboard: Delay configuration", testKeyboardDelays)
end testKeyboardController

on testGetPFKeyName()
	set keyName to keyboardController's getPFKeyName(3)
	if keyName contains "PF3" then
		return {success:true, message:"Got key name: " & keyName}
	else
		return {success:false, message:"Wrong key name: " & keyName}
	end if
end testGetPFKeyName

on testGetAllPFKeys()
	set allKeys to keyboardController's getAllPFKeys()
	if (count of allKeys) = 12 then
		return {success:true, message:"Got all 12 PF keys"}
	else
		return {success:false, message:"Expected 12 keys, got " & (count of allKeys)}
	end if
end testGetAllPFKeys

on testKeyboardDelays()
	try
		keyboardController's setKeystrokeDelay(0.05)
		keyboardController's setPostEnterDelay(0.5)
		keyboardController's setPostPFKeyDelay(0.2)
		return {success:true, message:"Delays configured"}
	on error errMsg
		return {success:false, message:"Delay configuration failed: " & errMsg}
	end try
end testKeyboardDelays

-- ============================================================================
-- PARSER TESTS
-- ============================================================================

on testParsers()
	log "--- Testing Parsers ---"
	
	runTest("Parser: Parse CMS prompt", testParseCMSPrompt)
	runTest("Parser: Parse XEDIT screen", testParseXEDIT)
	runTest("Parser: Parse NETLOG screen", testParseNETLOG)
	runTest("Parser: Detect screen type", testDetectScreenType)
	runTest("Parser: Parse PF key menu", testParsePFKeyMenu)
end testParsers

on testParseCMSPrompt()
	set testScreen to "Ready;" & return & "LISTFILE * * A"
	set parsed to screenParser's parseScreen(testScreen)
	if parsed's screenType contains "READY" or parsed's screenType contains "CMS" then
		return {success:true, message:"CMS prompt detected"}
	else
		return {success:false, message:"Wrong screen type: " & parsed's screenType}
	end if
end testParseCMSPrompt

on testParseXEDIT()
	set testScreen to "TESTUSER MYFILE DATA A1 V 80" & return & "====>" & return & "Line 1 content"
	set parsed to screenParser's parseScreen(testScreen)
	if parsed's screenType is "XEDIT" then
		return {success:true, message:"XEDIT screen detected"}
	else
		return {success:false, message:"Wrong screen type: " & parsed's screenType}
	end if
end testParseXEDIT

on testParseNETLOG()
	set testScreen to "TESTUSER NETLOG NETLOG A0" & return & "* * * Top of File * * *" & return & "recv from USER1"
	set parsed to screenParser's parseScreen(testScreen)
	if parsed's screenType is "NETLOG" then
		return {success:true, message:"NETLOG screen detected"}
	else
		return {success:false, message:"Wrong screen type: " & parsed's screenType}
	end if
end testParseNETLOG

on testDetectScreenType()
	set testLines to {"Ready;", "LISTFILE * * A"}
	set screenType to screenParser's detectScreenType(testLines)
	if screenType is not "UNKNOWN" then
		return {success:true, message:"Screen type: " & screenType}
	else
		return {success:false, message:"Could not detect screen type"}
	end if
end testDetectScreenType

on testParsePFKeyMenu()
	set testFooter to "1=Help 2=Add 3=Quit 4=Tab 5=Change"
	set pfKeys to screenParser's parsePFKeyMenu(testFooter)
	if (count of pfKeys) > 0 then
		return {success:true, message:"Parsed " & (count of pfKeys) & " PF keys"}
	else
		return {success:false, message:"No PF keys parsed"}
	end if
end testParsePFKeyMenu

-- ============================================================================
-- DECISION ENGINE TESTS
-- ============================================================================

on testDecisionEngine()
	log "--- Testing Decision Engine ---"
	
	runTest("Decision: Make navigation decision", testNavigationDecision)
	runTest("Decision: Validate decision", testValidateDecision)
	runTest("Decision: Error recovery decision", testErrorRecoveryDecision)
end testDecisionEngine

on testNavigationDecision()
	set screenData to {screenType:"CMS_READY", content:{}, header:{}}
	set goal to {goalType:"navigate_to_file", target:{filename:"TEST", filetype:"DATA"}}
	
	set decision to decisionEngine's makeDecision(screenData, goal)
	if decision's action is not "error" then
		return {success:true, message:"Decision: " & decision's action & " (confidence: " & decision's confidence & ")"}
	else
		return {success:false, message:"Decision error: " & decision's reasoning}
	end if
end testNavigationDecision

on testValidateDecision()
	set decision to {action:"type_command", parameters:{}, confidence:0.9}
	set screenData to {screenType:"CMS_READY"}
	
	set valid to decisionEngine's validateDecision(decision, screenData)
	if valid then
		return {success:true, message:"Decision validated"}
	else
		return {success:false, message:"Decision validation failed"}
	end if
end testValidateDecision

on testErrorRecoveryDecision()
	set screenData to {screenType:"ERROR", content:{"DMSABE104S File not found"}}
	
	set decision to decisionEngine's decideErrorRecovery(screenData)
	if decision's action is not "error" then
		return {success:true, message:"Recovery decision: " & decision's action}
	else
		return {success:false, message:"Recovery decision failed"}
	end if
end testErrorRecoveryDecision

-- ============================================================================
-- WORKFLOW EXECUTOR TESTS
-- ============================================================================

on testWorkflowExecutor()
	log "--- Testing Workflow Executor ---"
	
	runTest("Workflow: Create simple workflow", testCreateSimpleWorkflow)
	runTest("Workflow: Validate step result", testValidateStepResult)
end testWorkflowExecutor

on testCreateSimpleWorkflow()
	set actions to {"capture_screen", "parse_screen", "wait"}
	set workflow to workflowExecutor's createSimpleWorkflow(actions)
	
	if (count of workflow) = 3 then
		return {success:true, message:"Created workflow with 3 steps"}
	else
		return {success:false, message:"Wrong step count: " & (count of workflow)}
	end if
end testCreateSimpleWorkflow

on testValidateStepResult()
	set result to {success:true, data:{screenType:"CMS_READY"}}
	set expected to {validationType:"screen_type", expectedValue:"CMS_READY"}
	
	set validation to workflowExecutor's validateStepResult(result, expected)
	if validation's success then
		return {success:true, message:"Step validation passed"}
	else
		return {success:false, message:validation's message}
	end if
end testValidateStepResult

-- ============================================================================
-- LOGGER TESTS
-- ============================================================================

on testLogger()
	log "--- Testing Logger ---"
	
	runTest("Logger: Initialize logging", testInitializeLogging)
	runTest("Logger: Log messages", testLogMessages)
	runTest("Logger: Get session stats", testGetSessionStats)
	runTest("Logger: Format duration", testFormatDuration)
end testLogger

on testInitializeLogging()
	set result to logger's initializeLogging()
	if result's success then
		return {success:true, message:"Logging initialized"}
	else
		return {success:false, message:result's message}
	end if
end testInitializeLogging

on testLogMessages()
	try
		logger's logInfo("Test info message", {test:true})
		logger's logWarn("Test warning message", missing value)
		logger's logDebug("Test debug message", missing value)
		return {success:true, message:"All log levels working"}
	on error errMsg
		return {success:false, message:"Logging failed: " & errMsg}
	end try
end testLogMessages

on testGetSessionStats()
	set stats to logger's getSessionStats()
	if stats's success then
		return {success:true, message:"Stats retrieved"}
	else
		return {success:false, message:stats's message}
	end if
end testGetSessionStats

on testFormatDuration()
	try
		set formatted to logger's formatDuration(2.5)
		if formatted contains "s" then
			return {success:true, message:"Duration formatted: " & formatted}
		else
			return {success:false, message:"Wrong format: " & formatted}
		end if
	on error errMsg
		return {success:false, message:"Format failed: " & errMsg}
	end try
end testFormatDuration

-- ============================================================================
-- ERROR HANDLER TESTS
-- ============================================================================

on testErrorHandler()
	log "--- Testing Error Handler ---"
	
	runTest("Error Handler: Categorize error", testCategorizeError)
	runTest("Error Handler: Calculate backoff", testCalculateBackoff)
	runTest("Error Handler: Check recoverable", testIsRecoverable)
end testErrorHandler

on testCategorizeError()
	set category to errorHandler's categorizeError("timeout occurred")
	if category is "transient" then
		return {success:true, message:"Error categorized as transient"}
	else
		return {success:false, message:"Wrong category: " & category}
	end if
end testCategorizeError

on testCalculateBackoff()
	set backoff to errorHandler's calculateBackoff(2)
	if backoff > 0 then
		return {success:true, message:"Backoff: " & backoff & " seconds"}
	else
		return {success:false, message:"Invalid backoff: " & backoff}
	end if
end testCalculateBackoff

on testIsRecoverable()
	set recoverable to errorHandler's isRecoverable("transient")
	if recoverable then
		return {success:true, message:"Transient errors are recoverable"}
	else
		return {success:false, message:"Should be recoverable"}
	end if
end testIsRecoverable

-- ============================================================================
-- MAIN API TESTS
-- ============================================================================

on testMainAPI()
	log "--- Testing Main API ---"
	
	runTest("Main API: Session initialization", testInitSession)
	runTest("Main API: Get session state", testGetSessionState)
	runTest("Main API: Close session", testCloseSession)
end testMainAPI

on testInitSession()
	set result to mainAPI's initSession(TEST_SESSION)
	if result's success then
		-- Store session for other tests
		set my testSession to result's session
		return {success:true, message:"Session initialized: " & result's screenType}
	else
		return {success:false, message:result's message}
	end if
end testInitSession

on testGetSessionState()
	try
		set result to mainAPI's initSession(TEST_SESSION)
		if not result's success then
			return {success:false, message:"Session init failed", skipped:true}
		end if
		
		set stateResult to mainAPI's getSessionState(result's session)
		mainAPI's closeSession(result's session)
		
		if stateResult's success then
			return {success:true, message:"State retrieved"}
		else
			return {success:false, message:stateResult's message}
		end if
	on error errMsg
		return {success:false, message:errMsg}
	end try
end testGetSessionState

on testCloseSession()
	try
		set result to mainAPI's initSession(TEST_SESSION)
		if not result's success then
			return {success:false, message:"Session init failed", skipped:true}
		end if
		
		set closeResult to mainAPI's closeSession(result's session)
		if closeResult's success then
			return {success:true, message:"Session closed"}
		else
			return {success:false, message:closeResult's message}
		end if
	on error errMsg
		return {success:false, message:errMsg}
	end try
end testCloseSession

-- ============================================================================
-- WORKFLOW TESTS
-- ============================================================================

on testWorkflows()
	log "--- Testing Example Workflows ---"
	
	runTest("Workflow: Basic session workflow", testBasicWorkflow)
end testWorkflows

on testBasicWorkflow()
	try
		-- Simple workflow: init, get state, close
		set result to mainAPI's initSession(TEST_SESSION)
		if not result's success then
			return {success:false, message:"Init failed"}
		end if
		
		set session to result's session
		set stateResult to mainAPI's getSessionState(session)
		set closeResult to mainAPI's closeSession(session)
		
		if closeResult's success then
			return {success:true, message:"Basic workflow completed"}
		else
			return {success:false, message:"Workflow failed"}
		end if
	on error errMsg
		return {success:false, message:errMsg}
	end try
end testBasicWorkflow

-- ============================================================================
-- TEST UTILITIES
-- ============================================================================
on runTestDirect(testName, testHandlerName)
	set totalTests to totalTests + 1
	
	try
		if VERBOSE_OUTPUT then
			log "  Running: " & testName
		end if
		
		-- Call the test handler by name
		if testHandlerName is "testGetAllSessions" then
			set result to testGetAllSessions()
		else if testHandlerName is "testFindHODWindow" then
			set result to testFindHODWindow()
		else if testHandlerName is "testActivateWindow" then
			set result to testActivateWindow()
		else if testHandlerName is "testGetWindowBounds" then
			set result to testGetWindowBounds()
		else if testHandlerName is "testValidateWindow" then
			set result to testValidateWindow()
		else
			set result to {success:false, message:"Unknown test: " & testHandlerName}
		end if
		
		-- Check if test was skipped
		try
			if result's skipped then
				set skippedTests to skippedTests + 1
				log "  ⊘ SKIPPED: " & testName & " - " & result's message
				set end of testResults to {name:testName, status:"SKIPPED", message:result's message}
				return
			end if
		end try
		
		-- Check test result
		if result's success then
			set passedTests to passedTests + 1
			if VERBOSE_OUTPUT then
				log "  ✓ PASSED: " & testName & " - " & result's message
			end if
			set end of testResults to {name:testName, status:"PASSED", message:result's message}
		else
			set failedTests to failedTests + 1
			log "  ✗ FAILED: " & testName & " - " & result's message
			set end of testResults to {name:testName, status:"FAILED", message:result's message}
		end if
		
	on error errMsg number errNum
		set failedTests to failedTests + 1
		log "  ✗ ERROR: " & testName & " - " & errMsg & " (" & errNum & ")"
		set end of testResults to {name:testName, status:"ERROR", message:errMsg}
	end try
end runTestDirect


on runTest(testName, testHandler)
	set totalTests to totalTests + 1
	
	try
		if VERBOSE_OUTPUT then
			log "  Running: " & testName
		end if
		
		set result to testHandler()
		
		-- Check if test was skipped
		try
			if result's skipped then
				set skippedTests to skippedTests + 1
				log "  ⊘ SKIPPED: " & testName & " - " & result's message
				set end of testResults to {name:testName, status:"SKIPPED", message:result's message}
				return
			end if
		end try
		
		-- Check test result
		if result's success then
			set passedTests to passedTests + 1
			if VERBOSE_OUTPUT then
				log "  ✓ PASSED: " & testName & " - " & result's message
			end if
			set end of testResults to {name:testName, status:"PASSED", message:result's message}
		else
			set failedTests to failedTests + 1
			log "  ✗ FAILED: " & testName & " - " & result's message
			set end of testResults to {name:testName, status:"FAILED", message:result's message}
		end if
		
	on error errMsg number errNum
		set failedTests to failedTests + 1
		log "  ✗ ERROR: " & testName & " - " & errMsg & " (" & errNum & ")"
		set end of testResults to {name:testName, status:"ERROR", message:errMsg, errorNumber:errNum}
	end try
end runTest

on printTestSummary()
	log ""
	log "========================================================================"
	log "TEST SUMMARY"
	log "========================================================================"
	log "Total Tests:   " & totalTests
	log "Passed:        " & passedTests & " (" & (round ((passedTests / totalTests) * 100)) & "%)"
	log "Failed:        " & failedTests
	log "Skipped:       " & skippedTests
	log "========================================================================"
	
	if failedTests > 0 then
		log ""
		log "FAILED TESTS:"
		repeat with result in testResults
			if result's status is "FAILED" or result's status is "ERROR" then
				log "  - " & result's name & ": " & result's message
			end if
		end repeat
	end if
	
	log ""
	if failedTests = 0 then
		log "✓ ALL TESTS PASSED!"
	else
		log "✗ SOME TESTS FAILED - Review errors above"
	end if
	
	log ""
	log "End Time: " & (current date as string)
	log "========================================================================"
end printTestSummary

-- ============================================================================
-- EXECUTE TEST SUITE
-- ============================================================================

-- Run all tests when script is executed
runAllTests()

-- Made with Bob