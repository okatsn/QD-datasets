# PLAN.md
Referring:
- (Main) https://gemini.google.com/app/482bcb782530fef4

## Overview

This project builds a hydro-seismicity analysis pipeline for Taiwan. The goal involves creating static "Seismo-Geographic Zones" using Voronoi tessellation on earthquake clusters.

In the current stage, we analyze only seismicity.
We are going to test different sets of criteria for defining "static zones" of seismic active area.
This plan use cut-off or binning approach to handle the "depth" dimension; each set of cut-off/binning criteria is controlled by hyperparameters.
The results against different hyperparameter settings will provide sensitivity of "Seismo-Geographic Zones" to the controlled volume, allowing insights for further exploratory analysis.

This stage includes catalog clustering and get Voronoi sites, involves the following core tasks:

**The plan for the first stage:**
- **Define cut-off/binning criteria:** Using cut-off / binning approach to separate the catalog into subsets by depth.
- **K-Means Clustering:** For each subset, using K-Means clustering to identify seismic clusters spatially (lon & lat).
- **Voronoi Site Points:** Based on the K-Means result get the point of the "center of mass" (centroids) for each cluster.
- **Voronoi Site Boundaries:** Based on the **Voronoi Site Points**, derive the boundaries (as a vector of points for each site point).

> - The centroid is the center of mass *if* the object has uniform density.
> - Although earthquake event magnitude varies, we don't apply any weighting by event magnitude because hydroseismicity is often low-magnitude.


## Data Standards, Workflow Hierarchy and Catalog

- **Workflow Management:**The pipeline is managed by DVC.
- **Paths:** Use Hive-style partitioning (see `AGENTS.md` for schema details).
- **Parameters:** Refer `params.yaml`:
  - `Mc.cutoff`: Global cutoff magnitude.
  - `criteria`: Dictionary of partitioning strategies. Each strategy defines its function name and arguments.


Here is the data schema of the catalog:

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




## Plans for each phase

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

#### Task B (Clustering)

- DVC stage: `cluster_events`
- **Goal:** Perform K-Means on each binned subset for each `k` in `params.yaml`.

#### Task C0 (Coastline Extraction)

- DVC stage: `generate_taiwan_coastline`
- **Goal:** Extract Taiwan coastline from shapefile for clipping Voronoi cells.
- **Input:** `../data/map/Taiwan/`
- **Output:** `assets/taiwan_coastline.geojson`

#### Task C (Geometry)

- DVC stage: `generate_boundaries`
- **Goal:** Compute Voronoi cells from centroids and clip to Taiwan coastline.

