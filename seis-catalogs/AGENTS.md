# AGENTS.md

## 1. Project Context
`seis-catalogs` is a DVC-managed data registry providing preprocessed seismic catalog data.
It serves as the foundational "off-the-shelf" layer for downstream seismological analysis in Julia.

**Primary Goals:**
1.  **Performance:** Data is stored in Apache Arrow format for zero-copy access.
2.  **Granularity:** Hive-style partitioning allows users to fetch specific subsets of data.

## 2. Architecture & Tech Stack
* **Language:** Julia (Processing logic in `src/`)
* **Data Format:** Apache Arrow (`.arrow` / `.parquet` compatible)
* **Query Engine:** DuckDB (Recommended for reading partitioned data)
* **Orchestration:** DVC (Data Version Control)

## 3. Data Schema (The Contract)

### [CWA catalogs](data/arrow/source=cwa/)

Refers [`catalog-cwa.jl`](scripts/catalog-cwa.jl) and [README](README.md)

## 4. Storage Layout (Hive Partitioning)
Data is organized hierarchically. New data sources or years must follow this pattern to be queryable.

```text
seis-catalogs/
└── data/
    └── arrow/
        └── source={SOURCE_ID}/        # e.g., source=cwa
            ├── year={YYYY}/           # e.g., year=2011
            │   └── data.arrow         # The schema-compliant file
            ├── year={YYYY}/
            │   └── data.arrow
            └── ...
```