using DataFrames
using OkFiles
using CairoMakie
using AlgebraOfGraphics
using CatalogPreprocess
using Chain
using Dates
using Shapefile
using Arrow

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

df0 = @chain arrow_files begin
    Arrow.Table.(_)
    DataFrame.(_)
    reduce(vcat, _)
    # Create year_month as NamedTuple from time column
    transform!(:time => ByRow(t -> (year=year(t), month=month(t))) => :year_month)
    # Create epochday from time column
    transform!(:time => ByRow(t -> Dates.date2epochdays(Date(t))) => :epochday)
    # Create depth_bin: 1 for [0,10), 2 for [10,20), etc.
    transform!(:depth => ByRow(d -> floor(Int, d / 10) + 1) => :depth_bin)
    sort!(:mag, rev=true) # ensure small event on top
end

mag_type = df0.mag_type |> unique |> only


# Create month name mapping function
month_labels(months) = [m => Dates.format(Date(2000, m, 1), "u") for m in months]

# transform mag (magnitude)
scaling_base = 3 # `magforward` calculates a quantity where the area of the marker size reflects the event size, with `scaling_base` defines the ratio between the area for `mag = n` and `n +1`.
magforward(x) = sqrt(scaling_base^x) # `sqrt` for calculating the "radius" of the marker from the "size".
maginverse(y) = log(scaling_base, y^2)  # or equivalently: log(x) / log(scaling_base)
magsizerange = (1, 35) # AoG normalize marker size within this range (default to (5,20))

# Global mag limits to keep color and marker size consistent across yearly figures
mag_min = floor(Int, minimum(df0.mag))
mag_max_data = maximum(df0.mag)
mag_max = ceil(Int, mag_max_data)

# MarkerSize ticks must be within the data range of the scale.
# If we use `ceil(maximum(mag))` we can easily create a tick that exceeds the actual data extrema.
markersize_ticks = let
    base = magforward.(mag_min:floor(Int, mag_max_data))
    top = magforward(mag_max_data)
    sort(base)
    # sort(unique(vcat(base, top))) # with an additional marker for largest earthquake.
end

function main()

    # Scatter plot for spatial distribution
    # Use figure-level pagination so scales are fit globally (across all years) and each page is a year.
    years = sort(unique(getfield.(df0.year_month, :year)))
    months = 1:12

    # Facet key used for both layers so the Taiwan basemap is drawn in every panel.
    year_month_levels = [(y, m) for y in years for m in months] # This is more robust than deriving levels from unique(df0.year_month).

    # Duplicate shapefile rows across facets (small: counties × 12 × years).
    twbase = DataFrame(twshp)
    n_map = nrow(twbase)
    twdf = repeat(twbase, outer=length(year_month_levels))
    twdf.year_month = repeat(year_month_levels, inner=n_map)

    eqkmap = data(df0) * mapping(:lon, :lat;
                 markersize=:mag => magforward => mag_type,
                 color=:mag,
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
            colorrange=(mag_min, mag_max), # fixes data → color mapping across pages
        ),
        MarkerSize=(;
            sizerange=magsizerange,
            ticks=markersize_ticks, # transformed tick positions
            tickformat=values -> string.(round.(maginverse.(values); digits=1)),
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
            figure=(; size=(1200, 1000)),
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
