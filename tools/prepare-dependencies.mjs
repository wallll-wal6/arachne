// Migrate only the published regexp@0.3.5 manifests, never engine sources.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? 'artifacts/dependency-preparation');
assert.ok(process.argv.length <= 3, 'Use: node tools/prepare-dependencies.mjs [output-directory]');
mkdirSync(output, { recursive: true });
const receipt = join(output, 'prepared.json');
if (existsSync(receipt)) unlinkSync(receipt);
function invoke(command, args) {
  const result = spawnSync(command, args, { cwd: root, encoding: 'utf8', timeout: 120_000, maxBuffer: 8 * 1024 * 1024 });
  if (result.error) throw result.error;
  return result;
}
// Moon downloads registry dependencies before rejecting the legacy manifest.
// Do not treat any other check failure as permission to change dependencies.
const probe = invoke('moon', ['check', '--deny-warn']);
writeFileSync(join(output, 'probe.stdout.txt'), probe.stdout ?? '');
writeFileSync(join(output, 'probe.stderr.txt'), probe.stderr ?? '');
const moduleRoot = join(root, '.mooncakes/moonbitlang/regexp');
let migrated = [];
if (probe.status !== 0) {
  assert.match(probe.stderr, /`moon\.mod\.json`.*is no longer supported/s, 'Unrecognized check failure; see dependency probe logs');
  assert.ok(probe.stderr.includes(moduleRoot.replaceAll('\\', '/')) || probe.stderr.includes(moduleRoot), 'Refusal must name the expected regexp cache');
  const metadata = JSON.parse(readFileSync(join(moduleRoot, 'moon.mod.json'), 'utf8'));
  assert.equal(metadata.name, 'moonbitlang/regexp');
  assert.equal(metadata.version, '0.3.5');
  function files(directory) {
    return readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
      if (entry.name === '_build') return [];
      const path = join(directory, entry.name);
      assert.ok(!entry.isSymbolicLink(), 'Dependency migration refuses symlinks');
      return entry.isDirectory() ? files(path) : [path];
    });
  }
  const originalFiles = files(moduleRoot);
  const legacy = originalFiles.filter(path => /(?:^|[\\/])moon\.(?:mod|pkg)\.json$/.test(path));
  const untouched = originalFiles.filter(path => !legacy.includes(path));
  const digest = path => createHash('sha256').update(readFileSync(path)).digest('hex');
  const hashes = untouched.map(path => [path, digest(path)]);
  for (const path of legacy) {
    const destination = path.slice(0, -5);
    assert.ok(!existsSync(destination), `Refusing to overwrite ${destination}`);
    const name = relative(moduleRoot, path).replaceAll('\\', '/');
    writeFileSync(join(output, name.replaceAll('/', '__')), readFileSync(path));
    // Standalone moonfmt converts the manifest only; moon fmt would also rewrite sources.
    const result = invoke('moonfmt', [path, '-o', destination]);
    writeFileSync(join(output, `${name.replaceAll('/', '__')}.log`), result.stdout + result.stderr);
    assert.equal(result.status, 0, `Manifest conversion failed: ${name}`);
    assert.ok(existsSync(destination), `Missing converted manifest: ${name}`);
    writeFileSync(join(output, name.replaceAll('/', '__') + '.converted'), readFileSync(destination));
    migrated.push(name);
  }
  for (const [path, hash] of hashes) assert.equal(digest(path), hash, `Dependency source changed: ${path}`);
  for (const path of legacy) unlinkSync(path);
  writeFileSync(join(output, 'source-hashes.json'), JSON.stringify(hashes.map(([path, sha256]) => ({ path: relative(moduleRoot, path), sha256 })), null, 2) + '\n');
}
writeFileSync(receipt, JSON.stringify({ dependency: 'moonbitlang/regexp@0.3.5', probe_exit: probe.status, migrated }, null, 2) + '\n');
console.log(`Dependency preparation completed: ${migrated.length} manifests converted; engine sources preserved. Run strict checks next.`);
