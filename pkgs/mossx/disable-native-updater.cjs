const fs = require('node:fs');

// Match only the updater registration, independent of neighboring plugins.
const file = 'src-tauri/src/lib.rs';
const source = fs.readFileSync(file, 'utf8');
const patched = source.replace(
  /\.plugin\(\s*tauri_plugin_updater::Builder::new\(\)\s*\.build\(\)\s*\)/g,
  '',
);
if (/\.plugin\(\s*tauri_plugin_updater/.test(patched)) {
  throw new Error('Unsupported Tauri updater registration; update the Nix patch');
}
fs.writeFileSync(file, patched);

const capability = 'src-tauri/capabilities/default.json';
const config = JSON.parse(fs.readFileSync(capability, 'utf8'));
config.permissions = config.permissions.filter(
  (permission) => (typeof permission === 'string' ? permission : permission.identifier) !== 'updater:default',
);
fs.writeFileSync(capability, `${JSON.stringify(config, null, 2)}\n`);
