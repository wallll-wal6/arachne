# Unicode corpus data

The compatibility corpus uses inclusive Unicode General_Category ranges from Unicode 17.0.0. I downloaded the versioned file from the official Unicode archive and verified that the generated section in `unicode_data.mbt` matches the generator output line-for-line. The input file's SHA-256 is `2e1efc1dcb59c575eedf5ccae60f95229f706ee6d031835247d843c11d96470c`; the source and license are also recorded in [third-party notices](../THIRD_PARTY_NOTICES.md). The generated file is test-oracle data; it is not used to classify input or execute regular expressions.

To regenerate it, download the versioned Unicode data file and run:

```sh
curl -fsSLo UnicodeData.txt https://www.unicode.org/Public/17.0.0/ucd/UnicodeData.txt
node tools/generate_unicode.mjs UnicodeData.txt > UnicodeData.generated.mbt
```

The generator emits the generated section only. `unicode_data.mbt` also has
hand-maintained fixture helpers after that section, so do not redirect directly
to `unicode_data.mbt`. Replace only its generated section, from the generated
file header through the `unicode_category_ranges` function, and retain the
helper code beginning at `UnicodeCorpusError`. Remove the scratch file before
running `moon fmt`, `moon fmt --check`, `moon check --deny-warn` and `moon test`.

Use the toolchain specified in the [quick start](../README.md#quick-start).
The generator emits `Int32` range endpoints to match the checked-in table.
Review the generated diff and keep the associated data notice in
[../UNICODE-LICENSE.txt](../UNICODE-LICENSE.txt).
The range ordering and inclusive endpoints are part of the corpus generator's input contract.

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
