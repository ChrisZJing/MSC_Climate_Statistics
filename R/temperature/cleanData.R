# Description: This file contains all the functions for cleaning the temperature source data stored in the Arkeon-LTCE database
# Project:     Canadian Climate Statistics Explorer 
# Author:      Chris Jing
# Created on:  2019-12-26



#  -------------------  #
# | TABLE OF CONTENTS | #
#  -------------------  #

# PART I (#C1-01):     GENERAL SQL COMMAND FUNCTIONS (NOT USED)
# PART II (#C2-01~05): STATION INFO PROCESSING FUNCTIONS
# PART III (#C3-01~03):TEMPERATURE EXTREMES DATA PROCESSING FUNCTIONS 
# PART IV (#C4-01~02): TEMPERATURE TIME SERIES PROCESSING FUNCTIONS



#  --------------------------------------  #
# |                                      | #
# |  I. GENERAL SQL COMMAND FUNCTIONS    | #
# |                                      | #
#  --------------------------------------  #

# FUNCTION #C1-01
# Purpose: This function uses SQL command to query a database and create an R data frame
# Note:    The allowed combinations of SQL strings are limited for this function
# Inputs:  con         [OraConnection] - the connection between R and the database 
#          select_SQL  [character]     - SQL clause after SELECT
#          from_SQL    [character]     - SQL clause after FROM
#          on_SQL      [character]     - SQL clause after ON
#          where_SQL   [character]     - SQL clause after WHERE
#          order_by_SQL[character]     - SQL clause after ORDER BY
# Output:  df_out      [list] 
commandSQL1 <- function(con, select_SQL, from_SQL, on_SQL, where_SQL, order_by_SQL){
  
  df_out <- dbGetQuery(con, paste("SELECT", select_SQL,
                                  "FROM", from_SQL,
                                  "ON", on_SQL,
                                  "WHERE", where_SQL, 
                                  "ORDER BY", order_by_SQL,
                                  sep=" "))
  return(df_out)
}



#  ---------------------------------------  #
# |                                       | #
# | II. STATION INFO PROCESSING FUNCTIONS | #
# |                                       | #
#  ---------------------------------------  #

