

shinyUI(fluidPage(
  includeScript(path = "js-checkbox.js"),
  titlePanel("Welcome to the TourR Shiny app powered by D3.js"),
  fluidRow(
    column(3,
      radioButtons(
        "type",
        label = "Select tour type",
        choices = c("Guided", "Little", "Grand"),
        selected = "Grand"
      ),
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
      radioButtons(
        "rescale",
        label = "Data rescaling",
        choices = c("None", "[0,1]"),
        selected = "None"
      ),

fileInput("file1", "Choose CSV File",
          accept = c(
            "text/csv",
            "text/comma-separated-values,text/plain",
            ".csv")
),

      sliderInput(
        "speed",
        label =  "Tour speed",
        min = 0,
        max = 5,
        value = 1,
        step = 0.1
      ) ,
      actionButton("restart_random", "Restart tour with random basis"),
      selectInput("point_label",choices = vector('character'), label = "Select labeling variable"),
      selectInput("class", choices = vector('character'), label = "Select class variable to colour the points"),
      conditionalPanel( condition = "output.numC",
                        sliderInput("cMax",label = "Threshold value", min=0, max =1, value= 0.5, step = 0.1)),
      conditionalPanel(condition = "output.numC", numericInput("numCmax", label = "Select exact threshold value", value=0.5))
      ),
    column(3,
      checkboxGroupInput(
        "variables",
        label = "Choose variables for the 2D tour",
        choices = vector('character'),
        selected = vector('character')
      )
    ),
    column(6,
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
      tags$script(src = "d3anim.js"))
  )
))
