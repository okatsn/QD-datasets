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

    for dfi in groupby(df0, :year)
        eqkmap = data(dfi) * mapping(:lon, :lat; markersize=:ML, color=:ML, layout=:month) * visual(Scatter; strokewidth=0.1, strokecolor=:white)
        fig = draw(eqkmap; figure=(; size=(1500, 1500)))
        display(fig)
    end

end
