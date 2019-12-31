# Description: R script for the Global side of Project CCSE
#              Any R objects created in this file become available to the ui.R and server.R files respectively
# Project:     Canadian Climate Statistics Explorer 
# Author:      Chris Jing
# Created on:  2019-12-26

# Import libraries
library(tidyverse)
library(rsconnect)
library(shiny)
library(DT)
library(leaflet)
library(stringi)
library(htmltools)


# Load the source R codes
source("R/temperature/cleanData.R", print=TRUE)
source("R/temperature/mapData.R", print=TRUE)
source("R/temperature/missingData.R", print=TRUE)
source("R/temperature/plotData.R", print=TRUE)
source("R/UI/UI_fun.R", print=TRUE)

# List of provinces and territories in alphabetical order:
region <- listProvName()

# Variable Selections:
para_select        <- list("", "Temperature", "Precipitation (coming soon)", "Wind (coming soon)", "Snow (coming soon)")
time_period_select <- list("", "Daily", "Monthly (coming soon)", "Seasonal (coming soon)", "Annual (coming soon)")
data_type_select  <- list("", "Time Series", "Extreme Record (coming soon)")

# Extreme Record Data Selections for each physical parameter:
ext_temp_select <- list("", "Highest Maximum", "Lowest Maximum","Highest Minimum", "Lowest Minimum", "All of the Above")
ext_prec_select <- list("", "Greatest precipitation")
ext_wind_select <- list("", "Wind speed")
ext_snow_select <- list("", "Greatest snowfall", "Most snow on ground")

# Time Series Data Selections for each physical parameter:
time_series_temp_select <- list("", "Maximum", "Minimum", "Mean", "Maximum & Minimum")
time_series_prec_select <- list("", "Accumulated Precipitation")
time_series_wind_select <- list("","Mean Wind Speed")
time_series_snow_select <- list("", "Accumulated Snowfall", "Total Snow on the Ground")

# List the name of months in order
month_names <- list(" ", "January", "February", "March", "April", "May", "June", 
                    "July", "August", "September", "October", "November", "December")

