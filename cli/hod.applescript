property lastRecoveryWasAttn : false

on run argv
	if (count of argv) is 0 then
		return "ERROR: Missing command"
	end if
	
	set actionName to item 1 of argv
	
	if actionName is "activate" then
		if (count of argv) < 2 then return "ERROR: activate requires session letter"
		return my activateSession(item 2 of argv)
	else if actionName is "type" then
		if (count of argv) < 2 then return "ERROR: type requires text"
		return my typeTextCommand(item 2 of argv)
	else if actionName is "input" then
		if (count of argv) < 2 then return "ERROR: input requires text"
		return my inputTextOnScreen(item 2 of argv)
	else if actionName is "enter" then
		return my pressKeyCode(36, 0.8, "ENTER")
	else if actionName is "newline" then
		return my pressKeyCode(36, 0.8, "ENTER")
	else if actionName is "tab" then
		return my pressKeyCode(48, 0.4, "TAB")
	else if actionName is "escape" then
		return my pressKeyCode(53, 0.8, "ESCAPE")
	else if actionName is "attn" then
		return my pressAttn()
	else if actionName is "clear" then
		return my pressClear()
	else if actionName is "reset-hold" then
		return my resetHoldingState()
	else if actionName is "pf" then
		if (count of argv) < 2 then return "ERROR: pf requires key number"
		return my pressPF(item 2 of argv)
	else if actionName is "pagedown" then
		return my pressPF("8")
	else if actionName is "capture" then
		set screenText to ""
		repeat 3 times
			set screenText to my captureViaRawProbe()
			if my isBadScreenProbe(screenText) is false then return screenText
			delay 0.5
		end repeat
		return "ERROR: capture failed" & return & screenText
	else if actionName is "command" then
		if (count of argv) < 2 then return "ERROR: command requires text"
		return my sendCommand(item 2 of argv)
	else if actionName is "read-file" then
		if (count of argv) < 4 then return "ERROR: read-file requires filename, filetype, mode"
		return my readFileInXedit(item 2 of argv, item 3 of argv, item 4 of argv)
	else if actionName is "write-file-line" then
		if (count of argv) < 5 then return "ERROR: write-file-line requires filename, filetype, mode, text"
		return my writeFileLineInXedit(item 2 of argv, item 3 of argv, item 4 of argv, item 5 of argv)
	else if actionName is "line-cmd" then
		if (count of argv) < 2 then return "ERROR: line-cmd requires text"
		return my sendLineCommand(item 2 of argv)
	else if actionName is "copy-screen" then
		return my copyScreenViaMenu()
	else
		return "ERROR: Unknown command " & actionName
	end if
end run

on getHODProcessName()
	tell application "System Events"
		if exists process "IBM Host On-Demand.app" then return "IBM Host On-Demand.app"
		if exists process "WSCachedLoader" then return "WSCachedLoader"
	end tell
	error "Neither IBM Host On-Demand.app nor WSCachedLoader is running"
end getHODProcessName

on getHODProcess()
	tell application "System Events"
		set processName to my getHODProcessName()
		return process processName
	end tell
end getHODProcess

on findSessionWindow(sessionLetter)
	set targetTitle to "GDLVM7 - " & sessionLetter
	
	tell application "System Events"
		set hodProcess to my getHODProcess()
		tell hodProcess
			repeat with win in windows
				try
					if (name of win) is targetTitle then return win
				end try
			end repeat
			
			try
				set matchingWindows to (every window whose name contains "GDLVM7")
				if (count of matchingWindows) > 0 then return item 1 of matchingWindows
			end try
		end tell
	end tell
	
	error "Session window not found: " & targetTitle
end findSessionWindow

on activateSession(sessionLetter)
	try
		tell application "System Events"
			set hodProcess to my getHODProcess()
			set targetWindow to my findSessionWindow(sessionLetter)
			
			set frontmost of hodProcess to true
			try
				if value of attribute "AXMinimized" of targetWindow is true then
					set value of attribute "AXMinimized" of targetWindow to false
				end if
			end try
			perform action "AXRaise" of targetWindow
		end tell
		
		delay 0.6
		
		return "OK: activated " & sessionLetter
	on error errMsg
		return "ERROR: " & errMsg
	end try
end activateSession

on typeTextCommand(theText)
	try
		tell application "System Events"
			keystroke theText
		end tell
		delay 0.15
		return "OK: typed " & theText
	on error errMsg
		return "ERROR: " & errMsg
	end try
end typeTextCommand