# FUNCTION #C2-01
# Purpose: This function lists the count of virtual stations in a specified province or territory
# Inputs:  con       [OraConnection] - the connection between R and Arkeon
#          prov_name [character]     - name of the province or territory (non-case sensitive, e.g. Alberta)
# Output:  count     [integer]       - the number of virtual stations
countVrtStn <- function(con, prov_name) {
  
  count <- dbGetQuery(con, paste("SELECT COUNT(DISTINCT VIRTUAL_CLIMATE_ID)
                                  FROM ARKEON2DWH.VIRTUAL_STATION_INFO_F_MVW 
                                  WHERE ENG_PROV_NAME='", toupper(prov_name), "'", sep=""))
  return(count)
}



# FUNCTION #C2-02
# Purpose: This function lists all the 10 provinces and 3 territories in Canada
# Input:   none
# Output:     [list]          - an R data frame that contains the province and territory names
listProvName <- function() {
  prov_names = list("Alberta", "British Columbia", "Manitoba", "New Brunswick", "Newfoundland and Labrador",
                    "Northwest Territories", "Nova Scotia", "Nunavut", "Ontario", "Prince Edward Island", 
                    "Quebec", "Saskatchewan", "Yukon")
  return(prov_names)
}



# FUNCTION #C2-03
# Purpose: This function lists the names of all virtual station that has a distinct virtual climate ID from 
#          the input province or territory
# Inputs:  prov_name [character]     - name of the province or territory (non-case sensitive, e.g. alberta)
# Output:  df_out    [list]          - an R data frame that contains station names ordered alphabeticlaly 
listVrtStn <- function(prov_name, station_list) {
  df_out <- subset(station_list, ENG_PROV_NAME==prov_name, VIRTUAL_STATION_NAME_E)
  return(df_out)
}



# FUNCTION #C2-04
# Purpose: This function modifies all elements in an R data frame to a mixed case capitalization
# Inputs:  df_in  [list] - input data frame
# Output:  df_in  [list] - the modified input data frame
simpleCapDf <- function(df_in) {
  
  simpleCap <- function(x) {
    s <- strsplit(x, " ")[[1]]
    return(paste(toupper(substring(s, 1, 1)), substring(s, 2),
          sep = "", collapse = " "))
  }
  
  for(row in seq(from=1, to=nrow(df_in), by=1)) {
    for(col in seq(from=1, to=ncol(df_in), by=1)) {
      df_in[row, col] <- simpleCap(tolower(as.character(df_in[row, col])))
    }
  }
  return(df_in)
}
       
                                                                                                                                                               

# FUNCTION #C2-05
# Purpose: This function returns a data frame that contains the basic information about a virtual station
# Inputs:  con            [OraConnection] - the connection between R and Arkeon
#          prov_name      [character]     - name of the province or territory (non-case sensitive, e.g. Alberta)
#          vrt_stn_name   [character]     - name of the virtual station (non-case sensitive, e.g. Airdrie Area)
#          element_name_1 [character]     - name of the 1st element (case sensitive, e.g. DAILY MAXIMUM TEMPERATURE)
#          element_name_2 [character]     - name of the 2nd element (case sensitive, e.g. DAILY MINIMUM TEMPERATURE)
# Output:  df_out         [list]          - an R data frame that contains the station name, climate ID, element name, 
#                                           start date, end date, data source, latitude, and longitude of the station 
getStnInfo <- function(con, prov_name, vrt_stn_name, element_name_1, element_name_2) {
  
  df_out <- dbGetQuery(con, paste("SELECT stn_info.ENG_STN_NAME, vrt_stn.CLIMATE_IDENTIFIER, vrt_stn.ELEMENT_NAME_E, 
                                          vrt_stn.START_DATE, vrt_stn.END_DATE, vrt_stn.DATA_SOURCE, 
                                          stn_info.LATITUDE_DECIMAL_DEGREES, stn_info.LONGITUDE_DECIMAL_DEGREES
                                     FROM ARKEON2DWH.VIRTUAL_STATION_INFO_F_MVW vrt_stn
                                     INNER JOIN ARKEON2DWH.STATION_INFORMATION stn_info
                                     ON vrt_stn.STN_ID = stn_info.STN_ID
                                     WHERE vrt_stn.VIRTUAL_STATION_NAME_E='", vrt_stn_name, "'", 
                                    "AND vrt_stn.ENG_PROV_NAME='", prov_name, "' AND (vrt_stn.ELEMENT_NAME_E='", 
                                    element_name_1, "' OR vrt_stn.ELEMENT_NAME_E='", element_name_2, "')", sep=""))
  
  df_out$LATITUDE_DECIMAL_DEGREES <- round(df_out$LATITUDE_DECIMAL_DEGREES, digits=2)
  df_out$LONGITUDE_DECIMAL_DEGREES <- round(df_out$LONGITUDE_DECIMAL_DEGREES, digits=2)
  df_out$START_DATE <- as.Date(df_out$START_DATE)
  df_out$END_DATE <- as.Date(df_out$END_DATE)
  
  colnames(df_out) <- c("Station Name", "Climate ID", "Element Name", "Start Date", 
                        "End Date", "Data Source", "Latitude (⁰)", "Longitude (⁰)")
  return(df_out)
}



#  -----------------------------------------------------  #
# |                                                     | #
# | III. TEMPERATURE EXTREMES DATA PROCESSING FUNCTIONS | #
# |                                                     | #
#  -----------------------------------------------------  #

# FUNCTION #C3-01
# Purpose: This function returns a data frame of extreme temperature values 
#          by dates in an ascending or descending order
# Inputs:  con         [OraConnection] - the connection between R and Arkeon 
#          type        [character]     - the type of extreme data 
#                     (e.g. "Highest Maximum", "Lowest Maximum", "Highest Minimum", or "Lowest Minimum")
#          descending  [boolean]       - TRUE if provide ranking in descending order, FALSE if in ascending order
#          vrt_stn_name[character]     - English name of the virtual station (e.g. "Vancouver Area")
# Output:  df_out      [list]          - an R data frame that stores the ordered data
TempExtremeByDate <- function(type, descending, vrt_stn_name){
  
  if(type=="Highest Maximum"){
    value_column_name = "RECORD_HIGH_MAX_TEMP"
    year_column_name  = "RECORD_HIGH_MAX_TEMP_YR"
  }
  else if(type=="Lowest Maximum"){
    value_column_name = "RECORD_LOW_MAX_TEMP"
    year_column_name  = "RECORD_LOW_MAX_TEMP_YR"
  }
  else if(type=="Highest Minimum"){
    value_column_name = "RECORD_HIGH_MIN_TEMP"
    year_column_name  = "RECORD_HIGH_MIN_TEMP_YR"
  }
  else if(type=="Lowest Minimum"){
    value_column_name = "RECORD_LOW_MIN_TEMP"
    year_column_name  = "RECORD_LOW_MIN_TEMP_YR"
  }
  else{}
  
  df_out <- dbGetQuery(con, paste("SELECT * FROM ", string_SQL, " WHERE VIRTUAL_STATION_NAME_E = '", 
                                  toupper(virtual_station_name), "'", sep=""))
  # Add a ranking column
  df_out$RANK <- NA
  if(descending==TRUE){
    df_out$RANK[order(-df_out[, value_column_name], df_out[, year_column_name])] <- 1:nrow(df_out)
  }
  else{
    df_out$RANK[order(df_out[, value_column_name], df_out[, year_column_name])] <- 1:nrow(df_out)
  }

  # Output the complete version or the simplified version of the data frame for display purpose 
  if(display==FALSE){
    return(df_out)
  }
  else{
    df_out <- data.frame(as.Date(df_out[, "LOCAL_TIME"], format="%Y-%m-%d"),
                        df_out[, paste0(value_column_name, "_YR")], df_out$LOCAL_MONTH, df_out$LOCAL_DAY,
                        df_out[, value_column_name], df_out$RANK)
    colnames(df_out) <- c("LOCAL_DATE", "LOCAL_YEAR", "LOCAL_MONTH", "LOCAL_DAY", "TEMPERATURE", "RANK")
    return(df_out)
  }
}



# FUNCTION #C3-02
# Purpose: This function returns a data frame of ranked extreme temperature values and their dates 
# Inputs:  df_in           [list]       - input data frame (output of FUNCTION #C3-01, TempExtremeByDate) 
#          extreme_type    [character]  - name of the column to perform the ranking 
#                                         (e.g. "Highest Maximum", "Lowest Maximum", "Highest Minimum", or "Lowest Minimum")
#          date_column_name[character]  - name of the column that stores the date info (e.g. "LOCAL_TIME")
#          descending      [boolean]    - FALSE for rank in ascending order, TRUE for descending 
# Output:  df_out          [list]       - an R data frame that stores the rank, temperature, date, year, month, 
#                                         and day of the temperature extreme 
TempExtremeByRank <- function(df_in, extreme_type, date_column_name, descending) {
  
  if(extreme_type=="Highest Maximum"){
    value_column_name="RECORD_HIGH_MAX_TEMP"
  }
  else if(extreme_type=="Lowest Maximum"){
    value_column_name="RECORD_LOW_MAX_TEMP"
  }
  else if(extreme_type=="Highest Minimum"){
    value_column_name="RECORD_HIGH_MIN_TEMP"
  }
  else if(extreme_type=="Lowest Minimum"){
    value_column_name="RECORD_LOW_MIN_TEMP"
  }
  else{}
  
  # Descending order
  if(descending==TRUE) {
    df_ranked <- df_in[order(-df_in[, value_column_name], df_in[, paste0(value_column_name, "_YR")]),]
  }
  # Ascending order
  else{
    df_ranked <- df_in[order(df_in[, value_column_name], df_in[, paste0(value_column_name, "_YR")]),]
  }
  df_out <-  data.frame(df_ranked$RANK, df_ranked[, value_column_name], 
                        as.Date(df_ranked[, date_column_name], format="%Y-%m-%d"),
                      df_ranked[, paste0(value_column_name, "_YR")], df_ranked$LOCAL_MONTH, df_ranked$LOCAL_DAY)
  colnames(df_out) <- c("RANK", "TEMPERATURE", "LOCAL_DATE", "LOCAL_YEAR", "LOCAL_MONTH", "LOCAL_DAY")
  return(df_out)
}



# FUNCTION #C3-03
# Purpose: This function returns an R data frame with temperature extreme of all record types 
# Inputs:  df_high_max [list] - input data frame for highest maximum (output of FUNCTION #C3-01, TempExtremeByDate) 
#          df_low_max  [list] - input data frame for lowest maximum (output of FUNCTION #C3-01, TempExtremeByDate) 
#          df_high_min [list] - input data frame for highest minimum (output of FUNCTION #C3-01, TempExtremeByDate) 
#          df_low_min  [list] - input data frame for lowest minimum (output of FUNCTION #C3-01, TempExtremeByDate) 
# Output:  df_out      [list] - an R data frame that stores the filtered input data
TempExtremeAllTypes <- function(df_high_max, df_low_max, df_high_min, df_low_min) {
  
  df_out <- data.frame(df_high_max$LOCAL_MONTH, df_high_max$LOCAL_DAY,
                       df_high_max[, paste0("RECORD_HIGH_MAX_TEMP", "_YR")],
                       df_high_max[, "RECORD_HIGH_MAX_TEMP"],
                       df_low_max[, paste0("RECORD_LOW_MAX_TEMP", "_YR")],
                       df_low_max[, "RECORD_LOW_MAX_TEMP"],
                       df_high_min[, paste0("RECORD_HIGH_MIN_TEMP", "_YR")],
                       df_high_min[, "RECORD_HIGH_MIN_TEMP"],
                       df_low_min[, paste0("RECORD_LOW_MIN_TEMP", "_YR")],
                       df_low_min[, "RECORD_LOW_MIN_TEMP"])
  colnames(df_out) <- c("LOCAL_MONTH", "LOCAL_DAY",
                        "YEAR_HIGH_MAX", "TEMP_HIGH_MAX", "YEAR_LOW_MAX", "TEMP_LOW_MAX", 
                        "YEAR_HIGH_MIN", "TEMP_LOW_MIN", "YEAR_LOW_MIN", "TEMP_LOW_MIN")
  return(df_out)
}



#  -----------------------------------------------------  #
# |                                                     | #
# | IV. TEMPERATURE TIME SERIES PROCESSING FUNCTIONS    | #
# |                                                     | #
#  -----------------------------------------------------  #

# FUNCTION #C4-01
# Purpose: This function uses SQL commands to query the Arkeon database and create an R data frame that  
#          stores the daily maximum and daily minimum temperature time series from oldest to latest by dates
# Input:   con         [OraConnection] - the connection between R and the database 
# Output:  df_out      [list]          - an R data frame of daily maximum and minimum temperature time series 
TempDailyTimeSeries <- function(con){
  
  # SQL command code segments to generate the data frame
  select   = "Tmax.MAX_TEMPERATURE, Tmin.MIN_TEMPERATURE, Tmax.LOCAL_TIME, Tmax.LOCAL_YEAR, Tmax.LOCAL_MONTH, Tmax.LOCAL_DAY"
  from     = "ARKEON2DWH.VIRTUAL_MAX_TEMPERATURE Tmax FULL JOIN ARKEON2DWH.VIRTUAL_MIN_TEMPERATURE Tmin"
  on       = "Tmax.LOCAL_YEAR = Tmin.LOCAL_YEAR AND Tmax.LOCAL_MONTH = Tmin.LOCAL_MONTH AND Tmax.LOCAL_DAY = Tmin.LOCAL_DAY"
  where    = paste("Tmax.VIRTUAL_STATION_NAME_E = '", toupper(virtual_station_name),
                   "' AND Tmin.VIRTUAL_STATION_NAME_E = '", toupper(virtual_station_name), "'", sep="")
  order_by = "Tmax.LOCAL_TIME ASC"
  
  df_out <- dbGetQuery(con, paste("SELECT", select, "FROM", from, "ON", on, "WHERE", where, "ORDER BY", order_by, sep=" "))
  return(df_out)
}



# FUNCTION #C4-02
# Purpose: This function generates a data frame of annual mean temperature time series for a specified virtial station
# Inputs: df_in  [list] - an R data frame that stores the temperature time series (output of FUNCTION #C4-01, TempDailyTimeSeries)
# Output: df_out [list] - an R data frame of mean annual temperature time series for each year and all 12 months in each year
TempAnnualMeanTimeSeries <- function(df_in) {
  
  year_min <- min(df_in$LOCAL_YEAR, na.rm=TRUE)
  year_max <- max(df_in$LOCAL_YEAR, na.rm=TRUE)
  year_range <- seq(year_min, year_max, by=1)
  
  # Initialize the output data frame with appropriate column names
  df_out <- data.frame(LOCAL_YEAR=integer(), JAN=double(), FEB=double(), MAR=double(),
                       APR=double(), MAY=double(), JUN=double(), JUL=double(),
                       AUG=double(), SEP=double(), OCT=double(), NOV=double(), 
                       DEC=double(), ANNUAL_MEAN=double())
  
  for(year in year_range) {
    this_year <- c()
  
    for(month in seq(from=1, to=12, by=1)) {
      month_data <- filter(filter(df_in, LOCAL_YEAR==year), LOCAL_MONTH==month)
      Tmax_mean_monthly <- mean(month_data[, "MAX_TEMPERATURE"], na.rm=TRUE)
      Tmin_mean_monthly <- mean(month_data[, "MIN_TEMPERATURE"], na.rm=TRUE)
      Tmean_monthly <- mean(c(Tmax_mean_monthly, Tmin_mean_monthly))
      this_year <- c(this_year, Tmean_monthly)
    }
    this_year <- c(year, this_year, round(mean(this_year), digits=1))
    df_out <- rbind(df_out, this_year)
  }
  colnames(df_out) <- c("LOCAL_YEAR", "JAN", "FEB", "MAR", "APR", "MAY", "JUN", 
                        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC", "ANNUAL_MEAN")
  # Add a ranking column
  df_out$RANK <- NA
  df_out$RANK[order(df_out$ANNUAL_MEAN, df_out$LOCAL_YEAR, decreasing=TRUE)] <- 1:nrow(df_out)
  
  return(df_out)
}

