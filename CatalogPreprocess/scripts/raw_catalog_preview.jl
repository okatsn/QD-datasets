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
    transform!([:year, :month] => ByRow(tuple) => :year_month)
    sort!(:ML, rev=true) # ensure small event on top
end

# Create month name mapping function
month_labels(months) = [m => Dates.format(Date(2000, m, 1), "u") for m in months]

# transform ML
scaling_exponent = 2
mlforward(x) = scaling_exponent^x
mlinverse(y) = log(scaling_exponent, y)  # or equivalently: log(x) / log(scaling_exponent)
mlsizerange = (1, 40) # AoG normalize marker size within this range (default to (5,20))

# Global ML limits to keep color and marker size consistent across yearly figures
ml_min = floor(Int, minimum(df0.ML))
ml_max_data = maximum(df0.ML)
ml_max = ceil(Int, ml_max_data)

# MarkerSize ticks must be within the data range of the scale.
# If we use `ceil(maximum(ML))` we can easily create a tick that exceeds the actual data extrema.
markersize_ticks = let
    base = mlforward.(ml_min:floor(Int, ml_max_data))
    top = mlforward(ml_max_data)
    sort(unique(vcat(base, top)))
end

function main()

    # Scatter plot for spatial distribution
    # Use figure-level pagination so scales are fit globally (across all years) and each page is a year.
    years = sort(unique(df0.year))
    months = 1:12

    # Facet key used for both layers so the Taiwan basemap is drawn in every panel.
    year_month_levels = [(y, m) for y in years for m in months]

    # Duplicate shapefile rows across facets (small: counties × 12 × years).
    twbase = DataFrame(twshp)
    n_map = nrow(twbase)
    twdf = repeat(twbase, outer=length(year_month_levels))
    twdf.year_month = repeat(year_month_levels, inner=n_map)

    eqkmap = data(df0) * mapping(:lon, :lat;
                 markersize=:ML => mlforward => "ML",
                 color=:ML,
                 layout=:year_month,
             ) * visual(Scatter; strokewidth=0.1, strokecolor=:white)

    twmap = data(twdf) * mapping(:geometry, layout=:year_month) * visual(
                Choropleth,
                color=(:white, 0),
                linestyle=:solid,
                strokecolor=:turquoise2,
                strokewidth=0.75,
            )

    scl = scales(
        Color=(;
            colormap=:darktest,
            colorrange=(ml_min, ml_max), # fixes data → color mapping across pages
        ),
        MarkerSize=(;
            sizerange=mlsizerange,
            ticks=markersize_ticks, # transformed tick positions
            tickformat=values -> string.(round.(mlinverse.(values); digits=1)),
        ),
        Layout=(;
            # Keep month panels fixed (12 per year) and label by month only.
            categories=year_month_levels .=> Dates.format.(Date.(2000, last.(year_month_levels), 1), "u"),
            palette=wrapped(cols=4),
        ),
    )

    # One page per year: 12 (year, month) facets per page, ordered by year then month.
    pag = paginate(eqkmap + twmap, scl; layout=12)

    # (i, year_value) = [(i, year_value) for (i, year_value) in enumerate(years)][14]
    for (i, year_value) in enumerate(years)
        fig = draw(
            pag,
            i;
            axis=(; aspect=AxisAspect(1)),
            figure=(; size=(1500, 1500)),
        )
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
