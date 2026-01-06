---
applyTo: '**/gen_twin/*.jl'
---


# Julia Fake Data Guidelines

## ApplyTo
Files matching data generation scripts: `**/gen_twin/*.jl`.

## Libraries
- **Arrow:** Use `Arrow.jl` for reading/writing binary data.
- **DataFrames:** Use `DataFrames.jl` for in-memory construction.
- **Dates:** Use standard `Dates` library for realistic timestamps.

## Pattern: Generating Arrow Files

When creating fake Arrow files, explicitly define types to match the production schema.

## Base Directory

- The base directory is default to be the parent directory of `gen_twin`. Thus, always define `BASE_DIR` as `dirname(@__DIR__)`.
- This is critical for all script in `**/gen_twin/*.jl` to run correctly in BOTH
    - CLI mode (i.e., `julia --project=./ gen_twin/01_whatever.jl`)
    - REPL/interactive mode.


## Example

```julia
using Arrow, DataFrames, Dates, Random

const BASE_DIR = dirname(@__DIR__) # Define the base directory (i.e., `gen_twin/../`).
const OUTPUT_FILE = joinpath(BASE_DIR, "fake-data", "catalog_all.arrow")


# 1. Define exact schema types (Crucial for DVC compatibility)
df = DataFrame(
    id = Int32[1, 2, 3], # Match Int32 vs Int64 carefully
    timestamp = [DateTime(2023,1,1), DateTime(2023,1,2), DateTime(2023,1,3)],
    value = Float64[10.5, 20.0, 15.2]
)

# 2. Ensure directory exists
mkpath("fake-data/arrow/source=cwa/year=2011")

# 3. Write
Arrow.write("fake-data/arrow/source=cwa/year=2011/data.arrow", df)
```