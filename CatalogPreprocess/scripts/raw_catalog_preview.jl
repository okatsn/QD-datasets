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

# Create month name mapping function
month_labels(months) = [m => Dates.format(Date(2000, m, 1), "u") for m in months]

function main()

    # Scatter plot for spatial distribution
    for dfi in groupby(df0, :year)
        year_value = dfi.year |> unique |> only
        eqkmap = data(dfi) * mapping(:lon, :lat; markersize=:ML, color=:ML, layout=:month) * visual(Scatter; strokewidth=0.1, strokecolor=:white)



        fig = draw(eqkmap,
            scales(Layout=(; categories=month_labels));
            figure=(; size=(1500, 1500)))

        Label(fig.figure[0, :], "Year: $year_value", fontsize=30, font=:bold, tellwidth=false)
        display(fig)
    end

    # Prepare intermediate table for heatmap
    df_heat = @chain df0 begin
        transform(:ML => ByRow(x -> floor(x / 0.5) * 0.5) => :ML_level)
        groupby([:year, :month, :ML_level])
        combine(nrow => :count)
    end

    magheat = data(df0) * mapping(:epochday, :ML) * visual(Heatmap)

end



main()
