shinyServer(function(input, output, session) {
  fps <- 33 #frames per second is fixed here
  aps <- 5 #default for step size (as angle per second), can be updated via ui
  
  rv <- reactiveValues()
  
  
  #if restart_random button selected, re-initialise with randomly selected projection
  #FIXME should take into account subsetting done (i.e. selecting data only...)
  observeEvent(input$restart_random,
              {
                
                p <- length(input$variables)
                b <- matrix(runif(2*p), p, 2) # select projection matrix entries from uniform distribution
                
               
                rv$tour <- new_tour(as.matrix(filter(rv$dSelected,cat=="data")[input$variables]),
                                  choose_tour(input$type, b, input$guidedIndex, c(rv$cl), input$scagType),
                                 b)
               },priority = 3)
  
  #update step size (i.e. aps) given new ui input
  observeEvent(input$speed, rv$aps <- input$speed, priority = 4)

  #initiallize ui once input file has been selected  
  observeEvent(input$file1, {
    inFile <- input$file1
    rv$d <- read.csv(inFile$datapath, stringsAsFactors = FALSE)
    if(!("cat" %in% colnames(rv$d))){
      rv$d <- add_column(rv$d, cat="data")
    }
    
           
    rv$nums <- sapply(rv$d, is.numeric)
    rv$groups <- sapply(rv$d, is.character)
    
    updateCheckboxGroupInput(
      session, "variables",
      choices = names(rv$d[rv$nums]),
      selected = names(rv$d[rv$nums])[1:3]
    )
    updateCheckboxGroupInput(
      session, "metadata",
      choices = unique(filter(rv$d,cat!="data")$cat))

    updateSelectInput(session, "class", choices = names(rv$d)[names(rv$d) != "cat"])
    updateSelectizeInput(session, "class", selected = names(rv$d[names(rv$d) != "cat"])[-1])
    updateSelectInput(session, "point_label", choices = names(rv$d), selected = names(rv$d)[1])
    rv$showCube <- 0
    
    
  },priority = 7)
  
  # update slider input if numerical value is chosen for the grouping threshold
  observeEvent(input$numCmax,{updateSliderInput(session, "cMax", value = input$numCmax)},priority = 6)

  # if showCube is selected, we read cube parameters and activate drawing option here
  # FIXME allow selection of input file for drawing cube?
  observeEvent(c(input$showCube,input$rescale,input$variables),{
    if (input$showCube){
      rv$d <- filter(rv$d, !(cat %in% c("cubeLow","cubeUp")))
      nCube <- cube.iterate(length(input$variables))
      cubeSidesLow <- apply(filter(rv$d, cat=="data", pValue==68)[input$variables],2,min)
      cubeSidesUp <- apply(filter(rv$d, cat=="data", pValue==68)[input$variables],2,max)
      cubeSideLength <- cubeSidesUp - cubeSidesLow
      cubePoints <- nCube$points %*% diag(cubeSideLength)
      cubePoints <- sweep(cubePoints,2,as.matrix(cubeSidesLow),"+",check.margin = FALSE)
      i <- nrow(rv$d) + 1
      for(edgeLow in nCube$edges[,1]){
        rv$d[i,][input$variables] <- cubePoints[edgeLow,]
        rv$d[i,]["cat"] = "cubeLow"
        i <- i+1
      }
      for(edgeUp in nCube$edges[,2]){
        rv$d[i,][input$variables] <- cubePoints[edgeUp,]
        rv$d[i,]["cat"] = "cubeUp"
        i <- i+1
      }
      rv$showCube = 1
    }
    else{
      rv$d <- filter(rv$d, !(cat %in% c("cubeLow","cubeUp")))
      rv$showCube = 0
      } #turn off cube drawing when un-selecting the option in the ui
    session$sendCustomMessage("cube", toJSON(rv$showCube))
  },ignoreInit = TRUE, priority = 5
  )
  
  observeEvent(input$metadata,{
    if(is.null(input$metadata)){rv$showMeta = 0}
    else{rv$showMeta = 1}
    session$sendCustomMessage("metadata",toJSON(rv$showMeta))
    },ignoreInit = TRUE, priority = 5, ignoreNULL = FALSE)
  
  # need to reset tour when one of these input parameters is changed
  # FIXME need function that simply redraws last picture but with updated parameters, e.g. adding/removing cube, point labels
  observeEvent(c(input$type, input$variables, input$guidedIndex, input$class, input$scagType, input$point_label, input$cMax, input$cutData, input$rescale, input$showCube, input$metadata),
               {

                 session$sendCustomMessage("debug", paste("Changed tour type to ", input$type)) #FIXME what should be messages shown here?
                 
                 # first setup all necessary ui items
                 # if grouping according to numerical variable requested, set up slider and numeric input window based on minimum and maximum value in data
                 if (rv$nums[input$class]){
                   output$numC <- reactive(TRUE)
                   minC <- min(rv$d[input$class],na.rm = TRUE)
                   maxC <- max(rv$d[input$class], na.rm = TRUE)
                   #if selected value is between minimum and maximum value we use it
                   if((input$cMax >= minC) & (input$cMax <= maxC) ){medC <- input$cMax}
                   #otherwise reset to median value
                   else{medC <- median(rv$d[input$class][,1])}
                   stepC <- (max(rv$d[input$class]) - min(rv$d[input$class])) / 100

                   updateSliderInput(session, "cMax", min=minC, max=maxC, value=medC, step=stepC)
                   updateNumericInput(session, "numCmax", value = medC)
                   
                   #range should be between minimum and maximum value
                   c1 <- max(input$cutData[1],minC) %>% min(maxC)
                   c2 <- min(input$cutData[2],maxC) %>% max(minC)
                   #if zero width range, reset to include full range
                   if(c2==c1){
                     c1 <- minC
                     c2 <- maxC
                   }
                   
                   updateSliderInput(session, "cutData", min=minC, max=maxC, value=c(c1,c2), step=stepC)
                   rv$dSelected <- filter_(rv$d, paste("cat != 'data' | (", input$class, ">= c1 &", input$class,"<= c2)"))
                   
                   #create vector of Larger and Smaller class assignment
                   rv$class <- unname(ifelse(filter(rv$dSelected,cat=="data")[input$class] > input$cMax, "Larger", "Smaller"))
                   rv$cl <- rv$class[,1]
                 }
                 else{
                   #if class variable is categorigal, simply extract class vector from the data frame
                   rv$class <- unname(filter(rv$d,cat=="data")[input$class])
                   output$numC <- reactive(FALSE)
                   rv$cl <- rv$class[[1]]
                   rv$dSelected <- rv$d
                 }
                 outputOptions(output, "numC", suspendWhenHidden = FALSE)
                 
                 rv$dScaled <- rv$dSelected # we introduce a scaled version of the input data, rescale numerical columns, with exception of chi2 and pValue
                 if (input$rescale=="[0,1]"){
                   rv$dScaled[rv$nums] <- center(rescale(rv$dScaled[rv$nums]))
                 }
                 else{rv$dScaled[rv$nums] <- center(rv$dScaled[rv$nums])}
                   #use rescaled data to extract matrices based on requested input variables
                     rv$mat <- as.matrix(filter(rv$dScaled,cat=="data")[input$variables])
                     if(rv$showCube==1){
                       rv$a <- as.matrix(filter(rv$dScaled,cat=="cubeLow")[input$variables])
                       rv$b <- as.matrix(filter(rv$dScaled,cat=="cubeUp")[input$variables])
                     }
                   
                   #this vector contains the labels passed to d3, shown on mouse over
                   rv$pLabel <- unname(filter(rv$dSelected,cat=="data")[input$point_label])
          
                 # the classes I need to select colors for
                 #FIXME this should be more dynamical, what are the shells I want to show?
                 myColV <- unique(rv$cl)
                 if(!(is.null(input$metadata))){
                   rv$metadata <- as.matrix(filter(rv$dScaled, cat %in% input$metadata)[input$variables])
                   rv$meta <- unname(filter(rv$d, cat %in% input$metadata)["cat"])
                   clMeta <- rv$meta[[1]]
                   myColV <- c(unique(clMeta), unique(rv$cl))
                 }

                 # pass requested color assignment to d3
                 session$sendCustomMessage("newcolours", myColV)
                 
                 # now we can initialise the tour
                 rv$tour <-
                   new_tour(rv$mat,choose_tour(input$type, rv$currentProj, input$guidedIndex, rv$cl, input$scagType),
                            NULL)
                 
                 # make parallel coordinate plot of data points, showing the selected variables and grouping by selected grouping class
                 colSelection <- which( colnames(rv$dSelected) %in% input$variables )
                 output$paraCoords <- renderPlot(ggparcoord(filter(rv$dSelected,cat=="data"),columns=colSelection,groupColumn=input$class),height = 250)
               }, ignoreInit = TRUE, priority = 2)
  
  
  # main function for displaying the tour steps
  observe({

    if(is.null(rv$d) || is.null(rv$tour)){return()} #nothing to observe before input file is selected and tour initialised
    
    step <- rv$tour(rv$aps / fps)
    
    if (!is.null(step)) {
      invalidateLater(1000 / fps) #selecting frequency of re-executing this observe function
      rv$currentProj <- step$proj
      #FIXME do i need to call center function? it should be done for everything simultaneously?
      j <- rv$mat %*% step$proj
      j <- cbind(j, class = rv$class)
      colnames(j) <- NULL

      if(!is.null(input$metadata)){
        jMeta <- rv$metadata %*% step$proj
        jMeta <- cbind(jMeta, class = rv$meta)
        colnames(jMeta) <- NULL
      }
      else{
        jMeta <- matrix(c(0,0,0,0,0,0),ncol=3)
      }

      
      if(!input$showCube | is.null(rv$a)){
        cubeA <- matrix(c(0,0,0,0),ncol=2)
        cubeB <- matrix(c(0,0,0,0),ncol=2)
      }
      else{
        cubeA <- rv$a %*% step$proj
        cubeB <- rv$b %*% step$proj
        colnames(cubeA) <- NULL
        colnames(cubeB) <- NULL
      }
      
    
      
      session$sendCustomMessage(type = "data", message = list(d = toJSON(data_frame(pL=rv$pLabel[,1],x=j[,2],y=j[,1],c=j[,3])),
                                                              a = toJSON(data_frame(n=input$variables,y=step$proj[,1],x=step$proj[,2])),
                                                              m = toJSON(data_frame(x=jMeta[,2],y=jMeta[,1],c=jMeta[,3])),
                                                              cube = toJSON(data_frame(ax = cubeA[,2], ay = cubeA[,1], bx=cubeB[,2],by=cubeB[,1]))))
    }
    
      else{

      if (length(rv$mat[1, ]) < 3) {
        session$sendCustomMessage(type = "debug", message = "Error: Need >2 variables.")
      } else {
        session$sendCustomMessage(type = "debug", message = "Guided tour finished: no better bases found.")
      }
    }
  }, priority = 1)
  
})
