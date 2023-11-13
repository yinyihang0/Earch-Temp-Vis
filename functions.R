get_avg_by_10_years <- function(df, country, col_name_for_dt, state_col, average_col) {
  result <- df %>%
    mutate(year = year(!!sym(col_name_for_dt))) |>
    filter(Country == country) |>
    group_by(State, group = (year - 1) %/% 10) |>
    summarise(
      start_year = min(year),
      end_year = max(year),
      avg_value = mean(AverageTemperature, na.rm = TRUE))
  return(result)
}

get_city_by_country <- function(data1, data2, country){
  res <- data1 |> filter(Country == country)
  res2 <- data2 |> filter(Country == country)
  return(rbind(res, res2))
}

calculate_yearly_avg_for_country <- function(data, country_name, date_col, value_col) {
  data_subset <- data |> subset(Country == country_name)
  data_subset |>
    mutate(year = year(!!sym(date_col))) |>
    group_by(year) |>
    summarise(avg_value_ = mean(!!sym(value_col), na.rm = TRUE)) |>
    ungroup() |>
    mutate(dt = paste(year)) |>
    select(-year)
}

calculate_yearly_avg_for_city <- function(data1, data2, city_name, date_col, value_col) {
  data1_subset <- data1 |> subset(City == city_name) |>
    mutate(year = year(!!sym(date_col))) |>
    group_by(year) |>
    summarise(avg_value_ = mean(!!sym(value_col), na.rm = TRUE)) |>
    mutate(dt = paste(year)) |>
    select(-year)
  
  return(data1_subset)
}

calculate_monthly_avg_for_city <- function(data1, data2, city_name, date_col, value_col) {
  data1 |> subset(City == city_name) |>
    mutate(year = year(!!sym(date_col)), month = month(!!sym(date_col))) |>
    group_by(year, month) |>
    summarise(avg_value_ = mean(!!sym(value_col), na.rm = TRUE)) |>
    ungroup() |>
    mutate(dt = paste(year, month, sep = "-")) |>
    select(-year, -month)
}

calculate_monthly_avg_for_country <- function(data, country_name, date_col, value_col) {
  data |> subset(Country == country_name) |>
    mutate(year = year(!!sym(date_col)), month = month(!!sym(date_col))) |>
    group_by(year, month) |>
    summarise(avg_value_ = mean(!!sym(value_col), na.rm = TRUE)) |>
    ungroup() |>
    mutate(dt = paste(year, month, sep = "-")) |>
    select(-year, -month)
}

custom_mean <- function(x) {
  return(mean(x, na.rm = TRUE))
}


calculate_mean_for_df <- function(data, window_size) {
  # 将dt列放在前面
  data <- data[, c("dt", setdiff(names(data), "dt"))]
  # 按照个数进行平均 年份数据之类的
  data_mean <- as.data.frame(lapply(data[-1], function(col) {
    rollapply(col, width = window_size, FUN = custom_mean, fill = NA, align = "center")
  }))
  
  data_mean$dt <- data$dt
  colnames(data_mean)[colnames(data_mean) != "dt"] <-
    paste0(colnames(data_mean)[colnames(data_mean) != "dt"], "_avg")
  
  return(data_mean)
}
