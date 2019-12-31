# Description: This file contains all the functions for setting up the connection to the Arkeon-LTCE database
# Description: R program for the Shiny Server Function of Project CCSE
# Project:     Canadian Climate Statistics Explorer 
# Author:      Chris Jing
# Created on:  2019-12-26

 

# FUNCTION #L1-01
# Purpose: Set up the connection to the Arkeon-LTCE Oracle Database 
# Inputs:  ark_username [character]     - Arkeon account username 
#          ark_password [character]     - Arkeon password 
# Output:  con          [OraConnection] - the formal class OraConnection
connectArkeon <- function(ark_username, ark_password) {

  drv <- dbDriver("Oracle")                # Driver Name
  host <- "oraclu1.ontario.int.ec.gc.ca"   # Host Name
  port <- 1521                             # Port Number
  service <- "archive.tor.ec.gc.ca"        # Service Name
  schema <- "ARKEON2DWH"                   # Database Schema (not required here)
  
  connect.string <- paste("(DESCRIPTION=", 
                          "(ADDRESS=(PROTOCOL=tcp)(HOST=", host, ")(PORT=", port, "))", 
                          "(CONNECT_DATA=(service_name=", service, ")))", sep = "")
  con <- dbConnect(drv, username=ark_username, password=ark_password, dbname=connect.string) 
  return(con)
}



# FUNCTION #L1-02
# Purpose: Disconnect from the Arkeon-LTCE Oracle Database 
# Inputs:  con [OraConnection] - the formal class OraConnection
# Output:  none
disconnectArkeon <- function(con, drv) {
  
  dbDisconnect(con)
  return(NULL)
}