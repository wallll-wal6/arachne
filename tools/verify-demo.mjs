// End-to-end regression: run both real executables; never rewrite goldens.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const target = process.argv[2] ?? 'default';
assert.ok(['default', 'wasm', 'wasm-gc', 'js', 'native'].includes(target), 'Use default, wasm, wasm-gc, js, or native');

function run(packagePath) {
  const targetArgs = target === 'default' ? [] : ['--target', target];
  const result = spawnSync('moon', ['run', ...targetArgs, '--deny-warn', packagePath], {
    cwd: root,
    encoding: 'utf8',
    timeout: 120_000,
    maxBuffer: 4 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  assert.equal(result.status, 0, `${packagePath} failed:\n${result.stderr}`);
  // Normalize platform newlines only; preserve all meaningful whitespace.
  return result.stdout.replaceAll('\r\n', '\n');
}

const expectedText = readFileSync(new URL('../examples/demo/expected.txt', import.meta.url), 'utf8')
  .replaceAll('\r\n', '\n');
assert.equal(run('examples/demo'), expectedText, 'Text demo drifted; review the observations');
const expectedJson = JSON.parse(readFileSync(new URL('../examples/demo/expected.json', import.meta.url), 'utf8'));
const actualJson = JSON.parse(run('examples/demo-json'));
// Object key ordering/pretty printing are irrelevant; arrays and values matter.
assert.deepEqual(actualJson, expectedJson, 'JSON demo drifted; review the observations');
console.log(`Migration demo regression passed (${target}): text and JSON match checked-in fixtures.`);
