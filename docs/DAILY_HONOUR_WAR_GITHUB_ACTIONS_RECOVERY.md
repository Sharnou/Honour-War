# Daily Honour War Upgrade — GitHub Actions Fresh-Run Recovery Role

## Permanent rule

GitHub Actions recovery is part of every Daily Honour War Upgrade. CI failures are always repaired against the newest reachable `main` commit. Do not use an old failed run as the primary fix target.

## Fresh-commit rule

When an Action fails:
1. Identify the actual failing step and source commit.
2. Inspect the current `main` tree, not only the failing run's checkout.
3. Fix the root cause in the current code.
4. Commit the fix to a new commit on `main`.
5. Validate the new commit with a **fresh Actions run**.
6. Never treat a rerun of an old SHA as proof that the current `main` is healthy.

A rerun of an old job may be used only as diagnostic evidence; the acceptance run must execute against the newly fixed commit.

## Three-attempt escape rule

For one root-cause signature, allow at most **3 correction attempts** on the same validation path.

An attempt means:
- a concrete code/config/workflow correction is committed;
- a fresh Actions run executes that new commit;
- the failure signature is evaluated.

Do not make blind fourth edits to the same failing path.

After the third failed fresh run with the same or materially equivalent root-cause signature:
- stop editing that path for the current cycle;
- record the three attempts and their failure signatures;
- move to the next fresh Actions validation path or a different independent workflow;
- re-evaluate the problem from that new execution context before making another fix.

The goal is to escape repetitive repair loops, not to conceal a failure. A failure must remain visible and traceable.

## Fresh validation ladder

Use this order when available:

**1. Godot project validation**
- Godot 4.7.2 stable.
- Script/class/autoload parsing.
- Scene/resource loading.
- SS rental regression QA.

**2. GLB semantic/PBR validation**
- hero path/class/tier validation;
- hero node requirements;
- pet and monster structure;
- embedded material/image checks;
- generated asset count and binary GLB checks.

**3. Final GLB asset build**
- Visual RAG;
- Blender generation;
- PBR texture embedding;
- semantic gate;
- manifest;
- CI artifact.

**4. Windows build and launch validation**
- Godot 4.7.2 export;
- executable creation;
- launch smoke test;
- artifact publication.

If a path fails repeatedly, leave that path after three fresh attempts and continue with the next independent validation path rather than repeatedly rerunning or patching the same stale Action.

## Source-of-truth rule

The acceptance state is always the newest successful validation of the newest intended `main` commit. Historical successful runs on older commits are evidence only; they are not current release validation.

## Daily role integration

Every Daily Honour War Upgrade must:
- inspect current Action failures before changing code;
- use the newest `main` as the source of truth;
- distinguish stale-run failures from current-commit failures;
- make a new commit before acceptance validation;
- use fresh Actions for verification;
- enforce the three-attempt escape rule;
- continue to the next independent fresh Actions path after the third failed attempt;
- preserve the failure signature in the upgrade record.

## Hard rejection conditions

A Daily Upgrade must not report the project as CI-healthy when:
- only an old commit passed;
- only a rerun of the stale failing job passed;
- the current `main` commit has not received a fresh validation run;
- the same root-cause path has been blindly patched more than three times without changing validation context.

This recovery role is permanent and applies to all future Daily Honour War Upgrades.
