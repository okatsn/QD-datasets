#!/usr/bin/env julia
# Verify the structure and schemas of generated fake data

using Arrow
using DataFrames
using JSON

const BASE_DIR = dirname(@__DIR__)
const FAKE_DATA_DIR = joinpath(BASE_DIR, "fake-data")

function check_file_exists(path::String, description::String)
    full_path = joinpath(FAKE_DATA_DIR, path)
    exists = isfile(full_path)
    status = exists ? "✓" : "✗"
    println("$status $description")
    return exists
end

function check_arrow_schema(path::String, expected_columns::Vector{Symbol})
    full_path = joinpath(FAKE_DATA_DIR, path)
    if !isfile(full_path)
        return false
    end

    table = Arrow.Table(full_path)
    df = DataFrame(table)
    actual_cols = Set(Symbol.(names(df)))
    expected_cols = Set(expected_columns)

    if actual_cols == expected_cols
        println("    Schema: ✓ All columns present")
        return true
    else
        missing_cols = setdiff(expected_cols, actual_cols)
        extra_cols = setdiff(actual_cols, expected_cols)
        if !isempty(missing_cols)
            println("    Schema: ✗ Missing columns: $missing_cols")
        end
        if !isempty(extra_cols)
            println("    Schema: ✗ Extra columns: $extra_cols")
        end
        return false
    end
end

function count_hive_files(base_path::String)
    full_path = joinpath(FAKE_DATA_DIR, base_path)
    if !isdir(full_path)
        return 0
    end

    count = 0
    for (root, dirs, files) in walkdir(full_path)
        if "data.arrow" in files
            count += 1
        end
    end
    return count
end

function verify_structure()
    println("="^70)
    println("  Digital Twin Structure Verification")
    println("="^70)

    # Check main files
    println("\n📁 Main Files:")
    check_file_exists("catalog_all.arrow", "catalog_all.arrow")
    check_arrow_schema("catalog_all.arrow",
        [:event_id, :time, :lon, :lat, :depth, :mag, :mag_type,
            :is_depth_fixed, :quality, :rms, :erh, :erz])

    println("\n📁 Metrics:")
    check_file_exists("metrics/completeness.json", "completeness.json")

    println("\n📁 Assets:")
    check_file_exists("assets/taiwan_coastline.geojson", "taiwan_coastline.geojson")

    # Check Hive-style directories
    println("\n📁 Binned Data (Hive-style):")
    binned_count = count_hive_files("binned")
    println("  Found $binned_count partition files")
    println("  Expected: 3 (depth_iso) + 12 (crustal_split) = 15 total")

    # Sample one binned file
    sample_binned = "binned/criterion=depth_iso/partition=1/data.arrow"
    if check_file_exists(sample_binned, "Sample: depth_iso/partition=1")
        check_arrow_schema(sample_binned, [:event_id, :lat, :lon, :depth])
    end

    println("\n📁 Cluster Assignments:")
    assignments_count = count_hive_files("cluster_assignments")
    println("  Found $assignments_count assignment files")
    expected_assignments = 15 * 16  # 15 partitions × 16 k-values
    println("  Expected: ~$expected_assignments (15 partitions × 16 k-values)")

    # Sample one assignment file
    sample_assignment = "cluster_assignments/criterion=depth_iso/partition=1/k=5/data.arrow"
    if check_file_exists(sample_assignment, "Sample: depth_iso/partition=1/k=5")
        check_arrow_schema(sample_assignment, [:event_id, :cluster_id])
    end

    println("\n📁 Centroids:")
    centroids_count = count_hive_files("centroid_coordinates")
    println("  Found $centroids_count centroid files")
    println("  Expected: ~$expected_assignments (same as assignments)")

    # Sample one centroid file
    sample_centroid = "centroid_coordinates/criterion=depth_iso/partition=1/k=5/data.arrow"
    if check_file_exists(sample_centroid, "Sample: depth_iso/partition=1/k=5")
        check_arrow_schema(sample_centroid, [:cluster_id, :centroid])
    end

    println("\n📁 Voronoi Boundaries:")
    boundaries_count = count_hive_files("voronoi_boundaries")
    println("  Found $boundaries_count boundary files")
    println("  Expected: ~$expected_assignments (same as assignments)")

    # Sample one boundary file
    sample_boundary = "voronoi_boundaries/criterion=depth_iso/partition=1/k=5/data.arrow"
    if check_file_exists(sample_boundary, "Sample: depth_iso/partition=1/k=5")
        check_arrow_schema(sample_boundary, [:cluster_id, :geometry])
    end

    # Summary
    println("\n" * "="^70)
    total_expected = 1 + 1 + 1 + 15 + (expected_assignments * 3)
    println("  Summary")
    println("="^70)
    println("Total files expected: ~$total_expected")
    println("  - 1 catalog_all.arrow")
    println("  - 1 completeness.json")
    println("  - 1 taiwan_coastline.geojson")
    println("  - 15 binned partitions")
    println("  - ~$(expected_assignments) cluster assignments")
    println("  - ~$(expected_assignments) centroids")
    println("  - ~$(expected_assignments) boundaries")
    println("\nVerification complete! Check marks (✓) indicate successful validation.")
end

# Run verification
verify_structure()
