using DataFrames
using OkFiles
using CairoMakie
using CairoMakie: FileIO  # Import FileIO from CairoMakie to use explicit format specification
using AlgebraOfGraphics
using CatalogPreprocess
using Chain
using Dates
using Shapefile
using Arrow
"""
Helper function to save PNG with explicit format (avoids FileIO.query issues with special characters like '=' in filenames, that it cannot infer the file extension the file name)
"""
function save_png(filepath::String, fig)
    save(FileIO.File{FileIO.format"PNG"}(filepath), fig)
end

# ============================================================================
# Parameter Settings
# ============================================================================
const DEPTH_BIN_SIZE = 10           # km per depth bin
const depth_bin = bindepth(10)
const MAX_DEPTH = 90                # maximum depth to include (km)
const SCALING_BASE = 3              # ratio between marker area for mag n and n+1
const MARKER_SIZE_RANGE = (1, 35)   # AoG normalize marker size within this range

# Figure layout parameters
const MONTHS_PER_YEAR = 12
const MONTH_COLS = 4                # columns for month-based layout
const DEPTH_BINS_COUNT = 9          # number of depth bins (0-90 km)
const DEPTH_COLS = 3                # columns for depth-based layout

# Figure size parameters
const FIG_SIZE_MONTH = (1200, 1000)
const FIG_SIZE_DEPTH = (1200, 1200)

# ============================================================================
# Data Loading
# ============================================================================
twshp = Shapefile.Table(dir_data("map/Taiwan/COUNTY_MOI.shp"))

function dir_eqkmap(args...)
    path = dir_proj("preview", "eqkmap", args...)
    mkpath(dirname(path))  # Ensure directory exists
    return path
end
# Load Arrow files from data/arrow directory
arrow_files = filelistall(r"\.arrow$", dir_data_arrow())

# Read Arrow tables and extract metadata from first file
first_tbl = Arrow.Table(first(arrow_files))
tbl_metadata = Arrow.getmetadata(first_tbl)
col_metadata = Dict(col => Arrow.getmetadata(first_tbl[col]) for col in propertynames(first_tbl))

# Print metadata for reference
println("Table metadata: ", tbl_metadata)
println("Column metadata: ", col_metadata)

# ============================================================================
# Data Processing
# ============================================================================
df_all = @chain arrow_files begin
    Arrow.Table.(_)
    DataFrame.(_)
    reduce(vcat, _)
    # Create year_month as NamedTuple from time column
    transform!(:time => ByRow(t -> (year=year(t), month=month(t))) => :year_month)
    # Create epochday from time column
    transform!(:time => ByRow(t -> Dates.date2epochdays(Date(t))) => :epochday)
    # depth_bin: floor value of that bin (e.g., 0 for [0,10), 10 for [10,20), etc.)
    transform!(:depth => ByRow(depth_bin) => :depth_bin)
    sort!(:mag, rev=true)  # ensure small events plot on top
end

# Filter to shallowest depths
df0 = subset(df_all, :depth_bin => ByRow(d -> d < MAX_DEPTH); view=true)

# ============================================================================
# Common Derived Values
# ============================================================================
const MAG_TYPE = df0.mag_type |> unique |> only
const MAG_MIN = floor(Int, minimum(df0.mag))
const MAG_MAX_DATA = maximum(df0.mag)
const MAG_MAX = ceil(Int, MAG_MAX_DATA)
const YEARS = sort(unique(getfield.(df0.year_month, :year)))

# Base shapefile DataFrame (reused for faceting)
const TWBASE = DataFrame(twshp)
const N_MAP = nrow(TWBASE)

# ============================================================================
# Common Utilities: Magnitude Scaling
# ============================================================================
"""
Transform magnitude to marker size scale.
Area of marker reflects event size, with SCALING_BASE defining the ratio.
"""
magforward(x) = sqrt(SCALING_BASE^x)

"""Inverse of magforward for tick label formatting."""
maginverse(y) = log(SCALING_BASE, y^2)

# MarkerSize ticks within the data range
const MARKERSIZE_TICKS = sort(magforward.(MAG_MIN:floor(Int, MAG_MAX_DATA)))

# ============================================================================
# Common Utilities: Label Formatters
# ============================================================================
"""Format month number to abbreviated name (e.g., 1 → "Jan")."""
month_label(m::Int) = Dates.format(Date(2000, m, 1), "u")

"""Format depth bin floor value to range string (e.g., 0 → "0-10 km")."""
depth_bin_label(d) = "$(Int(d))-$(Int(d + DEPTH_BIN_SIZE)) km"

# ============================================================================
# Common Utilities: Faceting Helpers
# ============================================================================
"""
Create a DataFrame by repeating the base shapefile data for each facet level.
Returns a DataFrame with the shapefile geometry repeated for each level,
and a column `facet_col` containing the corresponding level.
"""
function repeat_shapefile_for_facets(levels, facet_col::Symbol)
    df = repeat(TWBASE, outer=length(levels))
    df[!, facet_col] = repeat(levels, inner=N_MAP)
    return df
end

# ============================================================================
# Shared AoG Visual Settings
# ============================================================================
const SCATTER_VISUAL = visual(Scatter; strokewidth=0.1, strokecolor=:white)

const BASEMAP_VISUAL = visual(
    Choropleth;
    color=(:white, 0),
    linestyle=:solid,
    strokecolor=:turquoise2,
    strokewidth=0.75,
)

