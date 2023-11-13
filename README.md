

# 地表温度可视化实验报告

## 目录

[toc]







------

![image-20231101165856137](C:\Users\lenovo\AppData\Roaming\Typora\typora-user-images\image-20231101165856137.png)



课设网页（加载可能需要等待一段时间）：[全球温度数据可视化 (shinyapps.io)](https://yyhaccount.shinyapps.io/project1/)

## 简介

这是一个由Shiny驱动、采用***echarts4R***进行动态交互展示的应用，致力于呈现全球各国和城市的气温数据。在此应用中，按照十年为一个单位整理了全球的历史温度数据，并在地图上进行了直观的可视化。用户可通过点击界面下方的按钮选择特定年份进行查看，或直接点击***时间轴***上的播放按钮，进行自动循环播放。

下方的折线图详细展示了年度与月度的气温平均值。用户可自主选择查看“每年”或“每月”的数据，还可以***拖动时间轴***，来查看特定时段的气温变化。

在左侧的全球地图中，当***点击某一国家***，将在右侧的小地图及下方的折线图中看到该国的详细气温数据。若选择在全球地图或某国的小地图上点击某一城市，该国家/城市的气温走势将会在下方的折线图进行呈现。值得注意的是，世界地图中仅展示了各主要城市，在小地图中，除了主要城市外，还会展现其他重要城市的信息。

最后，如果选择了“每月”作为时间尺度，还会对数据进行简单的时序分解。

## 数据预处理

### 数据介绍

本数据集由5个`CSV`文件组成，各文件内数据含义及其格式如下：

#### `GlobalTemperatures.csv`

全球历史地表温度数据，包括陆地均值、极值和陆海均值。

| 字段名                                    | 数据类型 | 简介                                   |
| :---------------------------------------- | :------: | :------------------------------------- |
| dt                                        |  `date`  | 按月间隔，自`1750-01-01`至`2015-12-01` |
| LandAverageTemperature                    | `double` | 陆地每月平均温度                       |
| LandAverageTemperatureUncertainty         | `double` | 陆地每月平均温度区间                   |
| LandMaxTemperature                        | `double` | 陆地每月最高温度                       |
| LandMaxTemperatureUncertainty             | `double` | 陆地每月最高温度区间                   |
| LandMinTemperature                        | `double` | 陆地每月最低温度                       |
| LandMinTemperatureUncertainty             | `double` | 陆地每月最低温度区间                   |
| LandAndOceanAverageTemperature            | `double` | 陆海每月平均温度                       |
| LandAndOceanAverageTemperatureUncertainty | `double` | 陆海每月平均温度区间                   |

#### `GlobalLandTemperaturesByCountry.csv`

全球各国平均每月温度数据。

| 字段名                        |  数据类型   | 简介                                   |
| :---------------------------- | :---------: | :------------------------------------- |
| dt                            |   `date`    | 按月间隔，自`1743-11-01`至`2013-09-01` |
| AverageTemperature            |  `double`   | 平均温度                               |
| AverageTemperatureUncertainty |  `double`   | 平均温度区间                           |
| Country                       | `character` | 国家名称                               |

#### `GlobalLandTemperaturesByState.csv`

全球按各国一级行政区（省、州、自治区等）分平均每月温度数据。

| 字段名                        |  数据类型   | 简介                                   |
| :---------------------------- | :---------: | :------------------------------------- |
| dt                            |   `date`    | 按月间隔，自`1855-05-01`至`2013-09-01` |
| AverageTemperature            |  `double`   | 平均温度                               |
| AverageTemperatureUncertainty |  `double`   | 平均温度区间                           |
| State                         | `character` | 一级行政区名称                         |
| Country                       | `character` | 国家名称                               |

本数据仅包括以下七个国家或地区：澳大利亚、巴西、中国（不含港澳台）、加拿大、印度、俄罗斯、美国。

#### `GlobalLandTemperaturesByMajorCity.csv`

全球主要城市平均每月温度数据

| 字段名                        |  数据类型   | 简介                                   |
| :---------------------------- | :---------: | :------------------------------------- |
| dt                            |   `date`    | 按月间隔，自`1849-01-01`至`2013-09-01` |
| AverageTemperature            |  `double`   | 平均温度                               |
| AverageTemperatureUncertainty |  `double`   | 平均温度区间                           |
| City                          | `character` | 城市名称                               |
| Country                       | `character` | 国家名称                               |
| Latitude                      | `character` | 城市经度                               |
| Longitude                     | `character` | 城市纬度                               |

#### `GlobalLandTemperaturesByCity.csv`

全球城市平均每月温度数据

| 字段名                        |  数据类型   | 简介                                   |
| :---------------------------- | :---------: | :------------------------------------- |
| dt                            |   `date`    | 按月间隔，自`1743-11-01`至`2013-09-01` |
| AverageTemperature            |  `double`   | 平均温度                               |
| AverageTemperatureUncertainty |  `double`   | 平均温度区间                           |
| City                          | `character` | 城市名称                               |
| Country                       | `character` | 国家名称                               |
| Latitude                      | `character` | 城市经度                               |
| Longitude                     | `character` | 城市纬度                               |

> 该数据表包括前述**主要城市**数据表中的内容且值基本一致。

### 数据预处理

数据处理主要是通过R语言完成的，详细的处理过程可以参考`map.Rmd`文件。以下是用到的主要数据变量以及其来源：

| 数据变量名称                      | 数据来源                            |
| --------------------------------- | ----------------------------------- |
| `df_global`                       | `GlobalTemperatures.csv`            |
| `df_by_states`                    | `GlobalLandTemperaturesByState`     |
| `df_by_major_city`                | `GlobalLandTemperaturesByMajorCity` |
| `df_by_city`                      | `GlobalLandTemperaturesByCity`      |
| `averages_10_years`               | 基于`df_global`的处理结果           |
| `averages_10_years_by_major_city` | 基于`df_by_major_city`的处理结果    |
| `averages_10_years_by_city`       | 基于`df_by_city`的处理结果          |
| `df_yearly_avg`                   | 基于`df_global`的处理结果           |
| `df_monthly_avg`                  | 基于`df_global`的处理结果           |

这样是否符合您的要求？

这样的表格形式可以清晰地表示数据的来源和处理，使得读者更容易理解。

## shiny程序

### UI

#### 界面设置

最后的用户界面展示如下：
![[Pasted image 20231101162904.png]]
在本应用中，我们采用了`dashboardPage`来构建一个具有标题、侧边栏和主体内容的仪表板布局。

##### 侧边栏

侧边栏的设计旨在提供交互性功能与简要介绍：

- **时间刻度选择**：通过`selectizeInput`，用户可以选择所需的时间刻度。
- **重置功能**：设有一个按钮，允许用户重置曲线到初始状态。
- **应用介绍**：为用户提供该应用的基本说明与操作指南。

##### 主体

主体部分的展示区域被设计为两行，附带一个条件性显示的行：

- **第一行**：
  - **左侧**：展示了一些核心的统计信息，这部分内容通过`uiOutput`动态呈现。
  - **右侧**：展示了一个全球气温数据的世界地图，供用户进行交互查看，通过`echarts4rOutput`输出。
- **第二行**：
  - **左侧**：根据用户在世界地图上的点击，动态显示所选国家的详细气温地图，通过`echarts4rOutput`输出。
  - **右侧**：展示了与所选地区匹配的气温趋势折线图，通过`echarts4rOutput`输出。
- **条件性显示的第三行**：只有当用户在侧边栏选择“每月”作为时间刻度时，此行才会显示，展示对应的时间序列数据分解，内容通过`plotOutput`输出。

#### 样式设置

在本应用中，我们通过CSS对字体和不同分类的字号进行了调整：

- **字体引入**：我们采用了“霞鹜文楷”字体，这是一款公开的TTF格式字体。为确保其正确加载，我们将字体文件存放在了项目的`www`目录下。有关此字体的更多信息，可以参考其[Github页面](https://github.com/lxgw/LxgwWenKai)。

- **CSS样式设置**：通过内嵌CSS并使用类选择器，我们为不同的文本部分设定了适当的字号和样式，确保整体设计的一致性。

#### 自定义JS

在本项目中，为了整合自定义的JavaScript代码，我们采用了`shinyjs`库。为确保JavaScript能够在UI中正确初始化和运行，我们在UI部分引入了`useShinyjs()`。

利用`extendShinyjs`函数，我们将自定义的JavaScript代码与其对应的函数名建立了联系，这为后续在server部分调用这些功能提供了便利。

具体来说，我们定义了两个JavaScript函数：`updateText`和`updateIndex`。这两个函数在某些交互事件触发时起到关键作用：

- `updateText`：当用户点击地图上的某个国家或城市时，此函数被触发，用于更新`input$clicked_country`和`input$type`的值。
- `updateIndex`：当时间轴发生切换时，此函数负责更新代表不同年代的`input$decade_id`值。

### server

#### 数据

##### 地图相关的数据处理

在展示某些特定国家的数据时，我们注意到默认的省级行政区域划分并不能完全满足我们的展示需求。为了获得更加精细的地图信息，我们为俄罗斯和巴西手动引入了[GADM maps](https://gadm.org/maps.html)提供的高精度地图数据。

对于中国，其省级行政区划地图以及在全球地图中的对应位置，我们采用了来自[Maps for 'echarts4r' • echarts4r.maps (john-coene.com)](https://echarts4r-maps.john-coene.com/)的数据。

但是，值得注意的是，由于不同来源的数据中，地名命名可能存在不统一或微妙的差异，我们需要手动进行一些地名字符串的转换和匹配，这是为了确保数据之间的准确对应和无缝展示。

**免责声明**：虽然我们已经尽最大努力确保数据的准确性和完整性，但我们不能对因数据错误或遗漏所导致的任何损失或损害承担责任。

##### 预先获取的数据

在本项目中，关键的数据集如`df_yearly_avg`、`df_monthly_avg`和`averages_10_years`等已经通过`map.Rmd`预处理并生成。为了优化性能和提高加载速度，这些预处理过的数据被保存在与`app.R`同一路径下的`base.RData`文件中。

在应用启动时，通过使用`load("base.RData")`命令，我们可以直接加载这些数据，而无需再次进行数据预处理。这种方法不仅节省了每次启动应用时的数据处理时间，还减轻了服务器磁盘的负担，确保了应用的流畅运行。

##### 反应值

在Shiny应用中，**反应性**是核心的概念。它指的是当某些变量或输入发生改变时，与它们相关的输出或计算会自动更新。

在Shiny中，有两类反应性元素：

1. **用户输入元素**：这些是与`input`相关的，通常由用户在前端界面中进行操作来设置。
2. **自定义反应性表达式**：这些是在服务器代码`server`部分使用`reactive()`函数创建的。

具体差异：

- 可以直接访问`input`对象中的值，例如使用`input$slider_value`。
- `reactive()`函数创建的反应性表达式需要像函数一样调用，例如`reactive_value()`。

在本课程项目中，反应性值主要通过以下三种途径设置：

1. **设置JS Handle**: 涉及到前端界面交互的JavaScript代码，正如在[[课设#UI#自定义JS]]部分所见。
2. **UI中的设置**: 主要在侧边栏中设置，例如选择时间尺度为“年”或“月”。这个选择会影响后续数据的展示和处理方式。决定是否显示第三行图像
3. **通过`reactive`函数设置**:
   - `avg_per`：决定时间序列数据的粒度，可以是年或月。
   - `main_df_rv_yearly`和`main_df_rv_monthly`：存储了用户点击的特定国家或城市对应的年度和月度气温数据。对应于**折线图**中的数据。

#### 外部函数

在shiny应用的server部分，我们依赖于多个外部函数来完成特定的计算和数据处理任务。这些函数被集中保存在`functions.R`文件中。为了确保这些函数在应用中可用，我们在文档的开始部分使用了`source("functions.R")`来加载这些外部函数。

其中，一些主要的函数包括：

- `calculate_yearly_avg_for_country`：用于计算特定国家的年度平均温度。
- `calculate_monthly_avg_for_country`：计算特定国家的月度平均温度。
- `calculate_mean_for_df`：对给定的数据框进行平均值计算。
- `get_city_by_country`：根据国家名称获取其主要城市的信息。

通过这种方式，我们能够保持主程序的简洁性，同时将特定的功能和逻辑封装在独立的函数中，提高代码的可读性和维护性。

#### 图像绘制

![image-20231101165935627](C:\Users\lenovo\AppData\Roaming\Typora\typora-user-images\image-20231101165935627.png)

该项目中主要涉及到三种不同的图形：
地图、折线图，时间序列分解图，下面分别进行介绍

##### 地图

<img src="C:\Users\lenovo\AppData\Roaming\Typora\typora-user-images\image-20231101170020496.png" alt="image-20231101170020496" style="zoom:35%;" />            <img src="C:\Users\lenovo\AppData\Roaming\Typora\typora-user-images\image-20231101170421003.png" alt="image-20231101170421003" style="zoom:70%;" />    



该部分是整个项目的核心，对温度数据进行了地图展示。不仅仅是一个静态的地图，而是通过结合`echarts`、`echarts4R`和`JS`技术，实现了动态交互的功能：

1. **时间轴的展示**：为用户提供了时间上的参考，使其可以在不同年份间流畅地切换，观察温度变化。

2. **国家温度数据的可视化**：各国在地图上的颜色深浅反映了其温度数据，使用户可以直观地看到各国的温度分布。

3. **城市点的标示**：在地图上，主要城市都以点的形式进行了标记，为用户提供了更具体的地理信息。

4. **城市和国家的点击事件**：用户可以点击特定的国家或城市。当发生这样的点击事件时，应用会展示与被点击地点相关的详细温度数据。

###### 国家与城市放在联合渲染

在此项目中，我们参考了来自[john-coene.com](https://echarts4r.john-coene.com/)的[地图](https://echarts4r.john-coene.com/articles/map)和[时间轴](https://echarts4r.john-coene.com/articles/timeline)实例，采用`echarts4r`库来制作时间轴动态地图。

首先，我们利用以下代码为不同国家的数据按年代设置时间轴：

```R
visual_map <- averages_10_years %>%
      group_by(end_year) %>%
      e_charts(Country, timeline = TRUE) %>%
      e_map(avg_temp, roam = TRUE, map = "world", geoIndex = 0) %>%
      e_timeline_opts(realtime = TRUE, axis_type = 'category')
```

然而，我们发现`echarts4r`在实现稍微复杂的效果上，特别是将城市点同时显示在地图上时，没有提供直接的支持。因此，为了达到我们的需求，做了以下事情：

1. 分别渲染两个结构体`visual_map`和`visual_scatter`。
2. 根据Apache ECharts的[官方文档](https://echarts.apache.org/zh/option.html#series-effectScatter)，我们了解到两者的具体结构，并将其合并。

接下来的代码是我们为了合并这两个结构体而编写的：

```R
for(i in seq_along(visual_scatter[["x"]][["opts"]][["options"]])){
      year <- min(1750 + (i-1) * 10, 2013)
      df_temp <- averages_10_years_by_major_city %>% filter(end_year == year)
      
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
```

通过上述方法，我们成功地将城市的点和国家的数据整合到了同一张动态时间轴地图中。

###### 点击事件

在本项目中，为了处理用户的点击事件，我们采用了`echarts4r`库中的`e_on`函数。这个函数允许我们为特定的ECharts组件定义JavaScript回调函数。

具体地说，`e_on`的使用是基于[Callbacks — callbacks • echarts4r (john-coene.com)](https://echarts4r.john-coene.com/reference/callbacks.html?q=e_on#ref-usage)。其中：

- `query`参数用于指定我们希望监听的ECharts组件，可以参考[Documentation - Apache ECharts](https://echarts.apache.org/zh/option.html#series)。
- `event`参数定义了我们要捕捉的具体事件类型，可以参考[Documentation - Apache ECharts](https://echarts.apache.org/zh/api.html#events)。
- `handler`参数则是当该事件被触发时执行的JavaScript函数。

在以下代码中，我们为两个不同的事件定义了回调函数：

```R
...|>
	e_on(query = 'series', event="click", handler = "function(pa){console.log(pa.componentSubType);shinyjs.updateText(pa.name, pa.componentSubType);}") |>
    e_on(query = 'timeline', event="timelinechanged", handler = "function(pa){console.log(pa);shinyjs.updateIndex(pa.currentIndex)}")
```

1. **点击事件**：
   当用户点击地图上的一个点时，我们捕捉了该点的`name`属性（即国家或城市的名称）以及`componentSubType`属性（告诉我们用户点击的是一个国家还是城市）。这些信息然后被传递给`shinyjs.updateText`函数进行进一步的处理。

2. **时间节点改变事件**：
   当用户在时间轴上选择了一个不同的时间点，我们记录了这个点的`currentIndex`属性（即当前选择的时间点的索引值）。这个值然后被传递给`shinyjs.updateIndex`函数。

此外，我们使用了`console.log()`函数来在浏览器的开发者控制台中打印相关信息。这对于开发和调试过程非常有帮助，因为它允许我们直观地看到在不同操作下触发的事件的详细信息。


##### 折线图

![image-20231101204307873](C:\Users\lenovo\Desktop\image-20231101204307873.png)

当用户在地图上点击某一城市时，我们的应用程序会动态地更新并在折线图上展示该城市的平均数据。为了实现这一效果，我们参考并使用了`echarts4r`库中的`e_line_`函数。

具体地说，`e_line_`函数允许我们在ECharts图表中添加折线系列。结合Shiny的反应性，当用户点击一个城市时，我们可以获取对应的数据，并利用`e_line_`为当前的图表添加新的折线系列，从而动态展示该城市的平均数据。

核心的代码如下：

```R
      for(column_name in columns_to_plot) {
        chart <- chart |> e_line_(column_name, name = column_name)
      }
```

##### 时序分解

![image-20231101204333112](C:\Users\lenovo\Desktop\image-20231101204333112.png)

在时序分解部分，由于`echarts4r`对这一特定功能的支持并不完善，我们选择直接使用R的基础`plot`函数进行绘图。这样产生的图像是静态的，与`echarts4r`所生成的动态互动图表有所不同。

