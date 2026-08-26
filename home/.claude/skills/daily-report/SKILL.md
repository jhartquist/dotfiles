---
name: daily-report
description: Summarize yesterday's Claude Code sessions into an Obsidian daily report note
disable-model-invocation: true
---

# Daily report

Summarize all Claude Code sessions from a given day into one note in the Obsidian vault.

**Report date**: the argument if one was given (any parseable date), otherwise yesterday (local time).
**Note path**: `~/Documents/Notes/5 Foam/Daily Reviews/YYYY-MM-DD.md` (the report date).

If a note already exists at that path, stop and ask before overwriting.

## 1. Find the day's sessions

Session transcripts live under `~/.claude/projects/<project-dir>/<session-id>.jsonl`. File mtimes are local time.

```
find ~/.claude/projects -name "*.jsonl" -newermt "<date> 00:00:00" ! -newermt "<date+1> 00:00:00"
```

From the results:

- Keep only main session files (`<project-dir>/<uuid>.jsonl`). Paths containing `/subagents/` are agent transcripts, not chats.
- A `/subagents/` hit whose parent session file (`<uuid>.jsonl` beside the `<uuid>/` directory) fell outside the window means that session was active on the report date but continued later - include the parent.

Done when you have the deduplicated list of main session files and their project directories.

## 2. Summarize in parallel

Fan out Explore agents, ~3 session files each, all launched in one message. Each agent must extract conversations with jq rather than reading files whole:

```
jq -r 'select(.type=="user" and (.message.content|type=="string")) | .message.content' FILE
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' FILE
```

(User content may also be an array of blocks; skip tool_result noise and system-reminder blocks. Transcript `timestamp` fields are UTC; convert to local when reporting times.)

Per session, each agent returns: project directory, approximate local time range, then 2-5 terse bullets covering what was asked, what was done, and the outcome - each bullet one line, leading with the concrete result. For a session that continued past the report date, focus on the report date's portion.

Done when every session in the list has a summary back.

## 3. Write the note

Compile the summaries into the note. Format for skimming aloud in a daily standup - bullets, minimal words, no paragraphs:

- Title: `# Daily Report - YYYY-MM-DD`, then a one-line overview (session count, dominant theme).
- One `##` section per project. Under it, one bullet per piece of work (merge sessions covering the same thread), leading with the result: `- Built demo harness - 38 checks green (committed)`.
- Every bullet at most ~10 words - a phrase, not a sentence. If it needs more, split the detail into a sub-bullet.
- Nest sub-bullets freely to delineate details: findings, blockers, decisions, notable fixes. Top-level bullet stays the skimmable result; details live one level down.
- End with `## Next` - open threads and parked next steps pulled from the sessions, one bullet each.
- Plain dash everywhere, never the em dash.

Done when the note is saved and every session from step 1 appears in it. Tell the user the note path and give a 2-3 sentence recap.
