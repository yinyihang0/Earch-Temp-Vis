library(shiny)
library(echarts4r)
library(shinyjs)
library(echarts4r.maps)
library(dplyr)
library(lubridate)
library(zoo)
library(rjson)
library(shinydashboard)

load("base.RData")
source("functions.R")


jsCode1 <- "
shinyjs.updateText = function(country, type) {
  Shiny.setInputValue('clicked_country', country);
  if(type == 'map'){type = 'country';}
  else if(type == 'effectScatter'){type = 'city';}
  Shiny.setInputValue('type', type);
}
"
jsCode2 <- "
shinyjs.updateIndex = function(index) {
  Shiny.setInputValue('decade_id', index);
}
"

province_mapping <- data.frame(
  english_name = c("Anhui", "Beijing", "Chongqing", "Fujian", "Gansu", "Guangdong", 
                   "Guangxi", "Guizhou", "Hainan", "Hebei", "Heilongjiang", "Henan",
                   "Hong Kong", "Hubei", "Hunan", "Nei Mongol", "Jiangsu", "Jiangxi",
                   "Jilin", "Liaoning", "Macau", "Ningxia Hui", "Qinghai", "Shaanxi",
                   "Shandong", "Shanghai", "Shanxi", "Sichuan", "Tianjin", "Xizang",
                   "Xinjiang Uygur", "Yunnan", "Zhejiang"),
  chinese_name = c("安徽", "北京", "重庆", "福建", "甘肃", "广东", 
                   "广西", "贵州", "海南", "河北", "黑龙江", "河南",
                   "香港", "湖北", "湖南", "内蒙古", "江苏", "江西",
                   "吉林", "辽宁", "澳门", "宁夏", "青海", "陕西",
                   "山东", "上海", "山西", "四川", "天津", "西藏",
                   "新疆", "云南", "浙江")
)
province_dict <- setNames(object = province_mapping$chinese_name, 
                          nm = province_mapping$english_name)

state_mapping_india <- data.frame(
  ori = c("Andaman And Nicobar", "Jammu And Kashmir", "Dadra And Nagar Haveli","Uttaranchal",
          "Orissa"),
  dst = c("Andaman and Nicobar Islands", "Jammu and Kashmir", "Dadra and Nagar Haveli","Uttarakhand"
          ,"Odisha")
)

state_dict_india <- setNames(object = state_mapping_india$dst, 
                             nm = state_mapping_india$ori)

state_mapping_us <- data.frame(
  ori = c("Georgia (State)"),
  dst = c("Georgia")
)

state_dict_us <- setNames(object = state_mapping_us$dst, 
                          nm = state_mapping_us$ori)

state_mapping_rus <- data.frame(
  ori = c("Moscow City", "Mariy El", "Ul'Yanovsk", "City Of St. Petersburg", "Arkhangel'Sk","North Ossetia",
          "Kabardin Balkar", "Karachay Cherkess", "Yamal Nenets", "Primor'Ye", "Gorno Altay"),
  dst = c("MoscowCity", "Mariy-El", "Ul'yanovsk", "CityOfSt.Petersburg", "Arkhangel'sk","NorthOssetia",
          "Kabardin-Balkar", "Karachay-Cherkess", "Yamal-Nenets", "Primor'ye", "Gorno-Altay")
)

state_dict_rus <- setNames(object = state_mapping_rus$dst, 
                           nm = state_mapping_rus$ori)

state_mapping_bra <- data.frame(
  ori = c("Distrito Federal", "Mato Grosso", "Mato Grosso Do Sul", "Minas Gerais", "Rio De Janeiro",
          "Rio Grande Do Norte", "Rio Grande Do Sul", "Santa Catarina"),
  dst = c("DistritoFederal", "MatoGrosso", "MatoGrossodoSul", "MinasGerais", "RiodeJaneiro",
          "RioGrandedoNorte", "RioGrandedoSul", "SantaCatarina")
)

state_dict_bra <- setNames(object = state_mapping_bra$dst, 
                           nm = state_mapping_bra$ori)

