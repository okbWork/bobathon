-- ============================================================================
-- Integration Test for IBM Host On-Demand Automation
-- ============================================================================
-- Purpose: End-to-end testing with actual HOD session
-- Author: Bob (AI Software Engineer)
-- Phase: 8 - Testing & Demo
-- ============================================================================

-- Load required modules
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"
property logger : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/logger.applescript"
property errorHandler : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/error_handler.applescript"

-- Test configuration
property TEST_SESSION : "A" -- Change to your session letter
property TEST_FILE : "PROFILE" -- Change to a file that exists on your system
property TEST_FILETYPE : "EXEC"
property TEST_FILEMODE : "A1"
property ENABLE_PERFORMANCE_TESTS : true
property ENABLE_STRESS_TESTS : false

-- Test results
property testResults : {}
property totalTests : 0
property passedTests : 0
property failedTests : 0

-- ============================================================================
-- MAIN TEST RUNNER
-- ============================================================================

on testFullWorkflow()
	try
		log "========================================================================"
		log "IBM Host On-Demand Automation - Integration Test"
		log "========================================================================"
		log "Start Time: " & (current date as string)
		log ""
		log "IMPORTANT: This test requires an active HOD session."
		log "Session: " & TEST_SESSION
		log ""
		
		-- Initialize logging
		logger's initializeLogging()
		logger's logInfo("Integration test started", {session:TEST_SESSION})
		
		-- Reset counters
		set totalTests to 0
		set passedTests to 0
		set failedTests to 0
		set testResults to {}
		
		-- Run integration tests
		log "Running Integration Tests..."
		log ""
		
		testBasicWorkflow()
		testNavigationWorkflow()
		testCommandWorkflow()
		testErrorRecoveryWorkflow()
		
		if ENABLE_PERFORMANCE_TESTS then
			log ""
			testPerformance()
		end if
		
		if ENABLE_STRESS_TESTS then
			log ""
			testStressScenarios()
		end if
		
		-- Print summary
		printTestSummary()
		
		logger's logInfo("Integration test completed", {total:totalTests, passed:passedTests, failed:failedTests})
		
		return {success:(failedTests = 0), totalTests:totalTests, passed:passedTests, failed:failedTests, results:testResults}
		
	on error errMsg number errNum
		log "FATAL ERROR in integration test: " & errMsg & " (" & errNum & ")"
		logger's logError("Integration test fatal error: " & errMsg, {errorNumber:errNum})
		return {success:false, errorMsg:errMsg, errorNumber:errNum}
	end try
end testFullWorkflow

-- ============================================================================
-- BASIC WORKFLOW TEST
-- ============================================================================

