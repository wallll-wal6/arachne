# Unicode table generation

The engine's general-category matcher uses compact, sorted ranges generated from the official Unicode Character Database 17.0 `UnicodeData.txt`.

Download that versioned file and run the generator from the repository root:

```sh
curl -fsSLo UnicodeData.txt https://www.unicode.org/Public/17.0.0/ucd/UnicodeData.txt
node tools/generate_unicode.mjs UnicodeData.txt > unicode_data.mbt
```

The generator expands `<..., First>` / `<..., Last>` records, groups the 30 general categories and their seven aggregate groups, adds the unassigned `Cn` complement, then writes sorted inclusive ranges for binary search. It does not edit the engine. Review the generated diff and run `moon check` and `moon test` after regenerating. Unicode data license terms are reproduced in [../UNICODE-LICENSE.txt](../UNICODE-LICENSE.txt).
