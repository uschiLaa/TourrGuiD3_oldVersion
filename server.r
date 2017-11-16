shinyServer(function(input, output, session) {
  fps <- 33 #frames per second is fixed here
  aps <- 5 #default for step size (as angle per second), can be updated via ui
  
  rv <- reactiveValues()
  
  
  #if restart_random button selected, re-initialise with randomly selected projection
  observeEvent(input$restart_random,
              {
                
                p <- length(input$variables)
                b <- matrix(runif(2*p), p, 2) # select projection matrix entries from uniform distribution
               
                rv$tour <- new_tour(as.matrix(rv$d[input$variables]),
                                  choose_tour(input$type, input$guidedIndex, c(rv$class[[1]]), input$scagType),
                                 b)
               })
  
  #update step size (i.e. aps) given new ui input
  observeEvent(input$speed, rv$aps <- input$speed)

  #initiallize ui once input file has been selected  
  observeEvent(input$file1, {
    inFile <- input$file1
    rv$d <- read.csv(inFile$datapath, stringsAsFactors = FALSE)
           
    rv$nums <- sapply(rv$d, is.numeric)
    rv$groups <- sapply(rv$d, is.character)
    
    updateCheckboxGroupInput(
      session, "variables",
      choices = names(rv$d[rv$nums]),
      selected = names(rv$d[rv$nums])[1:3]
    )

    updateSelectInput(session, "class", choices = names(rv$d))
    updateSelectizeInput(session, "class", selected = names(rv$d[rv$groups])[1])
    updateSelectInput(session, "point_label", choices = names(rv$d), selected = names(rv$d)[1])
    
    
  })
  
  # update slider input if numerical value is chosen for the grouping threshold
  observeEvent(input$numCmax,{updateSliderInput(session, "cMax", value = input$numCmax)})

  # if showCube is selected, we read cube parameters and activate drawing option here
  # FIXME replace this by dynamically drawing cube according to number of input parameters and point positions read from some input file
  observeEvent(c(input$showCube,input$rescale),{
    if(input$showCube & length(input$variables==6)){
        rv$a <- as.matrix(filter(rv$dScaled,cat=="cubeA",pValue==68)[input$variables])
        rv$b <- as.matrix(filter(rv$dScaled,cat=="cubeB",pValue==68)[input$variables])
        showCube = 1
    }
    else{showCube = 0} #turn off cube drawing when un-selecting the option in the ui
    session$sendCustomMessage("cube", toJSON(showCube))
  }
  )
  
  # need to reset tour when one of these input parameters is changed
  # FIXME need function that simply redraws last picture but with updated parameters, e.g. adding/removing cube, point labels
  observeEvent(c(input$type, input$variables, input$guidedIndex, input$class, input$scagType, input$point_label, input$cMax, input$rescale),
               {

                 session$sendCustomMessage("debug", paste("Changed tour type to ", input$type)) #FIXME what should be messages shown here?
                 rv$dScaled <- rv$d # we introduce a scaled version of the input data, rescale numerical columns, with exception of chi2 and pValue
                 if (input$rescale=="[0,1]"){
                   scaleCols <- rv$nums
                   scaleCols["chi2"] = FALSE
                   scaleCols["pValue"] = FALSE
                   rv$dScaled[scaleCols] <- rescale(rv$dScaled[scaleCols])
                     }
                   #use rescaled data to extract matrices based on requested input variables
                     rv$mat <- as.matrix(filter(rv$dScaled,cat=="data")[input$variables])
                     rv$p68 <- as.matrix(filter(rv$dScaled,cat=="sampled",pValue==68)[input$variables])
                     rv$p95 <- as.matrix(filter(rv$dScaled,cat=="sampled",pValue==95)[input$variables])
                  # if grouping according to numerical variable requested, set up slider and numeric input window based on minimum and maximum value in data
                   if (rv$nums[input$class]){
                     output$numC <- reactive(TRUE)
                     minC <- min(rv$d[input$class])
                     maxC <- max(rv$d[input$class])
                     #if selected value is between minimum and maximum value we use it
                     if((input$cMax >= minC) & (input$cMax <= maxC) ){medC <- input$cMax}
                     #otherwise reset to median value
                     else{medC <- median(rv$d[input$class][,1])}
                     stepC <- (max(rv$d[input$class]) - min(rv$d[input$class])) / 100
                     #create vector of Larger and Smaller class assignment
                     rv$class <- unname(ifelse(filter(rv$d,cat=="data")[input$class] > input$cMax, "Larger", "Smaller"))
                     cl <- rv$class[,1]
                     updateSliderInput(session, "cMax", min=minC, max=maxC, value=medC, step=stepC)
                     updateNumericInput(session, "numCmax", value = medC)
                       
                     }
                   else{
                     #if class variable is categorigal, simply extract class vector from the data frame
                     rv$class <- unname(filter(rv$d,cat=="data")[input$class])
                     output$numC <- reactive(FALSE)
                     cl <- rv$class[[1]]
                   }
                   outputOptions(output, "numC", suspendWhenHidden = FALSE)
                   
                   #this vector contains the labels passed to d3, shown on mouse over
                   rv$pLabel <- unname(filter(rv$d,cat=="data")[input$point_label])
                 
                 # the classes I need to select colors for
                 #FIXME this should be more dynamical, what are the shells I want to show?
                 myColV <- c("p68", "p95", unique(cl))

                 # pass requested color assignment to d3
                 session$sendCustomMessage("newcolours", myColV)
                 
                 # now we can initialise the tour
                 rv$tour <-
                   new_tour(as.matrix(rv$d[input$variables]),
                            choose_tour(input$type, input$guidedIndex, cl, input$scagType),
                            NULL)
               }, ignoreInit = TRUE)
  
  
  #FIXME can i put these functions in a separate file?
  holes_ <- function() {
    function(mat) {
      n <- nrow(mat)
      d <- ncol(mat)
      
      num <- 1 - 1/n * sum(exp(-0.5 * rowSums(mat ^ 2)))
      den <- 1 - exp(-d / 2)
      
      val <- num / den
      return(val)
    }
  }
  
  scags <- function(cl,scagMetricIndex) {
    
    l <- length(unique(cl))

    if (l != 2)
    {
      stop("Scagnostics indices require two groups.")
    }
    
    
    function(mat) {
      mat_ <- cbind.data.frame(mat, class = cl)
      
      
      scagResults = c(scagnostics(subset(mat_, class == unique(cl)[1])[1:2])[scagMetricIndex],
                      scagnostics(subset(mat_, class == unique(cl)[2])[1:2])[scagMetricIndex]
        
      )
      
      
      return(abs(scagResults[1] - scagResults[2]))
      
    }
  }
  
  cmass_ <- function() {
    function(mat) {
      n <- nrow(mat)
      d <- ncol(mat)
      
      num <- 1 - 1/n * sum(exp(-0.5 * rowSums(mat ^ 2)))
      den <- 1 - exp(-d / 2)
      
      val <- num / den
      return(1 - val)
    }
  }
  
  
  # main function for displaying the tour steps
  observe({

    if(is.null(rv$d) || is.null(rv$tour)){return()} #nothing to observe before input file is selected and tour initialised
    
    tour <- rv$tour
    aps <- rv$aps
    
    step <- tour(aps / fps)
    
    if (!is.null(step)) {
      invalidateLater(1000 / fps) #selecting frequency of re-executing this observe function
      
      #FIXME do i need to call center function? it should be done for everything simultaneously?
      j <- center(rv$mat %*% step$proj)
      j <- cbind(j, class = rv$class)
      colnames(j) <- NULL
      
      j68 <- center(rv$p68 %*% step$proj)
      colnames(j68) <- NULL
      
      j95 <- center(rv$p95 %*% step$proj)
      colnames(j95) <- NULL
      
      if(!input$showCube | is.null(rv$a)){
        cubeA <- matrix(c(0,0,0,0),ncol=2)
        cubeB <- matrix(c(0,0,0,0),ncol=2)
      }
      else{
        cubeA <- center(rv$a %*% step$proj)
        cubeB <- center(rv$b %*% step$proj)
        colnames(cubeA) <- NULL
        colnames(cubeB) <- NULL
      }
      
    
      
      session$sendCustomMessage(type = "data", message = list(d = toJSON(data_frame(pL=rv$pLabel[,1],x=j[,2],y=j[,1],c=j[,3])),
                                                              a = toJSON(data_frame(n=input$variables,y=step$proj[,1],x=step$proj[,2])),
                                                              p68= toJSON(j68), p95= toJSON(j95),
                                                              cube = toJSON(data_frame(ax = cubeA[,2], ay = cubeA[,1], bx=cubeB[,2],by=cubeB[,1]))))
    }
    
      else{

      if (length(rv$mat[1, ]) < 3) {
        session$sendCustomMessage(type = "debug", message = "Error: Need >2 variables.")
      } else {
        session$sendCustomMessage(type = "debug", message = "Guided tour finished: no better bases found.")
      }
    }
  })
  
  
  
  choose_tour <- function(type,
                          subtype = "",
                          group_variable = "",
                          scagTypeIndex
  )

  {

    
    if (type == "Grand")
    {
      tourType <- grand_tour()
    }
    else if (input$type == "Little") {
      tourType <- little_tour()
      
    } else
     
    {
      if (subtype == "Holes") {
        #browser()
        tourType <- guided_tour(holes_())
      } else if (subtype == "Centre Mass") {
        #browser()
        tourType <- guided_tour(cmass_())
      }
      else if (subtype == "LDA") {
        tourType <- guided_tour(lda_pp(group_variable))
      } else if (subtype == "PDA") {
        tourType <- guided_tour(pda_pp(group_variable))
      } else {
        tourType <- guided_tour(scags(group_variable, scagTypeIndex))
      }
      
    }
    
    return(tourType)
  }
  
})