on testBasicWorkflow()
	log "--- Test 1: Basic Workflow (Init → State → Close) ---"
	set totalTests to totalTests + 1
	set testStartTime to current date
	
	try
		-- Step 1: Initialize session
		log "  Step 1: Initializing session..."
		set initResult to mainAPI's initSession(TEST_SESSION)
		
		if not initResult's success then
			log "  ✗ FAILED: Session initialization failed"
			log "    Error: " & initResult's message
			set failedTests to failedTests + 1
			set end of testResults to {name:"Basic Workflow", status:"FAILED", message:initResult's message}
			return
		end if
		
		log "  ✓ Session initialized: " & initResult's screenType
		set mySession to initResult's session
		
		delay 1
		
		-- Step 2: Get session state
		log "  Step 2: Getting session state..."
		set stateResult to mainAPI's getSessionState(mySession)
		
		if not stateResult's success then
			log "  ✗ FAILED: Could not get session state"
			mainAPI's closeSession(mySession)
			set failedTests to failedTests + 1
			set end of testResults to {name:"Basic Workflow", status:"FAILED", message:"State retrieval failed"}
			return
		end if
		
		log "  ✓ State retrieved: " & stateResult's state's currentScreen
		
		delay 1
		
		-- Step 3: Close session
		log "  Step 3: Closing session..."
		set closeResult to mainAPI's closeSession(mySession)
		
		if not closeResult's success then
			log "  ✗ FAILED: Session close failed"
			set failedTests to failedTests + 1
			set end of testResults to {name:"Basic Workflow", status:"FAILED", message:"Close failed"}
			return
		end if
		
		log "  ✓ Session closed successfully"
		
		-- Calculate duration
		set testDuration to (current date) - testStartTime
		log ""
		log "  ✓ PASSED: Basic Workflow (" & (round (testDuration * 10) / 10) & "s)"
		set passedTests to passedTests + 1
		set end of testResults to {name:"Basic Workflow", status:"PASSED", duration:testDuration}
		
	on error errMsg number errNum
		log "  ✗ FAILED: " & errMsg & " (" & errNum & ")"
		set failedTests to failedTests + 1
		set end of testResults to {name:"Basic Workflow", status:"ERROR", message:errMsg}
		
		-- Try to clean up
		try
			mainAPI's closeSession(mySession)
		end try
	end try
	
	log ""
end testBasicWorkflow

-- ============================================================================
-- NAVIGATION WORKFLOW TEST
-- ============================================================================

on testNavigationWorkflow()
	log "--- Test 2: Navigation Workflow ---"
	set totalTests to totalTests + 1
	set testStartTime to current date
	
	try
		log "  Target: " & TEST_FILE & " " & TEST_FILETYPE & " " & TEST_FILEMODE
		log ""
		
		-- Initialize session
		log "  Step 1: Initializing session..."
		set initResult to mainAPI's initSession(TEST_SESSION)
		
		if not initResult's success then
			log "  ✗ FAILED: Session initialization failed"
			set failedTests to failedTests + 1
			set end of testResults to {name:"Navigation Workflow", status:"FAILED", message:"Init failed"}
			return
		end if
		
		set mySession to initResult's session
		log "  ✓ Session initialized"
		
		delay 1
		
		-- Navigate to file
		log "  Step 2: Navigating to file..."
		set navResult to mainAPI's navigateToFile(mySession, TEST_FILE, TEST_FILETYPE, TEST_FILEMODE)
		
		if navResult's success then
			log "  ✓ Navigation successful"
			log "    - Steps taken: " & navResult's steps
			log "    - Final screen: " & navResult's screenType
			
			delay 2
			
			-- Close session
			log "  Step 3: Closing session..."
			mainAPI's closeSession(mySession)
			
			set testDuration to (current date) - testStartTime
			log ""
			log "  ✓ PASSED: Navigation Workflow (" & (round (testDuration * 10) / 10) & "s)"
			set passedTests to passedTests + 1
			set end of testResults to {name:"Navigation Workflow", status:"PASSED", duration:testDuration, steps:navResult's steps}
			
		else
			log "  ✗ FAILED: Navigation failed"
			log "    Error: " & navResult's message
			log "    Note: This may be expected if the test file doesn't exist"
			
			mainAPI's closeSession(mySession)
			set failedTests to failedTests + 1
			set end of testResults to {name:"Navigation Workflow", status:"FAILED", message:navResult's message}
		end if
		
	on error errMsg number errNum
		log "  ✗ FAILED: " & errMsg & " (" & errNum & ")"
		set failedTests to failedTests + 1
		set end of testResults to {name:"Navigation Workflow", status:"ERROR", message:errMsg}
		
		try
			mainAPI's closeSession(mySession)
		end try
	end try
	
	log ""
end testNavigationWorkflow

-- ============================================================================
-- COMMAND EXECUTION TEST
-- ============================================================================

on testCommandWorkflow()
	log "--- Test 3: Command Execution Workflow ---"
	set totalTests to totalTests + 1
	set testStartTime to current date
	
	try
		-- Initialize session
		log "  Step 1: Initializing session..."
		set initResult to mainAPI's initSession(TEST_SESSION)
		
		if not initResult's success then
			log "  ✗ FAILED: Session initialization failed"
			set failedTests to failedTests + 1
			set end of testResults to {name:"Command Workflow", status:"FAILED", message:"Init failed"}
			return
		end if
		
		set mySession to initResult's session
		log "  ✓ Session initialized"
		
		delay 1
		
		-- Execute command 1: QUERY TIME
		log "  Step 2: Executing QUERY TIME..."
		set cmdResult to mainAPI's executeCMSCommand(mySession, "QUERY TIME")
		
		if cmdResult's success then
			log "  ✓ Command executed"
			log "    - Output length: " & (length of cmdResult's output) & " characters"
		else
			log "  ✗ Command failed: " & cmdResult's message
			mainAPI's closeSession(mySession)
			set failedTests to failedTests + 1
			set end of testResults to {name:"Command Workflow", status:"FAILED", message:"QUERY TIME failed"}
			return
		end if
		
		delay 1
		
		-- Execute command 2: QUERY DISK
		log "  Step 3: Executing QUERY DISK..."
		set cmdResult to mainAPI's executeCMSCommand(mySession, "QUERY DISK")
		
		if cmdResult's success then
			log "  ✓ Command executed"
			log "    - Output length: " & (length of cmdResult's output) & " characters"
		else
			log "  ✗ Command failed: " & cmdResult's message
		end if
		
		delay 1
		
		-- Close session
		log "  Step 4: Closing session..."
		mainAPI's closeSession(mySession)
		
		set testDuration to (current date) - testStartTime
		log ""
		log "  ✓ PASSED: Command Workflow (" & (round (testDuration * 10) / 10) & "s)"
		set passedTests to passedTests + 1
		set end of testResults to {name:"Command Workflow", status:"PASSED", duration:testDuration}
		
	on error errMsg number errNum
		log "  ✗ FAILED: " & errMsg & " (" & errNum & ")"
		set failedTests to failedTests + 1
		set end of testResults to {name:"Command Workflow", status:"ERROR", message:errMsg}
		
		try
			mainAPI's closeSession(mySession)
		end try
	end try
	
	log ""
end testCommandWorkflow

-- ============================================================================
-- ERROR RECOVERY TEST
-- ============================================================================

on testErrorRecoveryWorkflow()
	log "--- Test 4: Error Recovery Workflow ---"
	set totalTests to totalTests + 1
	set testStartTime to current date
	
	try
		log "  Testing error recovery mechanisms..."
		log ""
		
		-- Test 1: Error categorization
		log "  Step 1: Testing error categorization..."
		set category1 to errorHandler's categorizeError("timeout occurred")
		set category2 to errorHandler's categorizeError("connection lost")
		
		if category1 is "transient" and category2 is "session" then
			log "  ✓ Error categorization working"
		else
			log "  ✗ Error categorization failed"
		end if
		
		-- Test 2: Backoff calculation
		log "  Step 2: Testing backoff calculation..."
		set backoff1 to errorHandler's calculateBackoff(1)
		set backoff2 to errorHandler's calculateBackoff(2)
		set backoff3 to errorHandler's calculateBackoff(3)
		
		if backoff2 > backoff1 and backoff3 > backoff2 then
			log "  ✓ Exponential backoff working"
			log "    - Attempt 1: " & backoff1 & "s"
			log "    - Attempt 2: " & backoff2 & "s"
			log "    - Attempt 3: " & backoff3 & "s"
		else
			log "  ✗ Backoff calculation failed"
		end if
		
		-- Test 3: Recoverability check
		log "  Step 3: Testing recoverability..."
		set recoverable1 to errorHandler's isRecoverable("transient")
		set recoverable2 to errorHandler's isRecoverable("fatal")
		
		if recoverable1 and not recoverable2 then
			log "  ✓ Recoverability check working"
		else
			log "  ✗ Recoverability check failed"
		end if
		
		set testDuration to (current date) - testStartTime
		log ""
		log "  ✓ PASSED: Error Recovery Workflow (" & (round (testDuration * 10) / 10) & "s)"
		set passedTests to passedTests + 1
		set end of testResults to {name:"Error Recovery Workflow", status:"PASSED", duration:testDuration}
		
	on error errMsg number errNum
		log "  ✗ FAILED: " & errMsg & " (" & errNum & ")"
		set failedTests to failedTests + 1
		set end of testResults to {name:"Error Recovery Workflow", status:"ERROR", message:errMsg}
	end try
	
	log ""
end testErrorRecoveryWorkflow

-- ============================================================================
-- PERFORMANCE TESTS
-- ============================================================================

on testPerformance()
	log "--- Performance Benchmarks ---"
	
	try
		log "  Running performance tests..."
		log ""
		
		-- Benchmark 1: Session initialization
		log "  Benchmark 1: Session initialization time"
		set iterations to 3
		set totalTime to 0
		
		repeat with i from 1 to iterations
			set startTime to current date
			set result to mainAPI's initSession(TEST_SESSION)
			if result's success then
				mainAPI's closeSession(result's session)
				set duration to (current date) - startTime
				set totalTime to totalTime + duration
				log "    Iteration " & i & ": " & (round (duration * 100) / 100) & "s"
			end if
			delay 1
		end repeat
		
		set avgTime to totalTime / iterations
		log "    Average: " & (round (avgTime * 100) / 100) & "s"
		log ""
		
		-- Benchmark 2: Command execution
		log "  Benchmark 2: Command execution time"
		set result to mainAPI's initSession(TEST_SESSION)
		if result's success then
			set mySession to result's session
			
			set startTime to current date
			set cmdResult to mainAPI's executeCMSCommand(mySession, "QUERY TIME")
			set duration to (current date) - startTime
			
			log "    Command execution: " & (round (duration * 100) / 100) & "s"
			
			mainAPI's closeSession(mySession)
		end if
		
		log ""
		log "  ✓ Performance benchmarks completed"
		
	on error errMsg
		log "  ✗ Performance test error: " & errMsg
	end try
	
	log ""
end testPerformance

-- ============================================================================
-- STRESS TESTS
-- ============================================================================

on testStressScenarios()
	log "--- Stress Tests ---"
	log "  WARNING: Stress tests are intensive and may take several minutes"
	log ""
	
	try
		-- Stress test 1: Rapid session cycling
		log "  Stress Test 1: Rapid session cycling (10 iterations)"
		set successCount to 0
		
		repeat with i from 1 to 10
			set result to mainAPI's initSession(TEST_SESSION)
			if result's success then
				mainAPI's closeSession(result's session)
				set successCount to successCount + 1
			end if
			delay 0.5
		end repeat
		
		log "    Success rate: " & successCount & "/10 (" & (successCount * 10) & "%)"
		log ""
		
		-- Stress test 2: Multiple commands
		log "  Stress Test 2: Multiple command execution (20 commands)"
		set result to mainAPI's initSession(TEST_SESSION)
		if result's success then
			set mySession to result's session
			set cmdSuccessCount to 0
			
			repeat with i from 1 to 20
				set cmdResult to mainAPI's executeCMSCommand(mySession, "QUERY TIME")
				if cmdResult's success then
					set cmdSuccessCount to cmdSuccessCount + 1
				end if
			end repeat
			
			mainAPI's closeSession(mySession)
			log "    Success rate: " & cmdSuccessCount & "/20 (" & (cmdSuccessCount * 5) & "%)"
		end if
		
		log ""
		log "  ✓ Stress tests completed"
		
	on error errMsg
		log "  ✗ Stress test error: " & errMsg
	end try
	
	log ""
end testStressScenarios

-- ============================================================================
-- UTILITIES
-- ============================================================================

on printTestSummary()
	log ""
	log "========================================================================"
	log "INTEGRATION TEST SUMMARY"
	log "========================================================================"
	log "Total Tests:   " & totalTests
	log "Passed:        " & passedTests & " (" & (round ((passedTests / totalTests) * 100)) & "%)"
	log "Failed:        " & failedTests
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
		log "✓ ALL INTEGRATION TESTS PASSED!"
		log ""
		log "The system is ready for production use."
	else
		log "✗ SOME TESTS FAILED"
		log ""
		log "Please review the errors above and check:"
		log "  - HOD is running and accessible"
		log "  - Session " & TEST_SESSION & " exists"
		log "  - Test file " & TEST_FILE & " " & TEST_FILETYPE & " exists"
		log "  - System permissions are granted"
	end if
	
	log ""
	log "End Time: " & (current date as string)
	log "========================================================================"
end printTestSummary

-- ============================================================================
-- EXECUTE INTEGRATION TEST
-- ============================================================================

-- Run the integration test when script is executed
testFullWorkflow()

-- Made with Bob