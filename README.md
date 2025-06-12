# Momentum Strategy Analysis in Financial Markets

## Overview
This project examines momentum effects in the U.S. stock market using data from 2001-2023. We construct winner and loser portfolios based on past 12-month returns and evaluate their future 3-month performance under different weighting schemes and asset pricing models.

## Research Question
Does momentum strategy generate abnormal returns that cannot be explained by traditional risk factors in financial markets?

## Data
- **Stock Price Data**: U.S. stock returns with price and volume information (`Data_Stock_Price_Momentum.csv`)
- **Risk Factors**: Fama-French factors including market premium (MktRF), size (SMB), value (HML), profitability (RMW), and investment (CMA) factors (`Data_Factors.xlsx`)
- **Sample Period**: January 2001 - December 2023

## Methodology
### Portfolio Construction
1. **Formation Period**: Past 12-month average returns (J=12)
2. **Holding Period**: Future 3-month average returns (K=3)
3. **Portfolio Selection**: Decile-based ranking (top 10% = winners, bottom 10% = losers)
4. **Weighting Schemes**: 
   - Equal-weighted (EW)
   - Value-weighted (VW) by market capitalization

## Key Findings
1. **Momentum Effect Exists**: Value-weighted long-short strategy generates 0.457% monthly excess returns
2. **Risk-Adjusted Outperformance**: Winner portfolios exhibit significant positive alphas in all models
3. **Size Effect**: Momentum is more pronounced in larger stocks (value-weighted > equal-weighted)
4. **Factor Independence**: Momentum represents a distinct risk factor beyond traditional models

## Files Structure
```
├── main.R
├── data.zip
├── Financial_Econometrics_Report.pdf
└── README.md
```

## Setup Instructions
**Before running the analysis**, please move the two datasets (in `data.zip`) to the same directory as `main.R`:
1. Extract `data.zip`
2. Place `Data_Stock_Price_Momentum.csv` and `Data_Factors.xlsx` in the same directory as `main.R`


## Technical Implementation
- **Data Processing**: Panel data handling with time-series operations using `slider` package
- **Portfolio Construction**: Decile ranking and weighted return calculations
- **Statistical Testing**: Robust standard errors using `sandwich` and `lmtest` packages
- **Risk Factor Analysis**: Multi-factor regression models

## Software Requirements
- R (≥ 4.0.0)
- Required packages: `dplyr`, `readxl`, `zoo`, `slider`, `tidyr`, `sandwich`, `lmtest`

---
*This project was completed as part of Financial Econometrics coursework*
