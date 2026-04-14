-- Simple Test Runner for IBM Host On-Demand Automation
-- Tests basic functionality without handler references

-- Load modules
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.scpt"
property logger : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/logger.scpt"

property TEST_SESSION : "A"
property passedTests : 0
property failedTests : 0

on run
	log "=========================================="
	log "Simple Test Suite"
	log "=========================================="
	log ""
	
	-- Initialize logging
	logger's initializeLogging()
	
	-- Test 1: Initialize Session
	log "Test 1: Initialize Session..."
	try
		set initResult to mainAPI's initSession(TEST_SESSION)
		if initResult's success then
			log "✓ PASSED: Session initialized"
			set passedTests to passedTests + 1
			set testSession to initResult's session
		else
			log "✗ FAILED: " & initResult's message
			set failedTests to failedTests + 1
			return
		end if
	on error errMsg
		log "✗ FAILED: " & errMsg
		set failedTests to failedTests + 1
		return
	end try
	
	-- Test 2: Capture Screen
	log "Test 2: Capture Screen..."
	try
		set captureResult to mainAPI's captureCurrentScreen(testSession)
		if captureResult's success then
			log "✓ PASSED: Screen captured (" & (count of captureResult's screenText) & " chars)"
			set passedTests to passedTests + 1
		else
			log "✗ FAILED: " & captureResult's message
			set failedTests to failedTests + 1
		end if
	on error errMsg
		log "✗ FAILED: " & errMsg
		set failedTests to failedTests + 1
	end try
	
	-- Test 3: Parse Screen
	log "Test 3: Parse Screen..."
	try
		set parseResult to mainAPI's parseCurrentScreen(testSession)
		if parseResult's success then
			log "✓ PASSED: Screen parsed (type: " & parseResult's screenType & ")"
			set passedTests to passedTests + 1
		else
			log "✗ FAILED: " & parseResult's message
			set failedTests to failedTests + 1
		end if
	on error errMsg
		log "✗ FAILED: " & errMsg
		set failedTests to failedTests + 1
	end try
	
	-- Close session
	try
		mainAPI's closeSession(testSession)
	end try
	
	-- Print results
	log ""
	log "=========================================="
	log "Test Results:"
	log "  Passed: " & passedTests
	log "  Failed: " & failedTests
	log "  Total:  " & (passedTests + failedTests)
	log "=========================================="
	
	if failedTests is 0 then
		log "✓ ALL TESTS PASSED!"
		return {success:true, passed:passedTests, failed:failedTests}
	else
		log "✗ SOME TESTS FAILED"
		return {success:false, passed:passedTests, failed:failedTests}
	end if
end run

-- Made with Bob
