using DataFrames, CSV
using OkFiles
using CatalogPreprocess
using Chain
using Dates
using Arrow

# ============================================================================
# 1. Read all raw CSV files
# ============================================================================
raws = filelist(r"GDMScatalog.*\.csv$", dir_data_raw())

df_raw = @chain raws begin
    CSV.read.(_, DataFrame)
    reduce(vcat, _)
end

# ============================================================================
# 2. Transform to target schema
# ============================================================================
df_transformed = @chain df_raw begin
    # Combine date and time into a single DateTime column
    transform(_, [:date, :time] => ((d, t) -> DateTime.(d) .+ t) => :time)

    # Map 'fixed' column: "X" -> true (fixed), "F" -> false (free)
    transform(_, :fixed => (x -> x .== "X") => :is_depth_fixed)

    # Convert ML to Float32 for mag
    transform(_, :ML => (x -> Float32.(x)) => :mag)

    # Add constant mag_type column
    transform(_, _ -> fill("ML", nrow(_)) => :mag_type)

    # Convert error columns to Float32
    transform(_, :trms => (x -> Float32.(x)) => :rms)
    transform(_, :ERH => (x -> Float32.(x)) => :erh)
    transform(_, :ERZ => (x -> Float32.(x)) => :erz)

    # Add year column for partitioning (extract from time)
    transform(_, :time => (t -> year.(t)) => :year)

    # Select only the columns we need (including year for partitioning)
    select(_, :time, :lon, :lat, :depth, :mag, :mag_type, :is_depth_fixed, :quality, :rms, :erh, :erz, :year)
end

# ============================================================================
# 3. Define metadata for Arrow files
# ============================================================================
col_metadata = Dict(
    :time => Dict(
        "unit" => "ISO-8601",
        "description" => "Origin time in UTC"
    ),
    :lon => Dict(
        "unit" => "degrees",
        "description" => "Longitude in Decimal Degrees (WGS84)"
    ),
    :lat => Dict(
        "unit" => "degrees",
        "description" => "Latitude in Decimal Degrees (WGS84)"
    ),
    :depth => Dict(
        "unit" => "km",
        "description" => "Hypocentral depth in km"
    ),
    :mag => Dict(
        "description" => "Event magnitude",
        "note" => "Scale defined in mag_type column"
    ),
    :mag_type => Dict(
        "description" => "Magnitude scale (ML=Local, Mw=Moment)"
    ),
    :is_depth_fixed => Dict(
        "description" => "true if depth was fixed/constrained; false if free"
    ),
    :quality => Dict(
        "description" => "Location quality grade (A, B, C, D)"
    ),
    :rms => Dict(
        "unit" => "seconds",
        "description" => "Root Mean Square residual in seconds"
    ),
    :erh => Dict(
        "unit" => "km",
        "description" => "Horizontal location error in km"
    ),
    :erz => Dict(
        "unit" => "km",
        "description" => "Vertical location error in km"
    )
)

tbl_metadata = Dict(
    "source" => "CWA Seismic Catalog",
    "description" => "Taiwan Central Weather Administration seismic catalog"
)

# ============================================================================
# 4. Partition by year and write Arrow files
# ============================================================================
arrow_base = joinpath(dir_data(), "arrow", "source=cwa")

# Group by year
grouped = groupby(df_transformed, :year)

for group in grouped
    year_val = first(group.year)

    # Create directory for this year
    year_dir = joinpath(arrow_base, "year=$year_val")
    mkpath(year_dir)

    # Remove the year column before writing (it's encoded in the path)
    df_to_write = select(group, Not(:year))

    # Write Arrow file with metadata
    output_path = joinpath(year_dir, "data.arrow")
    Arrow.write(output_path, df_to_write; metadata=tbl_metadata, colmetadata=col_metadata)

    println("✓ Written $(nrow(df_to_write)) events to $output_path")
end

println("\n✓ Processing complete! Data written to $arrow_base")
