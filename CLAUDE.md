# Token-Saving & Autonomy Rules

## Communication Style
- **Extremely Concise**: No greetings, no summaries, no conversational filler, no polite preamble/postscript.
- **No Unsolicited Explanations**: Execute commands directly. Do not explain code edits or reasoning in the console unless explicitly asked or when a build error halts execution.
- **Log File Only**: Keep terminal output strictly minimal. Write detailed progress, reasoning, decision logs, and error analyses into `BRANDING-LOG.md` instead of printing to the terminal.

## Build & Command Execution
- **Redirect Verbose Output**: Always redirect heavy build/compiler outputs to temporary log files (e.g., `> build.log 2>&1`) instead of dumping raw build output into the console.
- **Error Reading Limit**: On build failure, inspect only the last 50-100 lines of `build.log` to identify the cause. Do not dump or read full log files into context.
- **Non-Interactive Execution**: Resolve ambiguous choices using the safest fallback, log the decision to `BRANDING-LOG.md`, and proceed without stopping for input.
- **Strict Scope**: Do not scan, grep, or edit files outside the rebranding scope (avoid touching `src/csync/`, `src/common/`, SSL/crypto files).