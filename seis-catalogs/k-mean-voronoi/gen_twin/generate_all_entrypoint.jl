#!/usr/bin/env julia
# Master entrypoint script to generate all fake data for k-mean-voronoi project

using ArgParse

# CONSTANTS & DEFINITIONS (Global Scope)
const SCRIPT_DIR = @__DIR__
const SCRIPTS = [
    "01_catalog_all.jl",
    "06_metrics.jl",
    "07_coastline.jl",
    "02_binned.jl",
    "03_cluster_assignments.jl",
    "04_centroids.jl",
    "05_voronoi.jl"
]

"""
Defines and returns the ArgParseSettings for the script.
"""
function parse_commandline()
    settings = ArgParseSettings(
        description="Generate all fake data for k-mean-voronoi digital twin",
        exit_after_help=true
    )
    @add_arg_table! settings begin
        "--verbose", "-v"
        help = "enable verbose output"
        action = :store_true
        "--skip"
        help = "comma-separated list of script numbers to skip (e.g., '1,6')"
        default = ""
    end
    return settings
end

"""
Execute a Julia script in the gen_twin directory.
"""
function run_script(script_name::String, verbose::Bool)
    script_path = joinpath(SCRIPT_DIR, script_name)

    if !isfile(script_path)
        @warn "Script not found: $script_path"
        return false
    end

    println("\n" * "="^70)
    println("  Running: $script_name")
    println("="^70)

    try
        if verbose
            run(`julia --project=$(dirname(SCRIPT_DIR)) $script_path`)
        else
            # Capture output and only show if there's an error
            output = read(`julia --project=$(dirname(SCRIPT_DIR)) $script_path`, String)
            println(output)
        end
        return true
    catch e
        @error "Failed to run $script_name" exception = e
        return false
    end
end

"""
Main execution function.
"""
function main(args)
    # Parse command line arguments
    settings = parse_commandline()
    cli_args = parse_args(args, settings)

    verbose = cli_args["verbose"]
    skip_list = if isempty(cli_args["skip"])
        Int[]
    else
        [parse(Int, s) for s in split(cli_args["skip"], ",")]
    end

    println("🔧 Digital Twin Generator for k-mean-voronoi")
    println("Base directory: $(dirname(SCRIPT_DIR))")

    if !isempty(skip_list)
        println("Skipping scripts: $skip_list")
    end

    # Execute scripts in order
    success_count = 0
    total_count = 0

    for (idx, script) in enumerate(SCRIPTS)
        if idx in skip_list
            println("\n⏭️  Skipping: $script")
            continue
        end

        total_count += 1
        if run_script(script, verbose)
            success_count += 1
        else
            println("\n❌ Script failed: $script")
            # Continue with next script instead of aborting
        end
    end

    # Summary
    println("\n" * "="^70)
    println("  Summary")
    println("="^70)
    println("Completed: $success_count / $total_count scripts")

    if success_count == total_count
        println("\n✅ All fake data generated successfully!")
        println("Output location: $(joinpath(dirname(SCRIPT_DIR), "fake-data"))")
    else
        println("\n⚠️  Some scripts failed. Check the output above for details.")
    end
end

# SCRIPT ENTRYPOINT
if !isempty(PROGRAM_FILE) && abspath(PROGRAM_FILE) == @__FILE__
    # --- CLI EXECUTION ---
    println("Running in CLI mode...")
    main(ARGS)
else
    # --- INTERACTIVE EXECUTION (REPL/VSCode) ---
    println("Running in REPL/interactive mode. Using default arguments (empty array).")
    main([])
end
