#!/usr/bin/env julia
# Generate fake catalog_all.arrow with the complete schema

using Arrow
using DataFrames
using Dates
using Random

Random.seed!(1234)

# Output path
const BASE_DIR = dirname(@__DIR__)
const OUTPUT_FILE = joinpath(BASE_DIR, "fake-data", "catalog_all.arrow")

function generate_catalog_all(n_events::Int=500)
    # Generate fake earthquake catalog matching the schema
    start_time = DateTime(2011, 1, 1)
    end_time = DateTime(2025, 12, 31)
    time_range = end_time - start_time

    df = DataFrame(
        event_id=UInt64.(1:n_events),  # Unique immutable identifier
        time=[start_time + Millisecond(rand(0:Dates.value(time_range))) for _ in 1:n_events],
        lon=120.0 .+ 2.0 .* rand(n_events),  # Taiwan longitude range ~120-122°E
        lat=22.0 .+ 3.0 .* rand(n_events),   # Taiwan latitude range ~22-25°N
        depth=rand(n_events) .* 50.0,        # 0-50 km depth range
        mag=Float32.(1.5 .+ 3.5 .* rand(n_events)),  # Magnitude 1.5-5.0
        mag_type=rand(["ML", "Mw", "Mb"], n_events),
        is_depth_fixed=rand(Bool, n_events),
        quality=rand(["A", "B", "C", "D"], n_events),
        rms=Float32.(0.1 .+ 0.5 .* rand(n_events)),  # RMS 0.1-0.6 seconds
        erh=Float32.(0.5 .+ 2.0 .* rand(n_events)),  # Horizontal error 0.5-2.5 km
        erz=Float32.(1.0 .+ 3.0 .* rand(n_events))   # Vertical error 1.0-4.0 km
    )

    # Ensure output directory exists
    mkpath(dirname(OUTPUT_FILE))

    # Write Arrow file with CRS metadata (WGS84)
    metadata = Dict(
        "crs" => "EPSG:4326",
        "description" => "Synthetic catalog for testing",
        "generated_at" => string(now())
    )

    Arrow.write(OUTPUT_FILE, df; metadata=metadata)
    println("✓ Generated $OUTPUT_FILE with $n_events events")

    return df
end

# Run generation
generate_catalog_all()
