# Border Effects in Social Connectedness

**Shery Awad** — California State University, Long Beach | May 2026

---

## Summary

This repository contains the Stata replication code for the working paper **"Border Effects in Social Connectedness"** (Awad, 2026).

I examine the effect of U.S. state borders on county-to-county social connectedness using Meta's Social Connectedness Index and a PPML gravity framework. I find that crossing a state border reduces social connectedness by approximately **62%**, even after controlling for geographic distance and contiguity. I test four mechanisms through which state borders operate:

- **Undergraduate enrollment composition** — higher enrollment weakens within-state ties, consistent with a national orientation effect
- **Flagship university presence and catchment areas** — hosting a flagship weakens within-state ties, but proximity to one strengthens them
- **Shared commuting zones** — the strongest mechanism, nearly eliminating the border penalty for economically integrated cross-border pairs
- **Political differences** — political dissimilarity reduces connectedness and amplifies the cross-border penalty

---

## Data Sources

| Dataset | Source |
|---|---|
| Social Connectedness Index | Meta (Johnston, Kuchler, Kulkarni & Stroebel, 2026) |
| School Enrollment (ACS) | U.S. Census Bureau |
| College Scorecard | U.S. Department of Education |
| County Adjacency File | U.S. Census Bureau (2025) |
| County Centroids | SimpleMaps |
| Commuting Zones | USDA Economic Research Service (2026) |
| County Presidential Returns | MIT Election Data Lab |
| ZIP-County Crosswalk | HUD USPS (Q4 2025) |

---

## Code

| File | Description |
|---|---|
| `border_effects_analysis.do` | Full pipeline: data cleaning, merging, variable construction, PPML and OLS regressions, robustness checks, and map visualizations |

### Key Stata packages required
- `ppmlhdfe` — PPML with high-dimensional fixed effects
- `reghdfe` — OLS with high-dimensional fixed effects
- `estout` / `esttab` — regression output to LaTeX
- `coefplot` — coefficient plots
- `spmap` — choropleth map visualization

---

## Estimation Strategy

All regressions are estimated using **Poisson Pseudo Maximum Likelihood (PPML)** following Santos Silva & Tenreyro (2006), with origin and destination county fixed effects and standard errors clustered at both the user and friend region levels. OLS on log-linearized SCI is reported as a robustness check.

---

## Working Paper

Available at: [sheryawad728.github.io](https://sheryawad728.github.io)

---

## Contact

Shery Awad — sherysameh1@gmail.com
