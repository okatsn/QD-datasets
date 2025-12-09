
"""
Return a function that bins ML values into `n` increments.
For example, `mllevel(0.5)(0.2)` returns `0`, indicating `0<= 0.2 < 0.5`;
`mllevel(0.5)(0.75)` returns `0.5`, indicating `0.5<= 0.75 < 1.0`.
"""
mllevel(n) = x -> floor(x / n) * n
