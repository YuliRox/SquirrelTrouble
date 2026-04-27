# SquirrelTrouble

Factorio 2.0 mod workspace for `squirrel_madness`.

## Getting Started

This repo uses a split workflow:

- do coding, scripting, and test runs from **WSL**
- do in-game debugging from **Windows VS Code**

That split is intentional. The test wrapper is built to run well from WSL, while the `factoriomod-debug` VS Code extension needs to launch the Windows `factorio.exe`.

### Prerequisites

Install these first:

- **WSL** with this repo checked out on the Windows filesystem, typically at `C:\Code\SquirrelTrouble` and visible in WSL as `/mnt/c/Code/SquirrelTrouble`
- **Node.js + npm** available in WSL
- **Factorio 2.0** installed on Windows
- **VS Code on Windows**
- the VS Code extension `justarandomgeek.factoriomod-debug`

The repo already includes:

- `.vscode/launch.json` with Factorio debug launch entries
- `.vscode/settings.json` with Factorio version entries
- `scripts/test-factorio.sh` for WSL-friendly Factorio test runs
- `scripts/factorio-debug-wrapper.sh` for Windows `factorio.exe` launch compatibility

### Contributor Workflow

- Use WSL terminals for `git`, editing support tools, `npm install`, and `npm test`.
- Use Windows VS Code for live in-game debugging.
- If you open VS Code from WSL, the debugger path handling will break on Windows-vs-WSL path translation for `config.ini`, `modsPath`, and related debug arguments.

### Install Dependencies

From WSL in the repo root:

```bash
npm install
```

This installs the local Node dependencies and runs the repo's `postinstall` patch for `factorio-test-cli`.

### Configure Factorio Test Runs In WSL

Create a local `.env.local` in the repo root with your Factorio path.

Typical WSL setup:

```bash
FACTORIO_PATH="/mnt/c/Program Files/Factorio/bin/x64/factorio.exe"
```

If your Windows install lives somewhere else, point `FACTORIO_PATH` at that `factorio.exe`.

Notes:

- `npm test` calls `scripts/test-factorio.sh`
- when `FACTORIO_PATH` points to a Windows `.exe` from WSL, the wrapper switches to Windows path semantics automatically
- the Factorio test scratch directory is `../.factorio-test`

Run the full suite with:

```bash
npm test
```

Useful variants:

```bash
npm run test:watch
npm run test:gui
```

### Get The Factorio Tests Running

1. Install Windows Factorio.
2. Install WSL Node.js dependencies with `npm install`.
3. Set `FACTORIO_PATH` in `.env.local`.
4. Run `npm test` from WSL.

If tests fail because the Factorio path is wrong, fix `FACTORIO_PATH` first. The test wrapper already handles the WSL-to-Windows launch path once the executable path is correct.

### Get The Factorio Debugger Running

1. Start **Windows VS Code**, not WSL VS Code.
2. Open the repo at `C:\Code\SquirrelTrouble`.
3. Install the recommended extension `justarandomgeek.factoriomod-debug` if VS Code has not already done so.
4. Check `.vscode/settings.json` and update the hardcoded paths if your local install differs:
   - `factorioPath`
   - `configPath`
   - optional `docsPath` and `protosPath`
5. Use one of the checked-in launch configs from `.vscode/launch.json`:
   - `Factorio Mod Debug`
   - `Factorio Mod Debug (Settings & Data)`
   - `Factorio Mod Debug (Profile)`

Important:

- the debugger should be launched from Windows VS Code because it starts the Windows `factorio.exe`
- this repo already points the WSL-wrapper entry at `scripts/factorio-debug-wrapper.sh`, but the normal contributor path is still to launch VS Code from Windows
- if your repo is not at `C:\Code\SquirrelTrouble`, update `.vscode/settings.json` accordingly

### Repository Paths

Most repo documentation assumes this layout:

- Windows repo path: `C:\Code\SquirrelTrouble`
- WSL repo path: `/mnt/c/Code/SquirrelTrouble`

## Verification

Run the integration suite with:

```bash
npm test
```
