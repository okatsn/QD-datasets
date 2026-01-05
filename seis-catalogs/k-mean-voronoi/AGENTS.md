# AGENTS.md

## Project Context
We are building a pipeline to analyze Hydroseismicity in Taiwan.
The goal is to correlate rainfall timeseries with earthquake cluster activity.
We use Julia.
We use DVC for pipeline management.

## Coding Standards and Technology Stack
- **Language:** Julia 1.12+.
- **Data Format:**
  - Apache Arrow (`Arrow.jl` in Github repository `apache/arrow-julia`)
  - DataFrames (`JuliaData/DataFrames.jl`): Standard tabular data handling.
- **Configuration:** YAML (`YAML.jl`)
- **Geometry:**
  - `VoronoiCells.jl` (`JuliaGeometry/VoronoiCells.jl`
  - `JuliaGeometry/DelaunayTriangulation.jl`)
  - `GeometryBasics.jl` (`JuliaGeometry/GeometryBasics.jl`), `LibGEOS.jl` (`JuliaGeo/LibGEOS.jl`): For handling the polygon operations (clipping Voronoi cells against the Taiwan coastline).
  - `GeoInterface.jl` (`JuliaGeo/GeoInterface.jl`)
  - `GeoTables.jl` (`JuliaEarth/GeoTables.jl`)
  - `Distances.jl` (`JuliaStats/Distances.jl`): For calculating metric distances if needed.
- **Clustering:**
  - `NearestNeighbors.jl` (`KristofferC/NearestNeighbors.jl`)
  - `Clustering.jl` (`JuliaStats/Clustering.jl`): For kmeans algorithms.
- **Visualization:**
  - `GeoMakie.jl` (`MakieOrg/GeoMakie.jl`)
  - `Makie.jl` (`MakieOrg/Makie.jl`)
- **Style:** Follow standard Julia style (BlueStyle). Use explicit imports.
- **I/O:**
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
- **Sites:** Must contain `cluster_id`, `points`.
- **Boundaries:** Must contain `cluster_id`, `geometry` (WKT String).

## Coding Guidelines
- **Dispatching:** Use dictionary dispatch patterns (mapping string keys to functions) for handling different criteria. Avoid giant `if-else` blocks.
- **Reproducibility:** Set `Random.seed!(1234)` before any K-Means or stochastic operation.
- **Memory:** Use `mmap=true` when loading large Arrow files if necessary.

## Error Handling
- Fail fast.
- Check for empty DataFrames before processing. If a bin is empty, log a warning and exit gracefully (produce an empty output file or skip, depending on instruction).

## Data Schema Definition

Here are the strict schemas to follow.

### Task A0: Ingestion (Source of Truth)

**File:** `data/catalog_all.arrow`
- **Columns:** All columns from your `../data/arrow/source=cwa/**/data.arrow` **plus**:
  - `event_id` (`UInt64`): A unique, immutable identifier for every event.

### Task A: Binning

**File:** `data/binned/criterion=<tag>_partition=<n>.arrow`
- **Columns:**
  - `event_id`: To link back to the main catalog.
  - `lat`, `lon`: The only features needed for K-Means.
  - `depth`: For verification, but strictly not required for 2D K-Means.

**Metadata:** Example: `{"criterion": "depth_iso", "partition": "1", "description": "0-10km"}`

### Task B: Clustering

**File 1 (Traceability):** `data/cluster_assignments/criterion=<tag>_partition=<n>.arrow`
- **Columns:**
  - `event_id`
  - `cluster_id` (a vector of `Int64`): The assigned cluster (1 to $k$).

**File 2 (Geometry Source):** `data/centroid_coordinates/criterion=<tag>_partition=<n>.arrow`
- **Columns:**
  - `cluster_id`: The identifier (1 to $k$).
  - `centroid = (lat, lon)`: The centroid coordinates; a vector of `Tuple{Float64, Float64}`.

#### Task C: The Geometry Boundaries

**File:** `data/voronoi_boundaries/criterion=<tag>_partition=<n>.arrow`
- **Columns:**
  - `cluster_id`: Link to the site.
  - `geometry = (lat, lon)`: WKB format; a vector of `Tuple{Float64, Float64}`.
    - Note: Ensure the first and last points are identical (closed loop) to satisfy standard GIS requirements.
