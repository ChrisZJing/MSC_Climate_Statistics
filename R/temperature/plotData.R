# Description: This file contains all the functions for plotting/graphing visualizations
# Project:     Canadian Climate Statistics Explorer 
# Author:      Chris Jing
# Created on:  2019-12-26


# Load the source R codes
source("R/temperature/cleanData.R", print=TRUE)

#  -------------  #
# |  CONSTANTS  | #
#  -------------  #

# Color Code 
blue <- "#0000FF"       # Lowest Minimum
light_blue <- "#1E90FF" # T_min or Highest Minimum
red <- "#FF0000"        # Highest Maximum
light_red  <- "#B22222" # T_max or Lowest Maximum
black <- "#000000"      # for trend line
green <- "#32CD32"      # T_mean

# Monthly Time Series Color Code
jan_color <- "#0066FF"; feb_color <- "#00FFFF"; mar_color <- "#66FFCC"; apr_color <- "#66FF66"
may_color <- "#CCFF66"; jun_color <- "#FFFF66"; jul_color <- "#FFCC66"; aug_color <- "#FF6666"
sep_color <- "#FF66CC"; oct_color <- "#FF66FF"; nov_color <- "#CC66FF"; dec_color <- "#6666FF"


monthly_labels <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", 
                    "Sep", "Oct", "Nov", "Dec", "Annual Mean", "Trend Line")
monthly_values <- c("Jan"=jan_color, "Feb"=feb_color, "Mar"=mar_color, "Apr"=apr_color, "May"=may_color,
                    "Jun"=jun_color, "Jul"=jul_color, "Aug"=aug_color, "Sep"=sep_color, "Oct"=oct_color,
                    "Nov"=nov_color, "Dec"=dec_color, "Annual Mean"=green, "Trend Line"=red)


#  -------------------  #
# | TABLE OF CONTENTS | #
#  -------------------  #

# PART I (#P2-01~02): TEMPERATURE EXTREMES PLOTTING FUNCTIONS
# PART II (#P1-01~02):TEMPERATURE TIME SERIES PLOTTING FUNCTIONS
# PART III (#P3-01):  PLOTTING AESTHETIC FUNCTIONS 



#  ----------------------------------------------  #
# |                                              | #
# |  I. TEMPERATURE EXTREMES PLOTTING FUNCTIONS  | #
# |                                              | #
#  ----------------------------------------------  #

