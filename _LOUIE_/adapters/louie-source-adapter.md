# LOUIE Source Adapter Interface

A LOUIE source adapter connects an external task or project management system
to the LOUIE workflow. Any system can serve as a task source by implementing
this interface.

Concrete adapters live **outside** `_LOUIE_/`, in a sibling `louie-adapters/<name>/`
directory (private — gitignored in the public framework, or kept in a separate
private repo). `_LOUIE_/` itself stays fully tool-agnostic: it defines this
interface and the `louie-from-source` command, and names no specific source system.

## Required Operations

**fetch_next_task()**
Returns the next task ready for LOUIE processing.
Must provide: id, title, louie_type, concept (markdown, if available)

**fetch_task(id)**
Returns a specific task by ID.
Must provide: id, title, louie_type, concept (markdown, if available)

**update_status(id, status)**
Updates the task status in the source system.
Called by LOUIE on pickup ("In LOUIE") and on completion ("Done").

**attach_concept(id, markdown)**
Writes a concept document back to the source system.
Optional — only needed if concepts are generated outside the source system.

## louie_type Routing

The adapter must map louie_type to a LOUIE command:

| louie_type | LOUIE command   |
|------------|-----------------|
| setup      | louie-setup     |
| feature    | louie-feature   |
| extend     | louie-extend    |
| update     | louie-update    |
| bugfix     | louie-bugfix    |

## Concept Handoff

If a concept document is present when a task is fetched:
- Tom (Analyst) is skipped
- For setup / feature / extend: hand off directly to Sophie (Architect)
- For bugfix: hand off directly to the bugfix diagnosis chain

The concept is passed as the initial context document.

The routed command still runs its own confirmation gates — architecture and
tech-stack must be confirmed before feature work, and the feature document must
be approved before coding. A concept replaces Tom's interview; it does not
bypass the Three Critical Rules.
