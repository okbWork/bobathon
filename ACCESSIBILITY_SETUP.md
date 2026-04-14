# Accessibility Setup for IBM Host On-Demand Automation

## Current Status
✅ Window Detection: **WORKING** - Successfully found "GDLVM7 - A" window
❌ Mouse Control: **BLOCKED** - Need accessibility permissions

## Required Permissions

You need to grant accessibility permissions to **TWO** applications:

### 1. Terminal/osascript (Already Done ✓)
- You've already enabled "IBM Bob" in System Settings
- This allows the scripts to run

### 2. WSCachedLoader (REQUIRED - Not Done Yet)
- This is the actual IBM Host On-Demand process
- Without this, we cannot control the mouse or keyboard in HOD windows

## How to Add WSCachedLoader to Accessibility

### Step 1: Open System Settings
1. Click Apple menu → System Settings
2. Go to Privacy & Security → Accessibility

### Step 2: Add WSCachedLoader
Since WSCachedLoader is a Java application, you need to add it manually:

**Option A: Add the Java Process**
1. Click the "+" button at the bottom of the accessibility list
2. Press `Cmd+Shift+G` to open "Go to folder"
3. Enter one of these paths:
   - `/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java`
   - `/Library/Java/JavaVirtualMachines/*/Contents/Home/bin/java`
4. Click "Open"
5. Enable the toggle for Java

**Option B: Add IBM Host On-Demand Application**
1. Click the "+" button
2. Navigate to Applications
3. Find "IBM Host On-Demand" (or wherever HOD is installed)
4. Select it and click "Open"
5. Enable the toggle

### Step 3: Verify
After adding the permission:
1. **Restart IBM Host On-Demand** (important!)
2. Run the test again:
   ```bash
   osascript tests/simple_test.applescript
   ```

## Alternative: Use cliclick (Recommended)

Instead of relying on AppleScript's mouse control, install `cliclick`:

```bash
brew install cliclick
```

This tool provides more reliable mouse control and doesn't require as many permissions.

## Troubleshooting

### If you still get "Connection is invalid" error:
1. Make sure you **restarted** IBM Host On-Demand after adding permissions
2. Try logging out and back in to macOS
3. Check that both "IBM Bob" AND "WSCachedLoader/Java" are enabled in Accessibility

### If you can't find WSCachedLoader:
1. Open Terminal
2. Run: `ps aux | grep -i wscached`
3. This will show the full path to the WSCachedLoader process
4. Use that path when adding to Accessibility

## Current Test Results

```
✓ Window Detection: Working
✓ Process Name: WSCachedLoader
✓ Window Title: GDLVM7 - A
✗ Mouse Control: Blocked (needs accessibility permission)
```

## Next Steps

1. Add WSCachedLoader/Java to Accessibility permissions
2. Restart IBM Host On-Demand
3. Run test again: `osascript tests/simple_test.applescript`
4. If still failing, install cliclick: `brew install cliclick`