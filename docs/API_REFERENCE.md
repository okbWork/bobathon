# IBM Host On-Demand Automation - API Reference

## Table of Contents
- [Overview](#overview)
- [Main API Module](#main-api-module)
- [Core Modules](#core-modules)
- [Parser Modules](#parser-modules)
- [Engine Modules](#engine-modules)
- [Utility Modules](#utility-modules)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

---

## Overview

This API reference provides comprehensive documentation for all public functions in the IBM Host On-Demand automation system. The system is organized into modular components for maintainability and extensibility.

### Module Structure
```
src/
├── main.applescript           # High-level user API
├── core/                      # Core automation components
├── parsers/                   # Screen parsing modules
├── engine/                    # Intelligence and workflow
└── utils/                     # Utilities and helpers
```

---

## Main API Module

The main API module (`src/main.applescript`) provides high-level, user-friendly functions for common operations.

### initSession(sessionLetter)

Initialize a HOD session and prepare for automation.

**Parameters:**
- `sessionLetter` (string): Session letter (A-Z)

**Returns:**
```applescript
{
    success: boolean,
    session: record,
    screenType: string,
    message: string
}
```

**Example:**
```applescript
set result to initSession("A")
if result's success then
    set mySession to result's session
    log "Session initialized: " & result's screenType
end if
```

**Error Handling:**
- Returns `success:false` if window not found
- Returns `success:false` if screen capture fails
- Logs all errors to system log

---

### closeSession(session)

Close session and return to CMS prompt.

**Parameters:**
- `session` (record): Session object from initSession

**Returns:**
```applescript
{
    success: boolean,
    message: string,
    attempts: integer
}
```

**Example:**
```applescript
set result to closeSession(mySession)
if result's success then
    log "Session closed after " & result's attempts & " attempts"
end if
```

**Notes:**
- Automatically navigates back using PF3
- Maximum 5 attempts to reach CMS prompt
- Logs session summary before closing

---

### navigateToFile(session, filename, filetype, filemode)

Navigate to a specific file in the system.

**Parameters:**
- `session` (record): Active session object
- `filename` (string): File name (e.g., "PROFILE")
- `filetype` (string): File type (e.g., "EXEC")
- `filemode` (string): File mode (e.g., "A1")

**Returns:**
```applescript
{
    success: boolean,
    steps: integer,
    screenType: string,
    message: string
}
```

**Example:**
```applescript
set result to navigateToFile(mySession, "PROFILE", "EXEC", "A1")
if result's success then
    log "Navigated to file in " & result's steps & " steps"
end if
```

**Notes:**
- Uses intelligent decision engine for navigation
- Maximum 20 navigation steps (configurable)
- Automatically handles FILELIST and XEDIT screens
- Includes error recovery

---

### searchNetlog(session, searchCriteria)

Search NETLOG for entries matching criteria.

**Parameters:**
- `session` (record): Active session object
- `searchCriteria` (record): Search parameters
  ```applescript
  {
      filename: string (optional),
      user: string (optional),
      date: string (optional)
  }
  ```

**Returns:**
```applescript
{
    success: boolean,
    entries: list,
    pageCount: integer,
    totalEntries: integer
}
```

**Example:**
```applescript
set criteria to {filename:"MYFILE", user:"TESTUSER"}
set result to searchNetlog(mySession, criteria)
if result's success then
    log "Found " & result's totalEntries & " entries"
    repeat with entry in result's entries
        log entry's filename & " from " & entry's fromUser
    end repeat
end if
```

**Notes:**
- Searches up to 50 pages (configurable)
- Returns all matching entries
- Automatically navigates to NETLOG if needed

---

### editFile(session, lineNumber, newContent)

Edit a specific line in XEDIT.

**Parameters:**
- `session` (record): Active session object
- `lineNumber` (integer): Line number to edit
- `newContent` (string): New content for the line

**Returns:**
```applescript
{
    success: boolean,
    lineNumber: integer,
    message: string
}
```

**Example:**
```applescript
set result to editFile(mySession, 10, "New line content")
if result's success then
    log "Line " & result's lineNumber & " edited successfully"
end if
```

**Notes:**
- Must be in XEDIT mode
- Uses XEDIT change command
- Does not save automatically (use saveAndExit)

---

### saveAndExit(session)

Save file and exit XEDIT.

**Parameters:**
- `session` (record): Active session object

**Returns:**
```applescript
{
    success: boolean,
    message: string,
    warning: string (optional)
}
```

**Example:**
```applescript
set result to saveAndExit(mySession)
if result's success then
    log "File saved and closed"
end if
```

**Notes:**
- Sends FILE command to save and exit
- Verifies return to CMS prompt
- Returns warning if verification fails

---

### executeCMSCommand(session, command)

Execute a CMS command and capture output.

**Parameters:**
- `session` (record): Active session object
- `command` (string): CMS command to execute

**Returns:**
```applescript
{
    success: boolean,
    output: string,
    screenType: string,
    parsed: record
}
```

**Example:**
```applescript
set result to executeCMSCommand(mySession, "LISTFILE * * A")
if result's success then
    log "Command output: " & result's output
    log "Result screen: " & result's screenType
end if
```

**Notes:**
- Verifies CMS prompt before execution
- Waits 1.5 seconds for command completion
- Returns parsed screen data

---

### getSessionState(session)

Get current session state and statistics.

**Parameters:**
- `session` (record): Active session object

**Returns:**
```applescript
{
    success: boolean,
    state: record,
    screenData: record
}
```

**State Record:**
```applescript
{
    sessionLetter: string,
    currentScreen: string,
    operationCount: integer,
    lastOperation: string,
    sessionDuration: number
}
```

**Example:**
```applescript
set result to getSessionState(mySession)
if result's success then
    set state to result's state
    log "Current screen: " & state's currentScreen
    log "Operations: " & state's operationCount
end if
```

---

## Core Modules

### Window Manager (`src/core/window_manager.applescript`)

#### getHODWindow(sessionLetter)

Find and return HOD window reference.

**Parameters:**
- `sessionLetter` (string): Session letter (A-Z)

**Returns:**
```applescript
{
    success: boolean,
    windowRef: record,
    message: string
}
```

**Example:**
```applescript
set result to windowManager's getHODWindow("A")
if result's success then
    set winRef to result's windowRef
end if
```

---

### Screen Capture (`src/core/screen_capture.applescript`)

#### captureScreen(windowRef)

Capture screen content from HOD window.

**Parameters:**
- `windowRef` (record): Window reference from window manager

**Returns:**
```applescript
{
    success: boolean,
    screenText: string,
    message: string
}
```

**Example:**
```applescript
set result to screenCapture's captureScreen(windowRef)
if result's success then
    set screenText to result's screenText
    log "Captured " & (length of screenText) & " characters"
end if
```

**Notes:**
- Uses mouse automation for selection
- Copies to clipboard via toolbar button
- Includes retry logic (3 attempts)
- Validates captured content

---

### Keyboard Controller (`src/core/keyboard_controller.applescript`)

#### sendText(windowRef, text)

Type text into HOD window.

**Parameters:**
- `windowRef` (record): Window reference
- `text` (string): Text to type

**Returns:**
```applescript
{
    success: boolean,
    message: string
}
```

**Example:**
```applescript
set result to keyboardController's sendText(windowRef, "FILELIST")
```

---

#### sendEnter(windowRef)

Press Enter key.

**Parameters:**
- `windowRef` (record): Window reference

**Returns:**
```applescript
{
    success: boolean,
    message: string
}
```

---

#### sendPFKey(windowRef, keyNumber)

Press PF key (1-12).

**Parameters:**
- `windowRef` (record): Window reference
- `keyNumber` (integer): PF key number (1-12)

**Returns:**
```applescript
{
    success: boolean,
    message: string
}
```

**Example:**
```applescript
-- Press PF3 (Quit/Back)
set result to keyboardController's sendPFKey(windowRef, 3)
```

**PF Key Mappings:**
- PF1: Help
- PF3: Quit/Back
- PF7: Backward
- PF8: Forward
- PF12: Retrieve

---

### Clipboard Manager (`src/core/clipboard_manager.applescript`)

#### clearClipboard()

Clear system clipboard.

**Returns:**
```applescript
{
    success: boolean,
    message: string
}
```

---

#### readClipboard()

Read content from clipboard.

**Returns:**
```applescript
{
    success: boolean,
    content: string,
    message: string
}
```

---

## Parser Modules

### Screen Parser (`src/parsers/screen_parser.applescript`)

#### parseScreen(screenText)

Parse screen text into structured data.

**Parameters:**
- `screenText` (string): Raw screen text

**Returns:**
```applescript
{
    screenType: string,
    header: record,
    content: list,
    footer: string,
    pfKeys: list,
    rawLines: list,
    metadata: record (optional)
}
```

**Screen Types:**
- `"cms_prompt"`: CMS Ready prompt
- `"xedit"`: XEDIT editor
- `"netlog"`: NETLOG viewer
- `"filelist"`: File list
- `"error"`: Error screen
- `"unknown"`: Unrecognized screen

**Example:**
```applescript
set parsed to screenParser's parseScreen(screenText)
log "Screen type: " & parsed's screenType

if parsed's screenType is "xedit" then
    set meta to parsed's metadata
    log "Editing: " & meta's filename & " " & meta's filetype
end if
```

---

## Engine Modules

### Decision Engine (`src/engine/decision_engine.applescript`)

#### makeDecision(screenData, goal)

Make intelligent decision based on current state and goal.

**Parameters:**
- `screenData` (record): Parsed screen data
- `goal` (record): Desired outcome
  ```applescript
  {
      action: string,
      filename: string (optional),
      filetype: string (optional),
      parameters: record (optional)
  }
  ```

**Returns:**
```applescript
{
    action: string,
    parameters: record,
    reasoning: string,
    confidence: number (0.0-1.0)
}
```

**Example:**
```applescript
set goal to {action:"navigate_to_file", filename:"PROFILE", filetype:"EXEC"}
set decision to decisionEngine's makeDecision(screenData, goal)
log "Decision: " & decision's action
log "Reasoning: " & decision's reasoning
log "Confidence: " & decision's confidence
```

---

### Workflow Executor (`src/engine/workflow_executor.applescript`)

#### executeAction(windowRef, decision, screenData)

Execute a specific action based on decision.

**Parameters:**
- `windowRef` (record): Window reference
- `decision` (record): Decision from decision engine
- `screenData` (record): Current screen data

**Returns:**
```applescript
{
    success: boolean,
    message: string,
    data: record (optional)
}
```

**Example:**
```applescript
set result to workflowExecutor's executeAction(windowRef, decision, screenData)
if result's success then
    log "Action executed: " & result's message
end if
```

---

## Utility Modules

### Logger (`src/utils/logger.applescript`)

#### initializeLogging()

Initialize logging system.

**Returns:**
```applescript
{
    success: boolean,
    logPath: string,
    sessionStart: date
}
```

---

#### logInfo(message, context)

Log informational message.

**Parameters:**
- `message` (string): Log message
- `context` (record): Optional context data

**Example:**
```applescript
logger's logInfo("Operation started", {operation:"file_transfer", filename:"TEST"})
```

---

#### logError(message, context)

Log error message.

**Parameters:**
- `message` (string): Error message
- `context` (record): Optional error context

---

#### logOperationTiming(operationName, startTime, endTime)

Log operation timing metrics.

**Parameters:**
- `operationName` (string): Operation name
- `startTime` (date): Start time
- `endTime` (date): End time

**Returns:**
```applescript
{
    success: boolean,
    duration: number,
    formatted: string
}
```

---

### Error Handler (`src/utils/error_handler.applescript`)

#### handleError(errorType, errorDetails, windowRef)

Handle and recover from errors.

**Parameters:**
- `errorType` (string): Type of error
  - `"capture_failure"`: Screen capture failed
  - `"freeze"`: System freeze
  - `"unexpected_screen"`: Wrong screen
  - `"timeout"`: Operation timeout
- `errorDetails` (record): Error details
- `windowRef` (record): Window reference

**Returns:**
```applescript
{
    success: boolean,
    recovered: boolean,
    message: string,
    attempts: integer (optional)
}
```

**Example:**
```applescript
set recovery to errorHandler's handleError("capture_failure", {}, windowRef)
if recovery's recovered then
    log "Recovered after " & recovery's attempts & " attempts"
else
    log "Recovery failed: " & recovery's message
end if
```

---

## Error Handling

### Error Response Format

All functions return consistent error information:

```applescript
{
    success: boolean,
    message: string,
    errorNumber: integer (optional),
    errorType: string (optional)
}
```

### Common Error Types

1. **Window Not Found**
   - `success: false`
   - `message: "Failed to get HOD window"`
   - Solution: Verify HOD is running and session exists

2. **Screen Capture Failed**
   - `success: false`
   - `message: "Screen capture failed"`
   - Solution: Check window focus and clipboard access

3. **Navigation Timeout**
   - `success: false`
   - `message: "Max navigation steps exceeded"`
   - Solution: Verify target file exists and is accessible

4. **Parse Error**
   - `success: false`
   - `message: "Screen parse error"`
   - Solution: Check screen content format

---

## Best Practices

### 1. Always Check Success

```applescript
set result to initSession("A")
if not result's success then
    log "Error: " & result's message
    return
end if
```

### 2. Use Error Recovery

```applescript
set captureResult to screenCapture's captureScreen(windowRef)
if not captureResult's success then
    set recovery to errorHandler's handleError("capture_failure", {}, windowRef)
    if recovery's recovered then
        -- Retry operation
        set captureResult to screenCapture's captureScreen(windowRef)
    end if
end if
```

### 3. Log Important Operations

```applescript
logger's logInfo("Starting file transfer", {filename:"TEST", size:1024})
set startTime to current date
-- Perform operation
set endTime to current date
logger's logOperationTiming("file_transfer", startTime, endTime)
```

### 4. Clean Up Sessions

```applescript
try
    -- Perform operations
    set result to navigateToFile(session, "TEST", "DATA", "A")
on error errMsg
    logger's logError("Operation failed: " & errMsg, missing value)
end try

-- Always close session
closeSession(session)
```

### 5. Validate Screen State

```applescript
set state to getSessionState(session)
if state's success then
    if state's state's currentScreen is not "xedit" then
        log "Warning: Not in expected screen"
    end if
end if
```

### 6. Use Appropriate Timeouts

```applescript
-- For quick operations
property DEFAULT_TIMEOUT : 30

-- For long operations (file transfers)
property LONG_TIMEOUT : 120
```

### 7. Handle Partial Success

```applescript
set result to searchNetlog(session, criteria)
if result's success then
    if result's totalEntries is 0 then
        log "Search completed but no entries found"
    else
        log "Found " & result's totalEntries & " entries"
    end if
end if
```

---

## Version Information

- **API Version**: 1.0.0
- **Last Updated**: 2026-04-14
- **Compatibility**: macOS 10.14+, AppleScript 2.4+

---

## Support

For issues, questions, or contributions:
- Review the [Troubleshooting Guide](TROUBLESHOOTING.md)
- Check the [Workflow Guide](WORKFLOW_GUIDE.md) for examples
- See the [Quick Start Guide](QUICKSTART.md) for getting started

---

**Made with Bob** 🤖