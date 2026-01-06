#!/usr/bin/env julia
# Generate fake Voronoi boundaries (WKB polygons) for all centroids

using Arrow
using DataFrames
using Random

Random.seed!(1234)

const BASE_DIR = dirname(@__DIR__)
const CENTROIDS_DIR = joinpath(BASE_DIR, "fake-data", "centroid_coordinates")
const OUTPUT_DIR = joinpath(BASE_DIR, "fake-data", "voronoi_boundaries")

function find_all_centroid_files(centroids_dir::String)
    # Recursively find all data.arrow files
    files = []
    for (root, dirs, filenames) in walkdir(centroids_dir)
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

function point_to_wkb_polygon(center_lat::Float64, center_lon::Float64, radius::Float64=0.1)
    # Create a simple hexagonal polygon around a center point
    # This is a simplified WKB (Well-Known Binary) representation
    # In reality, this should be proper Voronoi cells, but for testing we use simple shapes

    # Generate 6 points around the center (hexagon)
    n_vertices = 7  # 6 + 1 to close the polygon
    angles = range(0, 2π, length=n_vertices)

    vertices = [(center_lat + radius * sin(θ), center_lon + radius * cos(θ)) for θ in angles]

    # Simple WKB encoding: we'll use a byte array
    # For testing purposes, we'll store as a simple binary format
    # Real WKB would have specific header bytes

    # Create a simplified binary representation (not true WKB, but demonstrates the concept)
    # Format: [n_points (UInt32)] [lat1, lon1, lat2, lon2, ...]
    io = IOBuffer()
    write(io, UInt32(n_vertices))
    for (lat, lon) in vertices
        write(io, Float64(lon))  # WKB uses lon, lat order (x, y)
        write(io, Float64(lat))
    end

    return take!(io)
end

function generate_boundaries_from_centroids(centroids_file::String)
    # Parse path
    criterion, partition, k = parse_hive_path(centroids_file)

    if isnothing(criterion) || isnothing(partition) || isnothing(k)
        @warn "Could not parse Hive path: $centroids_file"
        return
    end

    # Load centroids
    centroids_table = Arrow.Table(centroids_file)
    centroids_df = DataFrame(centroids_table)

    # Generate WKB polygons for each centroid
    geometries = []
    for row in eachrow(centroids_df)
        # Extract lat/lon from the nested struct
        center_lat = row.centroid.lat
        center_lon = row.centroid.lon

        # Create a fake Voronoi cell (hexagonal polygon)
        wkb = point_to_wkb_polygon(center_lat, center_lon, 0.15)
        push!(geometries, wkb)
    end

    # Create output DataFrame
    boundaries_df = DataFrame(
        cluster_id=centroids_df.cluster_id,
        geometry=geometries  # Binary/WKB
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
        "crs" => "EPSG:4326",
        "geometry_type" => "Polygon"
    )

    Arrow.write(output_path, boundaries_df; metadata=metadata)
    println("  ✓ $output_path ($k polygons)")
end

function generate_all_boundaries()
    # Find all centroid files
    centroid_files = find_all_centroid_files(CENTROIDS_DIR)
    println("Found $(length(centroid_files)) centroid files")

    # Generate boundaries for each centroid file
    for centroid_file in centroid_files
        generate_boundaries_from_centroids(centroid_file)
    end

    println("\n✓ All Voronoi boundaries generated in $OUTPUT_DIR")
end

# Run generation
generate_all_boundaries()
