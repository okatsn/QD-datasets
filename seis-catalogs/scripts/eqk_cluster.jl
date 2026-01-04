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
# Data Loading
# ============================================================================
twshp = Shapefile.Table(dir_data("map/Taiwan/COUNTY_MOI.shp"))

# Load Arrow files from data/arrow directory
arrow_files = filelistall(r"\.arrow$", dir_data_arrow())

# Read Arrow tables and extract metadata from first file
first_tbl = Arrow.Table(first(arrow_files))
tbl_metadata = Arrow.getmetadata(first_tbl)
col_metadata = Dict(col => Arrow.getmetadata(first_tbl[col]) for col in propertynames(first_tbl))

# Print metadata for reference
println("Table metadata: ", tbl_metadata)
println("Column metadata: ", col_metadata)
