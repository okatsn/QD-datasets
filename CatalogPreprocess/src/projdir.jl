dir_proj(args...) = pkgdir(CatalogPreprocess, args...)
dir_data(args...) = dir_proj("data", args...)
dir_data_intermediate(args...) = dir_proj("data", "intermediate", args...)
dir_data_raw(args...) = dir_proj("data", "raw", args...)
