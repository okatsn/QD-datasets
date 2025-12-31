module CatalogPreprocess

using Pkg
include("projdir.jl")
export dir_data, dir_data_intermediate, dir_data_raw, dir_data_catalogs, dir_proj

include("mllevel.jl")
export mllevel

include("epintensity.jl")
export epintensity

end
