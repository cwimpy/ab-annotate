// ab-annotate-example.typ
// Minimal working example for Typst annotated bibliography.
//
// Compile with: typst compile ab-annotate-example.typ

#import "ab-annotate.typ": annotated-bib

#set document(
  title: "Annotated Bibliography: Rural Election Administration",
  author: "Cameron Wimpy",
)

#set page(paper: "us-letter", margin: 1in)
#set text(font: "New Computer Modern", size: 11pt)
#set par(justify: true)

= Annotated Bibliography: Rural Election Administration

This annotated bibliography surveys key works on election
administration in rural contexts. Entries include abstracts where
available and personal annotations noting relevance to ongoing research.

// Cite all entries so they appear in the bibliography
#cite(<kimball2013>, form: "full")
#cite(<hale2015>, form: "full")
#cite(<mcneal2023>, form: "full")
#cite(<stewart2020>, form: "full")

#annotated-bib(
  "ab-annotate-example.bib",
  style: "apa",
)
