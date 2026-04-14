#!/bin/bash

# Fix helpers.applescript - line 161: item -> listItem
sed -i '' 's/repeat with item in sourceList/repeat with listItem in sourceList/g' src/utils/helpers.applescript
sed -i '' 's/if class of item is record then/if class of listItem is record then/g' src/utils/helpers.applescript
sed -i '' 's/set copiedItem to deepCopyRecord(item)/set copiedItem to deepCopyRecord(listItem)/g' src/utils/helpers.applescript
sed -i '' 's/else if class of item is list then/else if class of listItem is list then/g' src/utils/helpers.applescript
sed -i '' 's/set copiedItem to deepCopyList(item)/set copiedItem to deepCopyList(listItem)/g' src/utils/helpers.applescript
sed -i '' 's/set copiedItem to item$/set copiedItem to listItem/g' src/utils/helpers.applescript

# Fix more item references in helpers
sed -i '' 's/repeat with item in lst$/repeat with listItem in lst/g' src/utils/helpers.applescript
sed -i '' 's/if class of item is record then$/if class of listItem is record then/g' src/utils/helpers.applescript
sed -i '' 's/set output to output & recordToString(item)/set output to output & recordToString(listItem)/g' src/utils/helpers.applescript
sed -i '' 's/else if class of item is list then$/else if class of listItem is list then/g' src/utils/helpers.applescript
sed -i '' 's/set output to output & listToString(item)/set output to output & listToString(listItem)/g' src/utils/helpers.applescript
sed -i '' 's/set output to output & (item as string)/set output to output & (listItem as string)/g' src/utils/helpers.applescript

sed -i '' 's/repeat with item in lst$/repeat with listItem in lst/g' src/utils/helpers.applescript
sed -i '' 's/if item is value then$/if listItem is value then/g' src/utils/helpers.applescript
sed -i '' 's/repeat with item in lst$/repeat with listItem in lst/g' src/utils/helpers.applescript
sed -i '' 's/if not isInList(item, uniqueItems) then$/if not isInList(listItem, uniqueItems) then/g' src/utils/helpers.applescript
sed -i '' 's/set end of uniqueItems to item$/set end of uniqueItems to listItem/g' src/utils/helpers.applescript

# Fix logger.applescript - line 311: error -> hasError
sed -i '' 's/{topFiles:{}, totalFiles:0, error:errMsg}/{topFiles:{}, totalFiles:0, hasError:errMsg}/g' src/utils/logger.applescript

# Fix filelist_parser.applescript - line 175: files parameter
sed -i '' 's/on parseFileList(files)/on parseFileList(fileLines)/g' src/parsers/filelist_parser.applescript
sed -i '' 's/repeat with line in files$/repeat with line in fileLines/g' src/parsers/filelist_parser.applescript

# Fix xedit_parser.applescript - line 170: lines parameter  
sed -i '' 's/on parseXeditContent(lines)/on parseXeditContent(contentLines)/g' src/parsers/xedit_parser.applescript
sed -i '' 's/repeat with line in lines$/repeat with line in contentLines/g' src/parsers/xedit_parser.applescript

# Fix decision_engine.applescript - line 103: class -> screenClass
sed -i '' 's/set class to "unknown"/set screenClass to "unknown"/g' src/engine/decision_engine.applescript

# Fix workflow_executor.applescript - line 82: error -> hasError
sed -i '' 's/return {success:false, error:true, message:errMsg}/return {success:false, hasError:true, message:errMsg}/g' src/engine/workflow_executor.applescript

# Fix main.applescript - line 343: contains with record syntax
sed -i '' 's/if searchCriteria contains {filename:missing value} is false then/if searchCriteria is not missing value then/g' src/main.applescript
sed -i '' 's/if searchCriteria contains {user:missing value} is false then/if searchCriteria is not missing value then/g' src/main.applescript

# Fix batch_operations - line 236: list -> listCommand
sed -i '' 's/set listCommand to "LISTFILE/set listCmd to "LISTFILE/g' workflows/batch_operations.applescript
sed -i '' 's/set listResult to mainAPI/set listRes to mainAPI/g' workflows/batch_operations.applescript

# Fix file_transfer - line 212: list -> listCommand  
sed -i '' 's/set listCommand to "LISTFILE/set listCmd to "LISTFILE/g' workflows/file_transfer.applescript
sed -i '' 's/set listResult to mainAPI/set listRes to mainAPI/g' workflows/file_transfer.applescript

# Fix netlog_analysis - line 39: contains syntax
sed -i '' 's/if analysisResult'"'"'s analysis contains {fileFrequency:missing value} is false then/if analysisResult'"'"'s analysis is not missing value then/g' workflows/netlog_analysis.applescript

echo "Syntax fixes applied"
