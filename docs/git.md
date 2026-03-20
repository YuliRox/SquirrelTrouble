# Git Usage — second_engineer

## Commit message format

Use conventional commits:

```
type: short imperative summary (≤72 chars)

- bullet list of meaningful details
- one line per logical change

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Valid types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`.

Write the commit message to a temp file, then commit with `-F`:

```bash
printf 'type: short summary\n\n- bullet detail\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>\n' > /tmp/commit_msg.txt
git commit -F /tmp/commit_msg.txt
```

## What to stage

Stage only files directly related to the change. Always review `git status` before staging and explicitly name each file or directory — do not use `git add -A` or `git add .`.

**Never stage without checking first:**
- `mod-list.json` — records which mods are enabled in the local Factorio install; not part of mod source
- `mod-settings.dat` — binary; local Factorio settings
- `.env`, credentials, or any secrets

## Working directory

The shell is always at the repository root (`C:/Code/FactorioMod`). Run git commands directly — never prefix them with `cd /c/Code/FactorioMod &&` or any other `cd`.

## Auto-commit after substantial changes

Commit automatically after each substantial change without waiting for the user to ask. A change is substantial if it:

- Creates or deletes a file
- Completes a self-contained piece of work (new feature, refactor, fix, docs update)

Do not commit after every tiny edit. Batch related edits (e.g. file + its locale entry + CLAUDE.md update) into one commit. When in doubt, commit.

## What not to do

- Never use `--no-verify` (bypass hooks)
- Never force-push to `main`
- Never amend a published commit — create a new one instead
- Never use `git add -A` or `git add .`
- Never combine git commands with `cd`
