// End-to-end regression: run both real executables; never rewrite goldens.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const target = process.argv[2] ?? 'default';
assert.ok(['default', 'wasm', 'wasm-gc', 'js', 'native'].includes(target), 'Use default, wasm, wasm-gc, js, or native');
assert.ok(process.argv.length <= 4, 'Use: node tools/verify-demo.mjs [target] [output-directory]');
const outputDirectory = process.argv[3] ? resolve(process.argv[3]) : null;
if (outputDirectory) {
  mkdirSync(outputDirectory, { recursive: true });
  // A previous successful run must never label a failed rerun as verified.
  rmSync(resolve(outputDirectory, 'verified.json'), { force: true });
  writeFileSync(resolve(outputDirectory, 'run.json'), JSON.stringify({
    target, node_version: process.version, command: process.argv.slice(1),
  }, null, 2) + '\n');
}

function run(packagePath, artifactName) {
  const targetArgs = target === 'default' ? [] : ['--target', target];
  const result = spawnSync('moon', ['run', ...targetArgs, '--deny-warn', packagePath], {
    cwd: root,
    encoding: 'utf8',
    timeout: 120_000,
    maxBuffer: 4 * 1024 * 1024,
  });
  if (outputDirectory) {
    writeFileSync(resolve(outputDirectory, artifactName), result.stdout ?? '');
    writeFileSync(resolve(outputDirectory, `${artifactName}.stderr.txt`), result.stderr ?? '');
  }
  if (result.error) throw result.error;
  assert.equal(result.status, 0, `${packagePath} failed:\n${result.stderr}`);
  // Normalize platform newlines only; preserve all meaningful whitespace.
  return result.stdout.replaceAll('\r\n', '\n');
}

const expectedText = readFileSync(new URL('../examples/demo/expected.txt', import.meta.url), 'utf8')
  .replaceAll('\r\n', '\n');
const actualText = run('examples/demo', 'demo.txt');
assert.equal(actualText, expectedText, 'Text demo drifted; review the observations');
const expectedJson = JSON.parse(readFileSync(new URL('../examples/demo/expected.json', import.meta.url), 'utf8'));
const actualJsonText = run('examples/demo-json', 'demo.json');
const actualJson = JSON.parse(actualJsonText);
// Object key ordering/pretty printing are irrelevant; arrays and values matter.
assert.deepEqual(actualJson, expectedJson, 'JSON demo drifted; review the observations');
assert.equal(run('examples/demo', 'demo-repeat.txt'), actualText, 'Text demo changed on a repeated run');
assert.equal(run('examples/demo-json', 'demo-repeat.json'), actualJsonText, 'JSON demo changed on a repeated run');
if (outputDirectory) {
  writeFileSync(resolve(outputDirectory, 'verified.json'), JSON.stringify({
    target, text_snapshot: true, json_snapshot: true, repeat_output: true,
  }, null, 2) + '\n');
}
console.log(`Migration demo regression passed (${target}): text and JSON match checked-in fixtures and repeat identically.`);
