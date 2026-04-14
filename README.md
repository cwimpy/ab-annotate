# ab-annotate

Produce annotated bibliographies that render the **citation**, **abstract**, and **user annotation** for each entry — from a single `.bib` file, across LaTeX, Typst, and Quarto.

Both the `abstract` and `annotation` (or `annote`) fields are standard BibLaTeX; no custom entry types required. Any combination is optional per entry.

## Installation

### Typst (via Typst Universe)

Once published to the registry:

```typst
#import "@preview/ab-annotate:0.1.0": annotated-bib

#annotated-bib("references.bib", style: "apa")
```

Pre-publication, clone and import locally:

```typst
#import "ab-annotate.typ": annotated-bib
```

Publishing steps are in `typst/PUBLISHING.md` (see Roadmap below).

### Quarto (as an extension)

```bash
quarto add cwimpy/ab-annotate
```

Then in your `.qmd`:

```yaml
---
bibliography: references.bib
citeproc: false
filters:
  - ab-annotate
---
```

Setting `citeproc: false` is required — the filter calls citeproc itself so it can inject annotations after citations are processed.

### LaTeX (manual install, CTAN submission pending)

Drop `latex/ab-annotate.sty` into your project directory or a local `texmf` tree, then:

```latex
\usepackage[style=authoryear]{biblatex}
\usepackage{ab-annotate}
```

Build with `pdflatex → biber → pdflatex → pdflatex`.

## BibTeX fields

```bibtex
@article{example2024,
  author     = {Smith, Jane},
  title      = {Rural Election Administration Challenges},
  journal    = {Journal of Elections and Public Opinion},
  year       = {2024},
  abstract   = {This paper examines the unique challenges...},
  annotation = {Key paper for the adaptive informality framework.}
}
```

## Layout

```
ab-annotate/
├── _extensions/ab-annotate/    # Quarto extension (installable via `quarto add`)
├── latex/                      # biblatex .sty package
├── typst/                      # Typst module + typst.toml manifest
└── quarto/                     # Working copy of lua/css + example .qmd
```

The `_extensions/` directory at the repo root is what `quarto add cwimpy/ab-annotate` looks for.

## Roadmap to distribution

- [x] Typst manifest (`typst/typst.toml`)
- [x] Quarto extension manifest (`_extensions/ab-annotate/_extension.yml`)
- [ ] Publish Typst package: PR to [typst/packages](https://github.com/typst/packages) adding `packages/preview/ab-annotate/0.1.0/`
- [ ] Tag a GitHub release so `quarto add cwimpy/ab-annotate@v0.1.0` is pinnable
- [ ] CTAN: wrap `.sty` in a `.dtx`/`.ins` pair with PDF docs and submit at [ctan.org/upload](https://ctan.org/upload)

## License

MIT. See `LICENSE`.
