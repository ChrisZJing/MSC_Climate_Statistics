# Description: R program for the Shiny User Interface Object of Project CCSE
# Project:     Canadian Climate Statistics Explorer 
# Author:      Chris Jing
# Created on:  2019-12-26

fluidPage(
  fluidRow(
    # Page Title 
    column(width=8, align="left", titlePanel("CCSE - Canadian Climate Statistics Explorer")),
    column(width=4, align="right", br(), imageOutput(outputId="Canada_logo", width="70%", height="70%", inline=FALSE))),
  
  fluidRow(
    # Left Panel - Input Selections Menu 
    column(width=3,
           wellPanel(
             
             h4("Select Geographical Location"),
             
             selectInput(inputId="region", label="Province/Territory",choices=c("", region), selected="British Columbia"),
             selectInput(inputId="station", label="Virtual Station Name", choices=c("")),
             
             h4("Select Meteorological Variable"),
            
             fluidRow(
               column(width=6, selectInput(inputId="parameter", label="Parameter", choices=c(para_select), selected="Temperature"),
                               selectInput(inputId="time_period", label="Time Interval", choices=c(time_period_select), selected="Daily")),
               column(width=6, selectInput(inputId="data_type", label="Data Type", choices=c(data_type_select), selected="Time Series"),
                               selectInput(inputId="record_type", label="Record Type", choices=c("")))
             ),
             # Reactive buttons include "Clear", "Submit" and "Download"
             fluidRow(align="center",
                      actionButton("clear", "Clear", icon("trash"), style="color: #fff; padding:10px; font-size:100%; 
                                   text-align:center; width: 80px; background-color: #C0C0C0; border-color: #2e6da4; padding: 10px 5px"), 
                      actionButton("submit", "Submit", icon("paper-plane"), style="color: #fff; padding:10px; font-size:100%; 
                                   text-align:center;width: 90px; background-color: #337ab7; border-color: #2e6da4; padding: 10px 5px"),
                      downloadButton("download", "Download", icon("download"), style="color: #000; padding:10px; font-size:100%; 
                                     text-align:center; width: 105px; background-color: #ffffff; border-color: #2e6da4; padding: 10px 5px")
             ),
             style = "padding: 10px 15px;"
           ),
           
           # Widget Controls to adjust the threshold of time and physical parameter
           wellPanel(
             h4("Filter Data Properties"),
             
             sliderInput("y_axis_range", "y-axis: Parameter Range",
                        -50, 50, value=c(-50, 50), sep="", step=1),
             sliderInput("x_axis_range", "x-axis: Year Range", 1871, as.integer(format(Sys.Date(), "%Y")), 
                        value=c(1871, as.integer(format(Sys.Date(), "%Y"))), sep="", step=1),

             fluidRow(
               column(width=6, selectInput(inputId="begin_month", label="Begin Month", choices=c("(coming soon)", month_names)),
                      selectInput(inputId="end_month", label="End Month", choices=c("(coming soon)",month_names))),
               column(width=6, selectInput(inputId="begin_date", label="Begin Date", choices=c("(coming soon)", " ")),
                      selectInput(inputId="end_date", label="End Date", choices=c("(coming soon)"," ")))
             ),
             
             # Optional add-on features to embed in the plot
             h4("Optional Plotting Features"),
             checkboxInput(inputId="trend_line", label="Display Trend Line", value=FALSE),
             checkboxInput(inputId="trend_eqn", label="Display Trend Equation (coming soon)", value=FALSE),
             checkboxInput(inputId="normal_data", label="Climate Normals (1981-2010) data (coming soon)", value=FALSE),
             style = "padding: 10px 15px;"
          )
        ),
    
    # Main Window - Output Data Display 
    column(width=9,
           tabsetPanel(id="inTabset",
             tabPanel("Map View", value="Map",
                      wellPanel(
                        leafletOutput("map", width="100%", height=600)),
                      
                      wellPanel(
                        h4("How to navigate the map interface:"),
                        p(paste0("1. When you make the selection on the virtual station you are looking for in the left panel, ",
                                 "the map will automatically zoom in to the nearest proximity of the station you have selected.")),
                        p(paste0("2. By clicking on the marker, a popup will display the detailed information about this virtual station, ",
                                 "such as station name, climate ID, data source, latitude/longitude, and the URL link to its weather record.")),
                        p(paste0("3. To start a new search, click the 'Clear' button to return to the default nationwide map view.")),
                        br(),
                        p(paste0("Note: The map interface is still experimental and any existing features may be modified based on the user feedback."))
                        )
                      ),
             tabPanel("Graph View", value="Graph",
                      wellPanel(
                        splitLayout(plotOutput(outputId="graph", width="100%", height="600px", click="plot_click")),
                      
                        # Respond to the clicked data point by displaying its information under the plot 
                        verbatimTextOutput("click_info_1"), 
                        verbatimTextOutput("click_info_2")),
                        
                        h3(textOutput(outputId="top_N_rows_title")), 
                        DT::dataTableOutput("top_N_rows"),
                      
                      wellPanel(
                        h4("How to navigate the graph interface:"),
                        p(paste0("1. Make a selection on the meteorological variable you wish to plot in the left panel. After done, click 'Submit'.")),
                        p(paste0("2. Click anywhere near a data point in the plot area to obtain detailed information about this data entry, ",
                                 "such as the x and y-axis coordinates. These are displayed in a row tabular form just below the plot.")),
                        p(paste0("3. You may filter data properties by altering the widget controls in the lower section of the left panel. ",
                                 "Any changes made should result in an instant response in the plot.")),
                        br(),
                        p(paste0("Note: The graph interface is still experimental and any existing features may be modified based on the user feedback."))
                        )
                      ),
             tabPanel("Table View", value="Table",
                      wellPanel(
                        h3("Virtual Station Climate Data Table"),
                        DT::dataTableOutput("data_table")),
                      
                      wellPanel(
                        h4("How to navigate the data table interface:"),
                        p(paste0("1. This table contains the dataset used to generate the plot under 'Graph View'.")),
                        p(paste0("2. Any changes made to the plot will result in a change in this data table by applying the same filter. ",
                                 "This table should always be reflective of what is displayed in the plot.")),
                        p(paste0("3. Search for a keyword in the upper-right search box or rearrange a column in ascending/descending order.")),
                        p(paste0("4. Click 'Download' to receive a copy of the data table in CSV format.")),
                        br(),
                        p(paste0("Note: The data table interface is still experimental and any existing features may be modified based on the user feedback."))
                        )
                      ),
             tabPanel("Missing Data", value="Missing",
                      wellPanel(
                        h3("Missing Temperature Data (Labelled as NA)"),
                        DT::dataTableOutput("NA_data"),
                        h4(textOutput(outputId="percent_complete_NA"))
                      ),
                      wellPanel(
                        h3("Missing Dates within the Whole Period of Record"),
                        DT::dataTableOutput("skipped_dates"),
                        h4(textOutput(outputId="percent_complete_dates"))
                      ),
             
                      wellPanel(
                        h4("How to navigate the missing data page:"),
                        p(paste0("1. The upper table contains all the data entries with label 'NA' (i.e. Not Available).")),
                        p(paste0("2. The lower table contains the missing/skipped dates between begin date and end date for the whole period of record.")),
                        p(paste0("3. Click 'Download' to receive a copy of the missing data table in CSV format.")),
                        br(),
                        p(paste0("Note: The Missing Data Page is still experimental and any existing features may be modified based on the user feedback."))
                      )
                    )
             )
           )
    )
  )
  

