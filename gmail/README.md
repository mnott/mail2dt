# Gmail Archive Labeler

Google Apps Script (`Code.gs`) that labels every archived Gmail message which
is not yet filed under any user label.

## Why this exists

Gmail has no archive folder. "Archiving" a mail in Gmail means *removing the
INBOX label* — nothing else. A mail that leaves the inbox that way carries no
label at all, and since Gmail exposes labels (not the archive) as IMAP
folders, an unfiled archived mail is **invisible to any IMAP client**: there
is no folder to look in.

That breaks the mail2dt pipeline, which pulls mail for archiving over IMAP
from a specific folder. This script is the Gmail-side half of the pipeline: it
sweeps the mailbox and applies the label `Archivieren` to every archived
message that has no user label yet, so those mails show up under one IMAP
folder the pipeline (or a mail client) can pick them up from.

## How it works

- Search query: `-in:inbox -in:sent -in:drafts -has:userlabels -label:_archived_processed -in:trash -in:spam -in:chats`
  — i.e. archived, not trash/spam/chat, and carrying no user label.
- Each processed message gains the visible label `Archivieren` plus the
  hidden marker label `_archived_processed`, which drops it out of the next
  run's result set — the script is idempotent and resumes where it stopped.
- `batchModify` is called in chunks of 50 (the API documents a 1000-id limit
  but fails with "Internal error" well below that), with retries and a
  per-message fallback so one poisoned id cannot stall a run.
- Each run stops after 4.5 minutes to stay under Apps Script's 6-minute
  execution cap; an hourly trigger walks the backlog.

## Install

1. Open [script.google.com](https://script.google.com), new project, paste
   `Code.gs`.
2. Run `installHourlyTrigger` once (authorizes Gmail + Triggers scopes).
   It clears its own duplicate triggers before installing.
3. Optional: run `countUnprocessed` to see the backlog size; run `labelArchived`
   manually for a first sweep.

The deployed instance lives in the mail account as project "Gmail Archive
Labeler"; this copy is the version-controlled source of truth.
