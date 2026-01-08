"""
    bindepth(bin_size)

Return a function that bins depth values into intervals of size `bin_size`.
For depth `d`, returns the floor of the interval `[k*bin_size, (k+1)*bin_size)` containing `d`.

Uses integer division (`div`), which truncates toward zero.

# Examples
```jldoctest
julia> f = bindepth(5);

julia> f(0)
0

julia> f(4.9)
0.0

julia> f(5)
5

julia> f(9.9)
5.0

julia> f(10)
10
```
"""
bindepth(bin_size) = d -> div(d, bin_size) * bin_size
