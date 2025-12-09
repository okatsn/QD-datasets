using DataFrames, CSV
using OkFiles
using CairoMakie
using AlgebraOfGraphics
using CatalogPreprocess
using Chain
using Dates

raws = filelist(r"catalog.*\.csv$", dir_data_raw())

df0 = @chain raws begin
    CSV.read.(_, DataFrame)
    reduce(vcat, _)
    transform!(:date => ByRow(x -> (year=year(x), month=month(x))) => AsTable)
    transform!(:date => ByRow(Dates.date2epochdays) => :epochday)
    sort!(:ML, rev=true) # ensure small event on top
end

function main()
    eqkmap = data(df0) * mapping(:lon, :lat; markersize=:ML, color=:date) * visual(Scatter) |> draw

end
