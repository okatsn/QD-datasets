using Arrow, DataFrames, YAML

# 1. Define the Binning Logic Library
function bin_by_depth_edges(df, edges)
    # Returns a Dictionary of Dict(partition_id => subset_df)
    partitions = Dict{Int,DataFrame}()
    for i in 1:(length(edges)-1)
        lower, upper = edges[i], edges[i+1]
        subset = filter(row -> row.depth >= lower && row.depth < upper, df)
        partitions[i] = subset
    end
    return partitions
end

function bin_by_boolean_filter(df, args)
    cutoff = args["cutoff"]
    return Dict(
        1 => filter(r -> r.depth <= cutoff, df),
        2 => filter(r -> r.depth > cutoff, df)
    )
end

# 2. The Dispatcher Map
CONST_STRATEGIES = Dict(
    "bin_by_depth_edges" => bin_by_depth_edges,
    "bin_by_boolean_filter" => bin_by_boolean_filter
)

# 3. Execution (Mockup)
config = YAML.load_file("params.yaml")
catalog = Arrow.Table("data/catalog.arrow") |> DataFrame

for (tag, settings) in config["criteria"]
    # Retrieve the function
    strategy_func = CONST_STRATEGIES[settings["func"]]

    # Execute
    results = strategy_func(catalog, settings["args"])

    # Save (Task A logic)
    for (pid, sub_df) in results
        # save_arrow(sub_df, tag, pid) ...
    end
end
