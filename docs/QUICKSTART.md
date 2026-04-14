# IBM Host On-Demand Automation - Quick Start Guide

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [First-Time Setup](#first-time-setup)
- [Your First Automation](#your-first-automation)
- [Simple Examples](#simple-examples)
- [Testing Your Setup](#testing-your-setup)
- [Next Steps](#next-steps)

---

## Prerequisites

### System Requirements
- **macOS**: 10.14 (Mojave) or later
- **AppleScript**: Version 2.4 or later
- **IBM Host On-Demand**: Installed and configured
- **Disk Space**: 50 MB for logs and captures

### Required Permissions
1. **Accessibility Access**
   - System Preferences > Security & Privacy > Privacy > Accessibility
   - Add Terminal or Script Editor

2. **Automation Access**
   - System Preferences > Security & Privacy > Privacy > Automation
   - Allow control of System Events

### Verify Prerequisites

```applescript
-- Run this to check your setup
tell application "System Events"
    try
        -- Test accessibility
        set frontmost of process "Finder" to true
        log "✓ Accessibility access OK"
    on error
        log "✗ Accessibility access needed"
    end try
end tell

-- Check AppleScript version
log "AppleScript version: " & (AppleScript version)

-- Check if HOD is installed
tell application "System Events"
    if exists process "HOD" then
        log "✓ HOD is running"
    else
        log "⚠ HOD is not running - please start it"
    end if
end tell
```

---

## Installation

### Step 1: Download the Project

```bash
# Clone or download to your home directory
cd ~
# Assuming project is in ~/bobathon
cd bobathon
```

### Step 2: Verify Directory Structure

```bash
# Check that all directories exist
ls -la ~/bobathon/

# You should see:
# - src/          (source code)
# - docs/         (documentation)
# - workflows/    (example workflows)
# - logs/         (will be created automatically)
# - config/       (configuration files)
# - tests/        (test scripts)
```

### Step 3: Set Permissions

```bash
# Make scripts executable
chmod +x ~/bobathon/src/main.applescript
chmod +x ~/bobathon/workflows/*.applescript
chmod +x ~/bobathon/tests/*.applescript
```

### Step 4: Create Log Directory

```bash
# Create logs directory if it doesn't exist
mkdir -p ~/bobathon/logs
```

---

## First-Time Setup

### Configure Window Title

The automation needs to know your HOD window title format.

**Default format:** `"GDLVM7 - A"` (hostname - session letter)

**If your format is different:**

```applescript
-- Edit src/core/window_manager.applescript
-- Change this line:
property windowTitlePrefix : "GDLVM7 - "

-- To match your hostname:
property windowTitlePrefix : "YOUR_HOST - "
```

### Test Window Detection

```applescript
-- Run this test to verify window detection
property windowManager : load script POSIX file "/Users/okyereboateng/bobathon/src/core/window_manager.applescript"

-- Find all available sessions
set sessions to windowManager's getAllHODSessions()
log "Found sessions: " & (sessions as string)

-- Test finding a specific session (replace "A" with your session)
set windowRef to windowManager's getHODWindow("A")
if windowRef is not missing value then
    log "✓ Successfully found HOD window for session A"
else
    log "✗ Could not find HOD window - check window title format"
end if
```

### Calibrate Screen Capture

```applescript
-- Run this once to calibrate the toolbar copy button position
property windowManager : load script POSIX file "/Users/okyereboateng/bobathon/src/core/window_manager.applescript"
property screenCapture : load script POSIX file "/Users/okyereboateng/bobathon/src/core/screen_capture.applescript"

-- Get window reference
set windowRef to windowManager's getHODWindow("A")

-- Calibrate button position
set buttonPos to screenCapture's calibrateToolbarButton(windowRef)

if buttonPos is not missing value then
    log "✓ Toolbar button found at: x=" & buttonPos's x & ", y=" & buttonPos's y
    log "Save these coordinates for future use"
else
    log "✗ Calibration failed - you may need to set coordinates manually"
    log "Try: screenCapture's setToolbarCopyButtonCoordinates(100, 30)"
end if
```

---

## Your First Automation

### Example 1: Initialize and Close Session

The simplest automation - just connect and disconnect.

```applescript
-- Save as: my_first_automation.applescript

-- Load the main API
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"

-- Initialize session
log "Initializing session..."
set result to mainAPI's initSession("A")

if result's success then
    log "✓ Session initialized successfully"
    log "Screen type: " & result's screenType
    
    -- Store session for use
    set mySession to result's session
    
    -- Wait a moment
    delay 2
    
    -- Close session
    log "Closing session..."
    set closeResult to mainAPI's closeSession(mySession)
    
    if closeResult's success then
        log "✓ Session closed successfully"
    else
        log "✗ Session close failed: " & closeResult's message
    end if
else
    log "✗ Session initialization failed: " & result's message
end if
```

**Run it:**
```bash
osascript my_first_automation.applescript
```

---

### Example 2: View a File

Navigate to and view a file.

```applescript
-- Save as: view_file.applescript

property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"
property logger : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/logger.applescript"

-- Initialize logging
logger's initializeLogging()

-- Initialize session
set result to mainAPI's initSession("A")
if not result's success then
    log "Failed to initialize session"
    return
end if

set mySession to result's session

-- Navigate to a file (change these to match your file)
set filename to "PROFILE"
set filetype to "EXEC"
set filemode to "A1"

log "Navigating to " & filename & " " & filetype & " " & filemode

set navResult to mainAPI's navigateToFile(mySession, filename, filetype, filemode)

if navResult's success then
    log "✓ Successfully opened file in " & navResult's steps & " steps"
    
    -- File is now open in XEDIT
    -- Wait to view it
    delay 3
    
    -- Close the file (PF3)
    tell application "System Events"
        tell process "HOD"
            key code 99  -- F3 key
        end tell
    end tell
    delay 1
else
    log "✗ Navigation failed: " & navResult's message
end if

-- Close session
mainAPI's closeSession(mySession)
log "Done!"
```

---

### Example 3: Execute a Command

Execute a CMS command and see the output.

```applescript
-- Save as: execute_command.applescript

property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"

-- Initialize session
set result to mainAPI's initSession("A")
if not result's success then
    log "Failed to initialize session"
    return
end if

set mySession to result's session

-- Execute a command (list files)
log "Executing LISTFILE command..."
set cmdResult to mainAPI's executeCMSCommand(mySession, "LISTFILE * * A")

if cmdResult's success then
    log "✓ Command executed successfully"
    log "Screen type: " & cmdResult's screenType
    log "Output length: " & (length of cmdResult's output) & " characters"
    
    -- You can parse the output here
    if cmdResult's output contains "PROFILE" then
        log "Found PROFILE file"
    end if
else
    log "✗ Command failed: " & cmdResult's message
end if

-- Close session
mainAPI's closeSession(mySession)
```

---

## Simple Examples

### Search NETLOG

```applescript
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"

-- Initialize session
set result to mainAPI's initSession("A")
if not result's success then return

set mySession to result's session

-- Search for files from a specific user
set criteria to {user:"TESTUSER"}

log "Searching NETLOG..."
set searchResult to mainAPI's searchNetlog(mySession, criteria)

if searchResult's success then
    log "✓ Found " & searchResult's totalEntries & " entries"
    
    -- Display first few entries
    repeat with i from 1 to (count of searchResult's entries)
        if i > 5 then exit repeat  -- Show first 5
        
        set entry to item i of searchResult's entries
        log "Entry " & i & ": " & entry's filename & " from " & entry's fromUser
    end repeat
else
    log "✗ Search failed: " & searchResult's message
end if

mainAPI's closeSession(mySession)
```

---

### Edit a File

```applescript
property mainAPI : load script POSIX file "/Users/okyereboateng/bobathon/src/main.applescript"

-- Initialize session
set result to mainAPI's initSession("A")
if not result's success then return

set mySession to result's session

-- Navigate to file
log "Opening file..."
set navResult to mainAPI's navigateToFile(mySession, "TEST", "DATA", "A")

if navResult's success then
    -- Edit line 1
    log "Editing line 1..."
    set editResult to mainAPI's editFile(mySession, 1, "This is the new first line")
    
    if editResult's success then
        -- Save and exit
        log "Saving file..."
        set saveResult to mainAPI's saveAndExit(mySession)
        
        if saveResult's success then
            log "✓ File edited and saved successfully"
        end if
    end if
end if

mainAPI's closeSession(mySession)
```

---

## Testing Your Setup

### Run the Test Suite

```bash
# Run comprehensive tests
osascript ~/bobathon/tests/test_suite.applescript
```

### Run Individual Module Tests

```applescript
-- Test window manager
property windowManager : load script POSIX file "/Users/okyereboateng/bobathon/src/core/window_manager.applescript"
windowManager's runTests()

-- Test clipboard manager
property clipboardManager : load script POSIX file "/Users/okyereboateng/bobathon/src/core/clipboard_manager.applescript"
clipboardManager's runTests()

-- Test keyboard controller
property keyboardController : load script POSIX file "/Users/okyereboateng/bobathon/src/core/keyboard_controller.applescript"
keyboardController's runTests("A")  -- Replace "A" with your session
```

### Verify Logging

```bash
# Check that logs are being created
ls -lh ~/bobathon/logs/

# View recent log entries
tail -20 ~/bobathon/logs/hod_automation.log

# Watch logs in real-time
tail -f ~/bobathon/logs/hod_automation.log
```

---

## Common First-Time Issues

### Issue: "Window not found"

**Solution:**
1. Verify HOD is running
2. Check window title format matches configuration
3. Try: `windowManager's getAllHODSessions()` to see available sessions

### Issue: "Screen capture failed"

**Solution:**
1. Run calibration: `screenCapture's calibrateToolbarButton(windowRef)`
2. Grant Accessibility permissions
3. Ensure window is visible and not minimized

### Issue: "Permission denied"

**Solution:**
1. System Preferences > Security & Privacy > Privacy > Accessibility
2. Add Terminal or Script Editor
3. Restart Terminal/Script Editor after granting permissions

### Issue: "Module not found"

**Solution:**
1. Verify file paths in your script
2. Use absolute paths: `/Users/okyereboateng/bobathon/src/...`
3. Check file permissions: `ls -l ~/bobathon/src/main.applescript`

---

## Next Steps

### Learn More

1. **Read the API Reference**
   - [API_REFERENCE.md](API_REFERENCE.md)
   - Complete function documentation
   - Parameter details and examples

2. **Study Example Workflows**
   - `workflows/file_transfer.applescript`
   - `workflows/batch_operations.applescript`
   - `workflows/netlog_analysis.applescript`

3. **Read the Workflow Guide**
   - [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md)
   - Advanced patterns
   - Best practices

4. **Review Troubleshooting**
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
   - Common issues and solutions
   - Debug techniques

### Try Advanced Features

```applescript
-- Use error recovery
property errorHandler : load script POSIX file "/Users/okyereboateng/bobathon/src/utils/error_handler.applescript"

set recovery to errorHandler's handleError("capture_failure", {}, windowRef)
if recovery's recovered then
    log "Recovered from error"
end if

-- Use decision engine
property decisionEngine : load script POSIX file "/Users/okyereboateng/bobathon/src/engine/decision_engine.applescript"

set goal to {action:"navigate_to_file", filename:"TEST", filetype:"DATA"}
set decision to decisionEngine's makeDecision(screenData, goal)
log "Decision: " & decision's action
log "Reasoning: " & decision's reasoning

-- Use workflow executor
property workflowExecutor : load script POSIX file "/Users/okyereboateng/bobathon/src/engine/workflow_executor.applescript"

set result to workflowExecutor's executeAction(windowRef, decision, screenData)
```

### Create Your Own Workflows

1. Start with a simple workflow template
2. Add error handling
3. Include logging
4. Test thoroughly
5. Document your workflow

### Run the Demo

```bash
# See the system in action
osascript ~/bobathon/demo.applescript
```

---

## Quick Reference Card

### Essential Functions

```applescript
-- Session Management
initSession(sessionLetter)
closeSession(session)
getSessionState(session)

-- File Operations
navigateToFile(session, filename, filetype, filemode)
editFile(session, lineNumber, newContent)
saveAndExit(session)

-- Commands
executeCMSCommand(session, command)

-- Search
searchNetlog(session, criteria)

-- Logging
logger's initializeLogging()
logger's logInfo(message, context)
logger's logError(message, context)
```

### Common Patterns

```applescript
-- Basic workflow structure
logger's initializeLogging()
set session to mainAPI's initSession("A")
-- Do work
mainAPI's closeSession(session)

-- Error handling
try
    -- operations
on error errMsg
    logger's logError("Error: " & errMsg, missing value)
end try

-- Check success
if result's success then
    -- continue
else
    log "Failed: " & result's message
end if
```

---

## Getting Help

- **Documentation**: Check `docs/` directory
- **Examples**: See `workflows/` directory
- **Logs**: Review `logs/hod_automation.log`
- **Tests**: Run `tests/test_suite.applescript`

---

## Congratulations! 🎉

You're now ready to automate IBM Host On-Demand tasks. Start with simple examples and gradually build more complex workflows.

**Happy Automating!**

---

**Made with Bob** 🤖