# Description: R program for the Shiny Server Function of Project CCSE
# Project:     Canadian Climate Statistics Explorer 
# Author:      Chris Jing
# Created on:  2019-12-26


# Load the source R codes
source("ui.R", print=TRUE)
source("global.R", print=TRUE)

options(width = 1500)

station_search_history <<- c("empty")
TIME_SERIES_FLAG  <- FALSE # flag to indicate if the current request is for the time series data type
SAME_STATION_FLAG <- FALSE # if submit again for the same station, no need to regrab the same data already have
FIRST_LAUNCH      <- TRUE  # flag to indicate if this is the first time of launching the current dashboard session

function(input, output, session) {

  # Initialize the lower bounds, upper bounds, axes spacing, click info of the plot 
  x_min <- integer(); y_min <- integer(); x_max <- integer(); y_max <- integer(); x_break <- "5 years"; y_break <- 5
  y_click1 <- character(); y_click2 <- character(); 
  
  output$Canada_logo <- renderImage({
    filename <- normalizePath(file.path('figs', paste('canada_logo.png', sep='')))
    list(src = filename, width="80%", height="80%")}, deleteFile = FALSE)
  
  observeEvent(input$region, {
    if(input$region!=""){
      stations_list <<- read.csv("data/STATION_LIST.csv")
      input_stations_list <<- as.list(listVrtStn(input$region, stations_list))
      updateSelectInput(session, inputId="station", choices=input_stations_list)
      output$map <<- renderLeaflet(generateMap(stations_list, input$region))
    }
  })

  observeEvent(input$parameter, {
    observeEvent(input$data_type,{
      type_data <<- RecordTypeSelect(input$data_type, input$parameter)
      updateSelectInput(session, inputId="record_type", choices=type_data)
      
      if(FIRST_LAUNCH){
        updateSelectInput(session, inputId="station", choices=input_stations_list, selected="Vancouver")
        updateSelectInput(session, inputId="record_type", choices=type_data, selected="Minimum")
        FIRST_LAUNCH <<- FALSE
      }
    })
  })
  
  observeEvent(input$begin_month, {
      updateSelectInput(session, inputId="begin_date", choices=datesSelect(input$begin_month))
  })
  
  observeEvent(input$end_month, {
    updateSelectInput(session, inputId="end_date", choices=datesSelect(input$end_month))
  })
    
  #  ----------------  #
  # |  CLEAR BUTTON  | #
  #  ----------------  #
  
  # Process the following when the "Clear" button is pressed
  observeEvent(input$clear, {
    updateTabsetPanel(session, inputId="inTabset", selected = "Map")
    
    # Set all input selections, widget controls and the map to their default modes 
    output$map <<- renderLeaflet(generateMap(active_vrt_stn_list=stations_list, zoom_region="Canada"))
    
    updateSelectInput(session, inputId="region", choices=c("", region))
    updateSelectInput(session, inputId="station", choices=c(""))
    updateSelectInput(session, inputId="parameter", choices=c(para_select))
    updateSelectInput(session, inputId="data_type", choices=c(data_type_select))
    updateSelectInput(session, inputId="time_period", choices=c(time_period_select))
    updateSelectInput(session, inputId="record_type", choices=c(""))
    updateSliderInput(session, inputId="y_axis_range", label="y-axis: Parameter Range", -50, 50, value = c(-50, 50), step=1)
    updateSliderInput(session, inputId="x_axis_range", label="x-axis: Year Range", 1871, 
                      as.integer(format(Sys.Date(), "%Y")), value = c(1871, as.integer(format(Sys.Date(), "%Y"))), step = 1)
    updateSelectInput(session, inputId="begin_month", choices=c("(coming soon)", month_names))
    updateSelectInput(session, inputId="begin_date", choices=c("(coming soon)", ""))
    updateSelectInput(session, inputId="end_month", choices=c("(coming soon)", month_names))
    updateSelectInput(session, inputId="end_date", choices=c("(coming soon)", ""))
  })
  
  
  
  #  -----------------  #
  # |  SUBMIT BUTTON  | #
  #  -----------------  #
  
  # Process the following when the "Submit" button is pressed
  observeEvent(input$submit, {
    updateTabsetPanel(session, inputId="inTabset", selected = "Graph")
    
    # Chech whether submitting data request for the same station 
    station_search_history <<- c(station_search_history[length(station_search_history)], input$station)
    if(station_search_history[length(station_search_history)]==station_search_history[length(station_search_history)-1]){
      SAME_STATION_FLAG <<- TRUE
    }
    else{
      SAME_STATION_FLAG <<-FALSE; TIME_SERIES_FLAG <<- FALSE
    }
    
    # Obtain the station name (as a string), station information (as an R data frame), and the type of time series (as a string)
    virtual_station_name <<- input$station
    region_name <<- input$region
    type_record <<- input$record_type
    
    # Generate the plot of the extreme record data
    if(input$data_type=="Extreme Record"){
      param_slider_label <<- yAxisTextLabel(input$parameter)
      element1 <<- "DAILY MAXIMUM TEMPERATURE"; element2 <<- "DAILY MINIMUM TEMPERATURE"
      
      # Plot all four temperature extreme records 
      if(type_record=="All of the Above"){
        df_all_extreme <<- read.csv(paste0("data/Temperature/TEMP_EXTREME_RECORDS_", 
                                           toupper(virtual_station_name), " AREA.csv"))
        
        df_high_max <<- subset(df_all_extreme, select=c(LOCAL_MONTH, LOCAL_DAY, YEAR_HIGH_MAX, TEMP_HIGH_MAX))
        df_low_max  <<- subset(df_all_extreme, select=c(LOCAL_MONTH, LOCAL_DAY, YEAR_LOW_MAX, TEMP_LOW_MAX))
        df_high_min <<- subset(df_all_extreme, select=c(LOCAL_MONTH, LOCAL_DAY, YEAR_HIGH_MIN, TEMP_HIGH_MIN))
        df_low_min  <<- subset(df_all_extreme, select=c(LOCAL_MONTH, LOCAL_DAY, YEAR_LOW_MIN, TEMP_LOW_MIN))
         
        y_min <<- floor(min(df_all_extreme$TEMP_LOW_MIN, na.rm=TRUE)/10)*10
        y_max <<- ceiling(max(df_all_extreme$TEMP_HIGH_MAX, na.rm=TRUE)/10)*10
        
        # Update the x-axis and y-axis slider widget controls (The 8th column stores the time (year) information)
        updateSliderInput(session, inputId="x_axis_range", label="Record Year Range", 
                          min=min(subset(df_all_extreme, 
                                         select=c(YEAR_HIGH_MAX, YEAR_LOW_MAX, YEAR_HIGH_MIN, YEAR_LOW_MIN)), na.rm=TRUE), 
                          max=max(subset(df_all_extreme, 
                                         select=c(YEAR_HIGH_MAX, YEAR_LOW_MAX, YEAR_HIGH_MIN, YEAR_LOW_MIN)), na.rm=TRUE), step=1)
        updateSliderInput(session, inputId="y_axis_range", label=param_slider_label, min=y_min, max=y_max, value = c(y_min, y_max), step=1)
        
        output$graph <<- renderPlot(expr=plotAllTempDailyExtremes(df_all_extreme, paste0(virtual_station_name, ", ", region_name), 
                                                               ymin=min(input$y_axis_range), ymax=max(input$y_axis_range), 
                                                               ybreak=5, year_min=min(input$x_axis_range), 
                                                               year_max=max(input$x_axis_range)),
                                          width = 1350, height = 600, res = 120)
        
       
        output$data_table <<- DT::renderDataTable({datatable(df_all_extreme, 
                                                             colnames=c("Month", "Day", "Year High Max", "Temp High Max (°C)", 
                                                                        "Year Low Max", "Temp Low Max (°C)", 
                                                                        "Year High Min", "Temp High Min (°C)",
                                                                        "Year Low Min", "Temp Low Min (°C)"))})
        output$click_info_1 <<- renderPrint({})
        output$top_N_rows <<- DT::renderDataTable({})
        output$top_N_rows_title <<- renderText(" ")
      }
      
      # Plot only one temperature extreme record
      else{
        
        if(type_record=="Highest Maximum" || type_record=="Highest Minimum"){DSC = TRUE}
        else if(type_record=="Lowest Maximum" || type_record=="Lowest Minimum"){DSC = FALSE}
        else{}
        
        if(type_record=="Highest Maximum" || type_record=="Lowest Maximum"){
          element1 <<- "DAILY MAXIMUM TEMPERATURE"; element2 <<- " "
        }
        else if(type_record=="Highest Minimum" || type_record=="Lowest Minimum"){
          element1 <<- " "; element2 <<- "DAILY MINIMUM TEMPERATURE"
        }
        else{}
        
        df_extreme <<- TempExtremeByDate(con, type_record, descending=DSC, virtual_station_name, FALSE)
        df_ranked <<- TempExtremeByRank(df_extreme, type_record, "LOCAL_TIME", DSC)
        
        y_min <<- floor(min(df_ranked$TEMPERATURE, na.rm=TRUE)/10)*10
        y_max <<- ceiling(max(df_ranked$TEMPERATURE, na.rm=TRUE)/10)*10
        
        # Update the x-axis and y-axis slider widget controls (The 8th column stores the time (year) information)
        updateSliderInput(session, inputId="x_axis_range", label="Record Year Range", 
                          min=min(df_extreme[,8], na.rm=TRUE), max=max(df_extreme[,8], na.rm=TRUE), 
                          value = c(min(df_extreme[,8], na.rm=TRUE), max(df_extreme[,8], na.rm=TRUE)), step=1)
        updateSliderInput(session, inputId="y_axis_range", label=param_slider_label, min=y_min, max=y_max, value = c(y_min, y_max), step=1)
        
        # Plot the Temperature Extreme Graph
        output$graph <<- renderPlot(expr=plotTempDailyExtreme(df_extreme, paste0(virtual_station_name, ", ", region_name), type_record, 
                                                           ymin=min(input$y_axis_range), ymax=max(input$y_axis_range), ybreak=5, rank=FALSE, 
                                                           extreme_N=1, year_min=min(input$x_axis_range), year_max=max(input$x_axis_range)),
                                          width = 1350, height = 600, res = 120)
        
        # This is the data frame used to display detailed information when a data point in the plot is clicked 
        # (The 8th column stores the time (year) information, the 9th column stores the temperature record information)
        df_on_click <<- data.frame(as.Date(paste("2000-", as.character(df_extreme$LOCAL_MONTH), "-", as.character(df_extreme$LOCAL_DAY), sep="")), 
                                         df_extreme[,8], df_extreme$LOCAL_MONTH, df_extreme$LOCAL_DAY, round(df_extreme[,9], digits=1))
        colnames(df_on_click) <<- c("Date", "Year", "Month", "Day", "Extreme Temperature (°C)")
        
        # Output the corresponding row of the data frame when a data point in the plot is clicked 
        output$click_info_1 <<- renderPrint({
          nearPoints(df_on_click, input$plot_click, xvar="Date", yvar="Extreme Temperature (°C)", threshold=5, maxpoints=1)
        })
        
        # Simplified Version of the Data Frame to be displayed in Table View
        df_display <<- TempExtremeByDate(con, type_record, descending=DSC, virtual_station_name, display=TRUE)
        output$data_table <<- DT::renderDataTable({datatable(df_display, colnames=c("Date Recorded", "Year", "Month", "Day", "Temperature (°C)", "Rank"))})
        output$top_N_rows <<- DT::renderDataTable({datatable(df_ranked[1:5,], colnames=c("Rank", "Extreme Temperature", 
                                                                                        "Date", "Year", "Month", "Day"))})
        output$top_N_rows_title <<- renderText("All-time Extreme Records Ranking:")
      }
      
      # No missing data for extreme records (leave them empty)
      output$NA_data <<- DT::renderDataTable({})
      output$skipped_dates <<- DT::renderDataTable({})
      output$percent_complete_NA <<- renderText("")
      output$percent_complete_dates <<- renderText("")
      
    }
    
    # Generate the plot of the Time Series data
    # Plot Type #1: Daily Temperature Time Series
    else if(input$data_type=="Time Series") {
      if(!(SAME_STATION_FLAG==TRUE && TIME_SERIES_FLAG==TRUE)) {
        TIME_SERIES_FLAG <<- TRUE
        
        # Generate the temperature data frame 
        
        df_temp_time_series <<- data.frame(read.csv(paste0("data/Temperature/TEMP_TIME_SERIES_", 
                                                           toupper(virtual_station_name), " AREA.csv")))
        df_temp_time_series$LOCAL_TIME <<- as.Date(df_temp_time_series$LOCAL_TIME, format="%Y-%m-%d")
        df_temp_time_series$MEAN_TEMPERATURE <<- round((df_temp_time_series$MAX_TEMPERATURE+df_temp_time_series$MIN_TEMPERATURE)/2, digits=1)
        df_temp_time_series <<- df_temp_time_series[, c("LOCAL_TIME", "LOCAL_YEAR", "LOCAL_MONTH", "LOCAL_DAY", 
                                "MIN_TEMPERATURE","MAX_TEMPERATURE", "MEAN_TEMPERATURE")]
      } 
        # Output the corresponding row of the data frame when a data point in the plot is clicked 
        df_on_click <<- data.frame(as.Date(df_temp_time_series$LOCAL_TIME, format="%Y-%m-%d"), 
                                   round(df_temp_time_series$MAX_TEMPERATURE, digits=1), 
                                   round(df_temp_time_series$MIN_TEMPERATURE, digits=1), df_temp_time_series$MEAN_TEMPERATURE)
        colnames(df_on_click) <<- c("Date (YYYY-MM-DD)", "Daily Max (°C)", "Daily Min (°C)", "Daily Mean (°C)")
      
      
      # Update the x-axis and y-axis slider widget controls
      param_slider_label <<- yAxisTextLabel(input$parameter)
      updateSliderInput(session, inputId="x_axis_range", label="x-axis: Year Range", 
                        min=min(df_temp_time_series$LOCAL_YEAR, na.rm=TRUE), max=max(df_temp_time_series$LOCAL_YEAR, na.rm=TRUE), 
                        value = c(min(df_temp_time_series$LOCAL_YEAR, na.rm=TRUE), max(df_temp_time_series$LOCAL_YEAR, na.rm=TRUE)), step=1)
      
      y_min <<- floor(min(df_temp_time_series$MIN_TEMPERATURE, na.rm=TRUE)/10)*10
      y_max <<- ceiling(max(df_temp_time_series$MAX_TEMPERATURE, na.rm=TRUE)/10)*10
      updateSliderInput(session, inputId="y_axis_range", label=param_slider_label, min=y_min, max=y_max, value = c(y_min, y_max), step=1)
      
      # Determine the Record Type of temperature time series to plot
      if(input$record_type=="Maximum") {
        element1 <<- "DAILY MAXIMUM TEMPERATURE"; element2 <<- " "
        plot_Tmax <<- TRUE; plot_Tmin <<- FALSE; y_click1<<-"Daily Max (°C)" #;  
        output$click_info_2 <<- renderPrint({})
      }
      else if(input$record_type=="Minimum") {
        element1 <<- "DAILY MINIMUM TEMPERATURE"; element2 <<- " "
        plot_Tmax <<- FALSE; plot_Tmin <<- TRUE; y_click1<<-"Daily Min (°C)" #;
        output$click_info_2 <<- renderPrint({})
      }
      if(input$record_type=="Maximum & Minimum") {
        element1 <<- "DAILY MAXIMUM TEMPERATURE"; element2 <<- "DAILY MINIMUM TEMPERATURE"
        plot_Tmax <<- TRUE; plot_Tmin <<- TRUE; y_click1<<-"Daily Min (°C)"; y_click2<<-"Daily Max (°C)"
        
        # Output the corresponding row of the data frame when a data point in the plot is clicked 
        output$click_info_2 <<- renderPrint({
          nearPoints(df_on_click, input$plot_click, xvar="Date (YYYY-MM-DD)", yvar=y_click2, threshold=5, maxpoints=1)
        })
      }
      else if(input$record_type=="Mean"){
        element1 <<- "DAILY MAXIMUM TEMPERATURE"; element2 <<- "DAILY MINIMUM TEMPERATURE"
        plot_Tmax <<- FALSE; plot_Tmin <<- FALSE; y_click1<<-"Daily Mean (°C)" #;
        output$click_info_2 <<- renderPrint({})
      }
      
      else{}
      
      # Plot the Temperature Time Series Graph
      output$graph <<- renderPlot(expr=plotTempDailyTimeSeries(df_temp_time_series, paste0(virtual_station_name, ", ", region_name), 
                                                                min(input$y_axis_range), max(input$y_axis_range), y_break, 
                                                                min(input$x_axis_range), max(input$x_axis_range), x_break, 
                                                                plot_Tmax, plot_Tmin, trend=input$trend_line, eqn=input$trend_eqn),
                                       width = 1350, height = 600, res = 120)
      
      # Output the corresponding row of the data frame when a data point in the plot is clicked 
      output$click_info_1 <<- renderPrint({
        nearPoints(df_on_click, input$plot_click, xvar="Date (YYYY-MM-DD)", yvar=y_click1, threshold=5, maxpoints=1)
        })
      
      # Generate data tables for NA temperature values, skipped dates, and the time series
      output$NA_data <<- DT::renderDataTable({datatable(filterNAData(df_temp_time_series), colnames=c("Date", "Year", "Month", "Day",
                                                                                                "T Minimum (°C)", "T Maximum (°C)", "T Mean (°C)"))})
      output$skipped_dates <<- DT::renderDataTable({datatable(filterSkippedDates(df_temp_time_series), colnames=c("Date", "Year", "Month", "Day",
                                                                                                      "T Minimum (°C)", "T Maximum (°C)", "T Mean (°C)"))})
      output$data_table <<- DT::renderDataTable({datatable(df_temp_time_series, colnames=c("Date", "Year", "Month", "Day", 
                                                                                           "T Minimum (°C)", "T Maximum (°C)", "T Mean (°C)"))})
      
      output$percent_complete_NA <<- renderText(paste0("Percent Completeness = ", 
                                                       as.character(round((1 - nrow(filterNAData(df_temp_time_series))/nrow(df_temp_time_series))*100, 
                                                                          digits=2)), " %"))                                                                         
      output$percent_complete_dates <<- renderText(paste0("Percent Completeness = ", 
                                                          as.character(round((1 - nrow(filterSkippedDates(df_temp_time_series))/
                                                                                (nrow(filterSkippedDates(df_temp_time_series))+
                                                                                   nrow(df_temp_time_series)))*100, digits=2)), " %"))                                                                                                                                                       
      output$top_N_rows_title <<- renderText(" ")
      output$top_N_rows <<- DT::renderDataTable({})
    }
    
    else{}
    
    # Update default table to download when the "Download" button is pressed
    observeEvent(input$inTabset, {
      if(input$inTabset=="Table" || input$inTabset=="Graph") {
        if(input$data_type=="Time Series"){
          download_table <<- df_temp_time_series; file_name <<- "TEMP_TIME_SERIES_"
        }
        else {
          #download_table <<- df_display; file_name <<- "TEMP_EXTREME_RECORDS_"
        }
      }
      else if(input$inTabset=="Missing"){
        if(input$data_type=="Time Series") {
          download_table <<- rbind(filterNAData(df_temp_time_series), filterSkippedDates(df_temp_time_series))
          file_name <<- "TEMP_MISSING_DATA_"
        }
        else{
          file_name <<- "EMPTY_"; download_table <<- data.frame()
        }
      }
      else {
        file_name <<- "EMPTY_"; download_table <<- data.frame()
      }
    })
  })
  
  
    
  #  -------------------  #
  # |  DOWNLOAD BUTTON  | #
  #  -------------------  #
  
  # Generate a CSV file when the "Download" button is pressed
  output$download <- downloadHandler(
    filename = function() {
      paste(file_name, toupper(virtual_station_name), ".csv", sep="")
    },
    content = function(file) {
      write.csv(as.data.frame(download_table), file)
    }
  )
    
  
  
  #  ---------------------  #
  # |  OPTIONAL CHECKBOX  | #
  #  ---------------------  #
  
  # Coming soon: optional add-on features to embed in the plot
  observeEvent(input$checkGroup, {
    if(input$checkGroup=="Highlight Missing Data Range"){
    }
    else if(input$checkGroup=="Display Trend Line(s)"){
    }
    else if(input$checkGroup=="Highlight Missing Data Range" & input$checkGroup=="Display Trend Line(s)"){
    }
    else{}
  })
  
  
  
  #  -------------------------  #
  # |  CLOSE CURRENT SESSION  | #
  #  -------------------------  #
  
  # Disconnect from Arkeon database when the current session is closed
  onSessionEnded(function() {stopApp()}, session = getDefaultReactiveDomain())
}