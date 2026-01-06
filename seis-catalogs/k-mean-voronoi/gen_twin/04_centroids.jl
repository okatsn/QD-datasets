#!/usr/bin/env julia
# Generate fake centroid coordinates for all cluster assignments

using Arrow
using DataFrames
using Random

Random.seed!(1234)

const BASE_DIR = dirname(@__DIR__)
const BINNED_DIR = joinpath(BASE_DIR, "fake-data", "binned")
const ASSIGNMENTS_DIR = joinpath(BASE_DIR, "fake-data", "cluster_assignments")
const OUTPUT_DIR = joinpath(BASE_DIR, "fake-data", "centroid_coordinates")

function find_all_assignment_files(assignments_dir::String)
    # Recursively find all data.arrow files
    files = []
    for (root, dirs, filenames) in walkdir(assignments_dir)
        for filename in filenames
            if filename == "data.arrow"
                push!(files, joinpath(root, filename))
            end
        end
    end
    return files
end

function parse_hive_path(path::String)
    # Extract criterion, partition, and k from Hive-style path
    parts = splitpath(path)

    criterion = nothing
    partition = nothing
    k = nothing

    for part in parts
        if startswith(part, "criterion=")
            criterion = split(part, "=")[2]
        elseif startswith(part, "partition=")
            partition = parse(Int, split(part, "=")[2])
        elseif startswith(part, "k=")
            k = parse(Int, split(part, "=")[2])
        end
    end

    return criterion, partition, k
end

function generate_centroids_from_assignments(assignments_file::String)
    # Parse path
    criterion, partition, k = parse_hive_path(assignments_file)

    if isnothing(criterion) || isnothing(partition) || isnothing(k)
        @warn "Could not parse Hive path: $assignments_file"
        return
    end

    # Load corresponding binned data to get lat/lon ranges
    binned_file = joinpath(
        BINNED_DIR,
        "criterion=$criterion",
        "partition=$partition",
        "data.arrow"
    )

    if !isfile(binned_file)
        @warn "Binned file not found: $binned_file"
        return
    end

    binned_table = Arrow.Table(binned_file)
    binned_df = DataFrame(binned_table)

    # Calculate realistic centroid ranges from the binned data
    lat_min, lat_max = extrema(binned_df.lat)
    lon_min, lon_max = extrema(binned_df.lon)

    # Generate k centroids within the data range
    centroids_df = DataFrame(
        cluster_id=Int64.(1:k),
        # Create struct-like nested columns (lat, lon)
        centroid=[(lat=lat_min + (lat_max - lat_min) * rand(),
            lon=lon_min + (lon_max - lon_min) * rand()) for _ in 1:k]
    )

    # Create output path
    output_path = joinpath(
        OUTPUT_DIR,
        "criterion=$criterion",
        "partition=$partition",
        "k=$k",
        "data.arrow"
    )
    mkpath(dirname(output_path))

    # Write with metadata
    metadata = Dict(
        "criterion" => criterion,
        "partition" => string(partition),
        "k" => string(k),
        "crs" => "EPSG:4326"
    )

    Arrow.write(output_path, centroids_df; metadata=metadata)
    println("  ✓ $output_path ($k centroids)")
end

function generate_all_centroids()
    # Find all assignment files
    assignment_files = find_all_assignment_files(ASSIGNMENTS_DIR)
    println("Found $(length(assignment_files)) cluster assignment files")

    # Generate centroids for each assignment file
    for assignment_file in assignment_files
        generate_centroids_from_assignments(assignment_file)
    end

    println("\n✓ All centroids generated in $OUTPUT_DIR")
end

# Run generation
generate_all_centroids()
