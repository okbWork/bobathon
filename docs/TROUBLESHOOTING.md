# IBM Host On-Demand Automation - Troubleshooting Guide

## Table of Contents
- [Common Issues](#common-issues)
- [Error Messages](#error-messages)
- [Debug Mode](#debug-mode)
- [Log Analysis](#log-analysis)
- [Screen Capture Issues](#screen-capture-issues)
- [Performance Problems](#performance-problems)
- [Configuration Issues](#configuration-issues)
- [Recovery Procedures](#recovery-procedures)

---

## Common Issues

### Issue 1: Window Not Found

**Symptoms:**
- Error: "Failed to get HOD window"
- Session initialization fails
- `success: false` from `initSession()`

**Causes:**
1. HOD application not running
2. Wrong session letter
3. Window title doesn't match expected format
4. HOD window minimized or hidden

**Solutions:**

```applescript
-- Solution 1: Verify HOD is running
tell application "System Events"
    if not (exists process "HOD") then
        log "HOD application is not running"
        -- Launch HOD or notify user
    end if
end tell

-- Solution 2: Check available sessions
property windowManager : load script POSIX file "/path/to/window_manager.applescript"
set sessions to windowManager's getAllHODSessions()
log "Available sessions: " & (sessions as string)

-- Solution 3: Verify window title format
-- Default format: "GDLVM7 - A"
-- If different, update windowTitlePrefix in window_manager.applescript
windowManager's setWindowTitlePrefix("YOUR_HOST - ")

-- Solution 4: Ensure window is visible
tell application "System Events"
    tell process "HOD"
        set visible to true
        set frontmost to true
    end tell
end tell
```

**Prevention:**
- Always verify HOD is running before automation
- Use `getAllHODSessions()` to check available sessions
- Configure correct window title prefix

---

### Issue 2: Screen Capture Fails

**Symptoms:**
- Error: "Screen capture failed"
- Empty or invalid screen content
- Clipboard contains wrong data

**Causes:**
1. Window not in focus
2. Clipboard access denied
3. Mouse automation failed
4. Toolbar button position incorrect
5. Screen transition in progress

**Solutions:**

```applescript
-- Solution 1: Ensure window focus
property windowManager : load script POSIX file "/path/to/window_manager.applescript"
set windowRef to windowManager's getHODWindow("A")
windowManager's activateHODWindow(windowRef)
delay 0.5  -- Wait for activation

-- Solution 2: Clear clipboard before capture
property clipboardManager : load script POSIX file "/path/to/clipboard_manager.applescript"
clipboardManager's clearClipboard()

-- Solution 3: Use retry logic
property screenCapture : load script POSIX file "/path/to/screen_capture.applescript"
set captureResult to screenCapture's captureScreenWithRetry(windowRef, 3)

-- Solution 4: Calibrate toolbar button position
set buttonPos to screenCapture's calibrateToolbarButton(windowRef)
if buttonPos is not missing value then
    screenCapture's setToolbarCopyButtonCoordinates(buttonPos's x, buttonPos's y)
end if

-- Solution 5: Wait for screen to stabilize
delay 1.0
set captureResult to screenCapture's captureScreen(windowRef)
```

**Prevention:**
- Always activate window before capture
- Use retry logic for captures
- Calibrate toolbar button position once
- Add delays after screen transitions

---

### Issue 3: Navigation Timeout

**Symptoms:**
- Error: "Max navigation steps exceeded"
- Workflow hangs during navigation
- Never reaches target file

**Causes:**
1. File doesn't exist
2. Wrong file path (filename/filetype/mode)
3. Insufficient navigation steps limit
4. Screen not updating
5. Decision engine stuck in loop

**Solutions:**

```applescript
-- Solution 1: Verify file exists first
property mainAPI : load script POSIX file "/path/to/main.applescript"
set session to mainAPI's initSession("A")

-- Execute LISTFILE command to check
set listResult to mainAPI's executeCMSCommand(session, "LISTFILE MYFILE DATA A")
if listResult's output contains "MYFILE" then
    log "File exists, proceeding with navigation"
else
    log "File not found"
end if

-- Solution 2: Increase navigation step limit
-- Edit MAX_NAVIGATION_STEPS in main.applescript
-- Default is 20, increase to 30 or 40 for complex navigation

-- Solution 3: Add debug logging
property logger : load script POSIX file "/path/to/logger.applescript"
logger's initializeLogging()

-- Enable detailed logging during navigation
set navResult to mainAPI's navigateToFile(session, "MYFILE", "DATA", "A")
-- Check logs/hod_automation.log for decision path

-- Solution 4: Manual navigation test
-- Try navigating manually to verify path exists
-- Then automate the same path
```

**Prevention:**
- Verify files exist before navigation
- Use appropriate step limits
- Enable debug logging
- Test navigation paths manually first

---

### Issue 4: Keyboard Input Not Working

**Symptoms:**
- Text not appearing in terminal
- PF keys not responding
- Commands not executing

**Causes:**
1. Window not in focus
2. Keyboard controller delays too short
3. System Events permissions denied
4. Wrong key codes for PF keys

**Solutions:**

```applescript
-- Solution 1: Verify window focus
property keyboardController : load script POSIX file "/path/to/keyboard_controller.applescript"
tell application "System Events"
    tell process "HOD"
        set frontmost to true
    end tell
end tell
delay 0.3

-- Solution 2: Increase delays
keyboardController's setKeystrokeDelay(0.1)  -- Increase from 0.05
keyboardController's setPostEnterDelay(1.0)  -- Increase from 0.5
keyboardController's setPostPFKeyDelay(0.5)  -- Increase from 0.2

-- Solution 3: Check System Events permissions
-- System Preferences > Security & Privacy > Privacy > Accessibility
-- Ensure Terminal or Script Editor has permission

-- Solution 4: Test individual keys
set testResult to keyboardController's sendText(windowRef, "TEST")
if testResult then
    log "Text input working"
else
    log "Text input failed"
end if

set pfResult to keyboardController's sendPFKey(windowRef, 3)
if pfResult then
    log "PF keys working"
else
    log "PF keys failed"
end if
```

**Prevention:**
- Always activate window before input
- Use appropriate delays for system speed
- Verify System Events permissions
- Test keyboard functions individually

---

### Issue 5: Session Hangs or Freezes

**Symptoms:**
- Terminal becomes unresponsive
- No screen updates
- Commands don't complete

**Causes:**
1. System overload
2. Network issues
3. HOD application freeze
4. Infinite loop in automation

**Solutions:**

```applescript
-- Solution 1: Use error recovery
property errorHandler : load script POSIX file "/path/to/error_handler.applescript"
set recovery to errorHandler's handleError("freeze", {}, windowRef)

if recovery's recovered then
    log "System recovered from freeze"
    -- Continue automation
else
    log "Could not recover, manual intervention needed"
end if

-- Solution 2: Add timeout protection
on executeWithTimeout(operation, timeoutSeconds)
    set startTime to current date
    set result to operation()
    set elapsed to (current date) - startTime
    
    if elapsed > timeoutSeconds then
        error "Operation timed out after " & timeoutSeconds & " seconds"
    end if
    
    return result
end executeWithTimeout

-- Solution 3: Send Attn key to interrupt
tell application "System Events"
    tell process "HOD"
        keystroke "c" using {control down}  -- Ctrl+C for Attn
    end tell
end tell
delay 1.0

-- Solution 4: Force screen refresh
keyboardController's sendEnter(windowRef)
delay 1.0
```

**Prevention:**
- Use timeout wrappers for long operations
- Add progress logging
- Implement error recovery
- Monitor system resources

---

## Error Messages

### "DMSABE" Errors

**Message:** `DMSABE104S File "FILENAME FILETYPE FM" not found`

**Meaning:** File does not exist in specified location

**Solution:**
```applescript
-- Verify file exists
set listResult to mainAPI's executeCMSCommand(session, "LISTFILE FILENAME FILETYPE FM")

-- Check alternative locations
set listResult to mainAPI's executeCMSCommand(session, "LISTFILE FILENAME * *")

-- Create file if needed
set createResult to mainAPI's executeCMSCommand(session, "XEDIT FILENAME FILETYPE FM")
```

---

### "Invalid Command" Errors

**Message:** `Invalid command` or `Unknown command`

**Meaning:** CMS command syntax error

**Solution:**
```applescript
-- Verify command syntax
-- Correct: "FILELIST"
-- Wrong: "FILELIST "  (trailing space)

-- Ensure at CMS prompt
set state to mainAPI's getSessionState(session)
if state's state's currentScreen is not "cms_prompt" then
    -- Navigate back to prompt
    keyboardController's sendPFKey(windowRef, 3)
    delay 1.0
end if
```

---

### "Clipboard Error" Messages

**Message:** `pbpaste: command not found` or `Clipboard read failed`

**Meaning:** Clipboard access issue

**Solution:**
```applescript
-- Verify pbpaste/pbcopy available
do shell script "which pbpaste"
do shell script "which pbcopy"

-- Alternative: Use AppleScript clipboard
set the clipboard to ""
delay 0.1
set clipContent to the clipboard as text
```

---

## Debug Mode

### Enable Debug Logging

```applescript
-- In your workflow script
property DEBUG_MODE : true
property logger : load script POSIX file "/path/to/logger.applescript"

on debugLog(message, context)
    if DEBUG_MODE then
        log "DEBUG: " & message
        logger's logDebug(message, context)
    end if
end debugLog

-- Use throughout workflow
debugLog("Starting navigation", {filename:"TEST"})
set result to mainAPI's navigateToFile(session, "TEST", "DATA", "A")
debugLog("Navigation result", {success:result's success, steps:result's steps})
```

### Capture Screen States

```applescript
-- Save screen captures for debugging
property logger : load script POSIX file "/path/to/logger.applescript"

on captureDebugScreen(label)
    set captureResult to screenCapture's captureScreen(windowRef)
    if captureResult's success then
        logger's logScreenCapture(captureResult's screenText, label)
    end if
end captureDebugScreen

-- Use at key points
captureDebugScreen("before_navigation")
set navResult to mainAPI's navigateToFile(session, "TEST", "DATA", "A")
captureDebugScreen("after_navigation")
```

### Trace Decision Path

```applescript
-- Enable decision logging
property decisionEngine : load script POSIX file "/path/to/decision_engine.applescript"
property logger : load script POSIX file "/path/to/logger.applescript"

-- Decision engine automatically logs to logger
-- Check logs/hod_automation.log for entries like:
-- [INFO] DECISION: Screen=cms_prompt, Goal=navigate_to_file, Action=type_command
```

---

## Log Analysis

### Reading Log Files

Log location: `/Users/okyereboateng/bobathon/logs/hod_automation.log`

```bash
# View recent logs
tail -f ~/bobathon/logs/hod_automation.log

# Search for errors
grep ERROR ~/bobathon/logs/hod_automation.log

# Find specific operation
grep "navigate_to_file" ~/bobathon/logs/hod_automation.log

# View timing information
grep TIMING ~/bobathon/logs/hod_automation.log
```

### Log Entry Format

```
2026-04-14 10:30:45 [INFO] Starting navigation | Context: {filename:TEST, filetype:DATA}
2026-04-14 10:30:46 [DEBUG] Screen captured: 1024 characters
2026-04-14 10:30:46 [INFO] DECISION: Screen=cms_prompt, Goal=navigate_to_file, Action=type_command
2026-04-14 10:30:48 [INFO] TIMING: navigateToFile completed in 3.2s
```

### Analyzing Performance

```applescript
-- Get session statistics
set stats to logger's getSessionStats()
if stats's success then
    log "Session duration: " & stats's sessionDuration
    log "Operations: " & stats's operationCount
end if
```

---

## Screen Capture Issues

### Calibration Problems

**Issue:** Toolbar copy button not found

**Solution:**
```applescript
-- Run calibration
property screenCapture : load script POSIX file "/path/to/screen_capture.applescript"
set buttonPos to screenCapture's calibrateToolbarButton(windowRef)

if buttonPos is not missing value then
    log "Button found at: x=" & buttonPos's x & ", y=" & buttonPos's y
    -- Save these coordinates for future use
else
    log "Calibration failed, try manual positioning"
    -- Manually set coordinates
    screenCapture's setToolbarCopyButtonCoordinates(100, 30)
end if
```

### Selection Issues

**Issue:** Screen selection not capturing full content

**Solution:**
```applescript
-- Adjust selection margins
property screenCapture : load script POSIX file "/path/to/screen_capture.applescript"

set margins to {top:60, left:5, right:5, bottom:5}
screenCapture's setSelectionMargins(margins)

-- For larger screens, increase margins
set margins to {top:80, left:10, right:10, bottom:10}
screenCapture's setSelectionMargins(margins)
```

---

## Performance Problems

### Slow Operations

**Symptoms:**
- Operations take longer than expected
- Timeouts occurring
- System feels sluggish

**Solutions:**

```applescript
-- 1. Reduce logging verbosity
-- In logger.applescript, change:
property CURRENT_LOG_LEVEL : LOG_INFO  -- Instead of LOG_DEBUG

-- 2. Optimize screen captures
-- Only capture when necessary
if needsScreenUpdate then
    set captureResult to screenCapture's captureScreen(windowRef)
end if

-- 3. Reuse sessions
-- Don't create new session for each operation
set session to mainAPI's initSession("A")
repeat with file in fileList
    mainAPI's navigateToFile(session, file's name, file's type, file's mode)
end repeat
mainAPI's closeSession(session)

-- 4. Adjust delays
-- Reduce delays if system is fast
keyboardController's setPostEnterDelay(0.3)  -- From 0.5
keyboardController's setPostPFKeyDelay(0.1)  -- From 0.2
```

### Memory Issues

**Symptoms:**
- Script becomes slow over time
- System memory usage high

**Solutions:**

```applescript
-- 1. Clear variables in loops
repeat with item in largeList
    set result to processItem(item)
    -- Clear result after use
    set result to missing value
end repeat

-- 2. Process in batches
set batchSize to 10
set totalItems to count of itemList
repeat with i from 1 to totalItems by batchSize
    set endIndex to i + batchSize - 1
    if endIndex > totalItems then set endIndex to totalItems
    
    set batch to items i thru endIndex of itemList
    processBatch(batch)
    
    -- Clear batch
    set batch to {}
end repeat

-- 3. Restart session periodically
set operationCount to 0
repeat with item in itemList
    processItem(session, item)
    set operationCount to operationCount + 1
    
    -- Restart session every 50 operations
    if operationCount mod 50 = 0 then
        mainAPI's closeSession(session)
        delay 2
        set session to mainAPI's initSession("A")
    end if
end repeat
```

---

## Configuration Issues

### Path Problems

**Issue:** Scripts can't find modules

**Solution:**
```applescript
-- Use absolute paths
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"

-- Or use relative paths from known location
set scriptPath to POSIX path of (path to me)
set basePath to do shell script "dirname " & quoted form of scriptPath
property mainAPI : load script POSIX file (basePath & "/src/main.applescript")
```

### Permission Issues

**Issue:** "Operation not permitted" errors

**Solution:**
1. Grant Accessibility permissions:
   - System Preferences > Security & Privacy > Privacy > Accessibility
   - Add Terminal or Script Editor

2. Grant Automation permissions:
   - System Preferences > Security & Privacy > Privacy > Automation
   - Allow script to control System Events

3. Test permissions:
```applescript
try
    tell application "System Events"
        set frontmost of process "HOD" to true
    end tell
    log "Permissions OK"
on error errMsg
    log "Permission error: " & errMsg
end try
```

---

## Recovery Procedures

### Emergency Stop

```applescript
-- Add to all workflows
on emergencyStop(session)
    try
        -- Send Attn to interrupt
        tell application "System Events"
            tell process "HOD"
                keystroke "c" using {control down}
            end tell
        end tell
        delay 1
        
        -- Try to close session
        mainAPI's closeSession(session)
        
        -- Log emergency stop
        logger's logError("Emergency stop executed", missing value)
        
    on error
        -- Force quit if needed
        log "Emergency stop failed, manual intervention required"
    end try
end emergencyStop

-- Use in error handlers
on error errMsg
    emergencyStop(session)
    error errMsg
end try
```

### Session Recovery

```applescript
-- Recover from unknown state
on recoverSession(session)
    try
        property errorHandler : load script POSIX file "/path/to/error_handler.applescript"
        
        -- Attempt generic recovery
        set recovery to errorHandler's genericRecovery(session's windowRef)
        
        if recovery's recovered then
            log "Session recovered"
            return {success:true, message:"Session recovered"}
        else
            log "Recovery failed, creating new session"
            mainAPI's closeSession(session)
            set newSession to mainAPI's initSession(session's sessionLetter)
            return {success:true, message:"New session created", session:newSession}
        end if
        
    on error errMsg
        return {success:false, message:"Recovery failed: " & errMsg}
    end try
end recoverSession
```

---

## Getting Help

### Diagnostic Information

When reporting issues, include:

```applescript
-- Run diagnostic script
on collectDiagnostics()
    set diag to {}
    
    -- System info
    set end of diag to "macOS Version: " & (system version of (system info))
    
    -- HOD status
    tell application "System Events"
        if exists process "HOD" then
            set end of diag to "HOD: Running"
        else
            set end of diag to "HOD: Not running"
        end if
    end tell
    
    -- Available sessions
    set sessions to windowManager's getAllHODSessions()
    set end of diag to "Sessions: " & (sessions as string)
    
    -- Log file size
    try
        set logSize to do shell script "ls -lh ~/bobathon/logs/hod_automation.log | awk '{print $5}'"
        set end of diag to "Log size: " & logSize
    end try
    
    -- Recent errors
    try
        set recentErrors to do shell script "grep ERROR ~/bobathon/logs/hod_automation.log | tail -5"
        set end of diag to "Recent errors:" & return & recentErrors
    end try
    
    return diag
end collectDiagnostics

-- Output diagnostics
set diag to collectDiagnostics()
repeat with line in diag
    log line
end repeat
```

### Support Resources

- **API Reference**: [API_REFERENCE.md](API_REFERENCE.md)
- **Workflow Guide**: [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Log Files**: `~/bobathon/logs/`
- **Example Scripts**: `~/bobathon/workflows/`

---

**Made with Bob** 🤖