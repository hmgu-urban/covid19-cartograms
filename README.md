# Making Global Disparities Visible: COVID-19 Cartograms

This repository provides reproducible R code for generating continuous area cartograms that visualize global disparities in COVID-19 vaccination coverage, infection rates, mortality rates, and case fatality rates.

The code accompanies the manuscript:
**“Making global disparities visible: what cartograms reveal about COVID-19 protection and burden.”**

## Data Sources
This analysis relies exclusively on publicly available datasets:
- WHO COVID-19 Dashboard (https://covid19.who.int)
- WHO vaccination data

The authors do not claim ownership of the underlying data. Users should download the datasets directly from the official sources.

## Method Overview
- Country-level indicators are derived from WHO cumulative data reported through **December 31, 2023**.
- Population size is estimated from vaccination coverage where official population figures are not directly available in the datasets.
- Continuous area cartograms are generated using the **Dougenik–Chrisman–Niemeyer** algorithm.
- To stabilize cartogram geometry and limit extreme distortion from skewed indicator distributions, cartogram weights are rank-scaled prior to area transformation.
- All spatial operations are conducted in the **EPSG:3857** coordinate reference system.

## Reproducibility
- R version: **4.4.0**
- Key packages: `sf`, `rnaturalearth`, `dplyr`, `ggplot2`, `cartogram`, `parallel`

To reproduce the analysis:
1. Download the WHO datasets from the official sources.
2. Place the CSV files in a local directory of your choice.
3. Update file paths in `scripts/covid19-cartograms.R`.
4. Run the script.

## Notes
- Countries with missing or incomplete data are excluded from the cartograms.
- Visual outputs are intended for comparative interpretation rather than precise metric reading.
- The cartograms are designed to highlight relative global disparities, not to serve as exact spatial measurements.

## Contributors
- Hanmin Gu (code, data processing, cartogram generation)
- Yuki Iwai (conceptualization, interpretation, manuscript co-author)

## License
This code is released under the **MIT License**.