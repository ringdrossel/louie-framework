# RUN — {goal in one line}

<!-- Run spec written by `louie-spec-run`, executed by `louie-run`. With a source
adapter this whole text is the description of a task with `louie_type: run`;
without one it is a local file. Keep to headings, bullet lists, plain text and
inline code — trackers that store rich text convert it on every read, and
tables or checkboxes are the first to come back changed. Remove this comment. -->

This is a LOUIE run spec, not a feature: execute it with `louie-run` (`_LOUIE_/commands/louie-run.md`) — `louie-from-source <id>` routes there.

Mode: unattended
Project: {repo path}

## Goal

{What is finished when this run ends — one short paragraph. "Ready for human testing" is the usual end state; merging, pushing and deploying are never part of a run.}

## Sub-tasks

<!-- Dependency order. One line each: tracker id (or — without a tracker),
feature slug as in _LOUIE-output/implementations/overview.md, what it depends
on (other slugs in this list, or features already Implemented). Every slug
needs _LOUIE-output/implementations/<slug>/requirements.md before the build. -->

- #{id} `{feature-slug}` — depends: none
- #{id} `{feature-slug}` — depends: `{feature-slug}`

## Standing rules

<!-- Project limits that hold for every session of this run: external services,
rate limits, credentials, things never to do. Delete the section if none. -->

- {rule}

## Before the build

<!-- Steps the orchestrator does before the unattended part, in order.
[human] = needs the user at the keyboard; [agent] = the orchestrator does it.
Write each so its outcome can be checked (a file exists, a commit landed) —
a resumed run skips steps whose outcome is already there. Delete if none. -->

1. [agent] {step}
2. [human] {step}

## Unattended build

- Unit: phase
- Timeout per session: 7200
- Max sessions: 40

## After the build

<!-- Steps after the build stops with `done`: live acceptance with the user,
anything only a human can verify. The handoff (resolutions) always happens
and need not be listed. Delete if none. -->

1. [human] {step}

## If the run stops

{Anything run-specific beyond the default: bring each parked question to the user, record the answer in the feature's `requirements.md` or `decisions.md`, rerun the build.}
