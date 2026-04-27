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

That drops a filter into `_extensions/cwimpy/ab-annotate/`. It does **not** create a starter `.qmd` — you provide that. A minimal working document:

````markdown
---
title: "My Document"
bibliography: refs.bib
nocite: |
  @*
citeproc: false
filters:
  - ab-annotate
format:
  html: default
  pdf:
    pdf-engine: xelatex
---

# References

::: {#refs}
:::
````

Two pieces are required:

- `citeproc: false` — the filter calls citeproc itself so it can inject annotations after citations are resolved.
- An empty `::: {#refs} :::` div (or inline `@key` citations / `nocite: "@*"`) so there's a `#refs` div for the filter to walk.

A fully working example is in [`examples/quarto/`](examples/quarto/) — clone the repo or copy `demo.qmd` + `refs.bib`.

### LaTeX (via CTAN)

The LaTeX component is distributed on CTAN as **[`biblatex-abs-annote`](https://ctan.org/pkg/biblatex-abs-annote)** (the project as a whole remains `ab-annotate`; CTAN asked for a more explicit, biblatex-scoped name). It ships with TeX Live and MiKTeX.

Install via your TeX distribution:

```bash
# TeX Live
tlmgr install biblatex-abs-annote

# MiKTeX
mpm --install=biblatex-abs-annote
```

Then load it alongside biblatex:

```latex
\usepackage[style=authoryear]{biblatex}
\usepackage{biblatex-abs-annote}
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
- [x] CTAN: published as [`biblatex-abs-annote`](https://ctan.org/pkg/biblatex-abs-annote)

## License

MIT. See `LICENSE`.
