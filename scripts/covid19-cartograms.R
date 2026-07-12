# ============================================================
# COVID-19 Global Cartograms
# Continuous area cartograms based on WHO COVID-19 data
# ============================================================

# ----------------------------
# 1. Load Libraries
# ----------------------------
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(dplyr)
library(readr)
library(ggplot2)
library(cartogram)
library(parallel)

# ----------------------------
# 2. Load Data
# ----------------------------
# Users should download the datasets directly from WHO sources
who_data <- read_csv("data/WHO-COVID-19-global-data.csv")
vax_data <- read_csv("data/vaccination-data.csv")

# ----------------------------
# 3. Clean Vaccination Data
#    (Estimate population from vaccination coverage)
# ----------------------------
vax_data_clean <- vax_data %>%
  filter(
    !is.na(TOTAL_VACCINATIONS),
    !is.na(TOTAL_VACCINATIONS_PER100),
    TOTAL_VACCINATIONS_PER100 > 0
  ) %>%
  mutate(
    POP_ESTIMATED = TOTAL_VACCINATIONS / (TOTAL_VACCINATIONS_PER100 / 100)
  ) %>%
  select(COUNTRY, ISO3, POP_ESTIMATED, TOTAL_VACCINATIONS_PER100)

# ----------------------------
# 4. Extract Latest WHO Data
# ----------------------------
who_latest <- who_data %>%
  group_by(Country) %>%
  filter(Date_reported == "2023-12-31") %>%
  ungroup()

# ----------------------------
# 5. Merge and Compute Indicators
# ----------------------------
merged <- who_latest %>%
  left_join(vax_data_clean, by = c("Country" = "COUNTRY")) %>%
  mutate(
    INFECTION_RATE_PCT  = 100 * Cumulative_cases / POP_ESTIMATED,
    MORTALITY_RATE_PCT  = 100 * Cumulative_deaths / POP_ESTIMATED,
    FATALITY_RATE_PCT   = 100 * Cumulative_deaths / Cumulative_cases
  )

# ----------------------------
# 6. Load World Map
# ----------------------------
world <- ne_countries(scale = "medium", returnclass = "sf")

# ----------------------------
# 7. Prepare sf Data
# ----------------------------
prepare_sf_data <- function(world, data, by, value_column) {
  world %>%
    left_join(data, by = by) %>%
    filter(!is.na(.data[[value_column]])) %>%
    st_transform(crs = 3857) %>%
    mutate(weight = .data[[value_column]])
}

world_vax        <- prepare_sf_data(world, vax_data_clean,
                                    c("iso_a3" = "ISO3"),
                                    "TOTAL_VACCINATIONS_PER100")

world_infection  <- prepare_sf_data(world, merged,
                                    c("iso_a3" = "iso_a3"),
                                    "INFECTION_RATE_PCT")

world_mortality  <- prepare_sf_data(world, merged,
                                    c("iso_a3" = "iso_a3"),
                                    "MORTALITY_RATE_PCT")

world_fatality   <- prepare_sf_data(world, merged,
                                    c("iso_a3" = "iso_a3"),
                                    "FATALITY_RATE_PCT")

# ----------------------------
# 8. Rank-based Area Scaling
# ----------------------------
rank_and_scale <- function(sf_obj) {
  sf_obj$weight <- rank(sf_obj$weight, ties.method = "average")
  mean_area <- mean(as.numeric(st_area(sf_obj)))
  sf_obj$weight <- sf_obj$weight / mean(sf_obj$weight, na.rm = TRUE) * mean_area
  sf_obj
}

world_vax        <- rank_and_scale(world_vax)
world_infection  <- rank_and_scale(world_infection)
world_mortality  <- rank_and_scale(world_mortality)
world_fatality   <- rank_and_scale(world_fatality)

# ----------------------------
# 9. Cartogram Wrapper
# ----------------------------
cartogram_wrapper <- function(data) {
  cartogram_cont(
    data,
    weight = "weight",
    itermax = 1,
    maxSizeError = 0.01,
    prepare = "none"
  )
}

# ----------------------------
# 10. Parallel Cartogram Generation
# ----------------------------
data_list <- list(
  world_vax,
  world_infection,
  world_mortality,
  world_fatality
)

cl <- makeCluster(detectCores() - 1)
clusterEvalQ(cl, library(cartogram))
clusterExport(cl, c("cartogram_wrapper", "data_list"))

cartograms <- parLapply(cl, data_list, cartogram_wrapper)
stopCluster(cl)

world_cartogram_vax        <- cartograms[[1]]
world_cartogram_infection  <- cartograms[[2]]
world_cartogram_mortality  <- cartograms[[3]]
world_cartogram_fatality   <- cartograms[[4]]

# ----------------------------
# 11. Visualisation
# ----------------------------
plot_cartogram <- function(data, fill_var, legend_title, colours) {
  ggplot(data) +
    geom_sf(aes(fill = .data[[fill_var]]),
            color = "grey30", size = 0.1) +
    scale_fill_gradientn(colours = colours, name = legend_title) +
    theme_minimal() +
    theme(legend.position = "bottom")
}

plot_cartogram(world_cartogram_vax,
               "TOTAL_VACCINATIONS_PER100",
               "Doses per 100 people",
               c("#e41a1c", "#ffff99", "#377eb8"))

plot_cartogram(world_cartogram_infection,
               "INFECTION_RATE_PCT",
               "Infection rate (%)",
               c("#ffeda0", "#feb24c", "#f03b20"))

plot_cartogram(world_cartogram_mortality,
               "MORTALITY_RATE_PCT",
               "Mortality rate (%)",
               c("#e5f5e0", "#a1d99b", "#31a354"))

plot_cartogram(world_cartogram_fatality,
               "FATALITY_RATE_PCT",
               "Case fatality rate (%)",
               c("#f7fbff", "#6baed6", "#08306b"))
