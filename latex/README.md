# ab-annotate

A `biblatex` supplement for producing annotated bibliographies that render an **abstract** and a user-supplied **annotation** beneath each citation entry.

Both the `abstract` and `annotation` (or `annote`) fields are standard BibLaTeX, so no custom entry types are required. Any combination is optional per entry; an entry with neither renders as an ordinary citation.

## Installation

When the package is accepted into CTAN, TeX Live and MikTeX users get it automatically. Otherwise:

```
tlmgr install ab-annotate
```

## Usage

```latex
\usepackage[style=authoryear]{biblatex}
\usepackage{ab-annotate}
\addbibresource{refs.bib}

\begin{document}
\nocite{*}
\printbibliography
\end{document}
```

See `ab-annotate.pdf` for the full manual, including options, customization commands, and compatibility notes.

## Bundle contents

| File | Purpose |
|------|---------|
| `ab-annotate.sty` | The package |
| `ab-annotate.tex` | Documentation source |
| `ab-annotate.pdf` | Documentation (compiled) |
| `LICENSE`         | LPPL 1.3c text |
| `README.md`       | This file |

## Dependencies

`biblatex` (with `biber`), `xpatch`, `changepage`, `kvoptions` — all standard in current TeX Live and MikTeX distributions.

## Cross-format companions

`ab-annotate` is part of a cross-format toolchain sharing the same `.bib` conventions:

- A **Typst** package (`@preview/ab-annotate`) for Typst documents.
- A **Quarto** extension (`cwimpy/ab-annotate`) for PDF/HTML/Word/Typst output from a single `.qmd`.

Full source: <https://github.com/cwimpy/ab-annotate>.

## License

LaTeX Project Public License, version 1.3c. See `LICENSE`.

## Maintainer

Cameron Wimpy — <cwimpy@astate.edu>
