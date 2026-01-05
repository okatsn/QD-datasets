# AGENTS.md

## Project Context
We are building a pipeline to analyze Hydroseismicity in Taiwan.
The goal is to correlate rainfall timeseries with earthquake cluster activity.
We use Julia.
We use DVC for pipeline management.

## Coding Standards
1.  **Language:** Julia 1.12+.
2.  **Style:** Follow standard Julia style (BlueStyle). Use explicit imports.
4.  **I/O:**
    - Read parameters from `params.yaml`.
    - Inputs/Outputs must strictly follow the DVC dependency graph paths provided in the prompt.
    - Always ensure directories exist (`mkpath`) before writing.

## DVC Protocol
- Scripts must be atomic (one input stage -> one output stage).
- Do not hardcode paths; assume scripts are run from the project root.
- If a script generates a plot, save it to `plots/` folder.

## Key Libraries
- Data: `DataFrames`, `CSV`, `GeoJSON`
- Math: `Clustering`, `VoronoiCells`, `LibGEOS`
- Config: `YAML`

## Error Handling
- Fail fast. If input data is empty or malformed, throw an error immediately so DVC stops the pipeline.