# FUNCTION #P1-01
# Purpose: This function plots the climate extreme values vs dates in a year for a virtual station 
# Inputs:df [R data frame]    - the data table that stores the temperature time series
#                               (see output of FUNCTION #C1-02 in cleanData as an example)
#        vrt_stn_name [character]   - the name of the virtual station (e.g "Vancouver Area")
#        type [character]     - the type of extreme data 
#                             ("highest maximum", "lowest maximum", "highest minimum", or "lowest minimum")
#        ymin [integer]       - the lower bound of the y-axis (degrees; e.g. -10)
#        ymax [integer]       - the upper bound of the y-axis (degrees; e.g. 30)
#        ybreak [integer]     - the spacing interval of the y-axis (degrees; e.g. 2)
#        rank [boolean]       - TRUE if rank the extreme values when plotting
#        extreme_N [integer]  - number of data points (with the most extreme values) to highlight
#        year_min [integer]       - the lower bound of the record year (e.g. 1896)
#        year_max [integer]       - the upper bound of the record year (e.g. 2019)
# Output: A plot of climate extreme values vs dates in a year 
plotTempDailyExtreme <- function(df, vrt_stn_name, type, ymin, ymax, ybreak, rank, extreme_N, year_min, year_max){
  ranked_df <- df[with(df, order(df %>% select(matches("RANK")))),]
  timed_df  <- df[with(df, order(df %>% select(matches("LOCAL_TIME")))),]
  
  # check for the type of extreme data
  if(type=="Highest Maximum"){
    valueColumnName = "RECORD_HIGH_MAX_TEMP"
    yearColumnName  = "RECORD_HIGH_MAX_TEMP_YR"
    colorName       = "Record High Maximum"
    colorValue      = red
    highest_rank    = 1; lowest_rank = 366
  }
  else if(type=="Lowest Maximum"){
    valueColumnName = "RECORD_LOW_MAX_TEMP"
    yearColumnName  = "RECORD_LOW_MAX_TEMP_YR"
    colorName       = "Record Low Maximum"
    colorValue      = light_red
    highest_rank    = 366; lowest_rank = 1
  }
  else if(type=="Highest Minimum"){
    valueColumnName = "RECORD_HIGH_MIN_TEMP"
    yearColumnName  = "RECORD_HIGH_MIN_TEMP_YR"
    colorName       = "Record High Minimum"
    colorValue      = light_blue
    highest_rank    = 1; lowest_rank = 366
  }
  else if(type=="Lowest Minimum"){
    valueColumnName = "RECORD_LOW_MIN_TEMP"
    yearColumnName  = "RECORD_LOW_MIN_TEMP_YR"
    colorName       = "Record Low Minimum"
    colorValue      = blue
    highest_rank    = 366; lowest_rank = 1
  }
  else{}
  
  df <- df[(df[,8]>=year_min & df[,8]<=year_max),]
  
  # Case 1: ranking not required
  if(rank==FALSE){
    newPlot <- ggplot(data=df, aes(x=as.Date(paste("2000-", as.character(LOCAL_MONTH), "-", as.character(LOCAL_DAY), sep="")))) + 
      geom_point(aes(y=df[, valueColumnName], color=colorName), shape=16, size=1) +
      labs(title=paste("Daily Climate Extremes for", vrt_stn_name, sep=" "), 
           subtitle=paste("Earliest Extreme: ", as.character(format(timed_df[1, valueColumnName])), "°C on ",
                          as.character(format(timed_df[1, "LOCAL_TIME"], format="%Y-%m-%d")),
                          "; Latest Extreme: ", as.character(format(timed_df[366, valueColumnName])), "°C on ",
                          as.character(format(timed_df[366, "LOCAL_TIME"], format="%Y-%m-%d")), "\n",
                          "Highest Extreme: ", as.character(max(df[, valueColumnName])), "°C on ", as.character(format(ranked_df[highest_rank, "LOCAL_TIME"], format="%Y-%m-%d")),
                          "; Lowest Extreme: ", as.character(min(df[, valueColumnName])),"°C on ", as.character(format(ranked_df[lowest_rank, "LOCAL_TIME"], format="%Y-%m-%d")), sep=""), 
           x="Date (in any given year)", y="Temperature (°C)", 
           colour="Data Index", caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
      scale_x_date(limits=c(as.Date("2000-01-01"),as.Date("2000-12-31")), date_labels="%b %d", breaks=seq(as.Date("2000-01-01"), as.Date("2000-12-31"), "1 month")) +
      scale_y_continuous(limits=c(ymin, ymax), breaks=seq(from=ymin, to=ymax, by=ybreak)) + 
      scale_color_manual(labels=colorName, values=colorValue) +
      geom_text(aes(y=df[,valueColumnName], color=colorName, label=ifelse((RANK<=extreme_N), as.character(paste(df[, yearColumnName], "\n", df[, valueColumnName], "°C", sep="")), '')), hjust=0, vjust=0, show.legend=FALSE) 
  }
  
  # Case 2: ranking required
  else{
    newPlot <- ggplot(data=df, aes(x=RANK)) + 
      geom_point(aes(y=df[, valueColumnName], color=colorName), shape=21, size=2) +
      labs(title=paste("Daily Climate Extremes for", vrt_stn_name, sep=" "), 
           subtitle=paste("Earliest Extreme: ", as.character(format(timed_df[1, valueColumnName])), "°C on ",
                          as.character(format(timed_df[1, "LOCAL_TIME"], format="%Y-%m-%d")),
                          "; Latest Extreme: ", as.character(format(timed_df[366, valueColumnName])), "°C on ",
                          as.character(format(timed_df[366, "LOCAL_TIME"], format="%Y-%m-%d")), "\n",
                          "Highest Extreme: ", as.character(max(df[, valueColumnName])), "°C on ", as.character(format(ranked_df[highest_rank, "LOCAL_TIME"], format="%Y-%m-%d")),
                          "; Lowest Extreme: ", as.character(min(df[, valueColumnName])),"°C on ", as.character(format(ranked_df[lowest_rank, "LOCAL_TIME"], format="%Y-%m-%d")), sep=""), 
           x="Ranking Result (out of 366 days)", y="Temperature (°C)", 
           colour="Data Index", caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
      scale_x_continuous(limits=c(1, 366), breaks=seq(from=1, to=366, by=15)) +
      scale_y_continuous(limits=c(ymin, ymax), breaks=seq(from=ymin, to=ymax, by=ybreak)) + 
      scale_color_manual(labels=colorName, values=colorValue) +
      geom_text(aes(y=df[,valueColumnName], color=colorName, label=ifelse((RANK<=extreme_N), as.character(paste(df[, yearColumnName], "\n", df[, valueColumnName], "°C", sep="")), '')), hjust=0, vjust=0, show.legend=FALSE) 
  }
  return(newPlot)
}


# FUNCTION #P1-02
# Purpose: Similar as #P1-01, except it plots all four sets of extreme data in the same graph
# Inputs:con [OraConnection]  - the connection between R and Arkeon 
#        vrt_stn_name [character] - name of the virtual station (e.g "Vancouver Area")
#        ymin [integer]       - the lower bound of the y-axis (degrees; e.g. -10)
#        ymax [integer]       - the upper bound of the y-axis (degrees; e.g. 30)
#        ybreak [integer]     - the spacing interval of the y-axis (degrees; e.g. 2)
#        year_min [integer]   - the lower bound of the record year (e.g. 1896)
#        year_max [integer]   - the upper bound of the record year (e.g. 2019)
# Output: A plot of climate extreme values vs dates in a year 
plotAllTempDailyExtremes <- function(df_in, vrt_stn_name, ymin, ymax, ybreak, year_min, year_max){
  
  colorNames <- c("Record High Maximum", "Record Low Maximum", "Record High Minimum", "Record Low Minimum")
  colorValues <- c("Record High Maximum"=red, "Record Low Maximum"=light_red, "Record High Minimum"=light_blue, "Record Low Minimum"=blue)
  
  df_high_max <<- subset(df_in, select=c(LOCAL_MONTH, LOCAL_DAY, YEAR_HIGH_MAX, TEMP_HIGH_MAX))
  df_low_max  <<- subset(df_in, select=c(LOCAL_MONTH, LOCAL_DAY, YEAR_LOW_MAX, TEMP_LOW_MAX))
  df_high_min <<- subset(df_in, select=c(LOCAL_MONTH, LOCAL_DAY, YEAR_HIGH_MIN, TEMP_HIGH_MIN))
  df_low_min  <<- subset(df_in, select=c(LOCAL_MONTH, LOCAL_DAY, YEAR_LOW_MIN, TEMP_LOW_MIN))
  
  df_high_max <- df_high_max[(df_high_max[,YEAR_HIGH_MAX]>=year_min & df_high_max[,YEAR_HIGH_MAX]<=year_max),]
  df_low_max <-  df_low_max[(df_low_max[,YEAR_LOW_MAX]>=year_min & df_low_max[,YEAR_LOW_MAX]<=year_max),]
  df_high_min <- df_high_min[(df_high_min[,YEAR_HIGH_MIN]>=year_min & df_high_min[,YEAR_HIGH_MIN]<=year_max),]
  df_low_min <-  df_low_min[(df_low_min[,YEAR_LOW_MIN]>=year_min & df_low_min[,YEAR_LOW_MIN]<=year_max),]
  
  timed_df_high_max <- df_high_max[with(df_high_max, order(df_high_max %>% select(matches("LOCAL_MONTH")),
                                                           df_high_max %>% select(matches("LOCAL_DAY")))),]
  timed_df_low_max  <- df_low_max[with(df_low_max, order(df_low_max %>% select(matches("LOCAL_MONTH")),
                                                         df_low_max %>% select(matches("LOCAL_DAY")))),]
  timed_df_high_min <- df_high_min[with(df_high_min, order(df_high_min %>% select(matches("LOCAL_MONTH")),
                                                           df_high_min %>% select(matches("LOCAL_DAY")))),]
  timed_df_low_min  <- df_low_min[with(df_low_min, order(df_low_min %>% select(matches("LOCAL_MONTH")),
                                                         df_low_min %>% select(matches("LOCAL_DAY")))),]
  
  newPlot <- ggplot(data=df_in, aes(x=as.Date(paste("2000-", as.character(LOCAL_MONTH), "-", as.character(LOCAL_DAY), sep="")))) + 
    geom_point(data=df_in, aes(y=df_in[, TEMP_HIGH_MAX], color=colorNames[1]), shape=16, size=1) +
    geom_point(data=df_in, aes(y=df_in[, TEMP_HIGH_MIN], color=colorNames[2]), shape=16, size=1) +
    geom_point(data=df_in, aes(y=df_in[, TEMP_LOW_MAX], color=colorNames[3]), shape=16, size=1) +
    geom_point(data=df_in, aes(y=df_in[, TEMP_LOW_MIN], color=colorNames[4]), shape=16, size=1) +
    
    labs(title=paste("Daily Temperature Extremes for", vrt_stn_name, sep=" "), 
         subtitle=paste("Highest Maximum Ever Recorded: ", as.character(max(timed_df_high_max[, TEMP_HIGH_MAX])), "°C on ",
                        as.character(format(timed_df_high_max[which.max(timed_df_high_max$TEMP_HIGH_MAX), YEAR_HIGH_MAX]), format="%Y"),
                        "; Lowest Maximum Ever Recorded: ", as.character(min(timed_df_low_max[, TEMP_LOW_MAX])), "°C on ",
                        as.character(format(timed_df_low_max[which.min(timed_df_low_max$TEMP_LOW_MAX), YEAR_LOW_MAX]), format="%Y"), "\n",
                        "Highest Minimum Ever Recorded: ", as.character(max(timed_df_high_min[, TEMP_HIGH_MIN])), "°C on ", 
                        as.character(format(timed_df_high_min[which.max(timed_df_high_min$TEMP_HIGH_MIN), YEAR_HIGH_MIN]), format="%Y"), "\n",
                        "; Lowest Minimum Ever Recorded: ", as.character(min(timed_df_low_min[, TEMP_LOW_MIN])),"°C on ", 
                        as.character(format(timed_df_low_min[which.min(timed_df_low_min$TEMP_LOW_MIN), YEAR_LOW_MIN]), format="%Y")),
         x="Date (in any given year)", y="Temperature (°C)", 
         colour="Data Index", caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
    scale_x_date(limits=c(as.Date("2000-01-01"),as.Date("2000-12-31")), date_labels="%b %d", 
                 breaks=seq(as.Date("2000-01-01"), as.Date("2000-12-31"), "1 month")) +
    scale_y_continuous(limits=c(ymin, ymax), breaks=seq(from=ymin, to=ymax, by=ybreak)) + 
    scale_color_manual(labels=colorNames, breaks=colorNames, values=colorValues) 
  return(newPlot)
}



#  ------------------------------------------------  #
# |                                                | #
# | II. TEMPERATURE TIME SERIES PLOTTING FUNCTIONS | #
# |                                                | #
#  ------------------------------------------------  #

# FUNCTION #P2-01
# Purpose:This function plots the maximum and minimum temperature time series 
#         for any selected virtual station in Canada
# Inputs: df [list]          - the data frame that stores the temperature time series 
#                              (output of FUNCTION #C4-01, TempDailyTimeSeries) 
#         vrt_stn_name [character] - the name of the virtual station to display in the plot
#         ymin [double]      - the lower bound of the y-axis (temperature; e.g. -50)
#         ymax [double]      - the upper bound of the y-axis (temperature; e.g. 40)
#         ybreak [double]    - the spacing interval of the y-axis (temperature; e.g. 5)
#         xmin [integer]     - the lower bound of the x-axis (year; e.g. 1896)
#         xmax [integer]     - the upper bound of the x-axis (year; e.g. 2019)
#         xbreak [character] - the spacing interval between adjacent ticks (e.g. "5 years")
#         Tmax [boolean]     - if TRUE, plot the daily MAXimum temperature time series
#         Tmin [boolean]     - if TRUE, plot the daily MINimum temperature time series
#         Tmean [boolean]    - if TRUE, plot the daily MEAN temperature time series
#         trend [boolean]    - if TRUE, display trend line (linear fit)
#         eqn [boolean]      - if TRUE, display the equation (of the trend line) 
# Output: A plot of the daily minimum or/and maximum or mean temperature time series 
plotTempDailyTimeSeries <- function(df, vrt_stn_name, ymin, ymax, ybreak, xmin, xmax, xbreak, Tmax, Tmin, Tmean, trend, eqn) {
  
  # Case 1: Plot the time series for a SINGLE year only
  if(xmin==xmax) {
    dot_size=2; dot_shape=1; x_date_break="1 month"; x_date_labels="%Y-%b-%d"; xmin_date=paste(as.character(xmin), "-01-01", sep="")
    
    # Plot this year's data (let the end date be yesterday)
    if(xmax==max(df$LOCAL_YEAR, na.rm=TRUE)) { 
      xmax_date=as.Date(max(df$LOCAL_TIME, na.rm=TRUE), format="%Y-%m-%d")
    }
    
    # Plot other year's data (let the end date be December 31)
    else{ 
      xmax_date=paste(as.character(xmax), "-12-31", sep="")
    }
  }
  
  # Case 2: Plot the time series for MULTIPLE years
  else{
    dot_size=1; dot_shape=1; x_date_labels="%Y"
    
    # Let the start/end date be Jan. 1/Dec. 31 if the begin/end year is other than the first/last year when record begins
    if(xmin==min(df$LOCAL_YEAR, na.rm=TRUE)){
      xmin_date=as.Date(min(df$LOCAL_TIME, na.rm=TRUE), format="%Y-%m-%d")
    }
    else{
      xmin_date=paste(as.character(xmin), "-01-01", sep="")
    }
    if(xmax==max(df$LOCAL_YEAR, na.rm=TRUE)){
      xmax_date=as.Date(max(df$LOCAL_TIME, na.rm=TRUE), format="%Y-%m-%d")
    }
    else{
      xmax_date=paste(as.character(xmax), "-12-31", sep="")
    }
    
    # Make the x-axis scale size adjustable based on the time span
    if(xmax-xmin > 50){
      x_date_break = "5 years"
    }
    else if(xmax-xmin > 20){
      x_date_break = "2 years"
    }
    else if(xmax-xmin > 1){
      x_date_break = "1 year"
    }
    else{
      x_date_break = "1 month"
    }
  }
  
  # Determine the type of plot to generate: T_min & T_max, T_min only, T_max only, or T_mean only
  if(Tmax==TRUE && Tmin==TRUE) {
    yData1 <- df$MAX_TEMPERATURE; yData2 <- df$MIN_TEMPERATURE
    typeData=c("Daily Maximum", "Daily Minimum"); colorCode=c(light_red, light_blue)
    
    newPlot <- ggplot(data=df, aes(x=as.Date(LOCAL_TIME, format="%Y-%m-%d"))) + 
      geom_point(aes(y=MAX_TEMPERATURE,color="Daily Maximum", onclick=MAX_TEMPERATURE), shape=dot_shape, size=dot_size) + 
      geom_point(aes(y=MIN_TEMPERATURE, color="Daily Minimum", onclick=MIN_TEMPERATURE), shape=dot_shape, size=dot_size) +
      labs(title=paste("Daily Maximum and Minimum Temperature Time Series for", vrt_stn_name, sep=" "), 
           subtitle=paste("Record from", xmin_date, "to", xmax_date, sep=" "), 
           x="Time (date)", y="Temperature (°C)", 
           colour="Data Index", caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
      scale_x_date(date_labels=x_date_labels, date_breaks=x_date_break, limits=c(as.Date(xmin_date),as.Date(xmax_date))) + 
      scale_y_continuous(limits=c(ymin, ymax), breaks=seq(from=ymin, to=ymax, by=ybreak))
  }
  
  else if(Tmin==TRUE) {
    yData <- df$MIN_TEMPERATURE
    typeData="Daily Minimum"; colorCode=light_blue
    
    newPlot <- ggplot(data=df, aes(x=as.Date(LOCAL_TIME, format="%Y-%m-%d"))) + 
      geom_point(aes(y=MIN_TEMPERATURE, color="Daily Minimum", onclick=MIN_TEMPERATURE), shape=dot_shape, size=dot_size) +
      labs(title=paste("Daily Minimum Temperature Time Series for", vrt_stn_name, sep=" "), 
           subtitle=paste("Record from", xmin_date, "to", xmax_date, sep=" "), 
           x="Time (date)", y="Temperature (°C)", colour="Data Index",
           caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
      scale_x_date(date_labels=x_date_labels, date_breaks=x_date_break, limits=c(as.Date(xmin_date),as.Date(xmax_date))) + 
      scale_y_continuous(limits=c(ymin, ymax), breaks=seq(from=ymin, to=ymax, by=ybreak))
  }
  
  else if(Tmax==TRUE) {
    yData <- df$MAX_TEMPERATURE
    typeData="Daily Maximum"; colorCode=light_red
    
    newPlot <- ggplot(data=df, aes(x=as.Date(LOCAL_TIME, format="%Y-%m-%d"))) + 
      geom_point(aes(y=MAX_TEMPERATURE, color="Daily Maximum", onclick=MAX_TEMPERATURE), shape=dot_shape, size=dot_size) +
      labs(title=paste("Daily Maximum Temperature Time Series for", vrt_stn_name, sep=" "), 
           subtitle=paste("Record from", xmin_date, "to", xmax_date, sep=" "), 
           x="Time (date)", y="Temperature (°C)", colour="Data Index",
           caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
      scale_x_date(date_labels=x_date_labels, date_breaks=x_date_break, limits=c(as.Date(xmin_date),as.Date(xmax_date))) + 
      scale_y_continuous(limits=c(ymin, ymax), breaks=seq(from=ymin, to=ymax, by=ybreak))
  }
  
  else {
    yData <- df$MEAN_TEMPERATURE
    typeData="Daily Mean"; colorCode=green 
    
    newPlot <- ggplot(data=df, aes(x=as.Date(LOCAL_TIME, format="%Y-%m-%d"))) + 
      geom_point(aes(y=(MAX_TEMPERATURE+MIN_TEMPERATURE)/2, colour="Daily Mean", onclick=(MAX_TEMPERATURE+MIN_TEMPERATURE)/2), shape=dot_shape, size=dot_size) +
      labs(title=paste("Daily Mean Temperature Time Series for", vrt_stn_name, sep=" "), 
           subtitle=paste("Record from", xmin_date, "to", xmax_date, sep=" "), 
           x="Time (date)", y="Temperature (°C)", colour="Data Index",
           caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
      scale_x_date(date_labels=x_date_labels, date_breaks=x_date_break, limits=c(as.Date(xmin_date),as.Date(xmax_date))) + 
      scale_y_continuous(limits=c(ymin, ymax), breaks=seq(from=ymin, to=ymax, by=ybreak))
  }
  
  # Add the trend line and equation if required
  if(trend==TRUE) {
    if(Tmax==TRUE && Tmin==TRUE) {
      newPlot <- newPlot + 
        geom_smooth(aes(y=yData1,color="Trend Line"), method="lm", formula=y ~ x, se=FALSE, size=0.5) +
        geom_smooth(aes(y=yData2,color="Trend Line"), method="lm", formula=y ~ x, se=FALSE, size=0.5) +
        scale_color_manual(labels=c("Daily Maximum", "Daily Minimum", "Trend Line", "Trend Line"), 
                           values=c(light_red, light_blue, black, black))
    }
    else{
      if(eqn==FALSE){
        newPlot <- newPlot + 
          geom_smooth(aes(y=yData,color="Trend Line"), method="lm", formula=y ~ x, se=FALSE, size=0.5) +
          scale_color_manual(labels=c(typeData, "Trend Line"), values=c(colorCode, black)) 
      }
      else{
        newPlot <- newPlot +
          geom_smooth(aes(y=yData,color="Trend Line"), method="lm", formula=y ~ x, se=FALSE, size=0.5) + 
          stat_poly_eq(formula=y ~ x, aes(y=yData, label=paste(stat(eq.label), stat(adj.rr.label), sep="~~~~")), parse=TRUE,
                                          label.y="bottom", label.x="right", show.legend=FALSE) + 
          scale_color_manual(labels=c(typeData, "Trend Line"), values=c(colorCode, black)) 
      }
    }
  }
  else{
    newPlot <- newPlot + scale_color_manual(labels=c(typeData), values=c(colorCode)) 
  }
  return(newPlot)
}



# FUNCTION #P2-02
# Purpose: This function plots the mean annual temperature (in Celcisus) vs time (in years) 
#         for a chosen virtial station (by name) with an optional linear fit trend line.
#         Include the option of including 12-month mean temperature time series. 
# Inputs:df [list]            - the data frame that stores the temperature time series
#                               (output of FUNCTION #C4-02, TempAnnualMeanTimeSeries) 
#        vrt_stn_name [character] - the name of the virtual station to display in the plot
#        ymin [integer]       - the lower bound of the y-axis (degrees; e.g. -20)
#        ymax [integer]       - the upper bound of the y-axis (degrees; e.g. 30)
#        ybreak [integer]     - the spacing interval of the y-axis (degrees; e.g. 2)
#        xmin [integer]       - the lower bound of the x-axis (year, e.g. 1896)
#        xmax [integer]       - the upper bound of the x-axis (year; e.g. 2019)
#        xbreak [integer]     - the x spacing interval between adjacent ticks (years; e.g. 5)
#        mean_only [boolean]  - if FALSE, include the 12 monthly time series; else TRUE
#        extreme_N [integer]  - number of data points (with the most extreme values) to label in the plot
# Output: A plot of the annual mean temperature time series 
plotTempAnnualMeanTimeSeries <- function(df, vrt_stn_name, ymin, ymax, ybreak, xmin, xmax, xbreak, mean_only, extreme_N) {
  
  linear.fit.formula <- y ~ x
  
  # Case 1: Plot both the annual and 12-month mean data 
  if(mean_only == FALSE) {
    newPlot <- ggplot(data=df, aes(x=LOCAL_YEAR)) + 
      geom_line(aes(y=JAN, color=monthly_labels[1]), size=1) + 
      geom_line(aes(y=FEB, color=monthly_labels[2]), size=1) +
      geom_line(aes(y=MAR, color=monthly_labels[3]), size=1) + 
      geom_line(aes(y=APR, color=monthly_labels[4]), size=1) + 
      geom_line(aes(y=MAY, color=monthly_labels[5]), size=1) + 
      geom_line(aes(y=JUN, color=monthly_labels[6]), size=1) + 
      geom_line(aes(y=JUL, color=monthly_labels[7]), size=1) +
      geom_line(aes(y=AUG, color=monthly_labels[8]), size=1) + 
      geom_line(aes(y=SEP, color=monthly_labels[9]), size=1) + 
      geom_line(aes(y=OCT, color=monthly_labels[10]), size=1)+ 
      geom_line(aes(y=NOV, color=monthly_labels[11]), size=1)+ 
      geom_line(aes(y=DEC, color=monthly_labels[12]), size=1)+ 
      geom_line(aes(y=ANNUAL_MEAN, color=monthly_labels[13]), size=1, linetype="dotted") + 
      geom_point(aes(y=ANNUAL_MEAN, color=monthly_labels[13]), show.legend=FALSE, shape=18, size=2) +
      geom_smooth(aes(y=ANNUAL_MEAN,color="Trend Line"), 
                  method="lm", formula=y ~ x, se=FALSE, size=0.5) +
      labs(title=paste("Annual Mean Temperature Time Series for", vrt_stn_name, sep=" "), 
           subtitle=paste("Record from", xmin, "to", xmax, sep=" "), 
           x="Time (year)", y="Temperature (°C)", colour="Month Index", 
           caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
      scale_x_continuous(limits=c(xmin, xmax), breaks=seq(from=xmin, to=xmax, by=xbreak)) + 
      scale_y_continuous(limits=c(ymin, ymax), breaks=seq(from=ymin, to=ymax, by=ybreak)) +
      scale_color_manual(labels=monthly_labels, breaks=monthly_labels,values=monthly_values) +
      stat_poly_eq(formula=linear.fit.formula, 
                   aes(y=ANNUAL_MEAN, label=paste(stat(eq.label), stat(adj.rr.label), sep="~~~~")), 
                   parse=TRUE, label.y="bottom", label.x="right") 
  }
  
  # Case 2: Plot only the annual mean data with the top and bottom N extreme data points labelled
  else {
    newPlot <- ggplot(data=df, aes(x=LOCAL_YEAR)) + 
      geom_point(aes(y=ANNUAL_MEAN, color="Annual Mean"), shape=18, size=2) +
      geom_line(aes(y=ANNUAL_MEAN, color="Annual Mean"), show.legend=FALSE, size=1, linetype="dotted") + 
      geom_smooth(aes(y=ANNUAL_MEAN,color="Trend Line"), 
                  method="lm", formula=y ~ x, se=FALSE, size=0.5) +
      labs(title=paste("Annual Mean Temperature Time Series for", vrt_stn_name, sep=" "), 
           subtitle=paste("Record from", xmin, "to", xmax, sep=" "), 
           x="Time (year)", y="Temperature (°C)", colour="Legend",
           caption=paste("(based on data extracted from Environment Canada as of ", Sys.Date(), ")", sep="")) + 
      scale_x_continuous(limits=c(xmin, xmax), breaks=seq(from=xmin, to=xmax, by=xbreak)) + 
      scale_y_continuous(limits=c(floor(min(df$ANNUAL_MEAN, na.rm=TRUE)-3), 
                                  ceiling(max(df$ANNUAL_MEAN, na.rm=TRUE)+3)), 
                         breaks=seq(from=floor((min(df$ANNUAL_MEAN, na.rm=TRUE)-3)), 
                                    to=(ceiling(max(df$ANNUAL_MEAN, na.rm=TRUE)+3)), by=ybreak)) +
      scale_color_manual(labels=c("Annual Mean", "Trend Line", "Top Ranked", "Bottom Ranked"), 
                         breaks=c("Annual Mean", "Trend Line", "Top Ranked", "Bottom Ranked"),
                         values=c("Annual Mean"=green, "Trend Line"=red, "Top Ranked"=red, "Bottom Ranked"=blue)) +
      stat_poly_eq(formula=linear.fit.formula, 
                   aes(y=ANNUAL_MEAN, label=paste(stat(eq.label), stat(adj.rr.label), sep="~~~~")), 
                   parse=TRUE, label.y="bottom", label.x="right") +
      geom_text(aes(y=ANNUAL_MEAN, colour="Top Ranked",  
                    label=ifelse((RANK<=extreme_N), as.character(paste(LOCAL_YEAR, "\n", ANNUAL_MEAN, "°C", sep="")), '')), 
                hjust=0, vjust=0, show.legend=FALSE) + 
      geom_text(aes(y=ANNUAL_MEAN, colour="Bottom Ranked", 
                    label=ifelse((RANK>nrow(na.omit(df))-extreme_N), 
                                 as.character(paste(LOCAL_YEAR, "\n", ANNUAL_MEAN, "°C", sep="")), '')), 
                hjust=0, vjust=0, show.legend=FALSE)
    }
  return(newPlot)
}



#  --------------------------------------  #
# |                                      | #
# |  III. PLOTTING AESTHETIC FUNCTIONS   | #
# |                                      | #
#  --------------------------------------  #

# FUNCTION #P3-01
# Purpose: This function select a plot label for the y-axis based on the input parameter type
# Input:  str_in  [character] - a character string specifying the parameter
# Output: str_out [character] - a character string specifying the text label to be displayed
yAxisTextLabel <- function(str_in) {
  
  if(str_in=="Temperature") {
    str_out="y-axis: Temperature Range (°C)"
  }
  else if(str_in=="Precipitation") {
    str_out="y-axis: Precipitation Amount (mm)"
  }
  else if(str_in=="Wind") {
    str_out="y-axis: Wind Speed Range (km/h)"
  }
  else if(str_in=="Snow") {
    str_out="y-axis: Snow Amount (cm)"
  }
  else{
    str_out="y-axis: Unknown Parameter Range"
  }
  return(str_out)
}
