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
# Note: Transformation is done using Chain.jl's @chain macro.
# Schema follows AGENTS.md specification:
#   time (DateTime), lon (Float64), lat (Float64), depth (Float64),
#   mag (Float32), mag_type (String), is_depth_fixed (Bool), quality (String),
#   rms (Float32), erh (Float32), erz (Float32)

df_transformed = @chain df_raw begin
    # Combine date and time into a single DateTime column
    transform([:date, :time] => ByRow((d, t) -> DateTime(d) + t) => :time)

    # Map 'fixed' column: "X" -> true (fixed), "F" -> false (free)
    transform(:fixed => ByRow(x -> x == "X") => :is_depth_fixed)

    # Convert ML to Float32 for mag
    transform(:ML => ByRow(Float32) => :mag)

    # Add constant mag_type column (all events use ML scale)
    # KEYNOTE:
    # - The cost of adding semantic column is super low
    # - "ML" is stored only once and indexed by tiny integers
    # - Maybe adding only a few kB for 1 million rows
    # - This approach allows easy combination with catalog from other sources.
    transform(:ML => (_ -> "ML") => :mag_type)

    # Convert error columns to Float32
    transform(:trms => ByRow(Float32) => :rms)
    transform(:ERH => ByRow(Float32) => :erh)
    transform(:ERZ => ByRow(Float32) => :erz)

    # Extract year for partitioning
    transform(:time => ByRow(year) => :year)

    # Select only the columns we need (including year for partitioning)
    select(:time, :lon, :lat, :depth, :mag, :mag_type, :is_depth_fixed, :quality, :rms, :erh, :erz, :year)
end

# ============================================================================
# 3. Define metadata for Arrow files
# ============================================================================
# Arrow.write accepts:
#   - metadata: table-level metadata (Dict or iterable of string pairs)
#   - colmetadata: column-level metadata (Dict{Symbol => Dict} of string pairs)

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

    # Remove the year column before writing (partition key is encoded in the path)
    df_to_write = select(group, Not(:year))

    # Write Arrow file with metadata
    # - dictencode=true: enables dictionary encoding for string columns (mag_type, quality)
    #   This significantly reduces file size for low-cardinality string columns.
    output_path = joinpath(year_dir, "data.arrow")
    Arrow.write(
        output_path,
        df_to_write;
        metadata=tbl_metadata,
        colmetadata=col_metadata,
        dictencode=true
    )
end
println("\n✓ Processing complete! Data written to $arrow_base")
