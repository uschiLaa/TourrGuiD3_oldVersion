

shinyUI(fluidPage(
  includeScript(path = "js-checkbox.js"),
  titlePanel("Welcome to the TourR Shiny app powered by D3.js"),
  fluidRow(
 
       #first select tour type
    column(3,
      radioButtons(
        "type",
        label = "Select tour type",
        choices = c("Guided", "Little", "Grand", "Local"),
        selected = "Grand",
        inline = TRUE
      ),
 
          #for guided tour select also index function 
      conditionalPanel(
        "input.type == 'Guided'",
        selectInput(
          "guidedIndex",
          "Index function",
          c("Holes", "Centre Mass", "LDA", "PDA", "Scagnostics")
          ,
          selected = "LDA"
        )
      ),
 
         #if scagnostics selected as index fuction, select which scagnostics index to use
      conditionalPanel(
        "input.guidedIndex == 'Scagnostics'",
        selectInput("scagType", "Scagnostics Metric",
                    choices = list(
                      "Outlying",
                      "Skewed",
                      "Clumpy", 
                      "Sparse",
                      "Striated",
                      "Convex",
                      "Skinny",
                      "Stringy",
                      "Monotonic"), selected = "Outlying")),

          #by default do not rescale data, but dynamically can select rescaling to [0,1] interval
      radioButtons(
        "rescale",
        label = "Data rescaling",
        choices = c("None", "[0,1]"),
        selected = "None",
        inline = TRUE
      ),

      #input file upload
      fileInput("file1", "Choose CSV File",
          accept = c(
            "text/csv",
            "text/comma-separated-values,text/plain",
            ".csv")
      ),

      #tour speed selection to modify step size
      sliderInput(
        "speed",
        label =  "Tour speed",
        min = 0,
        max = 5,
        value = 1,
        step = 0.1
      ) ,
      
      
      actionButton("restart_random", "Restart tour with random basis"),
      
      #FIXME use input file to select length of cube edges?
      checkboxInput("showCube", "Show 1 sigma cube", value = FALSE),
      
      # labels for point identification from the plotted image
      selectInput("point_label",choices = vector('character'), label = "Select labeling variable"),
      
      # class can be either numerical or categorical variable
      selectInput("class", choices = vector('character'), label = "Select class variable to colour the points"),
      
      conditionalPanel(condition = "output.numC", checkboxInput("colZ", "colZ", value = FALSE)),
      
      # if class is numerical we group the points by selecting a threshold value that can be selected from a slider
      conditionalPanel( condition = "output.numC && !input.colZ",
                        sliderInput("cMax",label = "Threshold value", min=0, max =1, value= 0.5, step = 0.1)),

      # add also numeric input of threshold value for selection of exact value, this will update also the slider
      conditionalPanel(condition = "output.numC && !input.colZ", numericInput("numCmax", label = "Select exact threshold value", value=0.5)),
      
      conditionalPanel( condition = "output.numC",
                        sliderInput("cutData",label = "Select data range", min=0, max =1, value= c(0,1)))
      ),
 
       column(3,
              
      # the variables used in the tour can be selected from all numeric input columns
      checkboxGroupInput(
        "variables",
        label = "Choose variables for the 2D tour",
        choices = vector('character'),
        selected = vector('character')
      ),
      checkboxGroupInput(
        "metadata",
        label = "Choose which metadata to show",
        choices = vector('character'),
        selected = vector('character')
      )
    ),
    
    # draw d3 output here
    # FIXME how to get dynamically updated size of the plot?
    # tags$script calls to include d3 dependencies, tags$div adds d3 output to the page (check if all of them are needed?)
    column(6,
           fluidRow(column(12,
      tags$div(tags$p(" "),
               ggvisOutput("ggvis")),
      tags$div(tags$p(textOutput("type"))),
      tags$script(src = "https://d3js.org/d3.v4.min.js"),
      tags$script(src = "https://d3js.org/d3-contour.v1.min.js"),
      tags$script(src = "https://d3js.org/d3-scale-chromatic.v1.min.js"),
      tags$div(id = "d3_output"),
      tags$div(id = "d3_output_2"),
      tags$div(id = "info"),
      tags$div(id = "info_2"),
      tags$script(src = "d3anim.js")),
      fluidRow(column(12,
      plotOutput("paraCoords"))))
  )
)))
