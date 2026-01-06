#!/usr/bin/env julia
# Generate fake Taiwan coastline GeoJSON

using JSON
using Random

Random.seed!(1234)

const BASE_DIR = dirname(@__DIR__)
const OUTPUT_FILE = joinpath(BASE_DIR, "fake-data", "assets", "taiwan_coastline.geojson")

function generate_taiwan_coastline()
    # Generate a simplified polygon representing Taiwan's coastline
    # Real Taiwan is roughly between:
    # Lat: 22°N - 25°N
    # Lon: 120°E - 122°E

    # Create a simplified coastline polygon (counterclockwise for exterior ring)
    coordinates = [
        [120.0, 22.0],   # SW corner
        [120.5, 21.9],   # S coast
        [121.0, 22.0],
        [121.5, 22.5],   # SE
        [122.0, 23.0],   # E coast
        [122.0, 23.5],
        [121.8, 24.0],
        [121.5, 24.5],   # NE
        [121.0, 25.0],   # N coast
        [120.5, 25.0],
        [120.2, 24.5],   # NW
        [120.0, 24.0],
        [120.0, 23.5],   # W coast
        [120.0, 23.0],
        [120.0, 22.5],
        [120.0, 22.0]    # Close the polygon
    ]

    # Create GeoJSON structure
    geojson = Dict(
        "type" => "FeatureCollection",
        "features" => [
            Dict(
                "type" => "Feature",
                "properties" => Dict(
                    "name" => "Taiwan",
                    "type" => "coastline",
                    "generated" => true
                ),
                "geometry" => Dict(
                    "type" => "Polygon",
                    "coordinates" => [coordinates]  # Array of rings (only one exterior ring)
                )
            )
        ],
        "crs" => Dict(
            "type" => "name",
            "properties" => Dict(
                "name" => "EPSG:4326"
            )
        )
    )

    # Ensure output directory exists
    mkpath(dirname(OUTPUT_FILE))

    # Write GeoJSON file
    open(OUTPUT_FILE, "w") do io
        JSON.print(io, geojson, 2)  # Pretty print
    end

    println("✓ Generated $OUTPUT_FILE")
end

# Run generation
generate_taiwan_coastline()
