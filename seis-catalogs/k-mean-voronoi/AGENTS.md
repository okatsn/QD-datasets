# AGENTS.md

## Project Context
We are building a pipeline to analyze Hydroseismicity in Taiwan.
The goal is to correlate rainfall timeseries with earthquake cluster activity.
We use Julia.
We use DVC for pipeline management.

## Coding Standards and Technology Stack
* **Language:** Julia 1.12+.
* **Data Format:** Apache Arrow (`Arrow.jl`), DataFrames (`DataFrames.jl`)
* **Configuration:** YAML (`YAML.jl`)
* **Geometry:** `VoronoiCells.jl`, `GeometryBasics.jl`, `LibGEOS.jl`
* **Style:** Follow standard Julia style (BlueStyle). Use explicit imports.
* **I/O:**
    - Read parameters from `params.yaml`.
    - Inputs/Outputs must strictly follow the DVC dependency graph paths provided in the prompt.
    - Always ensure directories exist (`mkpath`) before writing.


## Input/Output Rules (Strict)
**Paths:**
- Never hardcode paths. Accept input/output paths as command-line arguments or derive them strictly from the `criterion` and `partition` tags.
- If a script generates a plot, save it to `plots/` folder.

**Arrow Metadata:**
- When saving an Arrow file in Task A/B/C, you **must** write the `criterion` and `partition_id` into the Arrow table metadata.

**Schema Compliance:**
- **Assignments:** Must contain `event_id` (UInt64/Int64) and `cluster_id` (Int).
- **Sites:** Must contain `cluster_id`, `lat`, `lon`.
- **Boundaries:** Must contain `cluster_id`, `geometry` (WKT String).

## Coding Guidelines
- **Dispatching:** Use dictionary dispatch patterns (mapping string keys to functions) for handling different criteria. Avoid giant `if-else` blocks.
- **Reproducibility:** Set `Random.seed!(1234)` before any K-Means or stochastic operation.
- **Memory:** Use `mmap=true` when loading large Arrow files if necessary.

## Error Handling
- Fail fast.
- Check for empty DataFrames before processing. If a bin is empty, log a warning and exit gracefully (produce an empty output file or skip, depending on instruction).