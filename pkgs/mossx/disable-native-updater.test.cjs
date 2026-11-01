const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

function run(source, check) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'mossx-updater-'));
  try {
    fs.mkdirSync(path.join(root, 'src-tauri/src'), { recursive: true });
    fs.mkdirSync(path.join(root, 'src-tauri/capabilities'));
    fs.writeFileSync(path.join(root, 'src-tauri/src/lib.rs'), source);
    fs.writeFileSync(path.join(root, 'src-tauri/capabilities/default.json'), JSON.stringify({
      permissions: ['dialog:default', 'updater:default', { identifier: 'updater:default' }, 'process:default'],
    }));
    const result = spawnSync(process.execPath, [path.join(__dirname, 'disable-native-updater.cjs')], { cwd: root, encoding: 'utf8' });
    check(result, root);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

for (const registration of [
  '.plugin(tauri_plugin_updater::Builder::new().build())',
  '.plugin(\n tauri_plugin_updater::Builder::new()\n .build()\n)',
  '',
]) {
  test(`updater removal tolerates formatting, neighboring plugins and prior removal: ${JSON.stringify(registration)}`, () => {
    run(`builder.plugin(other::init())${registration}.plugin(process::init())`, (result, root) => {
      assert.equal(result.status, 0, result.stderr);
      assert.equal(fs.readFileSync(path.join(root, 'src-tauri/src/lib.rs'), 'utf8'), 'builder.plugin(other::init()).plugin(process::init())');
      const capabilities = JSON.parse(fs.readFileSync(path.join(root, 'src-tauri/capabilities/default.json')));
      assert.deepEqual(capabilities.permissions, ['dialog:default', 'process:default']);
    });
  });
}

test('unrecognized updater registration fails explicitly', () => {
  run('builder.plugin(tauri_plugin_updater::init())', (result) => {
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Unsupported Tauri updater registration/);
  });
});
