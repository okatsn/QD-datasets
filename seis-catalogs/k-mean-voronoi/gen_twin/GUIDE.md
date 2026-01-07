# Digital Twin Generator - Quick Reference

## TL;DR

```bash
# Generate all fake data
cd /home/jovyan/workspace/seis-catalogs/k-mean-voronoi
julia --project=. gen_twin/generate_all_entrypoint.jl

# Or use the test script (includes validation)
./gen_twin/test.sh
```

## What Was Generated

### 📂 Directory Structure
```
gen_twin/
├── 01_catalog_all.jl              # ✓ Main catalog (500 events)
├── 02_binned.jl                   # ✓ Partitioned by depth (15 files)
├── 03_cluster_assignments.jl      # ✓ K-means assignments (~240 files)
├── 04_centroids.jl                # ✓ Cluster centers (~240 files)
├── 05_voronoi.jl                  # ✓ Polygon boundaries (~240 files)
├── 06_metrics.jl                  # ✓ Completeness metrics (1 JSON)
├── 07_coastline.jl                # ✓ Taiwan boundary (1 GeoJSON)
├── generate_all_entrypoint.jl     # ⭐ Master script
├── verify_structure.jl            # ✓ Validation script
├── test.sh                        # 🧪 Full test suite
├── README.md                      # 📖 Detailed documentation
├── SUMMARY.md                     # 📊 Complete summary
└── GUIDE.md                       # 📘 This file
```

### 📊 Output Files (~736 total)

| Category    | Count | Location                                    |
| ----------- | ----- | ------------------------------------------- |
| Catalog     | 1     | `fake-data/catalog_all.arrow`               |
| Metrics     | 1     | `fake-data/metrics/completeness.json`       |
| Coastline   | 1     | `fake-data/assets/taiwan_coastline.geojson` |
| Binned      | 15    | `fake-data/binned/criterion=*/partition=*/` |
| Assignments | ~240  | `fake-data/cluster_assignments/.../k=*/`    |
| Centroids   | ~240  | `fake-data/centroid_coordinates/.../k=*/`   |
| Boundaries  | ~240  | `fake-data/voronoi_boundaries/.../k=*/`     |

## Common Tasks

### 1. Generate Everything
```bash
cd /home/jovyan/workspace/seis-catalogs/k-mean-voronoi
julia --project=. gen_twin/generate_all_entrypoint.jl
```

### 2. Generate Only Specific Parts
```bash
# Just the catalog
julia --project=. gen_twin/01_catalog_all.jl

# Just binned data (requires catalog)
julia --project=. gen_twin/02_binned.jl

# Metrics only (independent)
julia --project=. gen_twin/06_metrics.jl
```

### 3. Skip Certain Stages
```bash
# Skip metrics (06) and coastline (07)
julia --project=. gen_twin/generate_all_entrypoint.jl --skip 6,7
```

### 4. Regenerate From Scratch
```bash
rm -rf fake-data/
julia --project=. gen_twin/generate_all_entrypoint.jl
```

### 5. Verify Output
```bash
julia --project=. gen_twin/verify_structure.jl
```

### 6. Run Full Test Suite
```bash
./gen_twin/test.sh
```

## Schema Reference

### catalog_all.arrow (Source of Truth)
```julia
event_id::UInt64          # Unique ID
time::DateTime            # UTC timestamp
lon::Float64, lat::Float64, depth::Float64
mag::Float32, mag_type::String
is_depth_fixed::Bool
quality::String
rms::Float32, erh::Float32, erz::Float32
```

### binned/criterion=*/partition=*/data.arrow
```julia
event_id::UInt64
lat::Float64, lon::Float64, depth::Float64
```

### cluster_assignments/.../k=*/data.arrow
```julia
event_id::UInt64
cluster_id::Int64         # 1 to k
```

### centroid_coordinates/.../k=*/data.arrow
```julia
cluster_id::Int64
centroid::Struct{lat::Float64, lon::Float64}
```

### voronoi_boundaries/.../k=*/data.arrow
```julia
cluster_id::Int64
geometry::Binary          # WKB polygon
```

## Troubleshooting

