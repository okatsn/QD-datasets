#!/usr/bin/env julia
# Generate fake cluster assignments for all binned partitions and k values

using Arrow
using DataFrames
using YAML
using Random

Random.seed!(1234)

const BASE_DIR = dirname(@__DIR__)
const BINNED_DIR = joinpath(BASE_DIR, "fake-data", "binned")
const OUTPUT_DIR = joinpath(BASE_DIR, "fake-data", "cluster_assignments")
const PARAMS_FILE = joinpath(BASE_DIR, "params.yaml")

function load_params()
    return YAML.load_file(PARAMS_FILE)
end

function find_all_binned_files(binned_dir::String)
    # Recursively find all data.arrow files in binned directory
    files = []
    for (root, dirs, filenames) in walkdir(binned_dir)
        for filename in filenames
            if filename == "data.arrow"
                push!(files, joinpath(root, filename))
            end
        end
    end
    return files
end

function parse_hive_path(path::String)
    # Extract criterion and partition from Hive-style path
    # Example: .../criterion=depth_iso/partition=1/data.arrow
    parts = splitpath(path)

    criterion = nothing
    partition = nothing

    for part in parts
        if startswith(part, "criterion=")
            criterion = split(part, "=")[2]
        elseif startswith(part, "partition=")
            partition = parse(Int, split(part, "=")[2])
        end
    end

    return criterion, partition
end

function generate_cluster_assignments_for_partition(binned_file::String, k_values::Vector{Int})
    # Load binned data
    table = Arrow.Table(binned_file)
    df = DataFrame(table)

    # Parse path to get criterion and partition
    criterion, partition = parse_hive_path(binned_file)

    if isnothing(criterion) || isnothing(partition)
        @warn "Could not parse Hive path: $binned_file"
        return
    end

    n_events = nrow(df)

    if n_events == 0
        @warn "Empty partition: criterion=$criterion, partition=$partition"
        return
    end

    # Generate assignments for each k
    for k in k_values
        # Skip if k is larger than number of events
        if k > n_events
            @warn "Skipping k=$k for criterion=$criterion, partition=$partition (only $n_events events)"
            continue
        end

        # Generate random cluster assignments (1 to k)
        cluster_ids = rand(1:k, n_events)

        # Create output DataFrame with event_id and cluster_id
        output_df = DataFrame(
            event_id=df.event_id,
            cluster_id=Int64.(cluster_ids)
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
            "k" => string(k)
        )

        Arrow.write(output_path, output_df; metadata=metadata)
        println("  ✓ $output_path ($(nrow(output_df)) assignments)")
    end
end

function generate_all_cluster_assignments()
    # Load parameters
    params = load_params()
    k_values = params["K_means"]["k"]

    # Find all binned files
    binned_files = find_all_binned_files(BINNED_DIR)
    println("Found $(length(binned_files)) binned partition files")

    # Generate cluster assignments for each partition and k
    for binned_file in binned_files
        println("\nProcessing: $binned_file")
        generate_cluster_assignments_for_partition(binned_file, k_values)
    end

    println("\n✓ All cluster assignments generated in $OUTPUT_DIR")
end

# Run generation
generate_all_cluster_assignments()
