# SquirrelTrouble

Factorio 2.0 mod workspace for `squirrel_madness`.

## VS Code Launch Note

If you want to use the `factoriomod-debug` VS Code debugger, start VS Code from **Windows**, not from WSL.

Why:
- the debugger launches the Windows `factorio.exe`
- running the extension from WSL causes recurring Windows-vs-WSL path translation problems for `config.ini`, `modsPath`, and related debug arguments

Recommended:
- open `C:\Code\SquirrelTrouble` in normal Windows VS Code for in-game debugging
- use WSL terminals for scripting, repository work, and `npm test`

## Verification

Run the integration suite with:

```bash
npm test
```
