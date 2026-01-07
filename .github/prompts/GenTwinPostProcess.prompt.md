---
agent: agent
---

# Post processing:

## Update `AGENTS.md`

Update the `AGENTS.md` in the **base directory** after fake dataset created, following the example below:

```md
(... existing contents...)
- **Testing:** The validity of the pipeline is tested by running the production logic against a lightweight "Fake Dataset" (`./fake-data`) that mirrors the structure of the real dataset (`./data`).

(... existing contents...)
## File Structure Conventions
- `./data`: Production data (Git-ignored, managed by DVC).
- `./fake-data`: Synthetic data for testing (matches `./data` schema exactly).
```

## Update `Project.toml`

Run `using Pkg; Pkg.add(...)` to add all required julia packages in the **base directory**.

## Update `.gitignore`

Update `.gitignore` in the **base directory** if not.

Example:

```
# Ignore all generated fake data
fake-data/

# But keep the directory structure visible
!fake-data/.gitkeep
```

## Create an entrypoint for all scripts

- Create an empty julia script at `./gen_twin/run_all_entrypoint.jl` if there is no such a script.
- Implement julia script that runs all scripts in `./gen_twin/`
- `./` refers the **base directory**.