on inputTextOnScreen(theText)
	try
		set activateResult to my activateSession("A")
		if activateResult does not start with "OK:" then return activateResult
		
		tell application "System Events"
			key code 48
		end tell
		delay 0.2
		
		set typeResult to my typeTextCommand(theText)
		if typeResult does not start with "OK:" then return typeResult
		
		return "OK: input " & theText
	on error errMsg
		return "ERROR: " & errMsg
	end try
end inputTextOnScreen

on pressKeyCode(keyCodeValue, waitSeconds, keyName)
	try
		tell application "System Events"
			key code keyCodeValue
		end tell
		delay waitSeconds
		return "OK: pressed " & keyName
	on error errMsg
		return "ERROR: " & errMsg
	end try
end pressKeyCode

on pressClear()
	try
		set clickResult to my clickNamedButton("A", "Clear")
		if clickResult is false then
			tell application "System Events"
				key code 51 using command down
			end tell
		end if
		delay 0.8
		return "OK: pressed CLEAR"
	on error errMsg
		return "ERROR: " & errMsg
	end try
end pressClear

on pressAttn()
	try
		set activateResult to my activateSession("A")
		if activateResult does not start with "OK:" then return activateResult
		
		set lastRecoveryWasAttn to false
		
		set pf3Result to my pressPF("3")
		if pf3Result does not start with "OK:" then return pf3Result
		
		set screenText to my captureViaRawProbe()
		if screenText contains "type QQUIT to quit anyway" then
			set qquitResult to my forceQuitChangedXedit()
			if qquitResult does not start with "OK:" then return qquitResult
			delay 1.0
			set screenText to my captureViaRawProbe()
		end if
		
		if screenText contains "Ready;" or screenText contains "VM READ" then
			set lastRecoveryWasAttn to true
			return "OK: pressed ATTN"
		end if
		
		if screenText contains "====>" and screenText does not contain "XEDIT * * * Top of File * * *" then
			set lastRecoveryWasAttn to true
			return "OK: pressed ATTN"
		end if
		
		return "ERROR: ATTN recovery not confirmed"
	on error errMsg
		set lastRecoveryWasAttn to false
		return "ERROR: " & errMsg
	end try
end pressAttn

on resetHoldingState()
	try
		tell application "System Events"
			key code 36
		end tell
		delay 0.8
		
		tell application "System Events"
			key code 51 using command down
		end tell
		delay 0.8
		
		return "OK: reset hold"
	on error errMsg
		return "ERROR: " & errMsg
	end try
end resetHoldingState

on pressPF(keyNumberText)
	try
		set keyNumber to keyNumberText as integer
		if keyNumber is less than 1 or keyNumber is greater than 12 then error "PF key must be 1-12"
		
		set buttonName to "PF" & keyNumber
		set clicked to my clickNamedButton("A", buttonName)
		if clicked is false then
			if keyNumber is 1 then
				set keyCodeValue to 122
			else if keyNumber is 2 then
				set keyCodeValue to 120
			else if keyNumber is 3 then
				set keyCodeValue to 99
			else if keyNumber is 4 then
				set keyCodeValue to 118
			else if keyNumber is 5 then
				set keyCodeValue to 96
			else if keyNumber is 6 then
				set keyCodeValue to 97
			else if keyNumber is 7 then
				set keyCodeValue to 98
			else if keyNumber is 8 then
				set keyCodeValue to 100
			else if keyNumber is 9 then
				set keyCodeValue to 101
			else if keyNumber is 10 then
				set keyCodeValue to 109
			else if keyNumber is 11 then
				set keyCodeValue to 103
			else if keyNumber is 12 then
				set keyCodeValue to 111
			end if
			
			tell application "System Events"
				key code keyCodeValue
			end tell
		end if
		
		delay 1.0
		return "OK: pressed PF" & keyNumber
	on error errMsg
		return "ERROR: " & errMsg
	end try
end pressPF

on sendCommand(theText)
	set activateResult to my activateSession("A")
	if activateResult does not start with "OK:" then return activateResult
	
	set beforeScreen to my captureViaRawProbe()
	set commandResult to my sendCommandSafely(theText, beforeScreen)
	set lastRecoveryWasAttn to false
	return commandResult
end sendCommand

on sendCommandAfterAttn(theText, beforeScreen)
	set commandResult to my sendCommandSafely(theText, beforeScreen)
	set lastRecoveryWasAttn to false
	return commandResult
end sendCommandAfterAttn

