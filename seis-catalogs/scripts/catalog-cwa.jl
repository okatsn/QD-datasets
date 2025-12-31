using DataFrames, CSV
using OkFiles
using CatalogPreprocess
using Chain
using Dates

twshp = Shapefile.Table(dir_data("map/Taiwan/COUNTY_MOI.shp"))
raws = filelist(r"catalog.*\.csv$", dir_data_raw())

df0 = @chain raws begin
    CSV.read.(_, DataFrame)
    reduce(vcat, _)
end
