Based on your refinement, I plan to use cut-off or binning approach to handle the "depth" dimension, making each cut-off/binning criteria controlled by a set of hyperparameters.
This is basically doing "Static Zones, Dynamic Activity" repeatedly but each time with a different criterion that defines "Static Zones".
The results against different hyperparameter settings will also provide sensitivity of "Seismo-Geographic Zones" to the controlled volume, allowing insights for further exploratory analysis.

Now I'm managing the project workflow for the first stage.
The first stage includes catalog clustering and get Voronoi sites, involves the following core tasks:

**The plan for the first stage:**
- **Define cut-off/binning criteria:** Using cut-off / binning approach to separate the catalog into subsets by depth.
- **K-Means Clustering:** For each subset, using K-Means clustering to identify seismic clusters spatially (lon & lat).
- **Voronoi Site Points:** Based on the K-Means result get the point of the "center of mass" (centroids) for each cluster.
- **Voronoi Site Boundaries:** Based on the **Voronoi Site Points**, derive the boundaries (as a vector of points for each site point).

For the first stage, I have one remaining question that need to be clarified:
- The centroid is the center of mass *if* the object has uniform density. However, earthquake event magnitude varies. Is applying weighting by event magnitude physically reasonable for my research objective?

After answer this question and update your understanding,
- refine **the plan for the first stage**
- suggest a list of Julia packages that are required/recommended to complete all jobs
- split the plan into tasks that can be done separately:
  - I use DVC to manage the workflow
  - I plan to dispatch tasks to different sets of AI/LLM agents, so ensure the defined task to be "dispatchable"
  - Draft a general `AGENTS.md` for all agents. Prefer simplicity and avoid overly verbose.



Here is the data schema of the catalog for your references:

```md
| Column Name      | Julia Type | Arrow Storage | Description / Constraints                               |
| :--------------- | :--------- | :------------ | :------------------------------------------------------ |
| `time`           | `DateTime` | `Timestamp`   | **UTC**. Combined date and time.                        |
| `lon`            | `Float64`  | `Double`      | Longitude in Decimal Degrees (WGS84).                   |
| `lat`            | `Float64`  | `Double`      | Latitude in Decimal Degrees (WGS84).                    |
| `depth`          | `Float64`  | `Double`      | Hypocentral depth in **km**.                            |
| `mag`            | `Float32`  | `Float`       | Magnitude value.                                        |
| `mag_type`       | `String`   | `DictEncoded` | Scale code (e.g., "ML", "Mw", "Mb").                    |
| `is_depth_fixed` | `Bool`     | `Boolean`     | `true` if depth was fixed/constrained; `false` if free. |
| `quality`        | `String`   | `DictEncoded` | Location quality grade (e.g., "A", "B", "C", "D").      |
| `rms`            | `Float32`  | `Float`       | Root Mean Square residual in **seconds**.               |
| `erh`            | `Float32`  | `Float`       | Horizontal location error in **km**.                    |
| `erz`            | `Float32`  | `Float`       | Vertical location error in **km**.                      |
```





# PLAN.md

Referring:
- (Main) https://gemini.google.com/app/482bcb782530fef4

## Project Overview
This project builds a hydro-seismicity analysis pipeline for Taiwan. The goal involves creating static "Seismo-Geographic Zones" using Voronoi tessellation on earthquake clusters.

## Workflow Hierarchy
The pipeline is managed by DVC. Tasks must be atomic.

### Phase 0: Foundation

####  Task 0 (Exploratory)

- DVC stage: `analyze_completeness`
- **Goal:** Determine the optimal Magnitude of Completeness ($M_c$).
- **Output:** Report/Plots (Does not block the pipeline; informs `params.yaml`).
- **Method:**
  * MAXC (Maximum Curvature): Compute a histogram of magnitudes with a bin size of 0.1. The $M_c$​ is simply the bin center with the highest frequency.

#### Task A0 (Ingestion)

- DVC stage: `ingest_catalog`
- **Goal:** Convert raw data to a single Arrow file and attach unique `event_id`.
- **Input:** `../data/arrow/source=cwa/**/data.arrow`
- **Output:**
      * a single `catalog_all.arrow` file with additional unique `event_id` column.

### Phase 1: Spatial Partitioning

#### Task A (Binning)

- DVC stage: `partition_catalog`
- **Goal:** Filter catalog by $M_c$ and split into subsets based on `criteria` defined in `params.yaml`.
- **Output:**
- `data/binned/criterion=<tag>_partition=<n>.arrow` (Metadata must include partition info).

#### Task B (Clustering)

- DVC stage: `cluster_events`
- **Goal:** Perform K-Means on each binned subset.
- **Input:** `data/binned/*.arrow`
- **Output 1:** `data/cluster_assignments/...arrow` (Map: `event_id` -> `cluster_id`)
- **Output 2:** `data/centroid_coordinates/...arrow` (Map: `cluster_id` -> `points`)

#### Task C (Geometry)

- DVC stage: `generate_boundaries`
- **Goal:** Compute Voronoi cells from sites and clip to Taiwan region.
- **Input:** `data/centroid_coordinates/*.arrow`, `assets/taiwan_coastline.geojson`
- **Output:** `data/voronoi_boundaries/...arrow` (Columns: `cluster_id`, `geometry`)

## Data Standards
* **Format:** All intermediate data must be **Apache Arrow**.
* **Metadata:** Every Arrow file must contain metadata keys describing its `criterion` and `partition`.

## Parameters (`params.yaml`)
* `Mc`: Global cutoff magnitude.
* `criteria`: Dictionary of partitioning strategies. Each strategy defines its function name and arguments.