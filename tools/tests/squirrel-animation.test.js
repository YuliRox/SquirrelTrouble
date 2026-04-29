const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const rootDir = path.resolve(__dirname, '..', '..');
const entitiesPath = path.join(rootDir, 'squirrel_madness', 'prototypes', 'entities.lua');

test('squirrel prototype uses paired body and shadow sprite sheets', () => {
  const source = fs.readFileSync(entitiesPath, 'utf8');
  const bodyRelativePath = 'graphics/entities/squirrel/sq.png';
  const shadowRelativePath = 'graphics/entities/squirrel/sq_shadow.png';
  const bodyAbsolutePath = path.join(rootDir, 'squirrel_madness', bodyRelativePath);
  const shadowAbsolutePath = path.join(rootDir, 'squirrel_madness', shadowRelativePath);

  assert.match(source, /graphics\/entities\/squirrel\/sq\.png/);
  assert.match(source, /graphics\/entities\/squirrel\/sq_shadow\.png/);
  assert.match(source, /width = 132/);
  assert.match(source, /height = 78/);
  assert.match(source, /frame_count = 5/);
  assert.match(source, /direction_count = 16/);
  assert.match(source, /width_in_frames = 8/);
  assert.match(source, /height_in_frames = 10/);
  assert.match(source, /draw_as_shadow = true/);
  assert.match(source, /local squirrel_shadow_tint = \{r = 0, g = 0, b = 0, a = 1\}/);
  assert.match(source, /local squirrel_scale = 0\.581818/);
  assert.match(source, /return squirrel_animation\(0\.3\)/);
  assert.match(source, /return squirrel_animation\(0\.01\)/);
  assert.equal(fs.existsSync(bodyAbsolutePath), true, `missing squirrel sprite sheet: ${bodyRelativePath}`);
  assert.equal(fs.existsSync(shadowAbsolutePath), true, `missing squirrel shadow sheet: ${shadowRelativePath}`);
});
