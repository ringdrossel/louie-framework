# LOUIE Source Adapter Interface

A LOUIE source adapter connects an external task or project management system
to the LOUIE workflow. Any system can serve as a task source by implementing
this interface.

Concrete adapters live **outside** `_LOUIE_/`, in one of two places:

1. `louie-adapters/<name>/` at the project root (sibling of `_LOUIE_/`) — a
   per-project override, always gitignored (the init scripts ensure this)
2. `~/.louie/adapters/<name>/` (`%USERPROFILE%\.louie\adapters\` on Windows) —
   a machine-global install shared by every LOUIE project; the recommended
   default (install once, works everywhere, credentials never sit in a
   project tree)

A project-local `louie-adapters/` takes precedence over the global directory.
`_LOUIE_/` itself stays fully tool-agnostic: it defines this interface and the
`louie-from-source` command, and names no specific source system.

## Operations

**fetch_next_task()** — *Required*
Returns the next task ready for LOUIE processing.
Must provide: id, title, louie_type, concept (markdown, if available), description (markdown — required for `run` tasks, whose
description is the run spec)

**fetch_task(id)** — *Required*
Returns a specific task by ID.
Must provide: id, title, louie_type, concept (markdown, if available), description (markdown — required for `run` tasks, whose
description is the run spec)

**update_status(id, status)** — *Required*
Brings the task to the given state in the source system. This is a **state
goal, not a single write**: the adapter is responsible for satisfying whatever
intermediate transitions its source system enforces to reach that state.
Callers issue exactly one `update_status` call per intended state and never
orchestrate intermediate steps themselves.
Called by LOUIE on pickup ("In LOUIE") and on user-confirmed completion
("Done") — never on chain completion alone, and never to close a task that has
no resolution unless the task was rejected; see `louie-from-source` step 7.

> If the source system has a constrained status lifecycle — a state machine
> that rejects direct hops between non-adjacent states — the adapter must
> document that lifecycle in its own `adapter.md` and walk it internally,
> so the framework never learns a source system's status lifecycle.
>
> If such a walk fails part-way, the adapter must surface the failure
> **together with the state actually reached** — the caller is otherwise
> left guessing between "unchanged" and "fully applied", and cannot decide
> whether to retry, resume, or escalate.

**create_task(...)** — *Optional*
Creates a new task in the source system. Returns the created task's `id`.
Fields: whatever identifies the owning project in that system, plus title,
description, louie_type, priority.

- The created task's **initial state is adapter-defined** and may not be a
  state LOUIE can pick up. An adapter that implements `create_task` must
  document which state creation yields. A caller must not assume a requested
  state is honored at creation — reach the intended state afterwards via
  `update_status`, which handles any required intermediate transitions.
- Used by `louie-spec-run`, which files a run task (`louie_type: run`, the run
  spec as `description`) and, where needed, its sub-tasks. Without
  `create_task`, `louie-spec-run` writes the spec as a local file instead.

**update_task(id, fields)** — *Optional*
Partial update of a task: changes only the fields sent. LOUIE uses it for one
field, the **resolution** — markdown recording how the task was resolved (what
was done, the outcome, assumptions, follow-ups). Written at handoff by
`louie-from-source` step 7 and by `louie-run`, and always present before a task
is closed, unless the task was rejected. An adapter whose system has no
resolution field may map it to a comment; one that cannot store it at all
omits the operation, and LOUIE then puts the resolution in its final message.

**attach_concept(id, markdown)** — *Optional*
Writes a concept document back to the source system.
Only needed if concepts are generated outside the source system.

## Requests outside `louie-from-source`

Any request about a task in the source system uses the same adapter lookup,
not only `louie-from-source`. That includes creating a task, closing one,
writing its resolution, commenting on it, or a bare `#NNN` task number in
conversation. Check the project's `louie-adapters/<name>/` first, then
`~/.louie/adapters/<name>/`, and follow that `adapter.md`. Say the source
system is unreachable only after both places came up empty.

The rules above still apply to these requests: before a close
(`update_status(id, "Done")`), write a resolution with `update_task`, unless
the task was rejected.

## louie_type Routing

The adapter must map louie_type to a LOUIE command:

| louie_type | LOUIE command   |
|------------|-----------------|
| setup      | louie-setup     |
| feature    | louie-feature   |
| extend     | louie-extend    |
| update     | louie-update    |
| bugfix     | louie-bugfix    |
| run        | louie-run       |

A `run` task carries its run spec (`_LOUIE_/templates/run-template.md`) in the
task description; there is no concept handoff for it — `louie-run` checks the
spec and executes it.

## Concept Handoff

If a concept document is present when a task is fetched:

- For setup / feature / extend: Tom (Analyst) runs a **concept intake** instead
  of his full interview — he narrates what he understood from the concept,
  asks any open questions and confirms the answers, then asks for explicit
  approval before handing over to Sophie (Architect). No handoff without that
  approval.
- For bugfix: the bugfix chain starts with the same gate — summarize the
  understanding from the concept, confirm with the user, then proceed to
  diagnosis.

The concept is passed as the initial context document.

The routed command still runs its own confirmation gates — architecture and
tech-stack must be confirmed before feature work, and the feature document must
be approved before coding. A concept replaces Tom's interview questions, not
his playback-and-approval gate, and it does not bypass the Three Critical Rules.

## Agentic Mode

Adapters and agentic mode are orthogonal layers that compose: the adapter
fetches the task and writes status back; agentic mode (`--agentic` on the
routed command) governs how gates resolve when an autonomous agent — not a
human — is driving. In that combination the concept is the task spec for Tom's
evidential gate, and the run-report `Status` maps back through
`update_status`: `completed` → a review/handoff state (an agentic run never
merges, so not "Done"; leave the task at "In LOUIE" if there is no such state),
`needs-human` / `blocked` → an escalation state. See `_LOUIE_/workflow/agentic-mode.md`.
