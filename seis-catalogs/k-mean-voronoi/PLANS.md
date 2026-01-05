Based on your refinement, I plan to use cut-off or binning approach to handle the "depth" dimension, making each cut-off/binning criteria controlled by a set of hyperparameters.
This is basically doing "Static Zones, Dynamic Activity" repeatedly but each time with a different criterion that defines "Static Zones".
The results against different hyperparameter settings will also provide sensitivity of "Seismo-Geographic Zones" to the controlled volume, allowing insights for further exploratory analysis.

Now I'm managing the project workflow for the first stage.
The first stage includes
The project involves the following core tasks.


- Using cut-off / binning approach to separate the catalog into subsets by depth.
- For each subset, using K-Means clustering to identify seismic clusters spatially (lon & lat)
- Based on the K-Means result get the "center of point" for each cluster


Here is the data schema of the catalog for your references:

```md
| Column Name      | Julia Type | Arrow Storage | Description / Constraints                               |
| :--------------- | :--------- | :------------ | :------------------------------------------------------ |
| `time`           | `DateTime` | `Timestamp`   | **UTC**. Combined date and time.                        |
| `lon`            | `Float64`  | `Double`      | Longitude in Decimal Degrees (WGS84).                   |
| `lat`            | `Float64`  | `Double`      | Latitude in Decimal Degrees (WGS84).                    |
| `depth`          | `Float64`  | `Double`      | Hypocentral depth in **km**.                            |
| `mag`            | `Float32`  | `Float`       | Magnitude value.                                        |
| `mag_type`       | `String`   | `DictEncoded` | Scale code (e.g., "ML", "Mw", "Mb").                    |
| `is_depth_fixed` | `Bool`     | `Boolean`     | `true` if depth was fixed/constrained; `false` if free. |
| `quality`        | `String`   | `DictEncoded` | Location quality grade (e.g., "A", "B", "C", "D").      |
| `rms`            | `Float32`  | `Float`       | Root Mean Square residual in **seconds**.               |
| `erh`            | `Float32`  | `Float`       | Horizontal location error in **km**.                    |
| `erz`            | `Float32`  | `Float`       | Vertical location error in **km**.                      |
```