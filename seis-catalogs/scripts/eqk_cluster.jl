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

# ============================================================================
# Parameter Settings
# ============================================================================


const DEPTH_BIN_SIZE = 10           # km per depth bin
# Derived/Dependent parameters
const depth_bin = bindepth(DEPTH_BIN_SIZE)

# ============================================================================
# Data Loading
# ============================================================================
twshp = Shapefile.Table(dir_data("map/Taiwan/COUNTY_MOI.shp"))

# Load Arrow files from data/arrow directory
arrow_files = filelistall(r"\.arrow$", dir_data_arrow())

# Read Arrow tables and extract metadata from first file
(tbl_metadata, col_metadata) = let first_tbl = Arrow.Table(first(arrow_files))
    tbl_metadata = Arrow.getmetadata(first_tbl)
    col_metadata = Dict(col => Arrow.getmetadata(first_tbl[col]) for col in propertynames(first_tbl))
    (tbl_metadata, col_metadata)
end
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
    # # Create epochday from time column
    transform!(:time => ByRow(t -> Dates.date2epochdays(Date(t))) => :epochday)
    # # Create depth_bin: floor value of that bin (e.g., 0 for [0,10), 10 for [10,20), etc.)
    transform!(:depth => ByRow(depth_bin) => :depth_bin)
end
