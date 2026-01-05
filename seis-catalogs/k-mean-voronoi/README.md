# README

## CHECKPOINT
- Data format: Ensure coordinates are consistently in TWD97 (EPSG:3826), or WGS84 (EPSG:4326) for standard Lat/Lon.
- You may need a layer converting [lat,lon] to a projected coordinate system.

### Magnitude of Completeness

There are Magnitude of Completeness ($M_c$) contains the following three following methods:
- Maximum Curvature (MAXC): Finding the magnitude bin with the highest frequency of events.
- Goodness-of-Fit Test (GFT): Comparing the observed frequency-magnitude distribution to a synthetic Gutenberg-Richter distribution.
- b-value Stability: Calculating b-values for different cut-off magnitudes to see where they stabilize.

KEYNOTE:
- `ObsPy` is the king of data retrieval.

Referring
- (Main) https://gemini.google.com/app/349cb78e08cc63fd
- https://gemini.google.com/app/bfb0d043127278be
