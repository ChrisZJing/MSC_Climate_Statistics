# Description: This file contains all the functions for the R Shiny User Interface
# Project:     Canadian Climate Statistics Explorer 
# Author:      Chris Jing
# Created on:  2019-12-26




# FUNCTION #U1-01
# Purpose: This function returns a list of Record Type selections correspond to the input Physical Parameter and Data Type
# Inputs: data_type_name   [character] - "Time Series" or "Extreme Record"
#         para_name        [character] - "Temperature", "Precipitation", "Wind" or "Snow"
# Output: record_type_list [list]      - a list of record types to select from   

RecordTypeSelect <- function(data_type_name, para_name) {
  
  if(data_type_name=="Time Series"){
    if(para_name=="Temperature") {
      record_type_list <- time_series_temp_select
    }
    else if(para_name=="Precipitation") {
      record_type_list <- time_series_prec_select
    }
    else if(para_name=="Wind") {
      record_type_list <- time_series_wind_select
    }
    else if(para_name=="Snow") {
      record_type_list <- time_series_snow_select
    }
    else{
      record_type_list <- c("")
    }
  }
  else if(data_type_name=="Extreme Record"){
    if(para_name=="Temperature") {
      record_type_list <- ext_temp_select
    }
    else if(para_name=="Precipitation") {
      record_type_list <- ext_prec_select
    }
    else if(para_name=="Wind") {
      record_type_list <- ext_wind_select
    }
    else if(para_name=="Snow") {
      record_type_list <- ext_snow_select
    }
    else{
      record_type_list <- c("")
    }
  }
  else{
    record_type_list <- c("")
  }
  return(record_type_list)
}



# FUNCTION #U1-02
# Purpose: This function returns a list of available dates correspond to the input month
# Input:   month_name [character] - "January", "February", ... , or "December"
# Output:  dates_list [list]      - a list of dates as integers from 1 to 29, 30, or 31
datesSelect <- function(month_name) {
  
  if(month_name=="January" || month_name=="March" || month_name=="May" ||
     month_name=="July" || month_name=="August" || month_name=="October" || month_name=="December"){
      dates_list =  c("(coming soon)", seq(1,31, by=1))
  }
  else if(month_name=="April" || month_name=="June" || month_name=="September" || month_name=="November") {
    dates_list = c("(coming soon)", seq(1, 30, by=1))
  }
  else if(month_name=="February"){
    dates_list = c("(coming soon)", seq(1, 29, by=1))
  }
  else{
    dates_list = c("(coming soon)"," ")
  }
  return(dates_list)
}

