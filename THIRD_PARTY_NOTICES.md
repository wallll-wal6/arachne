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
`0.3.5`, as a MoonBit dependency. Pattern parsing and matching are provided by
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

`unicode_data.mbt` contains a range table labelled Unicode 17.0, used to
construct bounded regression fixtures. The generator reads an externally
supplied `UnicodeData.txt`; the original input version lacks an independent
provenance record, as stated in the [disclosure](docs/2026-10-disclosure.md).
The table is not
an Arachne regex engine implementation. Its separate notice is in
[`UNICODE-LICENSE.txt`](UNICODE-LICENSE.txt), and regeneration is documented in
[`tools/README.md`](tools/README.md).
