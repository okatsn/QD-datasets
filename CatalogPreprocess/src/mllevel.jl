
"""
    mllevel(n)

Return a function that bins values into intervals of size `n`.
For value `x`, returns the lower bound of the interval `[k*n, (k+1)*n)` containing `x`.

# Examples
```jldoctest
julia> f = mllevel(0.5);

julia> f(0.2)
0.0

julia> f(0.5)
0.5

julia> f(0.75)
0.5

julia> f(1.0)
1.0

julia> f(2.3)
2.0
```
"""
mllevel(n) = x -> floor(x / n) * n
