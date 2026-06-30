# Sales Forecasting — Econometric vs. ML Models

<p align="right"><a href="README.ru.md">🇷🇺 Читать на русском</a></p>

Forecasting daily store sales using **time-series econometrics** and benchmarking against
machine-learning baselines.

## Problem

Predict 2016 sales for an Ecuadorian retail chain
([Kaggle "Store Sales — Time Series Forecasting"](https://www.kaggle.com/c/store-sales-time-series-forecasting/data)).
The final dataset is assembled from `train.csv`, `stores.csv`, and `oil.csv`, enriched with
external factors (oil price, holidays, store metadata).

## Models compared

- **Naive** baseline
- **ARIMA**(p, d, q)
- **SARIMA**(p, d, q)(P, D, Q)ₛ — seasonal extension
- **SARIMAX** — seasonal + exogenous regressors (oil price, holidays)
- **Gradient boosting** — ML benchmark on engineered features

## Workflow

EDA → stationarity analysis → model identification via ACF/PACF → fitting → residual diagnostics →
out-of-sample evaluation. Generated figures are in [`Plots/`](Plots/); the full write-up is in
[`Report/Report.pdf`](Report/Report.pdf).

## Structure

```
Project1.ipynb     # End-to-end notebook
Data/              # Raw input data
Plots/             # Generated EDA and forecast figures
Report/            # LaTeX report + compiled PDF
Utils/graphs.py    # Plotting helpers
```

## Run

```bash
pip install numpy pandas statsmodels scikit-learn matplotlib seaborn
jupyter notebook Project1.ipynb
```

---

*Course project (Vega Institute), completed in a team: Maksim Kiryakin, Daria Kurenkova, Natalia Koval.*
