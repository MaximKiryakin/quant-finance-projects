# Realized Volatility Forecasting — HAR vs. GARCH


Comparing two families of volatility models — **HAR** (Heterogeneous Autoregressive) and
**GARCH** — on real equity data.

## Setup

Underlying asset: **Sberbank (SBER)** equity. Two periods are studied:

1. 2020-01-03 → 2024-11-29 (full sample)
2. 2017-01-01 → 2020-03-25 (a more volatile sub-period, HAR models only)

## Models

- **GARCH family:** GARCH, EGARCH, NAGARCH, TGARCH, IGARCH
- **HAR family:** HAR, HARQ, HARJ
- **Naive** baseline

## Key results

| Period | Best model | MAE | MSE | MAPE |
|--------|-----------|----:|----:|-----:|
| 2020–2024 | TGARCH(1,1)-sstd | 2.2e-2 | 4.9e-4 | 0.994 |
| 2020–2024 | **HAR** | **3.0e-3** | **1.8e-5** | **0.198** |

On this data the **HAR** model clearly outperforms the GARCH family on realized-volatility error;
on the high-volatility sub-period HAR and HARQ are comparable. Full tables and diagnostics
(QQ-plots, news-impact curves) are in [`Report/Report.pdf`](Report/Report.pdf).

## Structure

```
source/Project2.ipynb   # Python implementation
source/Project2.R       # R implementation (rugarch / HARModel)
Report/                 # LaTeX report + compiled PDF + figures
```

---

*Course project, Vega Institute. Author: Maksim Kiryakin.*
