# Third-party notices

## Ownership and integration boundary

The contract runner, adapters, comparison and reports belong to this
repository. They call public dependency APIs; parsing and matching belong to
the engine dependencies. Arachne's owner and sole team member is Wei Anliang
(韦安良). The maintainers of these public dependencies are not Arachne team
members.
This integration makes no claim of upstream
contributions, joint development, or joint maintenance. Direct versions below
are recorded in `moon.mod`; package imports are recorded in `moon.pkg`.

## `moonbitlang/regexp`

The bundled `moonbit_regexp_adapter` in `contract.mbt` calls
[`moonbitlang/regexp`](https://github.com/moonbitlang/regexp.mbt), version
`0.3.6`, as a MoonBit dependency. Pattern parsing and matching are provided by
that package. No regexp engine source is copied into this repository; its
license and notices belong to the separately distributed upstream package.

## `walkzzz/re-mbt`

Arachne's optional cross-engine adapter calls the public Perl frontend from
[`walkzzz/re-mbt`](https://github.com/walkzzz/re-mbt), version `0.1.0`, as a
MoonBit dependency. No re-mbt engine source is copied into this repository.
The upstream module declares `LGPL-2.1-or-later`; its repository license also
contains an OCaml linking exception. See the upstream [`LICENSE`](https://github.com/walkzzz/re-mbt/blob/main/LICENSE)
for the complete terms. Arachne's own source remains under the license in
[`LICENSE`](LICENSE).

## Unicode category data

`unicode_data.mbt` contains a range table generated from the official Unicode
17.0.0 [`UnicodeData.txt`](https://www.unicode.org/Public/17.0.0/ucd/UnicodeData.txt).
The downloaded source has SHA-256
`2e1efc1dcb59c575eedf5ccae60f95229f706ee6d031835247d843c11d96470c`; its
generated section was reproduced and matched against the checked-in table.
Unicode data files are generally distributed under Unicode License v3; the
applicable notice is included in [`UNICODE-LICENSE.txt`](UNICODE-LICENSE.txt).
The table is used only to construct bounded regression fixtures, not as an
Arachne regex engine implementation. The license text is in
[`UNICODE-LICENSE.txt`](UNICODE-LICENSE.txt), and regeneration is documented in
[`tools/README.md`](tools/README.md).
