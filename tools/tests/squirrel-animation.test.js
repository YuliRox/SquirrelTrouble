const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const rootDir = path.resolve(__dirname, '..', '..');
const entitiesPath = path.join(rootDir, 'squirrel_madness', 'prototypes', 'entities.lua');

test('squirrel prototype uses the six-frame PixelLab run strips', () => {
  const source = fs.readFileSync(entitiesPath, 'utf8');
  const directions = [
    'north',
    'north-east',
    'east',
    'south-east',
    'south',
    'south-west',
    'west',
    'north-west'
  ];

  assert.match(source, /frame_count = 6/);
  assert.match(source, /direction_count = 8/);

  for (const direction of directions) {
    const relativePath = `graphics/entities/squirrel/run-strips/${direction}.png`;
    const absolutePath = path.join(rootDir, 'squirrel_madness', relativePath);

    assert.match(source, new RegExp(`run-strips/${direction.replace('-', '\\-')}\\.png`));
    assert.equal(fs.existsSync(absolutePath), true, `missing squirrel run strip: ${relativePath}`);
  }
});
