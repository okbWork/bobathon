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
		set processName to my getHODProcessName()
		do shell script "printf '' | pbcopy"
		tell application "System Events"
			set frontmost of process processName to true
		end tell
		delay 0.2
		return do shell script "osascript -e 'tell application \"System Events\" to keystroke \"c\" using control down' && sleep 1 && pbpaste"
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
		tell application "System Events"
			key code 51 using command down
		end tell
		delay 0.8
		return "OK: pressed CLEAR"
	on error errMsg
		return "ERROR: " & errMsg
	end try
end pressClear

on pressAttn()
	try
		tell application "System Events"
			keystroke "c" using control down
		end tell
		delay 1.0
		
		tell application "System Events"
			key code 99
		end tell
		delay 1.0
		
		tell application "System Events"
			key code 36
		end tell
		delay 1.0
		
		return "OK: pressed ATTN"
	on error errMsg
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
		else
			error "PF key must be 1-12"
		end if
		
		tell application "System Events"
			key code keyCodeValue
		end tell
		delay 1.0
		return "OK: pressed PF" & keyNumber
	on error errMsg
		return "ERROR: " & errMsg
	end try
end pressPF

on sendCommand(theText)
	set activateResult to my activateSession("A")
	if activateResult does not start with "OK:" then return activateResult
	
	try
		tell application "System Events"
			key code 53
		end tell
		delay 0.2
	end try
	
	try
		tell application "System Events"
			key code 51 using command down
		end tell
		delay 0.3
	end try
	
	repeat 2 times
		tell application "System Events"
			key code 48
		end tell
		delay 0.2
	end repeat
	
	try
		tell application "System Events"
			key code 51 using command down
		end tell
		delay 0.3
	end try
	
	set typeResult to my typeTextCommand(theText)
	if typeResult does not start with "OK:" then return typeResult
	
	set enterResult to my pressKeyCode(36, 1.2, "ENTER")
	if enterResult does not start with "OK:" then return enterResult
	
	return "OK: command " & theText
end sendCommand

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
			set winSize to size of targetWindow
		end tell
		
		set baseX to item 1 of winPosition
		set baseY to item 2 of winPosition
		
		my clickAtPoint(baseX + 90, baseY + 145)
		delay 0.1
		my clickAtPoint(baseX + 140, baseY + 180)
		delay 0.1
		my clickAtPoint(baseX + 220, baseY + 220)
		delay 0.1
		
		return true
	on error
		return false
	end try
end clickTerminalBody

on clickAtPoint(clickX, clickY)
	do shell script "/usr/bin/python3 - <<'PY'\nfrom Quartz.CoreGraphics import CGEventCreateMouseEvent, CGEventPost, kCGHIDEventTap, kCGEventMouseMoved, kCGEventLeftMouseDown, kCGEventLeftMouseUp\nx = " & clickX & "\ny = " & clickY & "\nfor event_type in (kCGEventMouseMoved, kCGEventLeftMouseDown, kCGEventLeftMouseUp):\n    event = CGEventCreateMouseEvent(None, event_type, (x, y), 0)\n    CGEventPost(kCGHIDEventTap, event)\nPY"
end clickAtPoint

-- Made with Bob
