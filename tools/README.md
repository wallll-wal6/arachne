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
