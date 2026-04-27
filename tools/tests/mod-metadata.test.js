const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

test("mod metadata keeps Robot Tree Farm as an optional dependency", () => {
  const infoPath = path.join(process.cwd(), "squirrel_madness", "info.json");
  const info = JSON.parse(fs.readFileSync(infoPath, "utf8"));

  assert.ok(Array.isArray(info.dependencies));
  assert.ok(info.dependencies.includes("? robot_tree_farm_update"));
});