on sendCommandSafely(theText, beforeScreen)
	try
		my clickTerminalBody("A")
		delay 0.2
	end try
	
	set clearResult to my pressClear()
	if clearResult does not start with "OK:" then return clearResult
	
	set typeResult to my typeTextCommand(theText)
	if typeResult does not start with "OK:" then return typeResult
	
	set enterClicked to my clickNamedButton("A", "Enter")
	if enterClicked is false then
		set enterResult to my pressKeyCode(36, 1.2, "ENTER")
		if enterResult does not start with "OK:" then return enterResult
	else
		delay 1.2
	end if
	
	return my verifyCommandEffect(theText, beforeScreen)
end sendCommandSafely

on forceQuitChangedXedit()
	try
		set clearResult to my pressClear()
		if clearResult does not start with "OK:" then return clearResult
		
		set typeResult to my typeTextCommand("QQUIT")
		if typeResult does not start with "OK:" then return typeResult
		
		set enterClicked to my clickNamedButton("A", "Enter")
		if enterClicked is false then
			set enterResult to my pressKeyCode(36, 1.2, "ENTER")
			if enterResult does not start with "OK:" then return enterResult
		else
			delay 1.2
		end if
		
		return "OK: force quit changed xedit"
	on error errMsg
		return "ERROR: " & errMsg
	end try
end forceQuitChangedXedit

on verifyCommandEffect(theText, beforeScreen)
	delay 1.0
	
	set afterScreen to my captureViaRawProbe()
	if my isBadScreenProbe(afterScreen) then return "ERROR: command result could not be confirmed for " & theText
	
	if (length of theText) ≥ 6 and (text 1 thru 6 of theText) is "XEDIT " then
		set requestedTarget to my extractRequestedXeditTarget(theText)
		set resultingTarget to my extractXeditHeaderTarget(afterScreen)
		
		if requestedTarget is not "" and resultingTarget is not "" then
			set requestedTargetNormalized to my normalizeXeditTarget(requestedTarget)
			set resultingTargetNormalized to my normalizeXeditTarget(resultingTarget)
			
			if requestedTargetNormalized is not resultingTargetNormalized then
				return "ERROR: command drifted; requested " & requestedTarget & " but screen shows " & resultingTarget
			end if
		end if
		
		set beforeTarget to my extractXeditHeaderTarget(beforeScreen)
		if requestedTarget is not "" and beforeTarget is not "" then
			if my normalizeXeditTarget(requestedTarget) is my normalizeXeditTarget(beforeTarget) then
				return "OK: command " & theText
			end if
		end if
		
		if requestedTarget is not "" and resultingTarget is not "" then
			if my normalizeXeditTarget(requestedTarget) is my normalizeXeditTarget(resultingTarget) then
				return "OK: command " & theText
			end if
		end if
	end if
	
	return "OK: command " & theText
end verifyCommandEffect

on extractRequestedXeditTarget(theText)
	try
		set parts to words of theText
		if (count of parts) ≥ 4 then
			return (item 2 of parts) & " " & (item 3 of parts) & " " & (item 4 of parts)
		end if
	on error
	end try
	return ""
end extractRequestedXeditTarget

on extractXeditHeaderTarget(screenText)
	try
		set normalizedText to do shell script "printf %s " & quoted form of screenText & " | tr '\\r' '\\n'"
		set firstLine to paragraph 1 of normalizedText
		set headerWords to words of firstLine
		if (count of headerWords) ≥ 3 then
			return (item 1 of headerWords) & " " & (item 2 of headerWords) & " " & (item 3 of headerWords)
		end if
	on error
	end try
	return ""
end extractXeditHeaderTarget

on normalizeXeditTarget(targetText)
	try
		set parts to words of targetText
		if (count of parts) is 3 then
			set fileName to item 1 of parts
			set fileType to item 2 of parts
			set fileMode to item 3 of parts
			if fileMode is "A1" then set fileMode to "A"
			return fileName & " " & fileType & " " & fileMode
		end if
	on error
	end try
	return targetText
end normalizeXeditTarget

on captureViaRawProbe()
	set processName to my getHODProcessName()
	do shell script "printf '' | pbcopy"
	tell application "System Events"
		set frontmost of process processName to true
	end tell
	delay 0.2
	return do shell script "osascript -e 'tell application \"System Events\" to keystroke \"c\" using control down' && sleep 1 && pbpaste"
end captureViaRawProbe

on isBadScreenProbe(screenText)
	if screenText is "" then return true
	if my looksLikeFooterOnlyCapture(screenText) then return true
	if screenText contains "Ready;" or screenText contains "VM READ" then return false
	if screenText contains "====>" then
		set xeditHeaderTarget to my extractXeditHeaderTarget(screenText)
		if xeditHeaderTarget is not "" then return false
		if screenText contains "XEDIT" then return false
	end if
	return true
