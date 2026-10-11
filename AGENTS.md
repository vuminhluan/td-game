# Code documentation

- Do not add explanatory comments inside functions, between code statements, or at the top of source files. Do not use docstrings as a replacement for comments.
- Keep important explanations, invariants, design decisions and maintenance notes in feature Markdown files under `docs/features/`.
- Group documents for a large feature in a subdirectory under `docs/features/` when useful. Link feature documents from `README.md`.
- Keep project Markdown under `docs/`, grouped as features, workflows, assets and QA. Only the entry-point `README.md` and this `AGENTS.md` stay at the repository root. Maintain `docs/README.md` as the documentation index; see `docs/maintenance.md`.
- Keep active generation sources under descriptive asset/role directories. Remove superseded runs only after checking runtime and source/reference dependencies, then update manifests, documentation links and QA fingerprint paths.
- Keep interpreter directives such as Python shebangs and tool-required syntax. Help text used by a CLI is runtime output, not a documentation comment.
- When removing comments, preserve behavior and transfer information that is important for understanding or safely changing the feature.
