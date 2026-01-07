# Digital Twin Generator for k-mean-voronoi

This directory contains Julia scripts to generate synthetic data that mirrors the production dataset structure for the k-mean-voronoi subproject.

## Purpose

The generated fake data (`./fake-data/`) serves as a lightweight digital twin for:
- **Testing the DVC pipeline** without real data
- **Smoke-testing analysis scripts** with known schemas
- **CI/CD validation** with reproducible synthetic datasets

## Structure

```
gen_twin/
├── generate_all_entrypoint.jl    # Master script - run this!
├── 01_catalog_all.jl              # Generate main catalog with event_id
├── 02_binned.jl                   # Generate partitioned data (Hive-style)
├── 03_cluster_assignments.jl      # Generate cluster assignments
├── 04_centroids.jl                # Generate centroid coordinates
├── 05_voronoi.jl                  # Generate WKB polygon boundaries
├── 06_metrics.jl                  # Generate completeness metrics
└── 07_coastline.jl                # Generate Taiwan coastline GeoJSON
```

## Usage

### Generate All Fake Data

```bash
cd /home/jovyan/workspace/seis-catalogs/k-mean-voronoi
julia --project=. gen_twin/generate_all_entrypoint.jl
```

### Options

```bash
# Verbose output
julia --project=. gen_twin/generate_all_entrypoint.jl --verbose

# Skip specific scripts (e.g., skip coastline and metrics)
julia --project=. gen_twin/generate_all_entrypoint.jl --skip 6,7
```

### Run Individual Scripts

```bash
julia --project=. gen_twin/01_catalog_all.jl
julia --project=. gen_twin/02_binned.jl
# ... etc
```

## Output Structure

The scripts generate data in `fake-data/` mirroring the expected `data/` structure:

```
fake-data/
├── catalog_all.arrow                           # Main catalog (500 events)
├── metrics/
│   └── completeness.json                       # MAXC analysis results
├── assets/
│   └── taiwan_coastline.geojson               # Simplified Taiwan boundary
├── binned/                                     # Hive-style partitioning
│   ├── criterion=depth_iso/
│   │   ├── partition=1/data.arrow             # 0-10 km
│   │   ├── partition=2/data.arrow             # 10-30 km
│   │   └── partition=3/data.arrow             # 30-300 km
│   └── criterion=crustal_split/
│       ├── partition=1/data.arrow             # < 5.0 km (cutoff 1)
│       ├── partition=2/data.arrow             # >= 5.0 km
│       ├── partition=3/data.arrow             # < 10.0 km (cutoff 2)
│       └── ...                                # (12 partitions total)
├── cluster_assignments/                        # For each partition × k
│   └── criterion=<tag>/partition=<n>/k=<k>/data.arrow
├── centroid_coordinates/                       # Cluster centroids
│   └── criterion=<tag>/partition=<n>/k=<k>/data.arrow
└── voronoi_boundaries/                         # WKB polygons
    └── criterion=<tag>/partition=<n>/k=<k>/data.arrow
```

## Data Characteristics

- **Reproducibility:** All scripts use `Random.seed!(1234)`
- **Scale:** 500 events in catalog (sufficient for smoke testing)
- **Geography:** Taiwan region (lat: 22-25°N, lon: 120-122°E)
- **Schema Compliance:** Exact column types match production requirements
- **Metadata:** CRS (EPSG:4326) and Hive-style tags embedded in Arrow files

## Schema Reference

### catalog_all.arrow
- `event_id` (UInt64), `time` (DateTime), `lon`, `lat`, `depth` (Float64)
- `mag` (Float32), `mag_type`, `quality` (String/DictEncoded)
- `is_depth_fixed` (Bool), `rms`, `erh`, `erz` (Float32)

### binned/
- `event_id` (UInt64), `lat`, `lon`, `depth` (Float64)

### cluster_assignments/
- `event_id` (UInt64), `cluster_id` (Int64)

### centroid_coordinates/
- `cluster_id` (Int64), `centroid` (Struct<lat: Float64, lon: Float64>)

### voronoi_boundaries/
- `cluster_id` (Int64), `geometry` (Binary/WKB)

## Notes

- The scripts read `params.yaml` to determine the number of partitions and k-values
- Total files generated: 1 catalog + 3 + 12 binned + (15 partitions × 16 k-values × 3 outputs) = **736 files**
- Execution time: ~1-2 minutes on typical hardware
- Output size: ~10-20 MB (versus production data which may be gigabytes)

## Troubleshooting

**Missing dependencies?**
```bash
cd /home/jovyan/workspace/seis-catalogs/k-mean-voronoi
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

**Clean and regenerate:**
```bash
rm -rf fake-data/
julia --project=. gen_twin/generate_all_entrypoint.jl
```
