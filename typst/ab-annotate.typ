// ab-annotate.typ
// Annotated bibliography support for Typst.
//
// Because Typst's bibliography() function renders as a monolithic block
// with no per-entry hooks, we take a different approach:
//   1. Parse the .bib file to extract abstract/annotation fields
//   2. For each entry, emit a formatted block with the citation key
//      as a label and the abstract/annotation underneath
//   3. Use Typst's native bibliography() in a hidden block so that
//      cite() works correctly for formatting
//
// Usage:
//   #import "ab-annotate.typ": annotated-bib, parse-bib
//
//   // At the end of your document:
//   #annotated-bib("references.bib")

// ── .bib parser ─────────────────────────────────────────────────
// Extracts key, abstract, annotation/annote from BibLaTeX .bib files.

#let parse-bib(bib-content) = {
  let entries = ()
  let text = bib-content
  
  // Find each @type{key block
  let entry-starts = ()
  let i = 0
  let chars = text.clusters()
  while i < chars.len() {
    if chars.at(i) == "@" {
      entry-starts.push(i)
    }
    i += 1
  }
  
  for (idx, start) in entry-starts.enumerate() {
    let end = if idx + 1 < entry-starts.len() {
      entry-starts.at(idx + 1)
    } else {
      chars.len()
    }
    let chunk = chars.slice(start, end).join()
    
    // Get entry type and key
    let header = chunk.match(regex("@(\w+)\s*\{\s*([^,\s]+)"))
    if header == none { continue }
    let entry-type = header.captures.at(0).trim()
    let key = header.captures.at(1).trim()
    
    // Skip @comment, @preamble, @string
    if entry-type in ("comment", "preamble", "string") { continue }
    
    // Helper: extract a brace-delimited field value
    let extract-field(field-name, chunk) = {
      let pattern = regex(field-name + "\s*=\s*\{")
      let m = chunk.match(pattern)
      if m == none { return none }
      let s = m.end
      let depth = 1
      let pos = s
      let c = chunk.clusters()
      while pos < c.len() and depth > 0 {
        if c.at(pos) == "{" { depth += 1 }
        if c.at(pos) == "}" { depth -= 1 }
        if depth > 0 { pos += 1 }
      }
      c.slice(s, pos).join().replace(regex("\s+"), " ").trim()
    }
    
    let abst = extract-field("abstract", chunk)
    let annot = extract-field("annotation", chunk)
    let annote = extract-field("annote", chunk)
    
    // Merge: annotation takes priority over annote
    let final-annotation = if annot != none { annot } else { annote }
    
    entries.push((
      key: key,
      abstract: abst,
      annotation: final-annotation,
    ))
  }
  
  entries
}

// ── Render annotated bibliography ───────────────────────────────

#let annotated-bib(
  bib-file,
  title: "Annotated Bibliography",
  style: "apa",
  show-abstract: true,
  show-annotation: true,
  show-labels: true,
  abstract-label: "Abstract",
  annotation-label: "Annotation",
  indent: 1.5em,
  block-spacing: 0.5em,
  entry-spacing: 1.2em,
) = {
  // Parse the .bib file
  let bib-content = read(bib-file)
  let entries = parse-bib(bib-content)
  
  // Title
  if title != none {
    heading(level: 1, numbering: none, title)
  }
  
  // Render the standard bibliography (hidden) so cite keys resolve
  // Then show our custom annotated version
  //
  // NOTE: We render a standard bibliography and follow it with
  // annotation blocks keyed to each entry. This is the most
  // reliable approach given Typst's current bibliography API.
  
  // Show the real bibliography
  bibliography(bib-file, title: none, style: style, full: true)
  
  // Now append annotation blocks for entries that have them
  for entry in entries {
    let has-abs = entry.abstract != none and show-abstract
    let has-ann = entry.annotation != none and show-annotation
    
    if has-abs or has-ann {
      v(block-spacing)
      block(
        inset: (left: indent, top: 0.3em, bottom: 0.3em),
        stroke: (left: 1.5pt + luma(180)),
        width: 100%,
      )[
        #text(weight: "bold", size: 9pt)[#entry.key]
        
        #if has-abs [
          #v(0.2em)
          #if show-labels [
            #text(weight: "bold", size: 8.5pt)[#abstract-label:]
            #h(0.3em)
          ]
          #text(size: 8.5pt, style: "italic")[#entry.abstract]
        ]
        
        #if has-ann [
          #v(0.2em)
          #if show-labels [
            #text(weight: "bold", size: 8.5pt)[#annotation-label:]
            #h(0.3em)
          ]
          #text(size: 8.5pt)[#entry.annotation]
        ]
      ]
    }
  }
}
