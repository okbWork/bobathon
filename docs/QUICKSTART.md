# Quick Start

This guide covers the current, reliable way to use this project: the CLI wrapper [`./hod`](../hod).

## Requirements

- macOS
- IBM Host On-Demand installed
- Accessibility permissions enabled for the terminal or editor running the commands
- An active HOD session, typically titled like `GDLVM7 - A`

## Core Principle

Use the tool step-by-step.

Do not chain a large number of blind actions together. The intended workflow is:

1. run one command
2. capture the screen
3. inspect the result
4. continue from confirmed state

That is the operating model the automation was hardened around.

## Main Commands

From the repository root:

```bash
./hod activate A
./hod capture
./hod attn
./hod clear
./hod pf 3
./hod pf 8
./hod command "XEDIT PROFILE EXEC A"
./hod write-file-line "SILLY" "JOKE" "A1" "I ASKED AI FOR A PUN, AND IT SAID IT WAS STILL TRAINING ITS THOUGHT PROCESSOR."
```

## Minimal Session Check

Bring session `A` forward and capture the current screen:

```bash
./hod activate A
./hod capture
```

If the session is healthy, capture should return readable HOD screen text rather than only the footer line.

## Recovery to a Stable Prompt

If XEDIT or another screen is in the way, recover first:

```bash
./hod attn
./hod capture
```

Expected result: a stable prompt such as `Ready;`.

The recovery flow is behavior-based. It does not just press keys and assume success.

## Open a File in XEDIT

```bash
./hod command "XEDIT PROFILE EXEC A"
./hod capture
```

You should see the XEDIT header and file contents in the capture output.

## Create or Update a File With One Line

```bash
./hod write-file-line "SILLY" "JOKE" "A1" "I ASKED AI FOR A PUN, AND IT SAID IT WAS STILL TRAINING ITS THOUGHT PROCESSOR."
./hod capture
```

Expected result after the write: the session returns to `Ready;`.

To verify the saved contents:

```bash
./hod command "XEDIT SILLY JOKE A"
./hod capture
```

## Recommended Verification Pattern

For file operations, use this sequence:

```bash
./hod attn
./hod capture
./hod write-file-line "FILE" "TYPE" "A1" "YOUR TEXT HERE"
./hod capture
./hod command "XEDIT FILE TYPE A"
./hod capture
```

This pattern confirms:

- recovery worked
- the write completed
- the saved file opens correctly
- the visible contents match expectation

## Useful PF Keys

Examples:

```bash
./hod pf 3
./hod pf 8
```

- [`PF3`](../hod) is commonly used to quit or back out
- [`PF8`](../hod) is commonly used to page forward

The implementation now prefers real HOD toolbar buttons where available.

## Common Problems

### Capture only shows footer/help keys

Use [`./hod capture`](../hod) again from a stable state. The wrapper was tuned to avoid footer-only captures, but the safest pattern is still:

```bash
./hod attn
./hod capture
```

### A command opens the wrong place

Recover first, then issue the command again:

```bash
./hod attn
./hod capture
./hod command "XEDIT FILE TYPE A"
./hod capture
```

The current command path was simplified to avoid the older fragile multi-Tab placement logic.

### XEDIT refuses to quit because the file changed

This is handled in the recovery path. [`./hod attn`](../hod) now exits changed XEDIT screens by using the correct XEDIT quit behavior rather than pretending recovery succeeded.

## Files That Matter Most

- [`hod`](../hod) — main CLI entrypoint
- [`cli/hod.applescript`](../cli/hod.applescript) — command implementation
- [`README.md`](../README.md) — overview
- [`docs/TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) — debugging notes
- [`docs/API_REFERENCE.md`](./API_REFERENCE.md) — command details

## One Good End-to-End Example

```bash
./hod attn
./hod capture
./hod write-file-line "TELL" "PUNN" "A1" "AI TRIED STAND-UP, BUT EVERY JOKE NEEDED A LITTLE MORE HUMAN TRAINING DATA."
./hod capture
./hod command "XEDIT TELL PUNN A"
./hod capture
```

That sequence creates or updates the file, files the changes, and verifies the resulting XEDIT screen from terminal output.