### Missing Dependencies
```bash
cd /home/jovyan/workspace/seis-catalogs/k-mean-voronoi
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Scripts Fail on Empty Partitions
This is expected behavior. Some depth partitions may have no events after Mc filtering. The scripts log warnings but continue.

### Wrong Number of Files
Check `params.yaml`:
- **depth_iso.edges** should have 4 values → 3 partitions
- **crustal_split.cutoff** should have 6 values → 12 partitions (2 per cutoff)
- **K_means.k** should have 16 values

Expected total:
- Binned: 15 files
- Assignments/Centroids/Boundaries: 15 partitions × 16 k-values = 240 each

### Slow Generation
Normal. Processing 15 partitions × 16 k-values = 240 combinations takes ~1-2 minutes.

### Can't Find Arrow.jl or Other Packages
Make sure you're running with `--project=.`:
```bash
julia --project=. gen_twin/01_catalog_all.jl  # ✓ Correct
julia gen_twin/01_catalog_all.jl              # ✗ Wrong (uses global env)
```

## Integration with Real Pipeline

### Testing DVC Stages

1. **Create a test branch of dvc.yaml:**
```yaml
# Replace data/ with fake-data/ in deps
ingest_catalog:
  deps:
    - "../fake-data/arrow/"  # Was "../data/arrow/"
  outs:
    - fake-data/catalog_all.arrow
```

2. **Run DVC stages:**
```bash
dvc repro partition_catalog
dvc repro cluster_events
```

3. **Validate outputs match expected schemas**

### CI/CD Integration

```yaml
# In .github/workflows/test.yml
- name: Generate test data
  run: |
    cd seis-catalogs/k-mean-voronoi
    julia --project=. gen_twin/generate_all_entrypoint.jl

- name: Run DVC pipeline
  run: |
    dvc repro
```

## Customization

### Change Number of Events
Edit `gen_twin/01_catalog_all.jl`:
```julia
generate_catalog_all(n_events::Int=500)  # Change 500 to desired value
```

### Add New Criteria
Edit `gen_twin/02_binned.jl`, add new function:
```julia
function bin_by_custom_logic(df::DataFrame, custom_args)
    # Your logic here
    return binned_dfs
end
```

And update the dispatch:
```julia
if func_name == "bin_by_custom_logic"
    # Handle it
end
```

### Add New k-values
Edit `params.yaml`:
```yaml
K_means:
  k: [5, 6, ..., 25]  # Add more values
```
No code changes needed!

## File Dependencies

```
01_catalog_all.jl (independent)
    ↓
02_binned.jl (needs catalog_all.arrow)
    ↓
03_cluster_assignments.jl (needs binned/)
    ↓ (parallel)
    ├→ 04_centroids.jl (needs binned/ + assignments/)
    │       ↓
    │   05_voronoi.jl (needs centroids/)
    │
06_metrics.jl (independent)
07_coastline.jl (independent)
```

## Performance

- **Generation time:** 1-2 minutes (typical hardware)
- **Disk usage:** ~10-20 MB (500 events)
- **Memory:** < 1 GB RAM required
- **Reproducible:** Always generates identical output (seeded RNG)

## Best Practices

1. **Always run from project root:**
   ```bash
   cd /home/jovyan/workspace/seis-catalogs/k-mean-voronoi
   julia --project=. gen_twin/...
   ```

2. **Verify after generation:**
   ```bash
   julia --project=. gen_twin/verify_structure.jl
   ```

3. **Don't commit fake-data/ to git:**
   Already in `.gitignore`, but be aware.

4. **Regenerate when params.yaml changes:**
   The generator reads params.yaml at runtime.

5. **Use test.sh for CI/CD:**
   It includes all validation steps.

## Documentation

- **README.md**: Detailed user guide
- **SUMMARY.md**: Complete technical summary
- **GUIDE.md**: This quick reference
- **AGENTS.md**: Schema and coding standards (parent directory)
- **PLANS.md**: Project context (parent directory)

## Support

For issues or questions:
1. Check [README.md](README.md) for detailed docs
2. Run `verify_structure.jl` to diagnose problems
3. Check error messages in terminal output
4. Verify `params.yaml` is correct

---

**Quick Start Reminder:**
```bash
cd /home/jovyan/workspace/seis-catalogs/k-mean-voronoi
./gen_twin/test.sh  # Generate + verify in one command
```
