Codebase-health recipes — audits that measure the code against a standard and turn what they find into tracked work.

Recipes in this section are **audit recipes**: they read the codebase, report findings, and file follow-up work in `_LOUIE-output/roadmap.md`. They never edit code and never run the feature chain — fixing is a separate, user-approved step (`louie-roadmap promote`, `louie-feature`, `louie-update`).

They differ from `louie-evaluate` by focus: `louie-evaluate` is a broad, multi-category assessment producing a persistent findings set with its own apply loop. A quality recipe checks **one** standard, end to end, cheaply enough to re-run often.
