const fs = require("fs");
const path = require("path");

const target = path.join(__dirname, "..", "node_modules", "factorio-test-cli", "process-utils.js");

if (!fs.existsSync(target)) {
  process.exit(0);
}

const desired = `import { spawn } from "child_process";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { CliError } from "./cli-error.js";
let verbose = false;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
export function setVerbose(v) {
    verbose = v;
}
export function runScript(...command) {
    if (command[0] === "fmtk") {
        const localFmtk = path.resolve(__dirname, "..", "factoriomod-debug", "dist", "fmtk-cli.js");
        if (fs.existsSync(localFmtk)) {
            return runProcess(verbose, "node", localFmtk, ...command.slice(1));
        }
    }
    if (process.platform === "win32") {
        return runProcess(verbose, "cmd.exe", "/d", "/s", "/c", "npx", ...command);
    }
    return runProcess(verbose, "npx", ...command);
}
export function runProcess(inheritStdio, command, ...args) {
    if (verbose)
        console.log("Running:", command, ...args);
    const proc = spawn(command, args, {
        stdio: inheritStdio ? "inherit" : "ignore",
    });
    return new Promise((resolve, reject) => {
        proc.on("error", reject);
        proc.on("exit", (code) => {
            if (code === 0) {
                resolve();
            }
            else {
                reject(new CliError(\`Command exited with code \${code}: \${command} \${args.join(" ")}\`));
            }
        });
    });
}
`;

const current = fs.readFileSync(target, "utf8");
if (current !== desired) {
  fs.writeFileSync(target, desired);
  console.log("Patched factorio-test-cli for Windows WSL execution.");
}
