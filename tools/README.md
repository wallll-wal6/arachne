# Unicode corpus data

The compatibility corpus uses inclusive Unicode General_Category ranges derived from Unicode 17.0 `UnicodeData.txt`. The generated file is test-oracle data; it is not used to classify input or execute regular expressions.

To regenerate it, download the versioned Unicode data file and run:

```sh
curl -fsSLo UnicodeData.txt https://www.unicode.org/Public/17.0.0/ucd/UnicodeData.txt
node tools/generate_unicode.mjs UnicodeData.txt > unicode_data.mbt
```

Review the generated diff, run `moon check --deny-warn` and `moon test`, and keep the associated data notice in [../UNICODE-LICENSE.txt](../UNICODE-LICENSE.txt). The range ordering and inclusive endpoints are part of the corpus generator's input contract.
