# IBM Host On-Demand Automation System

A CLI-first automation toolkit for IBM Host On-Demand on macOS.

This project automates HOD sessions with AppleScript and macOS accessibility APIs, with a focus on reliable session recovery, safe command entry, XEDIT editing, and screen capture that can be verified from terminal output.

## What Works

The current user-facing workflow is centered on [`./hod`](hod), which wraps [`cli/hod.applescript`](cli/hod.applescript).

Implemented and verified capabilities include:

- Session activation by letter
- Reliable screen capture through the CLI
- Safe CMS command entry
- XEDIT file open and single-line write workflows
- Behavior-based recovery back to `Ready;`
- Honest verification of command results
- Terminal-driven operation with capture between steps

## Primary Interface

Use the [`./hod`](hod) command from the repository root.

Examples:

```bash
./hod activate A
./hod capture
./hod attn
./hod command "XEDIT PROFILE EXEC A"
./hod write-file-line "SILLY" "JOKE" "A1" "I ASKED AI FOR A PUN, AND IT SAID IT WAS STILL TRAINING ITS THOUGHT PROCESSOR."
```

## Key Commands

- [`./hod activate A`](hod) — bring session `A` to the foreground
- [`./hod capture`](hod) — copy and print the current HOD screen text
- [`./hod attn`](hod) — recover cleanly to a stable prompt
- [`./hod clear`](hod) — clear the active command area
- [`./hod pf 3`](hod) / [`./hod pf 8`](hod) — press PF keys
- [`./hod command "..."`](hod) — send a CMS/XEDIT command safely
- [`./hod write-file-line FILE TYPE MODE "TEXT"`](hod) — open a file, insert one line, and file it

## Reliability Improvements in This Version

The automation was hardened around the issues that matter in live HOD usage:

- Recovery now verifies behavior, not just keypress success
- XEDIT exit handles changed-file cases correctly
- Command entry no longer relies on fragile multi-Tab placement
- Capture distinguishes valid XEDIT screens from footer-only failures
- Verification checks actual resulting screens instead of assuming success

Most of that logic lives in [`cli/hod.applescript`](cli/hod.applescript).

## Repository Layout

```text
bobathon/
├── hod                      # Main CLI entrypoint
├── cli/
│   └── hod.applescript      # HOD command implementation
├── src/                     # Lower-level modules and experiments
├── docs/
│   ├── QUICKSTART.md
│   ├── API_REFERENCE.md
│   ├── TROUBLESHOOTING.md
│   └── WORKFLOW_GUIDE.md
├── tests/
├── workflows/
└── logs/
```

## Requirements

- macOS
- IBM Host On-Demand installed and configured
- Accessibility permissions for the controlling terminal/app
- A running HOD session such as `GDLVM7 - A`

## Verification Style

The safest way to use this project is the same way it was debugged:

1. run one CLI action
2. capture output immediately
3. inspect the real screen text
4. continue only from confirmed state

That approach is documented in [`docs/QUICKSTART.md`](docs/QUICKSTART.md).

## Related Documentation

- [`docs/QUICKSTART.md`](docs/QUICKSTART.md)
- [`docs/API_REFERENCE.md`](docs/API_REFERENCE.md)
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)
- [`docs/WORKFLOW_GUIDE.md`](docs/WORKFLOW_GUIDE.md)
- [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md)