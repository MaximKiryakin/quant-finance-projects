# Quantitative Finance & Econometrics Projects

![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![R](https://img.shields.io/badge/R-276DC3?logo=r&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-F37626?logo=jupyter&logoColor=white)

A collection of applied projects in **time-series econometrics, volatility modeling, and
Monte-Carlo methods for derivatives pricing** — combining rigorous statistical modeling with
real market data and written reports.

---

## Projects

| Project | Topic | Methods | Stack |
|---------|-------|---------|-------|
| [**sales-forecasting**](sales-forecasting/) | Time-series sales forecasting | ARIMA, SARIMA, SARIMAX, gradient boosting, naive baselines | Python |
| [**volatility-har-garch**](volatility-har-garch/) | Realized-volatility forecasting | HAR / HARQ / HARJ vs. GARCH family (GARCH, EGARCH, TGARCH, IGARCH, NAGARCH) | Python, R |
| [**monte-carlo-option-pricing**](monte-carlo-option-pricing/) | Derivatives pricing | Monte-Carlo simulation under a CEV process | Python |

Each project folder contains code, data (or a data link), generated plots, and a written report
(LaTeX → PDF). English READMEs are primary; the original Russian write-ups are kept as `README.ru.md`.

---

## Highlights

- **Econometrics done properly** — stationarity testing, model identification (ACF/PACF),
  residual diagnostics, and out-of-sample evaluation (MAE / MSE / MAPE), not just `.fit()`.
- **Model comparison** — classical econometric models benchmarked head-to-head against gradient
  boosting and naive baselines on the same data.
- **Real market data** — Kaggle store-sales data and Moscow Exchange equity series.

---

*Course projects, Vega Institute. Author: Maksim Kiryakin.*
