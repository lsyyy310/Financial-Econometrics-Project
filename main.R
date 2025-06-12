library(readxl)
library(zoo)  # for yearmon
library(dplyr)
library(slider)
library(tidyr)
library(glue)
library(sandwich)
library(lmtest)

# load data
data.stock_price = read.csv("Data_Stock_Price_Momentum.csv")
data.factors = read_excel("Data_Factors.xlsx", sheet = 1)

# convert to Date (for mapping easily)
data.stock_price = data.stock_price %>%
  mutate(
    ym = as.yearmon(as.Date(date, format = "%d%b%Y")),
    .before = 2
  ) %>%
  subset(select = -c(date))
data.factors$ym = as.yearmon(as.character(data.factors$ym), format = "%Y%m")

# convert returns to numeric data
data.stock_price$ret = as.numeric(ifelse(data.stock_price$ret == "", NA, data.stock_price$ret))

# model setting
J = 12
K = 3

# Step 1
data.stock_price = data.stock_price %>%
  arrange(permno, ym) %>%
  group_by(permno) %>%
  mutate(
    past_12m_ret = slide_dbl(ret, mean, .before = J, .after = -1, .complete = T),  # past 12-month average return
    future_3m_ret = slide_dbl(ret, mean, .before = -1, .after = K, .complete = T)  # future 3-month average return
  ) %>%
  ungroup()

data.stock_price$marketcap = data.stock_price$prc * data.stock_price$shrout  # market capitalization

# Step 2
# 1 -> loser; 10 -> winner
winner_and_loser = data.stock_price %>%
  group_by(ym) %>%
  mutate(decile = ntile(past_12m_ret, 10)) %>%
  filter(decile %in% c(1, 10)) %>%
  mutate(decile = dplyr::recode(decile, `1` = "loser", `10` = "winner")) %>%
  ungroup() %>%
  arrange(ym, decile)

# Step 3 & Step 4
portfolio.ew = winner_and_loser %>%
  group_by(ym, decile) %>%
  summarise(ret_EW = mean(future_3m_ret, na.rm = T),
            .groups = "drop") %>%
  pivot_wider(names_from = decile, values_from = ret_EW) %>%
  mutate(
    long_short = winner - loser
  )

portfolio.vw = winner_and_loser %>%
  group_by(ym, decile) %>%
  summarise(ret_VW = weighted.mean(future_3m_ret, w = marketcap, na.rm = T),
            .groups = "drop") %>%
  pivot_wider(names_from = decile, values_from = ret_VW) %>%
  mutate(
    long_short = winner - loser
  )

# Step 5
# merge
portfolio.full = portfolio.ew %>%
  rename(EW_winner = winner, EW_loser = loser, EW_long_short = long_short) %>%
  left_join(rename(portfolio.vw, VW_winner = winner, VW_loser = loser, VW_long_short = long_short),
            by = "ym") %>%
  left_join(data.factors, by = "ym")

portfolio.names = colnames(portfolio.full)[2:7]
response_vars = paste0(portfolio.names, "_premium")

# report 1: average risk premium
portfolio.full = portfolio.full %>%
  mutate(
    across(all_of(portfolio.names), ~ . - RF, .names = "{.col}_premium"),
    .before = 7
  )

# compute average risk premium and corresponding SE
report_statistic = lapply(subset(portfolio.full, select = response_vars),
                         function(x) glue("{round(mean(x, na.rm = T), 5)} ({round(sd(x, na.rm = T) / sqrt(sum(!is.na(x))), 5)})")
)

# time-series regressions
regression = function(data, formula) {
  capm_model = lm(as.formula(formula), data = data)
  coeftest(capm_model, vcov. = NeweyWest(capm_model, lag = 12))
}

# report 2
# traditional CAPM
nw_se_capm = lapply(paste0(response_vars, " ~ MktRF"),
                    function(x) regression(portfolio.full, x)
)
names(nw_se_capm) = portfolio.names

# report 3
# Fama-French 3 factors
nw_se_3factors = lapply(paste0(response_vars, " ~ MktRF + SMB + HML"),
                        function(x) regression(portfolio.full, x)
)
names(nw_se_3factors) = portfolio.names

# report 4
# Fama-French 5 factors
nw_se_5factors = lapply(paste0(response_vars, " ~ MktRF + SMB + HML + RMW + CMA"),
                        function(x) regression(portfolio.full, x)
)
names(nw_se_5factors) = portfolio.names


# additional report
# plot
portfolio.avg_premium = portfolio.full %>%
  group_by(ym) %>%
  summarise(
    across(all_of(response_vars), ~ mean(.), .names = "{.col}"),
    .groups = "drop"
  )
portfolio.avg_premium = na.omit(portfolio.avg_premium)

colors = rep(c("lightcyan4", "lightpink2"), each = 3)
point_types = rep(0:2, times = 2)
plot(portfolio.avg_premium$ym, 
     portfolio.avg_premium[[2]],
     xlab = "year-month",
     ylab = "average premium",
     col = colors[1],
     pch = point_types[1],
     cex = 0.8)
for (i in 3:7) {
  points(portfolio.avg_premium$ym,
         portfolio.avg_premium[[i]],
         col = colors[i],
         pch = point_types[i],
         cex = 0.8)
}
