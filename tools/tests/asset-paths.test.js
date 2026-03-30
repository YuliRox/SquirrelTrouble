const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const rootDir = path.resolve(__dirname, '..', '..');
const modDir = path.join(rootDir, 'squirrel_madness');
const factorioTestDir = path.resolve(rootDir, '..', '.factorio-test');
const assetPathPattern = /__([A-Za-z0-9_-]+)__\/([A-Za-z0-9_./-]+)/g;
const sourceExtensions = new Set(['.lua', '.json']);
const assetExtensions = new Set([
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.ogg',
  '.wav',
  '.mp3'
]);

function walkFiles(dir, matches = []) {
  for (const entry of fs.readdirSync(dir, {withFileTypes: true})) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      walkFiles(fullPath, matches);
      continue;
    }

    if (sourceExtensions.has(path.extname(entry.name))) {
      matches.push(fullPath);
    }
  }

  return matches;
}

function parseEnvFile(envPath) {
  if (!fs.existsSync(envPath)) {
    return {};
  }

  const values = {};
  const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) {
      continue;
    }

    const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!match) {
      continue;
    }

    let value = match[2].trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    values[match[1]] = value;
  }

  return values;
}

function windowsPathToPosix(candidate) {
  if (typeof candidate !== 'string') {
    return null;
  }

  if (candidate.startsWith('/')) {
    return candidate;
  }

  const match = candidate.match(/^([A-Za-z]):\\(.*)$/);
  if (!match) {
    return candidate;
  }

  return path.posix.join(
    '/mnt',
    match[1].toLowerCase(),
    match[2].replace(/\\/g, '/')
  );
}

function findFactorioRoot() {
  const envValues = parseEnvFile(path.join(rootDir, '.env.local'));
  const localConfigPath = path.join(rootDir, '.factorio-test.local.json');
  const candidates = [];

  if (process.env.FACTORIO_PATH) {
    candidates.push(process.env.FACTORIO_PATH);
  }

  if (envValues.FACTORIO_PATH) {
    candidates.push(envValues.FACTORIO_PATH);
  }

  if (fs.existsSync(localConfigPath)) {
    const config = JSON.parse(fs.readFileSync(localConfigPath, 'utf8'));
    if (config.factorioPath) {
      candidates.push(config.factorioPath);
    }
  }

  candidates.push('/mnt/c/Program Files/Factorio/bin/x64/factorio.exe');

  for (const rawCandidate of candidates) {
    const candidate = windowsPathToPosix(rawCandidate);
    if (!candidate) {
      continue;
    }

    let current = fs.existsSync(candidate) ? candidate : path.dirname(candidate);
    if (!fs.existsSync(current)) {
      continue;
    }

    if (fs.statSync(current).isFile()) {
      current = path.dirname(current);
    }

    while (true) {
      if (fs.existsSync(path.join(current, 'data', 'base'))) {
        return current;
      }

      const parent = path.dirname(current);
      if (parent === current) {
        break;
      }
      current = parent;
    }
  }

  return null;
}

function findDependencyModRoot(modName) {
  const modsDir = path.join(factorioTestDir, 'mods');
  if (!fs.existsSync(modsDir)) {
    return null;
  }

  const exactPath = path.join(modsDir, modName);
  if (fs.existsSync(exactPath)) {
    return exactPath;
  }

  const candidates = fs.readdirSync(modsDir).filter((entry) => entry === modName || entry.startsWith(`${modName}_`));
  if (candidates.length === 0) {
    return null;
  }

  candidates.sort();
  return path.join(modsDir, candidates[candidates.length - 1]);
}

function resolveModRoot(modName, factorioRoot) {
  if (modName === 'squirrel_madness') {
    return modDir;
  }

  if (factorioRoot) {
    const bundledDataPath = path.join(factorioRoot, 'data', modName);
    if (fs.existsSync(bundledDataPath)) {
      return bundledDataPath;
    }
  }

  return findDependencyModRoot(modName);
}

function collectAssetReferences() {
  const references = [];

  for (const filePath of walkFiles(modDir)) {
    const text = fs.readFileSync(filePath, 'utf8');
    const relativePath = path.relative(rootDir, filePath);

    for (const match of text.matchAll(assetPathPattern)) {
      if (!assetExtensions.has(path.posix.extname(match[2]).toLowerCase())) {
        continue;
      }

      references.push({
        filePath: relativePath,
        fullReference: match[0],
        modName: match[1],
        relativeAssetPath: match[2]
      });
    }
  }

  return references;
}

test('all referenced asset paths resolve to real files', () => {
  const references = collectAssetReferences();
  const factorioRoot = findFactorioRoot();
  const unresolvedRoots = [];
  const missingFiles = [];

  for (const reference of references) {
    const modRoot = resolveModRoot(reference.modName, factorioRoot);

    if (!modRoot) {
      unresolvedRoots.push(
        `${reference.filePath}: ${reference.fullReference} (unknown asset root __${reference.modName}__)`
      );
      continue;
    }

    const fullAssetPath = path.join(modRoot, reference.relativeAssetPath);
    if (!fs.existsSync(fullAssetPath)) {
      missingFiles.push(
        `${reference.filePath}: ${reference.fullReference} -> ${fullAssetPath}`
      );
    }
  }

  assert.equal(
    unresolvedRoots.length,
    0,
    `Unresolved asset roots:\n${unresolvedRoots.join('\n')}`
  );

  assert.equal(
    missingFiles.length,
    0,
    `Missing asset files:\n${missingFiles.join('\n')}`
  );
});
