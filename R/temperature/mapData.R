# Description: This file contains all the functions for mapping applications in Leaflet
# Project:     ASCEND - MSC Applied Statistics on Climate Extremes & Numbers Dashboard  
# Ownership:   MSC - Meteorological Services of Canada
# Author:      Chris Jing
# Created on:  2019-10-31



#  -------------  #
# |  CONSTANTS  | #
#  -------------  #

# A list that stores the main political geographical regions of Canada
REGION_NAME <- list("Canada", "Alberta", "British Columbia", "Manitoba", "New Brunswick", 
                    "Newfoundland and Labrador", "Nova Scotia", "Ontario", "Prince Edward Island", "Quebec", 
                    "Saskatchewan", "Northwest Territories", "Nunavut", "Yukon")

# Lists that stores the boundaries of the latitide and longitudes of the country/province/territory in the order listed above
REGION_LAT_1 <- list(  40.00,  48.99,  48.30,  48.99, 44.60, 46.61, 43.42, 41.66, 45.95, 44.99,  48.99,  60.00,  51.64,  60.00)
REGION_LAT_2 <- list(  75.00,  60.00,  60.00,  60.00, 48.07, 60.37, 47.03, 56.86, 47.06, 62.59,  60.00,  78.76,  83.11,  69.65)
REGION_LNG_1 <- list(-145.00,-120.00,-139.06,-102.03,-69.06,-67.80,-66.32,-95.16,-64.41,-79.76,-109.99,-136.44,-120.68,-141.00)
REGION_LNG_2 <- list( -50.00,-109.99,-114.03, -88.94,-63.77,-52.61,-59.68,-74.34,-61.97,-57.10,-101.36,-101.98, -61.08,-123.81)



#  -------------  #
# |  FUNCTIONS  | #
#  -------------  #