end isBadScreenProbe

on looksLikeFooterOnlyCapture(screenText)
	if screenText does not contain "1=Hlp 2=Add 3=Quit" then return false
	if screenText contains "====>" then return false
	if screenText contains "Ready;" then return false
	if my extractXeditHeaderTarget(screenText) is not "" then return false
	return true
end looksLikeFooterOnlyCapture

on readFileInXedit(fileName, fileType, fileMode)
	set openResult to my sendCommand("XEDIT " & fileName & " " & fileType & " " & fileMode)
	if openResult does not start with "OK:" then return openResult
	
	delay 1.0
	set firstCapture to my captureScreenText()
	
	return firstCapture
end readFileInXedit

on writeFileLineInXedit(fileName, fileType, fileMode, lineText)
	set openResult to my sendCommand("XEDIT " & fileName & " " & fileType & " " & fileMode)
	if openResult does not start with "OK:" then return openResult
	
	delay 1.0
	
	tell application "System Events"
		key code 48
	end tell
	delay 0.2
	
	set typeResult to my typeTextCommand("I")
	if typeResult does not start with "OK:" then return typeResult
	
	set enterResult to my pressKeyCode(36, 0.8, "ENTER")
	if enterResult does not start with "OK:" then return enterResult
	
	delay 0.5
	
	set bodyTypeResult to my typeTextCommand(lineText)
	if bodyTypeResult does not start with "OK:" then return bodyTypeResult
	
	set bodyEnterResult to my pressKeyCode(36, 0.8, "ENTER")
	if bodyEnterResult does not start with "OK:" then return bodyEnterResult
	
	delay 0.5
	
	set fileResult to my sendCommand("FILE")
	if fileResult does not start with "OK:" then return fileResult
	
	return "OK: wrote line to " & fileName & " " & fileType & " " & fileMode
end writeFileLineInXedit

on sendLineCommand(theText)
	set activateResult to my activateSession("A")
	if activateResult does not start with "OK:" then return activateResult
	
	tell application "System Events"
		key code 48
	end tell
	delay 0.2
	
	set typeResult to my typeTextCommand(theText)
	if typeResult does not start with "OK:" then return typeResult
	
	return "OK: line-cmd " & theText
end sendLineCommand

on copyScreenViaMenu()
	try
		set processName to my getHODProcessName()
		
		tell application processName to activate
		delay 0.3
		
		tell application "System Events"
			set frontmost of process processName to true
		end tell
		delay 0.4
		
		tell application "System Events"
			tell process processName
				click menu item "Copy Screen" of menu "Edit" of menu bar 1
			end tell
		end tell
		delay 1.0
		return "OK: copy screen"
	on error errMsg
		return "ERROR: " & errMsg
	end try
end copyScreenViaMenu

on readStaticTextsFromWindow(targetWindow)
	try
		set textLines to {}
		tell application "System Events"
			set staticTextCount to count of static texts of targetWindow
			repeat with i from 1 to staticTextCount
				try
					set rawValue to value of static text i of targetWindow
					if rawValue is not missing value then
						set lineValue to rawValue as string
						if lineValue is not "" then set end of textLines to lineValue
					end if
				end try
			end repeat
		end tell
		return textLines
	on error
		return {}
	end try
end readStaticTextsFromWindow

on joinLines(theLines)
	set joinedText to ""
	repeat with oneLine in theLines
		set joinedText to joinedText & (oneLine as string) & return
	end repeat
	return joinedText
end joinLines

on isUsefulCapture(screenText)
	if screenText is "" then return false
	
	set normalizedText to do shell script "printf %s " & quoted form of screenText & " | tr '\\r' '\\n' | perl -0pe 's/[ \\t]+/ /g; s/\\n+/\\n/g'"
	
	if normalizedText contains "1=Hlp 2=Add 3=Quit 4=Tab 5=SChg 6=? 7=Bkwd 8=Fwd 9=Rpt 10=R/L 11=Sp/Jn 12=Cursr" then return false
	if normalizedText contains "1=Hlp 2=Add 3=Quit" then return false
	if normalizedText contains "4=Tab 5=SChg" then return false
	if normalizedText contains "11=Sp/Jn 12=Cursr" then return false
	if normalizedText contains "RUNNING GDLVM7" then return false
	if normalizedText contains "HOLDING GDLVM7" then return false
	if normalizedText contains "MORE... GDLVM7" then return false
	if normalizedText contains "GDLVM7 - A" then return false
	if normalizedText contains "GDLVM7 - Ad" then return false
	if normalizedText contains "Scratch Pad" then return false
	if normalizedText contains "Characters:" then return false
	
	return true