json_BRA <- fromJSON(file = "gadm41_BRA_1.json")

json_RUS <- fromJSON(file = "gadm41_RUS_1.json")

avg_period_choices <- c("每年","每月")

ui <- fluidPage(
  useShinyjs(),
  extendShinyjs(text = jsCode1, functions = c("updateText")),
  extendShinyjs(text = jsCode2, functions = c("updateIndex")),
  dashboardPage(
    dashboardHeader(title = "全球温度数据可视化", 
                    tags$li(class = "dropdown", style = "padding: 15px;", "联系方式: scarelsyyh@gmail.com")  
                  ),
    dashboardSidebar(
      tags$head(
        tags$style("
          # .main-sidebar {
          #   background-color: #d1e9f4 !important; /* 你想要的颜色 */
          # }
          @font-face {
            font-family: 'MyFont'; 
            src: url('LXGWWenKaiGBScreen.ttf') format('truetype');
          }
          
          body {
            font-family: 'MyFont', sans-serif;
            font-size: 16px;
          }

          .box-title {
            font-family: 'MyFont', sans-serif;
            font-size: 18px;
          }

          h3 {
              font-family: 'MyFont', sans-serif;
              font-size: 18px;
          }
          
        ")
      ),
      selectizeInput(inputId="avg_period",
                     label="折线图时间粒度",
                     choices=avg_period_choices),
      actionButton("button", "清除点击得到的曲线"),
      tags$div(style = "margin: 10px; padding: 5px;", 
            HTML("<h3>应用简介</h3>这是一个由Shiny驱动、采用echarts4R进行动态交互展示的应用，致力于呈现全球各国和城市的气温数据。
                  在此应用中，按照十年为一个单位整理了全球的历史温度数据，并在地图上进行了直观的可视化。<br>"),
            HTML("<h3>地图功能</h3>在左侧的全球地图中，当点击某一国家，将在下方的小地图及折线图中看到该国的详细气温数据。
            若选择在全球地图或某国的小地图上点击某一城市，该城市的气温走势将会在下方的折线图进行呈现。
            值得注意的是，世界地图中仅展示了各主要城市，在小地图中，除了主要城市外，还会展现其他重要城市的信息。此外用户可通过点击界面下方的按钮选择特定年份进行查看，或直接点击时间轴上的播放按钮，进行自动循环播放。<br>"),
            HTML("<h3>折线图</h3>下方的折线图详细展示了年度或月度的气温平均值。用户可自主选择查看“每年”或“每月”的数据，还可以拖动时间轴，来查看特定时段的气温变化。最后，如果选择了“每月”作为时间尺度，还会对数据进行简单的时序分解。<br>")
      )

    ),
    dashboardBody(
      fluidRow(
        column(width = 3,
               box(title="统计数据",
                   fluidRow(uiOutput("temp_max")),
                   fluidRow(uiOutput("temp_avg")),
                   fluidRow(uiOutput("temp_min")),
                   fluidRow(uiOutput("selectedBox")),
                   fluidRow(uiOutput("temp_avg_c"))
                   # ,
                   # tags$div(style = "margin: 2px; padding: 5px;",
                   #    HTML("点击右侧地图中的国家，在下方查看点击国家的具体数据<br>"),
                   #    HTML("点击右侧下方时间栏，查看对应时间段的全球温度数据<br>"),
                   #    HTML("点击具体的城市，在下方查看对应的温度数据折线图<br>")
                   # )
                   ,width = 12,height=700)
               )
        ,
        column(width = 9, 
               box(title = "全球温度数据",
                   echarts4rOutput("temp_by_country", height = "630px"),
                   width = 12, height = 700
               )
        )
      ),
      fluidRow(
        column(width = 6,
               box(title = "国家温度数据",
                   echarts4rOutput("country", height = "310px"),
                   width = 12, height = 420)
        ),
        column(width = 6,
               box(title = "温度数据",
                   echarts4rOutput("temp_lines_year", height = "350px"), width = 12, height = 420) 
        )
      ),
      fluidRow(column
               (width = 12,
                 conditionalPanel(
        condition = "input.avg_period == '每月'",
        box(title = "时间序列数据分解",
            plotOutput("new_lines"), width = 12),
        width = 12
      )
      )
      )
    )
  )
)
server <- function(input, output, session) {
  
  avg_per <- reactive({input$avg_period})
  main_df_rv_yearly <- reactiveVal(df_yearly_avg)
  
  main_df_rv_monthly <- reactiveVal(df_monthly_avg)

  
  output$temp_avg <- renderUI({
    if(is.null(input$decade_id)) {
      year <- 1750
    }else{
      year <- min(1750 + input$decade_id * 10, 2013)
    }
    avg_value  <- averages_10_years |> 
      filter(end_year == year)  |>
      summarise(temp = avg_temp) |>
      summarise_all(.funs = list(~mean(., na.rm = TRUE)))
    
    # print(avg_value)
    infoBox(paste0(as.numeric((year-1) %/% 10 * 10), " — ", as.numeric(year), "的全球平均气温"),
      paste0("平均温度：",format(avg_value$temp[1], nsmall = 2, digits = 2)),
      icon=icon("temperature-half"),color="light-blue",fill=TRUE,width=12)
  })
  output$temp_max <- renderUI({
    if(is.null(input$decade_id)) {
      year <- 1750
    }else{
      year <- min(1750 + input$decade_id * 10, 2013)
    }
    max_value  <- averages_10_years |> 
      filter(end_year == year)  |>
      summarise(temp = avg_temp) |>
      summarise_all(.funs = list(~max(., na.rm = TRUE)))
      
    infoBox(paste0(as.numeric((year-1) %/% 10 * 10), " — ", as.numeric(year), "的全球最高气温"),
      paste0("国家: ", max_value$Country[1], " 温度：",format(max_value$temp[1], nsmall = 2, digits = 2)),
      icon=icon("temperature-full"),color="maroon",fill=TRUE,width=12)
  })
  output$temp_min <- renderUI({
    if(is.null(input$decade_id)) {
      year <- 1750
    }else{
      year <- min(1750 + input$decade_id * 10, 2013)
    }
    min_value  <- averages_10_years |> 
      filter(end_year == year)  |>
      summarise(temp = avg_temp) |>
      summarise_all(.funs = list(~min(., na.rm = TRUE)))
    infoBox(paste0(as.numeric( (year-1)  %/% 10 * 10), " — ", as.numeric(year), "的全球最低气温"),
      paste0("国家: ", min_value$Country[1], " 温度：",format(min_value$temp[1], nsmall = 2, digits = 2))
      ,icon=icon("temperature-empty"),color = "aqua", fill=TRUE,width=12)
  })
  output$selectedBox <- renderUI({
    if (is.null(input$clicked_country)) {
      infoBox("选择的国家/城市","None -- 请在地图中点击",icon=icon("city"),fill=TRUE,width=12)
    } else {
      infoBox("选择的国家/城市",input$clicked_country,icon=icon("city"),fill=TRUE,width=12)
    }
  })
  
  
  output$temp_by_country <-renderEcharts4r({
    visual_map <- averages_10_years |> group_by(end_year) |> 
      e_charts(Country, timeline=TRUE) |>
      e_map(avg_temp, roam = TRUE, map = "world", geoIndex = 0) |>
      e_timeline_opts(realtime = TRUE, axis_type = 'category')
    
    visual_scatter <- averages_10_years_by_major_city |> group_by(end_year) |>
      e_charts(lon, timeline = TRUE) |>
      e_timeline_opts(realtime = TRUE, axis_type = 'category') |>
      e_geo(roam = TRUE, zlevel = 0, id = 0, map = "world")  |>
      e_effect_scatter(lat, coord_system = "geo", symbolSize = 15, 
                       showEffectOn = "render", rippleEffect = list(brushType = "stroke"),
                       label = list(
                         formatter = "{b}",
                         position = "right",
                         show = FALSE), 
                       emphasis = list(label = list(show = TRUE), scale = TRUE), geoIndex = 0)
    
    
    for(i in seq_along(visual_scatter[["x"]][["opts"]][["options"]])){
      year <- min(1750 + (i-1) * 10, 2013)
      df_temp <- averages_10_years_by_major_city |> filter(end_year == year)
      res <- lapply(1:nrow(df_temp), function(i) {
        list(
          name = df_temp$City[i],
          value = list(df_temp$lon[i], df_temp$lat[i], df_temp$avg_temp_city[i])
        )
      })
      visual_scatter[["x"]][["opts"]][["options"]][[i]][["series"]][[1]][["data"]] <- res
      visual_scatter[["x"]][["opts"]][["baseOption"]][["series"]][[2]] <-
        visual_map[["x"]][["opts"]][["baseOption"]][["series"]][[1]]
      visual_scatter[["x"]][["opts"]][["options"]][[i]][["series"]][[2]] <-
        visual_map[["x"]][["opts"]][["options"]][[i]][["series"]][[1]]
    }
    vs__ <- visual_scatter |>
      e_visual_map(inRange = list(color = list("#313695", "#4575b4", "#74add1", "#abd9e9", "#e0f3f8", "#ffffbf", "#fee090", "#fdae61", "#f46d43", "#d73027", "#a50026")))
    vs__[["x"]][["opts"]][["baseOption"]][["visualMap"]][[1]][["min"]] = -20
    vs__[["x"]][["opts"]][["baseOption"]][["visualMap"]][[1]][["max"]] = 30
    vs__ |> e_toolbox_feature(feature = c("restore")) |>
      e_on(query = 'series', handler = "function(pa){console.log(pa.componentSubType);shinyjs.updateText(pa.name, pa.componentSubType);}")|>
      e_on(query = 'timeline', event="timelinechanged", handler = "function(pa){console.log(pa);shinyjs.updateIndex(pa.currentIndex)}")
  })
  
  observeEvent(input$clicked_country ,{
    
    if(avg_per() == "每年"){
      if(!is.null(input$clicked_country) && !input$clicked_country %in% colnames(main_df_rv_yearly())) {
        if(input$type == 'country'){
          df_country <- calculate_yearly_avg_for_country(df, input$clicked_country, "dt", "AverageTemperature")
          df_country <- df_country |> rename(!!input$clicked_country := avg_value_)
          updated_df <- left_join(isolate(main_df_rv_yearly()), df_country, by = "dt") 
        }
        else if(input$type == 'city'){
          df_city <- calculate_yearly_avg_for_city( df_by_city, df_by_major_city, input$clicked_country, "dt", "AverageTemperature")
          df_city <- df_city |> rename(!!input$clicked_country := avg_value_)
          updated_df <- left_join(isolate(main_df_rv_yearly()), df_city, by = "dt") 
        }
        main_df_rv_yearly(updated_df)
      }
      
    }else if(avg_per() == "每月"){
      if(!is.null(input$clicked_country) && !input$clicked_country %in% colnames(main_df_rv_monthly()) ) {
        if(input$type == 'country'){
          df_country <- calculate_monthly_avg_for_country(df, input$clicked_country, "dt", "AverageTemperature")
          df_country <- df_country |> rename(!!input$clicked_country := avg_value_)
          updated_df <- left_join(isolate(main_df_rv_monthly()), df_country, by = "dt") 
        }
        else if(input$type == 'city'){
          df_city <- calculate_monthly_avg_for_city( df_by_city, df_by_major_city, input$clicked_country, "dt", "AverageTemperature")
          df_city <- df_city |> rename(!!input$clicked_country := avg_value_)
          updated_df <- left_join(isolate(main_df_rv_monthly()), df_city, by = "dt") 
        }
        main_df_rv_monthly(updated_df)
      }
    }
  })
  
  observeEvent(input$button, {
    if(avg_per() == "每年"){
      main_df_rv_yearly(df_yearly_avg)
    }
    else if(avg_per() == "每月"){
      main_df_rv_monthly(df_monthly_avg)
    }
  })
  
  output$temp_lines_year <- renderEcharts4r({
    df_draw = NULL
    columns_to_plot = NULL
    window_size = 5
    if(avg_per() == "每年"){
      df_draw <-  main_df_rv_yearly()
      columns_to_plot <- setdiff(names(main_df_rv_yearly()), "dt")
      df_draw_mean <- calculate_mean_for_df(df_draw, window_size)
      columns_to_plot_mean <- setdiff(names(df_draw_mean), "dt")
      
      df_draw <- left_join(df_draw, df_draw_mean, by = "dt")
      
      chart <- df_draw |> e_charts(dt)
      
      for(column_name in columns_to_plot) {
        chart <- chart |> e_line_(column_name, name = column_name)
      }
      for(column_name in columns_to_plot_mean) {
        chart <- chart |> e_line_(column_name, name = column_name, 
                                  lineStyle = list(type = 'dashed'))
      }
      
      chart |>
        e_tooltip(trigger = "axis") |>
        e_datazoom() |>
        e_toolbox_feature(feature = c("zoom","dataView"))
    }
    else if(avg_per() == "每月"){
      df_draw <-  main_df_rv_monthly()
      columns_to_plot <- setdiff(names(main_df_rv_monthly()), "dt")
      window_size = 12
      
      chart <- df_draw |> e_charts(dt)
      
      for(column_name in columns_to_plot) {
        chart <- chart |> e_line_(column_name, name = column_name)
      }
      
      chart |>
        e_tooltip(trigger = "axis") |>
        e_datazoom(start = 95) |>
        e_toolbox_feature(feature = c("zoom","dataView"))
    }
  })
  
  output$new_lines <- renderPlot({
    if(!is.null(input$clicked_country) && input$clicked_country %in% colnames(main_df_rv_monthly()) ){
      
      ts_data_column <- main_df_rv_monthly()[, c("dt",input$clicked_country)]
      
      row_index <- which(!is.na(ts_data_column[[input$clicked_country]]))[1]
      if(is.na(row_index)) {
        row_index <- 1
      }
      ts_data_column <- ts_data_column[row_index:nrow(ts_data_column), ]
      min_time <- ts_data_column$dt[1]
      parts <- unlist(strsplit(min_time, "-"))
      
      year_v <- parts[1]
      month_v <- parts[2]
      
      ts_data <- ts(ts_data_column[[input$clicked_country]], frequency=12, start=c(as.numeric(year_v),as.numeric(month_v)))
      ts_data <- na.approx(ts_data)
      
      result <- decompose(ts_data, type="additive")
      plot(result)
    }
    else{
      ts_data_column <- main_df_rv_monthly()
      row_index <- which(!is.na(ts_data_column$avg_value))[1]
      if(is.na(row_index)) {
        row_index <- 1
      }
      ts_data_column <- ts_data_column[row_index:nrow(ts_data_column), ]
      min_time <- ts_data_column$dt[1]
      parts <- unlist(strsplit(min_time, "-"))
      
      year_v <- parts[1]
      month_v <- parts[2]
      
      ts_data <- ts(ts_data_column$avg_value, frequency=12, start=c(as.numeric(year_v),as.numeric(month_v)))
      ts_data <- na.approx(ts_data)
      
      result <- decompose(ts_data, type="additive")
      plot(result)
    }
  })
  output$country <- renderEcharts4r({
    if(!is.null(input$clicked_country)) {
      if(input$type == 'country'){
        country_ <- input$clicked_country
        df_states <- NULL
        df_city_ <- get_city_by_country(averages_10_years_by_city, averages_10_years_by_major_city, country_)
        
        if(country_ %in% c("China", "India", "United States", "Canada", "Russia", "Brazil")){
          df_states <- get_avg_by_10_years(df_by_states, country_, "dt", "State" ,"AverageTemperature") 
        }
        if(country_ == "China"){
          df_states <- df_states |> mutate(State = recode(State, !!!province_dict))
        }
        if(country_ == "United States"){
          country_ <- "USA"
          df_states <- df_states |> mutate(State = recode(State, !!!state_dict_us))
        }
        if(country_ == "India"){
          df_states <- df_states |> mutate(State = recode(State, !!!state_dict_india))
        }
        if(country_ == "Russia"){
          country_ <- "RUS"
          df_states <- df_states |> mutate(State = recode(State, !!!state_dict_rus))
        }
        if(country_ == "Brazil"){
          country_ <- "BRA"
          df_states <- df_states |> mutate(State = recode(State, !!!state_dict_bra))
        }
        map_ <- NULL
        
        if(country_ == "BRA"){
          map_ <- df_states |> group_by(end_year) |>
            e_charts(State, timeline=TRUE) |>
            e_map_register(country_, json_BRA) |>
            e_map(avg_value, roam = TRUE, map = country_, geoIndex = 0)
        }
        else if(country_ == "RUS"){
          map_ <- df_states |> group_by(end_year) |>
            e_charts(State, timeline=TRUE) |>
            e_map_register(country_, json_RUS) |>
            e_map(avg_value, roam = TRUE, map = country_, geoIndex = 0)
        }
        else if(country_ %in% c("China", "India", "USA", "Canada", "USA")){
          map_ <- df_states |> group_by(end_year) |>
            e_charts(State, timeline=TRUE) |>
            em_map(country_) |> 
            e_map(avg_value, roam = TRUE, map = country_, geoIndex = 0)
        }else if(!is.null(country_)){
          map_ <- e_charts() |>
            em_map(country_) |>
            e_geo(roam = TRUE, map = country_, geoIndex = 0)
        }
        if(!is.null(map_)){
          min_year <- min(df_city_$end_year)
          visual_scatter <- df_city_ |> group_by(end_year) |>
            e_charts(lon, timeline = TRUE) |>
            e_timeline_opts(realtime = TRUE, axis_type = 'category') 
          if(country_ == "RUS"){
            visual_scatter <- visual_scatter |> 
              e_map_register(country_, json_RUS)
          }else if(country_ == "BRA"){
            visual_scatter <- visual_scatter |> 
              e_map_register(country_, json_BRA)
          }else{
            visual_scatter <- visual_scatter |> 
              em_map(country_)
          }
          visual_scatter <- visual_scatter |> 
            e_geo(roam = TRUE, zlevel = 0, map = country_)  |>
            e_effect_scatter(lat ,coord_system = "geo", symbolSize = 15, 
                             showEffectOn = "render", rippleEffect = list(brushType = "stroke"),
                             label = list( formatter = "{b}", position = "right", show = FALSE), 
                             emphasis = list(label = list(show = TRUE), scale = TRUE), geoIndex = 0)
          
          for(i in seq_along(visual_scatter[["x"]][["opts"]][["options"]])){
            year <- min(min_year + (i-1) * 10, 2013)
            df_temp <- df_city_ |> filter(end_year == year)
            res <- lapply(1:nrow(df_temp), function(i) {
              list(
                name = df_temp$City[i],
                value = list(df_temp$lon[i], df_temp$lat[i], df_temp$avg_temp_city[i])
              )
            })
            visual_scatter[["x"]][["opts"]][["options"]][[i]][["series"]][[1]][["data"]] <- res
            visual_scatter[["x"]][["opts"]][["baseOption"]][["series"]][[2]] <-
              map_[["x"]][["opts"]][["baseOption"]][["series"]][[1]]
            visual_scatter[["x"]][["opts"]][["options"]][[i]][["series"]][[2]] <-
              map_[["x"]][["opts"]][["options"]][[i]][["series"]][[1]]
          }
          
          vs__ <- visual_scatter |>
            e_visual_map(inRange = list(color = list("#313695", "#4575b4", "#74add1", "#abd9e9", "#e0f3f8", "#ffffbf", "#fee090", "#fdae61", "#f46d43", "#d73027", "#a50026")))
          vs__[["x"]][["opts"]][["baseOption"]][["visualMap"]][[1]][["min"]] = -20
          vs__[["x"]][["opts"]][["baseOption"]][["visualMap"]][[1]][["max"]] = 30
          vs__ |> e_toolbox_feature(feature = c("restore"))
        }
      }
    }
  })
}

shinyApp(ui, server)
