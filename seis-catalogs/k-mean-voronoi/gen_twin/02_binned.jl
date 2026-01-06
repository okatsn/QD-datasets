#!/usr/bin/env julia
# Generate fake binned data following Hive-style partitioning

using Arrow
using DataFrames
using YAML
using Random

Random.seed!(1234)

const BASE_DIR = dirname(@__DIR__)
const CATALOG_FILE = joinpath(BASE_DIR, "fake-data", "catalog_all.arrow")
const OUTPUT_DIR = joinpath(BASE_DIR, "fake-data", "binned")
const PARAMS_FILE = joinpath(BASE_DIR, "params.yaml")

function load_params()
    return YAML.load_file(PARAMS_FILE)
end

function apply_mc_filter(df::DataFrame, mc::Float64)
    return filter(row -> row.mag >= mc, df)
end

function bin_by_depth_edges(df::DataFrame, edges::Vector)
    # Create bins based on depth edges
    # edges = [0, 10, 30, 300] creates 3 bins: [0,10), [10,30), [30,300)
    n_bins = length(edges) - 1
    binned_dfs = Dict{Int,DataFrame}()

    for i in 1:n_bins
        lower = edges[i]
        upper = edges[i+1]
        binned_dfs[i] = filter(row -> lower <= row.depth < upper, df)
    end

    return binned_dfs
end

function bin_by_boolean_filter(df::DataFrame, cutoffs::Vector)
    # Each cutoff creates 2 partitions: shallow (< cutoff), deep (>= cutoff)
    # We'll generate separate outputs for each cutoff
    results = Dict{Tuple{Int,Float64},DataFrame}()

    for (idx, cutoff) in enumerate(cutoffs)
        # Partition 1: shallow (< cutoff)
        results[(1, cutoff)] = filter(row -> row.depth < cutoff, df)
        # Partition 2: deep (>= cutoff)
        results[(2, cutoff)] = filter(row -> row.depth >= cutoff, df)
    end

    return results
end

function generate_binned_data()
    # Load catalog
    catalog_table = Arrow.Table(CATALOG_FILE)
    catalog_df = DataFrame(catalog_table)

    # Load parameters
    params = load_params()
    mc = params["Mc"]["cutoff"][1]  # Use first Mc value
    criteria = params["criteria"]

    # Apply Mc filter
    filtered_df = apply_mc_filter(catalog_df, mc)
    println("Filtered catalog: $(nrow(filtered_df)) events with mag >= $mc")

    # Process each criterion
    for (criterion_name, criterion_config) in criteria
        func_name = criterion_config["func"]
        args = criterion_config["args"]

        println("\n Processing criterion: $criterion_name")

        if func_name == "bin_by_depth_edges"
            edges = args["edges"]
            bins = bin_by_depth_edges(filtered_df, edges)

            for (partition_id, bin_df) in bins
                # Select only required columns: event_id, lat, lon, depth
                output_df = select(bin_df, :event_id, :lat, :lon, :depth)

                # Create output path following Hive-style
                output_path = joinpath(OUTPUT_DIR, "criterion=$criterion_name", "partition=$partition_id", "data.arrow")
                mkpath(dirname(output_path))

                # Write with metadata
                metadata = Dict(
                    "criterion" => criterion_name,
                    "partition" => string(partition_id),
                    "description" => "$(edges[partition_id])-$(edges[partition_id+1])km",
                    "crs" => "EPSG:4326"
                )

                Arrow.write(output_path, output_df; metadata=metadata)
                println("  ✓ $output_path ($(nrow(output_df)) events)")
            end

        elseif func_name == "bin_by_boolean_filter"
            cutoffs = args["cutoff"]
            # For crustal_split, we treat each cutoff as creating a separate set of partitions
            # But we need to flatten this into the Hive structure
            # Strategy: Use the cutoff value encoded in the path or metadata

            for (idx, cutoff) in enumerate(cutoffs)
                shallow_df = filter(row -> row.depth < cutoff, filtered_df)
                deep_df = filter(row -> row.depth >= cutoff, filtered_df)

                # We'll create partitions based on index position in cutoff array
                # partition=1 for shallow, partition=2 for deep, but we need unique paths
                # Solution: encode cutoff in partition number or create subfolders

                # Simplified: use linear numbering across all cutoffs
                # Partition IDs: 1, 2 (cutoff 1), 3, 4 (cutoff 2), etc.
                partition_shallow = (idx - 1) * 2 + 1
                partition_deep = (idx - 1) * 2 + 2

                for (partition_id, bin_df, desc) in [
                    (partition_shallow, shallow_df, "< $(cutoff)km"),
                    (partition_deep, deep_df, ">= $(cutoff)km")
                ]
                    output_df = select(bin_df, :event_id, :lat, :lon, :depth)

                    output_path = joinpath(OUTPUT_DIR, "criterion=$criterion_name", "partition=$partition_id", "data.arrow")
                    mkpath(dirname(output_path))

                    metadata = Dict(
                        "criterion" => criterion_name,
                        "partition" => string(partition_id),
                        "description" => desc,
                        "cutoff" => cutoff,
                        "crs" => "EPSG:4326"
                    )

                    Arrow.write(output_path, output_df; metadata=metadata)
                    println("  ✓ $output_path ($(nrow(output_df)) events)")
                end
            end
        end
    end

    println("\n✓ All binned data generated in $OUTPUT_DIR")
end

# Run generation
generate_binned_data()