end isUsefulCapture

on captureScreenText()
	try
		set processName to my getHODProcessName()
		
		tell application "System Events"
			set frontmost of process processName to true
		end tell
		delay 0.2
		
		tell application "System Events"
			keystroke "c" using control down
		end tell
		delay 1.0
		
		set ctrlCopyText to do shell script "pbpaste"
		if ctrlCopyText is not "" then return ctrlCopyText
		
		tell application "System Events"
			keystroke "a" using control down
		end tell
		delay 0.3
		
		tell application "System Events"
			keystroke "c" using control down
		end tell
		delay 1.0
		
		set ctrlSelectCopyText to do shell script "pbpaste"
		if ctrlSelectCopyText is not "" then return ctrlSelectCopyText
		
		try
			my copyScreenViaMenu()
			delay 1.0
			set menuCopyText to do shell script "pbpaste"
			if menuCopyText is not "" then return menuCopyText
		end try
		
		return "ERROR: capture produced empty clipboard"
	on error errMsg
		return "ERROR: " & errMsg
	end try
end captureScreenText

on normalizeCaptureText(screenText)
	if screenText is "" then return ""
	return do shell script "printf %s " & quoted form of screenText & " | tr '\\r' '\\n' | perl -0pe 's/[ \\t]+/ /g; s/^ +//mg; s/ +$//mg; s/\\n+/\\n/g'"
end normalizeCaptureText

on isKnownBadCapture(screenText)
	if screenText is "" then return true
	if screenText contains "1=Hlp 2=Add 3=Quit" then return true
	if screenText contains "4=Tab 5=SChg" then return true
	if screenText contains "11=Sp/Jn 12=Cursr" then return true
	if screenText contains "RUNNING GDLVM7" then return true
	if screenText contains "HOLDING GDLVM7" then return true
	if screenText contains "MORE... GDLVM7" then return true
	if screenText contains "GDLVM7 - A" then return true
	if screenText contains "Scratch Pad" then return true
	if screenText contains "Characters:" then return true
	return false
end isKnownBadCapture

on clickTerminalBody(sessionLetter)
	try
		tell application "System Events"
			set targetWindow to my findSessionWindow(sessionLetter)
			set winPosition to position of targetWindow
			tell targetWindow
				set terminalArea to first scroll area
				set areaPosition to position of terminalArea
				set areaSize to size of terminalArea
			end tell
		end tell
		
		set windowX to item 1 of winPosition
		set windowY to item 2 of winPosition
		set areaX to item 1 of areaPosition
		set areaY to item 2 of areaPosition
		set areaWidth to item 1 of areaSize
		set areaHeight to item 2 of areaSize
		
		set centerX to windowX + areaX + (areaWidth div 2)
		set upperBodyY to windowY + areaY + 40
		set centerBodyY to windowY + areaY + (areaHeight div 2)
		set lowerBodyY to windowY + areaY + areaHeight - 40
		
		my clickAtPoint(centerX, upperBodyY)
		delay 0.15
		my clickAtPoint(centerX, centerBodyY)
		delay 0.15
		my clickAtPoint(centerX, lowerBodyY)
		delay 0.15
		
		return true
	on error
		return false
	end try
end clickTerminalBody

on clickAtPoint(clickX, clickY)
	do shell script "/usr/bin/python3 - <<'PY'\nfrom Quartz.CoreGraphics import CGEventCreateMouseEvent, CGEventPost, kCGHIDEventTap, kCGEventMouseMoved, kCGEventLeftMouseDown, kCGEventLeftMouseUp\nx = " & clickX & "\ny = " & clickY & "\nfor event_type in (kCGEventMouseMoved, kCGEventLeftMouseDown, kCGEventLeftMouseUp):\n    event = CGEventCreateMouseEvent(None, event_type, (x, y), 0)\n    CGEventPost(kCGHIDEventTap, event)\nPY"
end clickAtPoint

on clickNamedButton(sessionLetter, buttonName)
	try
		tell application "System Events"
			set targetWindow to my findSessionWindow(sessionLetter)
			tell targetWindow
				click first button whose name is buttonName
			end tell
		end tell
		delay 0.2
		return true
	on error
		return false
	end try
end clickNamedButton

-- Made with Bob