# ============================================================================
# Shared AoG Scale Settings
# ============================================================================
const COLOR_SCALE = (;
    colormap=:darktest,
    colorrange=(MAG_MIN, MAG_MAX),
)

const MARKERSIZE_SCALE = (;
    sizerange=MARKER_SIZE_RANGE,
    ticks=MARKERSIZE_TICKS,
    tickformat=values -> string.(round.(maginverse.(values); digits=1)),
)

# ============================================================================
# Utilities for main() - Monthly Facets
# ============================================================================
const MONTHS = 1:MONTHS_PER_YEAR
const YEAR_MONTH_LEVELS = [(year=y, month=m) for y in YEARS for m in MONTHS]
const YEAR_MONTH_LABELS = YEAR_MONTH_LEVELS .=> month_label.(last.(YEAR_MONTH_LEVELS))

# ============================================================================
# Utilities for main_depth() - Depth Bin Facets
# ============================================================================
const DEPTH_BINS = range(0; step=DEPTH_BIN_SIZE, length=DEPTH_BINS_COUNT)
const YEAR_DEPTH_LEVELS = [(year=y, depth_bin=d) for y in YEARS for d in DEPTH_BINS]
const YEAR_DEPTH_LABELS = YEAR_DEPTH_LEVELS .=> depth_bin_label.(last.(YEAR_DEPTH_LEVELS))

# Precompute df0 with year_depth column for depth faceting
const DF0_WITH_YEAR_DEPTH = transform(
    df0,
    [:year_month, :depth_bin] => ByRow((ym, db) -> (year=ym.year, depth_bin=db)) => :year_depth
)

# ============================================================================
# Main Functions
# ============================================================================

function main()
    # Prepare shapefile data for month faceting
    twdf = repeat_shapefile_for_facets(YEAR_MONTH_LEVELS, :year_month)

    # Build AoG layers
    eqkmap = data(df0) * mapping(
                 :lon, :lat;
                 markersize=:mag => magforward => MAG_TYPE,
                 color=:mag,
                 layout=:year_month,
             ) * SCATTER_VISUAL

    twmap = data(twdf) * mapping(:geometry; layout=:year_month) * BASEMAP_VISUAL

    scl = scales(;
        Color=COLOR_SCALE,
        MarkerSize=MARKERSIZE_SCALE,
        Layout=(;
            categories=YEAR_MONTH_LABELS,
            palette=wrapped(cols=MONTH_COLS),
        ),
    )

    # Paginate: one page per year with 12 month facets
    pag = paginate(eqkmap + twmap, scl; layout=MONTHS_PER_YEAR)

    for (i, year_value) in enumerate(YEARS)
        fig = draw(
            pag, i;
            axis=(; aspect=AxisAspect(1)),
            figure=(; size=FIG_SIZE_MONTH),
        )
        Label(fig.figure[0, :], "Year: $year_value", fontsize=30, font=:bold, tellwidth=false)
        display(fig)
        save_png(dir_eqkmap("slice=month_year=$year_value.png"), fig.figure)
    end

    # Prepare intermediate table for heatmap (kept for future use)
    df_heat = @chain df0 begin
        transform(:mag => ByRow(mllevel(0.5)) => :mag_level)
        transform(:year_month => ByRow(ym -> ym.year) => :year)
        transform(:year_month => ByRow(ym -> ym.month) => :month)
        groupby([:year, :month, :mag_level])
        combine(nrow => :count)
    end

    magheat = data(df0) * mapping(:epochday, :mag) * visual(Heatmap)
end

"""
Create figures sliced by depth_bin for each year.
Each panel shows earthquakes at a specific depth range.
"""
function main_depth()
    # Prepare shapefile data for depth faceting
    twdf_depth = repeat_shapefile_for_facets(YEAR_DEPTH_LEVELS, :year_depth)

    # Build AoG layers
    eqkmap_depth = data(DF0_WITH_YEAR_DEPTH) * mapping(
                       :lon, :lat;
                       markersize=:mag => magforward => MAG_TYPE,
                       color=:mag,
                       layout=:year_depth,
                   ) * SCATTER_VISUAL

    twmap_depth = data(twdf_depth) * mapping(:geometry; layout=:year_depth) * BASEMAP_VISUAL

    scl_depth = scales(;
        Color=COLOR_SCALE,
        MarkerSize=MARKERSIZE_SCALE,
        Layout=(;
            categories=YEAR_DEPTH_LABELS,
            palette=wrapped(cols=DEPTH_COLS),
        ),
    )

    # Paginate: one page per year with 9 depth_bin facets
    pag_depth = paginate(eqkmap_depth + twmap_depth, scl_depth; layout=DEPTH_BINS_COUNT)
    # (i, year_value) = [(i, year_value) for (i, year_value) in enumerate(years)][14]
    for (i, year_value) in enumerate(YEARS)
        fig = draw(
            pag_depth, i;
            axis=(; aspect=AxisAspect(1)),
            figure=(; size=FIG_SIZE_DEPTH),
        )
        Label(fig.figure[0, :], "Year: $year_value (by Depth)", fontsize=30, font=:bold, tellwidth=false)
        display(fig)
        save_png(dir_eqkmap("slice=depth_year=$year_value.png"), fig.figure)
    end
end

# ============================================================================
# Run
# ============================================================================
main()
main_depth()
