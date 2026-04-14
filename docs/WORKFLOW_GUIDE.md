# IBM Host On-Demand Automation - Workflow Guide

## Table of Contents
- [Introduction](#introduction)
- [Workflow Basics](#workflow-basics)
- [Simple Workflows](#simple-workflows)
- [Advanced Workflows](#advanced-workflows)
- [Common Patterns](#common-patterns)
- [Error Handling in Workflows](#error-handling-in-workflows)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting Workflows](#troubleshooting-workflows)

---

## Introduction

This guide teaches you how to create effective workflows for IBM Host On-Demand automation. Workflows combine multiple operations into cohesive, reusable automation scripts.

### What is a Workflow?

A workflow is a sequence of operations that accomplish a specific task, such as:
- Transferring files between systems
- Searching and analyzing NETLOG entries
- Batch editing multiple files
- Automated testing and validation

### Workflow Components

Every workflow consists of:
1. **Initialization**: Set up session and logging
2. **Operations**: Execute the main tasks
3. **Validation**: Verify results
4. **Cleanup**: Close session and save logs

---

## Workflow Basics

### Basic Workflow Structure

```applescript
-- Load required modules
property mainAPI : load script POSIX file "/path/to/src/main.applescript"
property logger : load script POSIX file "/path/to/src/utils/logger.applescript"

-- Workflow: Basic File View
on runBasicWorkflow()
    try
        -- 1. Initialize
        logger's initializeLogging()
        logger's logInfo("Starting basic workflow", missing value)
        
        -- 2. Create session
        set sessionResult to mainAPI's initSession("A")
        if not sessionResult's success then
            logger's logError("Session init failed", missing value)
            return {success:false, message:sessionResult's message}
        end if
        set mySession to sessionResult's session
        
        -- 3. Perform operations
        set navResult to mainAPI's navigateToFile(mySession, "PROFILE", "EXEC", "A1")
        if not navResult's success then
            logger's logError("Navigation failed", missing value)
            mainAPI's closeSession(mySession)
            return {success:false, message:navResult's message}
        end if
        
        -- 4. Cleanup
        mainAPI's closeSession(mySession)
        logger's logInfo("Workflow completed successfully", missing value)
        
        return {success:true, message:"Workflow completed"}
        
    on error errMsg number errNum
        logger's logError("Workflow error: " & errMsg, {errorNumber:errNum})
        return {success:false, message:errMsg, errorNumber:errNum}
    end try
end runBasicWorkflow

-- Execute workflow
runBasicWorkflow()
```

### Workflow Best Practices

1. **Always use try-catch blocks**
2. **Initialize logging first**
3. **Check success of each operation**
4. **Clean up resources (close sessions)**
5. **Log important events**
6. **Return meaningful results**

---

## Simple Workflows

### Workflow 1: View File Content

View the contents of a specific file.

```applescript
-- Workflow: View File Content
on viewFileWorkflow(sessionLetter, filename, filetype, filemode)
    try
        logger's initializeLogging()
        set startTime to current date
        
        -- Initialize session
        set sessionResult to mainAPI's initSession(sessionLetter)
        if not sessionResult's success then
            return {success:false, message:"Session init failed"}
        end if
        set mySession to sessionResult's session
        
        -- Navigate to file
        logger's logInfo("Navigating to file", {filename:filename, filetype:filetype})
        set navResult to mainAPI's navigateToFile(mySession, filename, filetype, filemode)
        
        if navResult's success then
            -- Get current state (file is now open in XEDIT)
            set stateResult to mainAPI's getSessionState(mySession)
            
            logger's logInfo("File opened successfully", {steps:navResult's steps})
            
            -- Close session
            mainAPI's closeSession(mySession)
            
            set endTime to current date
            logger's logOperationTiming("viewFile", startTime, endTime)
            
            return {success:true, message:"File viewed", steps:navResult's steps}
        else
            mainAPI's closeSession(mySession)
            return {success:false, message:navResult's message}
        end if
        
    on error errMsg
        logger's logError("View file workflow error: " & errMsg, missing value)
        try
            mainAPI's closeSession(mySession)
        end try
        return {success:false, message:errMsg}
    end try
end viewFileWorkflow

-- Example usage
viewFileWorkflow("A", "PROFILE", "EXEC", "A1")
```

---

### Workflow 2: Edit File Line

Edit a specific line in a file.

```applescript
-- Workflow: Edit File Line
on editFileLineWorkflow(sessionLetter, filename, filetype, filemode, lineNumber, newContent)
    try
        logger's initializeLogging()
        logger's logInfo("Starting edit workflow", {filename:filename, line:lineNumber})
        
        -- Initialize session
        set sessionResult to mainAPI's initSession(sessionLetter)
        if not sessionResult's success then
            return {success:false, message:"Session init failed"}
        end if
        set mySession to sessionResult's session
        
        -- Navigate to file
        set navResult to mainAPI's navigateToFile(mySession, filename, filetype, filemode)
        if not navResult's success then
            mainAPI's closeSession(mySession)
            return {success:false, message:"Navigation failed: " & navResult's message}
        end if
        
        -- Edit the line
        logger's logInfo("Editing line", {lineNumber:lineNumber})
        set editResult to mainAPI's editFile(mySession, lineNumber, newContent)
        if not editResult's success then
            mainAPI's closeSession(mySession)
            return {success:false, message:"Edit failed: " & editResult's message}
        end if
        
        -- Save and exit
        logger's logInfo("Saving file", missing value)
        set saveResult to mainAPI's saveAndExit(mySession)
        if not saveResult's success then
            mainAPI's closeSession(mySession)
            return {success:false, message:"Save failed: " & saveResult's message}
        end if
        
        -- Close session
        mainAPI's closeSession(mySession)
        logger's logInfo("Edit workflow completed", missing value)
        
        return {success:true, message:"File edited and saved", lineNumber:lineNumber}
        
    on error errMsg
        logger's logError("Edit workflow error: " & errMsg, missing value)
        try
            mainAPI's closeSession(mySession)
        end try
        return {success:false, message:errMsg}
    end try
end editFileLineWorkflow

-- Example usage
editFileLineWorkflow("A", "TEST", "DATA", "A", 5, "Updated line content")
```

---

### Workflow 3: Search NETLOG

Search NETLOG for specific entries.

```applescript
-- Workflow: Search NETLOG
on searchNetlogWorkflow(sessionLetter, searchFilename, searchUser)
    try
        logger's initializeLogging()
        logger's logInfo("Starting NETLOG search", {filename:searchFilename, user:searchUser})
        
        -- Initialize session
        set sessionResult to mainAPI's initSession(sessionLetter)
        if not sessionResult's success then
            return {success:false, message:"Session init failed"}
        end if
        set mySession to sessionResult's session
        
        -- Build search criteria
        set criteria to {filename:searchFilename, user:searchUser}
        
        -- Search NETLOG
        set searchResult to mainAPI's searchNetlog(mySession, criteria)
        
        if searchResult's success then
            logger's logInfo("Search completed", {entriesFound:searchResult's totalEntries, pagesSearched:searchResult's pageCount})
            
            -- Process results
            set matchingEntries to searchResult's entries
            
            -- Log each entry
            repeat with entry in matchingEntries
                logger's logInfo("Found entry", {filename:entry's filename, from:entry's fromUser, to:entry's toUser})
            end repeat
            
            -- Close session
            mainAPI's closeSession(mySession)
            
            return {success:true, entries:matchingEntries, totalEntries:searchResult's totalEntries}
        else
            mainAPI's closeSession(mySession)
            return {success:false, message:searchResult's message}
        end if
        
    on error errMsg
        logger's logError("NETLOG search workflow error: " & errMsg, missing value)
        try
            mainAPI's closeSession(mySession)
        end try
        return {success:false, message:errMsg}
    end try
end searchNetlogWorkflow

-- Example usage
searchNetlogWorkflow("A", "MYFILE", "TESTUSER")
```

---

## Advanced Workflows

### Workflow 4: Batch File Processing

Process multiple files in sequence.

```applescript
-- Workflow: Batch File Processing
on batchProcessWorkflow(sessionLetter, fileList)
    try
        logger's initializeLogging()
        logger's logInfo("Starting batch processing", {fileCount:(count of fileList)})
        
        set results to {}
        set successCount to 0
        set failCount to 0
        
        -- Initialize session once for all files
        set sessionResult to mainAPI's initSession(sessionLetter)
        if not sessionResult's success then
            return {success:false, message:"Session init failed"}
        end if
        set mySession to sessionResult's session
        
        -- Process each file
        repeat with fileInfo in fileList
            set filename to filename of fileInfo
            set filetype to filetype of fileInfo
            set filemode to filemode of fileInfo
            set operation to operation of fileInfo
            
            logger's logInfo("Processing file", {filename:filename, operation:operation})
            
            -- Navigate to file
            set navResult to mainAPI's navigateToFile(mySession, filename, filetype, filemode)
            
            if navResult's success then
                -- Perform operation based on type
                if operation is "view" then
                    -- Just view (already navigated)
                    set opResult to {success:true, message:"Viewed"}
                    
                else if operation is "edit" then
                    -- Edit file (example: add comment line)
                    set editResult to mainAPI's editFile(mySession, 1, "/* Processed by automation */")
                    if editResult's success then
                        set opResult to mainAPI's saveAndExit(mySession)
                    else
                        set opResult to editResult
                    end if
                    
                else
                    set opResult to {success:false, message:"Unknown operation"}
                end if
                
                -- Record result
                if opResult's success then
                    set successCount to successCount + 1
                    set end of results to {filename:filename, success:true, message:opResult's message}
                else
                    set failCount to failCount + 1
                    set end of results to {filename:filename, success:false, message:opResult's message}
                end if
                
                -- Return to CMS prompt for next file
                mainAPI's executeCMSCommand(mySession, "")
                delay 0.5
                
            else
                set failCount to failCount + 1
                set end of results to {filename:filename, success:false, message:"Navigation failed"}
            end if
        end repeat
        
        -- Close session
        mainAPI's closeSession(mySession)
        
        logger's logInfo("Batch processing completed", {success:successCount, failed:failCount})
        
        return {success:true, results:results, successCount:successCount, failCount:failCount}
        
    on error errMsg
        logger's logError("Batch processing error: " & errMsg, missing value)
        try
            mainAPI's closeSession(mySession)
        end try
        return {success:false, message:errMsg}
    end try
end batchProcessWorkflow

-- Example usage
set fileList to {¬
    {filename:"FILE1", filetype:"DATA", filemode:"A", operation:"view"}, ¬
    {filename:"FILE2", filetype:"DATA", filemode:"A", operation:"edit"}, ¬
    {filename:"FILE3", filetype:"DATA", filemode:"A", operation:"view"}}

batchProcessWorkflow("A", fileList)
```

---

### Workflow 5: Conditional Processing

Process files based on conditions.

```applescript
-- Workflow: Conditional File Processing
on conditionalProcessWorkflow(sessionLetter, filename, filetype, filemode, condition)
    try
        logger's initializeLogging()
        logger's logInfo("Starting conditional processing", {filename:filename, condition:condition})
        
        -- Initialize session
        set sessionResult to mainAPI's initSession(sessionLetter)
        if not sessionResult's success then
            return {success:false, message:"Session init failed"}
        end if
        set mySession to sessionResult's session
        
        -- Navigate to file
        set navResult to mainAPI's navigateToFile(mySession, filename, filetype, filemode)
        if not navResult's success then
            mainAPI's closeSession(mySession)
            return {success:false, message:"Navigation failed"}
        end if
        
        -- Get current screen state
        set stateResult to mainAPI's getSessionState(mySession)
        if not stateResult's success then
            mainAPI's closeSession(mySession)
            return {success:false, message:"Could not get state"}
        end if
        
        set screenData to stateResult's screenData
        
        -- Check condition
        set shouldProcess to false
        
        if condition is "file_exists" then
            -- File exists if we successfully navigated to it
            set shouldProcess to true
            
        else if condition is "file_size_large" then
            -- Check if file has more than 100 lines
            try
                set fileSize to size of metadata of screenData
                if fileSize > 100 then
                    set shouldProcess to true
                end if
            end try
            
        else if condition is "file_modified_today" then
            -- Check alteration count (simplified check)
            try
                set altCount to alteration of metadata of screenData
                if altCount > 0 then
                    set shouldProcess to true
                end if
            end try
        end if
        
        -- Process if condition met
        if shouldProcess then
            logger's logInfo("Condition met, processing file", {condition:condition})
            
            -- Example: Add timestamp comment
            set timestamp to (current date) as string
            set editResult to mainAPI's editFile(mySession, 1, "/* Processed: " & timestamp & " */")
            
            if editResult's success then
                set saveResult to mainAPI's saveAndExit(mySession)
                mainAPI's closeSession(mySession)
                return {success:true, message:"File processed", conditionMet:true}
            else
                mainAPI's closeSession(mySession)
                return {success:false, message:"Edit failed"}
            end if
        else
            logger's logInfo("Condition not met, skipping", {condition:condition})
            mainAPI's closeSession(mySession)
            return {success:true, message:"Condition not met, skipped", conditionMet:false}
        end if
        
    on error errMsg
        logger's logError("Conditional processing error: " & errMsg, missing value)
        try
            mainAPI's closeSession(mySession)
        end try
        return {success:false, message:errMsg}
    end try
end conditionalProcessWorkflow

-- Example usage
conditionalProcessWorkflow("A", "LARGEFILE", "DATA", "A", "file_size_large")
```

---

## Common Patterns

### Pattern 1: Retry with Backoff

Retry operations with exponential backoff.

```applescript
-- Pattern: Retry with Backoff
on retryOperation(operation, maxAttempts, initialDelay)
    set attempt to 0
    set delay to initialDelay
    
    repeat while attempt < maxAttempts
        set attempt to attempt + 1
        logger's logInfo("Attempt " & attempt & " of " & maxAttempts, missing value)
        
        set result to operation()
        
        if result's success then
            return result
        end if
        
        -- Wait before retry (exponential backoff)
        if attempt < maxAttempts then
            logger's logInfo("Waiting " & delay & " seconds before retry", missing value)
            delay delay
            set delay to delay * 2
        end if
    end repeat
    
    return {success:false, message:"Max retries exceeded"}
end retryOperation
```

---

### Pattern 2: Progress Tracking

Track and report progress for long operations.

```applescript
-- Pattern: Progress Tracking
on processWithProgress(itemList, processingHandler)
    set totalItems to count of itemList
    set processedItems to 0
    set results to {}
    
    repeat with item in itemList
        set processedItems to processedItems + 1
        set progress to (processedItems / totalItems) * 100
        
        logger's logInfo("Progress: " & (round progress) & "%", {item:processedItems, total:totalItems})
        
        -- Process item
        set result to processingHandler(item)
        set end of results to result
        
        -- Report milestone progress
        if progress ≥ 25 and progress < 30 then
            log "25% complete"
        else if progress ≥ 50 and progress < 55 then
            log "50% complete"
        else if progress ≥ 75 and progress < 80 then
            log "75% complete"
        end if
    end repeat
    
    logger's logInfo("Processing complete: 100%", {total:totalItems})
    return results
end processWithProgress
```

---

### Pattern 3: Transaction-like Processing

Ensure all-or-nothing processing with rollback capability.

```applescript
-- Pattern: Transaction Processing
on transactionWorkflow(sessionLetter, operations)
    try
        logger's initializeLogging()
        set completedOps to {}
        
        -- Initialize session
        set sessionResult to mainAPI's initSession(sessionLetter)
        if not sessionResult's success then
            return {success:false, message:"Session init failed"}
        end if
        set mySession to sessionResult's session
        
        -- Execute operations
        repeat with op in operations
            set opResult to executeOperation(mySession, op)
            
            if opResult's success then
                set end of completedOps to op
            else
                -- Operation failed, rollback
                logger's logError("Operation failed, rolling back", {operation:op})
                rollbackOperations(mySession, completedOps)
                mainAPI's closeSession(mySession)
                return {success:false, message:"Transaction rolled back", failedOp:op}
            end if
        end repeat
        
        -- All operations succeeded
        mainAPI's closeSession(mySession)
        return {success:true, message:"Transaction completed", operationsCompleted:(count of completedOps)}
        
    on error errMsg
        logger's logError("Transaction error: " & errMsg, missing value)
        try
            rollbackOperations(mySession, completedOps)
            mainAPI's closeSession(mySession)
        end try
        return {success:false, message:errMsg}
    end try
end transactionWorkflow
```

---

## Error Handling in Workflows

### Comprehensive Error Handling

```applescript
-- Workflow with Comprehensive Error Handling
on robustWorkflow(sessionLetter, filename, filetype, filemode)
    try
        logger's initializeLogging()
        set errorHandler to load script POSIX file "/path/to/src/utils/error_handler.applescript"
        
        -- Initialize session with retry
        set sessionResult to missing value
        set retries to 0
        repeat while retries < 3
            set sessionResult to mainAPI's initSession(sessionLetter)
            if sessionResult's success then
                exit repeat
            end if
            set retries to retries + 1
            delay 1
        end repeat
        
        if not sessionResult's success then
            return {success:false, message:"Session init failed after retries"}
        end if
        set mySession to sessionResult's session
        
        -- Navigate with error recovery
        set navResult to mainAPI's navigateToFile(mySession, filename, filetype, filemode)
        
        if not navResult's success then
            -- Attempt error recovery
            logger's logWarn("Navigation failed, attempting recovery", missing value)
            set recovery to errorHandler's handleError("navigation", {}, mySession's windowRef)
            
            if recovery's recovered then
                -- Retry navigation
                set navResult to mainAPI's navigateToFile(mySession, filename, filetype, filemode)
            end if
        end if
        
        if navResult's success then
            -- Success path
            mainAPI's closeSession(mySession)
            return {success:true, message:"Workflow completed"}
        else
            -- Failure path
            mainAPI's closeSession(mySession)
            return {success:false, message:"Navigation failed after recovery"}
        end if
        
    on error errMsg number errNum
        logger's logError("Workflow error: " & errMsg, {errorNumber:errNum})
        try
            mainAPI's closeSession(mySession)
        end try
        return {success:false, message:errMsg, errorNumber:errNum}
    end try
end robustWorkflow
```

---

## Performance Optimization

### Optimization Tips

1. **Reuse Sessions**
   ```applescript
   -- Good: One session for multiple operations
   set session to initSession("A")
   navigateToFile(session, "FILE1", "DATA", "A")
   navigateToFile(session, "FILE2", "DATA", "A")
   closeSession(session)
   
   -- Bad: New session for each operation
   set session1 to initSession("A")
   navigateToFile(session1, "FILE1", "DATA", "A")
   closeSession(session1)
   set session2 to initSession("A")
   navigateToFile(session2, "FILE2", "DATA", "A")
   closeSession(session2)
   ```

2. **Minimize Screen Captures**
   ```applescript
   -- Cache screen state when possible
   set state to getSessionState(session)
   set screenType to state's state's currentScreen
   -- Use cached screenType instead of capturing again
   ```

3. **Batch Operations**
   ```applescript
   -- Process multiple items in one session
   repeat with item in itemList
       processItem(session, item)
   end repeat
   ```

4. **Optimize Delays**
   ```applescript
   -- Use appropriate delays
   delay 0.5  -- For screen transitions
   delay 1.0  -- For command processing
   delay 1.5  -- For file operations
   ```

---

## Troubleshooting Workflows

### Common Issues

1. **Workflow Hangs**
   - Add timeout checks
   - Use error recovery
   - Log progress frequently

2. **Inconsistent Results**
   - Add validation after each step
   - Increase delays between operations
   - Check screen state before proceeding

3. **Resource Leaks**
   - Always close sessions in finally blocks
   - Clean up temporary files
   - Clear clipboard after use

### Debug Mode

```applescript
-- Enable debug logging
property DEBUG_MODE : true

on debugLog(message)
    if DEBUG_MODE then
        log "DEBUG: " & message
        logger's logDebug(message, missing value)
    end if
end debugLog

-- Use in workflow
debugLog("About to navigate to file")
set result to navigateToFile(session, filename, filetype, filemode)
debugLog("Navigation result: " & result's success)
```

---

## Next Steps

- Review the [API Reference](API_REFERENCE.md) for detailed function documentation
- Check the [Troubleshooting Guide](TROUBLESHOOTING.md) for common issues
- See example workflows in the `workflows/` directory
- Run the demo script to see workflows in action

---

**Made with Bob** 🤖