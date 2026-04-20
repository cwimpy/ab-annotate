# ab-annotate

A cross-format package for producing annotated bibliographies that display both abstracts and user-written annotations beneath each citation entry. Supports LaTeX (biblatex), Typst, and Quarto (targeting PDF, HTML, Typst, and Word).

## Project Goal

Create a unified annotated bibliography toolchain where each entry can show:

1. **Full citation** (formatted per the chosen style)
2. **Abstract** (from the standard `abstract` BibTeX/biblatex field)
3. **Annotation** (from the `annotation` or `annote` field — the user's own notes)

Both fields are optional per entry. If neither is present, the entry renders as a normal citation.

## Architecture Overview

Three independent implementations sharing the same `.bib` file format:

| Implementation | Mechanism | Dependencies |
|---|---|---|
| **LaTeX** | biblatex `.sty` package using `xpatch` to patch drivers | biblatex, biber, xpatch, changepage, kvoptions |
| **Typst** | `.typ` module that parses `.bib` and renders annotation blocks after `bibliography()` | Typst 0.11+ |
| **Quarto** | Lua filter that injects abstract/annotation divs into the `#refs` bibliography div after citeproc | Quarto 1.3+, works with PDF/HTML/Typst/Word output |

All three read from standard `.bib` files using the `abstract` and `annotation` (or `annote`) fields — no custom entry types or nonstandard fields required.

## File Structure

```
ab-annotate/
├── CLAUDE.md                           # This file
├── README.md                           # User-facing documentation
│
├── latex/                              # LaTeX/biblatex implementation
│   ├── biblatex-abs-annote.sty         # The package (CTAN name)
│   ├── biblatex-abs-annote.tex         # Documentation source
│   ├── biblatex-abs-annote-example.tex # MWE
│   └── biblatex-abs-annote-example.bib # Sample entries
│
├── typst/                              # Typst implementation
│   ├── ab-annotate.typ                 # The module
│   ├── ab-annotate-example.typ         # MWE
│   └── ab-annotate-example.bib         # Sample entries (same content)
│
└── quarto/                             # Quarto implementation
    ├── ab-annotate.lua                 # Lua filter
    ├── ab-annotate.css                 # HTML output styling
    ├── ab-annotate-example.qmd         # MWE (multi-format)
    └── ab-annotate-example.bib         # Sample entries (same content)
```

## BibTeX Entry Format (shared across all implementations)

```bibtex
@article{example2024,
  author     = {Smith, Jane},
  title      = {Rural Election Administration Challenges},
  journal    = {Journal of Elections and Public Opinion},
  year       = {2024},
  volume     = {34},
  pages      = {112--138},
  abstract   = {This paper examines the unique challenges...},
  annotation = {Key paper for the adaptive informality framework.
                Smith's typology maps well onto the Delta cases.}
}
```

The `annote` field is treated as a fallback for `annotation` in all three implementations.

---

## LaTeX Implementation (`latex/biblatex-abs-annote.sty`)

The LaTeX component is distributed on CTAN as **`biblatex-abs-annote`** (per CTAN naming guidance — the umbrella repo remains `ab-annotate`).

### Loading

```latex
\usepackage[style=authoryear]{biblatex}
\usepackage{biblatex-abs-annote}
```

### How it works

Uses `xpatch` to patch `\usebibmacro{finentry}` in all 16 standard biblatex drivers (article, book, incollection, inproceedings, thesis, report, misc, online, etc.). Each patch inserts `ab-annotate/abstract` and `ab-annotate/annotation` bibmacros before `finentry`.

### Package options (boolean, default true)

- `abstract` — toggle abstract display
- `annotation` — toggle annotation display
- `labels` — toggle "Abstract:" / "Annotation:" heading labels

### User-facing customization

```latex
\renewcommand{\abAnnotateAbstractLabel}{Abstract}
\renewcommand{\abAnnotateAnnotationLabel}{Annotation}
\renewcommand{\abAnnotateAbstractFont}{\small\itshape}
\renewcommand{\abAnnotateAnnotationFont}{\small}
\renewcommand{\abAnnotateLabelFont}{\small\bfseries}
\setlength{\abAnnotateAbstractIndent}{1.5em}
\setlength{\abAnnotateAnnotationIndent}{1.5em}
\setlength{\abAnnotateBlockSkip}{0.5ex}
\setlength{\abAnnotateInterSkip}{0.3ex}
```

### Build

```bash
pdflatex biblatex-abs-annote-example
biber biblatex-abs-annote-example
pdflatex biblatex-abs-annote-example
pdflatex biblatex-abs-annote-example
```

### Compatibility

Works with any biblatex style. Requires biblatex + biber (not natbib or raw bibtex `.bst` files). Target: TeX Live 2020+.

---

## Typst Implementation (`typst/ab-annotate.typ`)

### Loading

```typst
#import "ab-annotate.typ": annotated-bib
```

### How it works

Typst's `bibliography()` function is a monolithic block with no per-entry hooks. The module:

1. **Parses the `.bib` file** using a built-in brace-depth-aware parser to extract `abstract`, `annotation`, and `annote` fields
2. **Renders the standard `bibliography()`** with the chosen CSL style
3. **Appends styled annotation blocks** (with left-border styling) for each entry that has abstract/annotation data, keyed by citation key

### Current limitation

Because Typst's bibliography API doesn't allow per-entry injection, annotations appear as a grouped section after the bibliography rather than interleaved with each entry. This is the best we can do until Typst adds bibliography entry hooks (tracked in typst/typst#942).

### Parameters

```typst
#annotated-bib(
  "references.bib",
  title: "Annotated Bibliography",   // or none
  style: "apa",                       // any CSL style Typst supports
  show-abstract: true,
  show-annotation: true,
  show-labels: true,
  abstract-label: "Abstract",
  annotation-label: "Annotation",
  indent: 1.5em,
  block-spacing: 0.5em,
  entry-spacing: 1.2em,
)
```

### Build

```bash
typst compile ab-annotate-example.typ
```

### Notes

- Uses `read()` to access the `.bib` file contents
- The parser handles multi-line brace-delimited fields, nested braces, and `annote`→`annotation` fallback
- All entries in the `.bib` are included (`full: true`)

---

## Quarto Implementation (`quarto/ab-annotate.lua`)

### Loading

```yaml
---
bibliography: references.bib
citeproc: false
filters:
  - ab-annotate.lua
ab-annotate:
  show-abstract: true
  show-annotation: true
  show-labels: true
  abstract-label: "Abstract"
  annotation-label: "Annotation"
---
```

**IMPORTANT**: You must set `citeproc: false`. The filter calls `pandoc.utils.citeproc()` internally. This is necessary because Quarto runs its built-in citeproc *after* all Lua filters, so the `#refs` div would be empty when our filter executes. By disabling Quarto's citeproc and invoking it ourselves inside the filter, we guarantee the bibliography is populated before we inject annotation blocks. This is the same pattern used by established extensions like `recursive-citeproc` and `multibib`.

### How it works

The Lua filter uses a single `Pandoc`-level function that:

1. **Calls `pandoc.utils.citeproc(doc)`** to process citations and populate the `#refs` div
2. **Reads configuration** from the `ab-annotate` YAML key
3. **Parses each `.bib` file** listed in `bibliography` to extract `abstract`/`annotation`/`annote` fields per citation key
4. **Walks the document** looking for the `#refs` div. For each `ref-<key>` child div, appends styled abstract/annotation blocks

### Output format support

| Format | How annotations render |
|--------|----------------------|
| **HTML** | `<div>` blocks with `.ab-abstract` / `.ab-annotation` classes, styled via `ab-annotate.css` |
| **PDF (LaTeX)** | Pandoc paragraphs with `\textbf{}` labels and `\emph{}` abstracts |
| **Typst** | Pandoc paragraphs converted to Typst content blocks |
| **Word** | Pandoc paragraphs with bold/italic formatting |

### CSS classes (HTML output)

- `.ab-annotate-block` — shared wrapper class
- `.ab-abstract` — abstract-specific styling (blue left border)
- `.ab-annotation` — annotation-specific styling (green left border)

### Build

```bash
# PDF
quarto render ab-annotate-example.qmd --to pdf

# HTML
quarto render ab-annotate-example.qmd --to html

# Word
quarto render ab-annotate-example.qmd --to docx
```

### Key design decision: `citeproc: false`

Quarto's built-in citeproc runs after all Lua filters, which means the `#refs` div is empty when YAML-specified filters execute. The filter solves this by calling `pandoc.utils.citeproc()` directly, which requires `citeproc: false` in the YAML to avoid double-processing. CSL styles specified in the YAML are respected by the internal citeproc call.

---

## Testing Checklist

### All implementations

- [ ] Entry with both fields shows abstract then annotation
- [ ] Entry with only abstract shows just abstract block
- [ ] Entry with only annotation shows just annotation block
- [ ] Entry with neither shows as normal citation
- [ ] `annote` field works as fallback for `annotation`
- [ ] Toggling show-abstract/show-annotation suppresses the right blocks
- [ ] Toggling show-labels removes "Abstract:"/"Annotation:" headers

### LaTeX-specific

- [ ] Works with `authoryear`, `apa`, and `numeric` biblatex styles
- [ ] Font/indent customization commands work when redefined
- [ ] `xpatch` failures for missing drivers are silent

### Typst-specific

- [ ] Parser handles nested braces in field values
- [ ] Works with different CSL styles
- [ ] `read()` correctly loads `.bib` file

### Quarto-specific

- [ ] HTML output has correct CSS classes
- [ ] PDF output renders labels and formatting
- [ ] Word output renders labels and formatting
- [ ] Typst output renders correctly
- [ ] Filter works with multiple `.bib` files
- [ ] `#refs` div placement is respected

---

## Future Enhancements

- **Typst**: When Typst adds per-entry bibliography hooks, refactor to interleave annotations directly with entries instead of appending as a separate block
- **Quarto extension**: Package as a proper `quarto install extension` with `_extension.yml`
- **YAML annotations**: Support a sidecar `.yaml` file for annotations (for users who don't want to edit their `.bib`)
- **Zotero integration**: Map Zotero notes to the annotation field in exported `.bib`
- **Filtering**: Add options to only show annotations for entries matching certain keywords or entry types
- **Sort control**: Allow sorting annotated entries independently of bibliography order
