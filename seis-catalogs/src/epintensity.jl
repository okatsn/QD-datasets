# Refer: https://gemini.google.com/app/1403620729024ba4
"""
    epintensity(ML, depth; ref_ML=7.0, ref_depth=20.0)

Calculate epicentral intensity normalized by a reference event.

Epicentral intensity is computed using the empirical formula:
```
EpiI = c₁ × ML - c₂ × log₁₀(depth)
```

where:
- `c₁ = 1.1` (constant scaling factor)
- `c₂ = (c₁ - 1) × ref_ML / log₁₀(ref_depth)`

The constants are calibrated such that `EpiI == ref_ML` for the reference event,
ensuring that an earthquake with magnitude `ref_ML` at depth `ref_depth` has an
epicentral intensity equal to its magnitude.

# Arguments
- `ML::Real`: Local magnitude of the earthquake
- `depth::Real`: Focal depth in kilometers

# Keyword Arguments
- `ref_ML::Real=7.0`: Magnitude of the reference event (default: ML 7.0)
- `ref_depth::Real=20.0`: Depth of the reference event in kilometers (default: 20 km)

# Returns
- `Real`: Epicentral intensity value

# Examples
```julia
# Calculate epicentral intensity for a ML 5.0 event at 10 km depth
epintensity(5.0, 10.0)

# Use custom reference event (ML 6.5 at 15 km)
epintensity(5.0, 10.0; ref_ML=6.5, ref_depth=15.0)
```

# Reference
The epicentral intensity accounts for both magnitude and depth effects on surface
ground motion intensity at the epicenter.
"""
function epintensity(ML, depth; ref_ML=7.0, ref_depth=20.0, c1=1.1)

    c2 = (c1 - 1) * ref_ML / log10(ref_depth)
    return c1 * ML - c2 * log10(depth)
end