# FUNCTION #M1-01
# Purpose: This function queries all currently active virtual stations in the region 
# Inputs: con [OraConnection]        - the formal class OraConnection
#         region [character]         - the name of the province/territory to filter from (e.g. "Alberta")
# Output: active_vrt_stn_list [list] - a data frame that stores information about all active stations
getActiveVrtStnList <- function(con, region) {
  
  # Run the SQL command to extract distinct virtual stations with the most recent start date
  latest_start_date_vrt_stn_list <- dbGetQuery(con, "SELECT
    vrt_stn.*,
    real_stn.LONGITUDE_DECIMAL_DEGREES,
    real_stn.LATITUDE_DECIMAL_DEGREES,
    real_stn.ENG_STN_NAME
  FROM
    ARKEON2DWH.STATION_INFORMATION real_stn
    INNER JOIN ARKEON2DWH.VIRTUAL_STATION_INFO_F_MVW vrt_stn ON real_stn.STN_ID = vrt_stn.STN_ID
    INNER JOIN (
      SELECT
        DISTINCT vrt_stn.VIRTUAL_CLIMATE_ID,
        MAX(vrt_stn.START_DATE)
  AS MOST_RECENT_DATE
      FROM
        ARKEON2DWH.VIRTUAL_STATION_INFO_F_MVW vrt_stn
      WHERE 
        vrt_stn.ELEMENT_NAME_E = 'DAILY MAXIMUM TEMPERATURE'
      GROUP BY
        vrt_stn.VIRTUAL_CLIMATE_ID
    ) grouped_vrt_stn ON vrt_stn.VIRTUAL_CLIMATE_ID = grouped_vrt_stn.VIRTUAL_CLIMATE_ID
    AND vrt_stn.START_DATE = grouped_vrt_stn.MOST_RECENT_DATE
  WHERE
    vrt_stn.ELEMENT_NAME_E = 'DAILY MAXIMUM TEMPERATURE' 
  ORDER BY vrt_stn.ENG_PROV_NAME ASC, vrt_stn.VIRTUAL_STATION_NAME_E ASC
  ")
  
  # Filter out the virtual stations with END_DATE labelled as NA (i.e. currently active virtual stations)
  active_vrt_stn_list <-  latest_start_date_vrt_stn_list[is.na(latest_start_date_vrt_stn_list$END_DATE),]
  
  if(region=="Canada"){
    return(active_vrt_stn_list)
  }
  else{
    prov_name=toupper(region)
    return(active_vrt_stn_list[active_vrt_stn_list$ENG_PROV_NAME==prov_name,])
  }
}


# FUNCTION #M1-02
# Purpose: This function generates a Leaflet map populated by markers of virtual stations and zoom in to the location specified  
# Inputs: active_vrt_stn_list [list] - a list of all active virtual stations (output of FUNCTION #M1-01, getActiveVrtStnList) 
#         zoom_region [character]    - a character string that specify the country/province/territory to foucs on (e.g. "Alberta")
# Output: zoom_map    [leaflet]      - a Leaflet map based on the input selection
generateMap <- function(active_vrt_stn_list, zoom_region) {
  
  # Generate the text to display in the pop-up window of a virtual station marker
  location_info <- paste0("<div>", "<h3><b>", stri_trans_totitle(active_vrt_stn_list$ENG_STN_NAME), ", ", 
                                              stri_trans_totitle(active_vrt_stn_list$ENG_PROV_NAME), "<b></h3><br>", 
                          "<h4>", "Station Name: ", active_vrt_stn_list$ENG_STN_NAME, "</h4>", 
                          "<h4>", "Latitude: ", round(as.numeric(active_vrt_stn_list$LATITUDE_DECIMAL_DEGREES), digits=2), 
                                  "°N; Longitude: ", round(as.numeric(active_vrt_stn_list$LONGITUDE_DECIMAL_DEGREES), digits=2), "°W", "</h4>",
                          "<h4>", "Station ID: ", active_vrt_stn_list$CLIMATE_IDENTIFIER, "</h4>",
                          "<h4>", "Data Source: ", active_vrt_stn_list$DATA_SOURCE, "</h4>",
                          "<h4>", "Historical Temperature Max/Min Record for", "</h4>",
                          "<h4>", format(Sys.Date(),"%B %d"), ": ____/____ °C", "</h4>",
                          "<h4>", "Observed Temperature Max/Min on ","</h4>", 
                          "<h4>", Sys.Date(), ": ____/____ °C ", "</h4>", "<br>", 
                          "<h4>", "<b><a href='https://weather.gc.ca/city/pages/", 
                          active_vrt_stn_list$CLIMATE_IDENTIFIER, "_metric_e.html' target='_blank'>", 
                          "Live Weather Record</a></b>", "</h4>")
  
  # Generate a leaflet map based on the inputs
  for(i in seq(1:length(REGION_NAME))){
    if(zoom_region==REGION_NAME[i]){
      zoom_map <- leaflet(options=leafletOptions(minZoom=0, maxZoom=18), data=active_vrt_stn_list) %>%
        addProviderTiles(providers$Esri.NatGeoWorldMap) %>%  # Add default OpenStreetMap map tiles
        fitBounds(lng1=as.numeric(REGION_LNG_1[i]), lat1=as.numeric(REGION_LAT_1[i]), 
                  lng2=as.numeric(REGION_LNG_2[i]), lat2=as.numeric(REGION_LAT_2[i])) %>% #set to lat and lon bounds of Canada
        addMarkers(lng=~LONGITUDE_DECIMAL_DEGREES, lat=~LATITUDE_DECIMAL_DEGREES, 
                   popup=location_info,
                   popupOptions = popupOptions(minWidth=200, maxWidth=400),
                   labelOptions = labelOptions(noHide = T, direction = "bottom",
                                               style = list("color" = "black",
                                                            "box-shadow" = "3px 3px rgba(0,0,0,0.25)",
                                                            "font-size" = "20px",
                                                            "border-color" = "rgba(0,0,0,0.5)")))
      break
    }
  }
  return(zoom_map)
}

