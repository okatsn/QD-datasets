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
All processed Arrow files in `data/arrow/` **must** strictly adhere to this schema.

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

*Note: The partition keys (`source` and `year`) are **not** stored as columns inside the Arrow file to save space. They are inferred from the directory structure during query time.*

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