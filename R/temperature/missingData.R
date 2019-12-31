# Description: This file contains all the functions for analyzing the missing temperature 
#              source data stored in the Arkeon-LTCE database
# Project:     Canadian Climate Statistics Explorer 
# Author:      Chris Jing
# Created on:  2019-12-26


# FUNCTION #MI1-01
# Purpose: This function creates a filtered R data frame that stores all the rows with missing (NA) temperature values 
# Input: df_in   [list]  - the R data frame that stores the daily temperature time series to be checked 
#                          (output of FUNCTION #C4-01, TempDailyTimeSeries)
# Output: df_out [list]  - the filtered R data frame that only contains rows with missing (NA) temperature values 
filterNAData <- function(df_in) {
  
  df_out <- filter(df_in, is.na(MAX_TEMPERATURE) | is.na(MIN_TEMPERATURE))
  df_out$LOCAL_TIME <- as.Date(df_out$LOCAL_TIME, format="%Y-%m-%d")
  return(df_out)
}


# FUNCTION #MI2-02
# Purpose: This function create a filtered R data frame that stores all the rows with skipped dates 
# Input: df_in   [list]  - the R data frame that stores the daily temperature time series to be checked 
#                          (output of FUNCTION #C4-01, TempDailyTimeSeries)
# Output: df_out [list]  - the filtered R data frame that only contains rows with skipped dates
filterSkippedDates <- function(df_in) {
  
  # Create a table of all dates between the start date and end date of the data frame 
  data_range <- seq(as.Date(min(df_in$LOCAL_TIME)),                                                                                                                            
                   as.Date(max(df_in$LOCAL_TIME)), by = 1)
  
  # Get the dates in data_range that are not in the Time Series data frame
  skipped_dates <- data_range[!data_range %in% as.Date(df_in$LOCAL_TIME)] 
  
  # Create a new data frame to store the local time, year, month, and day of the missing dates
  df_out <- data.frame("LOCAL_TIME" =skipped_dates,
                       "LOCAL_YEAR" =as.numeric(format(skipped_dates, "%Y")),
                       "LOCAL_MONTH"=as.numeric(format(skipped_dates, "%m")),
                       "LOCAL_DAY"  =as.numeric(format(skipped_dates, "%d")),
                       "MAX_TEMPERATURE"=NA,
                       "MIN_TEMPERATURE"=NA,
                       "MEAN_TEMPERATURE"=NA)
  df_out$LOCAL_TIME <- as.Date(df_out$LOCAL_TIME, format="%Y-%m-%d")
  return(df_out)
}


