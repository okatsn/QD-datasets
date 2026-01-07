#!/usr/bin/env julia
# Generate fake completeness metrics (MAXC analysis results)

using JSON
using Random

Random.seed!(1234)

const BASE_DIR = dirname(@__DIR__)
const OUTPUT_FILE = joinpath(BASE_DIR, "fake-data", "metrics", "completeness.json")

function generate_completeness_metrics()
    # Generate fake MAXC (Maximum Curvature) analysis results
    # This represents the magnitude of completeness analysis

    metrics = Dict(
        "method" => "MAXC",
        "description" => "Maximum Curvature method for magnitude of completeness",
        "Mc" => 2.0,  # Magnitude of completeness
        "Mc_range" => [1.8, 2.2],  # Uncertainty range
        "bin_size" => 0.1,
        "total_events" => 500,
        "events_above_Mc" => 450,
        "completeness_percentage" => 90.0,
        "magnitude_histogram" => Dict(
            "bins" => [1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5],
            "counts" => [10, 15, 20, 25, 35, 50, 45, 40, 35, 30, 25]
        ),
        "generated_at" => "2026-01-06T00:00:00Z"
    )

    # Ensure output directory exists
    mkpath(dirname(OUTPUT_FILE))

    # Write JSON file
    open(OUTPUT_FILE, "w") do io
        JSON.print(io, metrics, 2)  # Pretty print with 2-space indent
    end

    println("✓ Generated $OUTPUT_FILE")
end

# Run generation
generate_completeness_metrics()
