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

Session transcripts live under `~/.claude/projects/<project-dir>/<session-id>.jsonl`. File mtime only shows the last write, so a session that started on the report date and continued later has a later mtime. Select by message timestamps instead. Timestamps are UTC, so convert the local day to a UTC window first (for example, PDT `2026-10-07` is `2026-10-07T07:00` to `2026-10-08T07:00`).

```
find ~/.claude/projects -name "*.jsonl" ! -path "*/subagents/*" -newermt "<date> 00:00:00" | while read f; do
  jq -r 'select(.timestamp) | .timestamp' "$f" | awk -v a="<utc-start>" -v b="<utc-end>" -v f="$f" '$0>=a && $0<b {print f; exit}'
done
```

Paths containing `/subagents/` are agent transcripts, not chats, so they are excluded.

Done when you have the list of main session files with at least one message on the report date.

## 2. Summarize in parallel

Fan out Explore agents, ~3 session files each, all launched in one message. Each agent must extract conversations with jq rather than reading files whole:

```
jq -r 'select(.type=="user" and (.message.content|type=="string")) | .message.content' FILE
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' FILE
```

(User content may also be an array of blocks; skip tool_result noise and system-reminder blocks. Transcript `timestamp` fields are UTC; convert to local when reporting times.)

Per session, each agent returns: project directory, approximate local time range, then 1-3 bullets on the outcomes - what changed, what was decided, what is blocked. Skip implementation detail. For a session that continued past the report date, focus on the report date's portion.

Done when every session in the list has a summary back.

## 3. Write the note

Compile the summaries into the note. Keep it high level: a reader must get the full day in 30 seconds.

Structure:

- Title: `# Daily Report - YYYY-MM-DD`, then a one-line overview (session count, main theme).
- One `##` section per project, with 1-4 bullets. Merge sessions on the same thread into one bullet.
- No sub-bullets. If a detail does not fit in one bullet, leave it out.
- End with `## Next` - open threads and next steps, one bullet each.

Language - write in ASD-STE100 Simplified Technical English:

- Each bullet is one sentence of 10-15 words maximum.
- One topic per sentence.
- Use active voice and simple tense: past for work done, present for state.
- Use simple, common words with one meaning. Use `start`, not `kick off`; `fix`, not `address`.
- Do not use phrasal verbs, idioms, or filler adjectives.
- Write technical names (files, tools, PRs) exactly as they are.
- Lead with the result: `- The demo harness is complete and all 38 checks pass.`
- Plain dash everywhere, never the em dash.

Done when the note is saved and every session from step 1 appears in it. Tell the user the note path and give a 2-3 sentence recap.
