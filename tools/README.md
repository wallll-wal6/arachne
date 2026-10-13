# Unicode corpus data

The compatibility corpus uses inclusive Unicode General_Category ranges derived from Unicode 17.0 `UnicodeData.txt`. The generated file is test-oracle data; it is not used to classify input or execute regular expressions.

To regenerate it, download the versioned Unicode data file and run:

```sh
curl -fsSLo UnicodeData.txt https://www.unicode.org/Public/17.0.0/ucd/UnicodeData.txt
node tools/generate_unicode.mjs UnicodeData.txt > unicode_data.mbt
```

Review the generated diff, run `moon check --deny-warn` and `moon test`, and keep the associated data notice in [../UNICODE-LICENSE.txt](../UNICODE-LICENSE.txt). The range ordering and inclusive endpoints are part of the corpus generator's input contract.

# Migration demo regression

`node tools/verify-demo.mjs` runs the real text and JSON examples against their
checked-in expected files. See the [migration walkthrough](../examples/demo/README.md)
for dependencies, target selection, scope, and human review of differences.

Both executables run twice; repeated normalized output must be identical.
The optional second argument saves actual outputs, stderr, target/Node metadata,
and a completion marker without shell encoding/redirection issues:

```sh
node tools/verify-demo.mjs default artifacts/default
node tools/verify-demo.mjs js artifacts/js
# Requires a C compiler supported by the installed MoonBit toolchain:
node tools/verify-demo.mjs native artifacts/native
```

`demo.json` is the observed envelope, not a copied golden. `verified.json` is
written only after text/parsed-JSON snapshot and repeatability checks pass;
a rerun removes the old marker before execution. Files captured on a failed run
are diagnostics, not acceptance evidence. Use a fresh output directory for a
new investigation; expected files are never rewritten by this tool. CI records
the MoonBit toolchain and Git revision beside these outputs and uploads each
target's directory, including diagnostics available after a failure.

# Legacy dependency manifest preparation

`node tools/prepare-dependencies.mjs [output-directory]` supports the unchanged
`moonbitlang/regexp@0.3.5` package on the locally tested MoonBit `0.1.20261012`.
Run `moon update` first. A strict check probe downloads dependencies; if it
succeeds, no files change. Only a rejection of the known regexp legacy manifest
allows conversion. Any other failure exits nonzero, with no `prepared.json`.

The tool uses the installed standalone `moonfmt` to convert one `moon.mod.json`
and five `moon.pkg.json` files inside `.mooncakes/moonbitlang/regexp`. It does
not run `moon fmt` on the dependency, which would also rewrite engine sources.
Before removing the legacy manifests it checks SHA-256 for every other file.
It records original/converted manifests, the probe's stdout/stderr and exit,
and source hashes in the output directory. Those cache manifests differ from
the registry archive; the package version and parser/matcher sources do not.

`prepared.json` means preparation finished, not that tests, CI or human
acceptance passed. A retry first removes its old receipt. Run the strict
check/test/build and demo verifier next. CI uses the same commands and saves
their logs with the toolchain and revision; Bash pipefail preserves failures.
Its current version guard rejects drift from moon `0.1.20261012` / moonc
`v0.10.15+943464bfa`. The official installer and Node.js 22 patch version still
come from moving downloads, so this is a drift guard, not an archived toolchain.
The installer script is retained in CI artifacts for diagnosis. Future versions
need explicit verification before changing the guard.
