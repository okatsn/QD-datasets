using DataFrames, CSV
using OkFiles
using CairoMakie
using AlgebraOfGraphics
using CatalogPreprocess
using Chain
using Dates
using Shapefile

twshp = Shapefile.Table(dir_data("map/Taiwan/COUNTY_MOI.shp"))
raws = filelist(r"catalog.*\.csv$", dir_data_raw())

df0 = @chain raws begin
    CSV.read.(_, DataFrame)
    reduce(vcat, _)
    transform!(:date => ByRow(x -> (year=year(x), month=month(x))) => AsTable)
    transform!(:date => ByRow(Dates.date2epochdays) => :epochday)
    sort!(:ML, rev=true) # ensure small event on top
end

# Create month name mapping function
month_labels(months) = [m => Dates.format(Date(2000, m, 1), "u") for m in months]

# transform ML
mlforward(x) = 10^x
mlinverse(x) = log10(x)
mlsizerange = (2, 30)

function main()

    # Scatter plot for spatial distribution
    # dfi = [dfi for dfi in groupby(df0, :year)][1]
    for dfi in groupby(df0, :year)
        year_value = dfi.year |> unique |> only
        eqkmap = data(dfi) * mapping(:lon, :lat;
                     markersize=:ML => mlforward => "ML", color=:ML, layout=:month) * visual(Scatter; strokewidth=0.1, strokecolor=:white)


        twmap = data(twshp) * mapping(:geometry) * visual(
                    Choropleth,
                    color=(:white, 0), linestyle=:solid, strokecolor=:turquoise2,
                    strokewidth=0.75,
                )

        fig = draw(eqkmap + twmap,
            scales(
                Layout=(; categories=month_labels),
                MarkerSize=(;
                    sizerange=mlsizerange,
                    ticks=[mlforward(i) for i in 1:7],  # Transformed values for tick positions
                    tickformat=values -> string.(mlinverse.(values))  # Display as original ML values
                ), # Rescale marker size in `sizerange`
            );
            axis=(; aspect=AxisAspect(1)),
            figure=(; size=(1500, 1500)))

        Label(fig.figure[0, :], "Year: $year_value", fontsize=30, font=:bold, tellwidth=false)
        display(fig)
    end

    # Prepare intermediate table for heatmap
    df_heat = @chain df0 begin
        transform(:ML => ByRow(mllevel(0.5)) => :ML_level)
        groupby([:year, :month, :ML_level])
        combine(nrow => :count)
    end

    magheat = data(df0) * mapping(:epochday, :ML) * visual(Heatmap)

end



main()
