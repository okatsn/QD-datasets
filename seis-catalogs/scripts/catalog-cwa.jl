using DataFrames, CSV
using OkFiles
using CatalogPreprocess
using Chain
using Dates
using Arrow

raws = filelist(r"catalog.*\.csv$", dir_data_raw())

df0 = @chain raws begin
    CSV.read.(_, DataFrame)
    reduce(vcat, _)
end

describe(df0)

using Arrow, DataFrames, Dates

# 1. An example DataFrame
df = DataFrame(
    time=[DateTime(2021, 1, 1, 12, 0, 0)],
    mag=[5.1],
    mag_type=["ML"]
)

# 2. Define Column-level Metadata
# This maps :ColumnName => Dict("Key" => "Value")
col_metadata = Dict(
    :time => Dict(
        "unit" => "ISO-8601",
        "description" => "Origin time in UTC"
    ),
    :depth => Dict(
        "unit" => "km",
        "description" => "Depth in km"
    ),
    :mag => Dict(
        "description" => "Event magnitude",
        "note" => "Scale defined in mag_type column"
    ),
    :mag_type => Dict(
        "description" => "Magnitude scale (ML=Local, Mw=Moment)"
    )
)

# 3. Define Table-level Metadata
tbl_metadata = Dict(
    "source" => "CWA Seismic Catalog",
)

# 4. Save with Metadata
Arrow.write(".../data.arrow", df; metadata=tbl_metadata, col_metadata=col_metadata)
