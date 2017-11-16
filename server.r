shinyServer(function(input, output, session) {
  fps <- 33
  aps <- 5
  

  f <- grand_tour()
  rv <- reactiveValues()
  
  

  observeEvent(input$restart_random,
              {
                
                p <- length(input$variables)
                b <- matrix(runif(2*p), p, 2)
               
                rv$tour <- new_tour(as.matrix(rv$d[input$variables]),
                                  choose_tour(input$type, input$guidedIndex, c(rv$class[[1]]), input$scagType),
                                 b)
               })
  
  observeEvent(input$speed, rv$aps <- input$speed)
  
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
  
  observeEvent(input$numCmax,{updateSliderInput(session, "cMax", value = input$numCmax)})
  
  observeEvent(c(input$showCube,input$rescale),{
    if(input$showCube & length(input$variables==6)){
        rv$a <- as.matrix(filter(rv$dScaled,cat=="cubeA",pValue==68)[input$variables])
        rv$b <- as.matrix(filter(rv$dScaled,cat=="cubeB",pValue==68)[input$variables])
        showCube = 1
    }
    else{showCube = 0}
    session$sendCustomMessage("cube", toJSON(showCube))
  }
  )
  
  observeEvent(c(input$type, input$variables, input$guidedIndex, input$class, input$scagType, input$point_label, input$cMax, input$rescale),
               {

                 session$sendCustomMessage("debug", paste("Changed tour type to ", input$type))
                 rv$dScaled <- rv$d
                 if (input$rescale=="[0,1]"){
                   rv$dScaled[1:6] <- rescale(rv$dScaled[1:6])
                     }
                 if (length(input$variables) == 0) {
                     rv$mat <- as.matrix(filter(rv$dScaled,cat=="data")[names(rv$d[nums])[1:3]])
                     rv$p68 <- as.matrix(filter(rv$dScaled,cat=="sampled",pValue==68)[names(rv$d[nums])[1:3]])
                     rv$p95 <- as.matrix(filter(rv$dScaled,cat=="sampled",pValue==95)[names(rv$d[nums])[1:3]])
                   rv$class <- unname(filter(rv$d,cat=="data")[names(rv$d)[1]])
                   if (is.numeric(rv$class[,1])){
                     output$numC <- reactive(TRUE)
                     minC <- min(rv$d[names(rv$d)[1]])
                     maxC <- max(rv$d[names(rv$d)[1]])
                     if((input$cMax >= minC) & (input$cMax <= maxC) ){medC <- input$cMax}
                     else{medC <- median(rv$d[names(rv$d)[1]][,1])}
                     stepC <- (max(rv$d[names(rv$d)[1]]) - min(rv$d[names(rv$d)[1]])) / 100
                     rv$class <- unname(ifelse(filter(rv$d,cat=="data")[names(rv$d)[1]] > input$cMax, "Larger", "Smaller"))
                     cl <- rv$class[,1]
                     updateSliderInput(session, "cMax", min=minC, max=maxC, value=medC, step=stepC)
                     updateNumericInput(session, "numCmax", value = medC)
                   }
                   else{
                     rv$class <- unname(filter(rv$d,cat=="data")[input$class])
                     output$numC <- reactive(FALSE)
                     cl <- rv$class[[1]]
                   }
                   rv$pLabel <- unname(filter(rv$d,cat=="data")[names(rv$d)[1]])
                 } else {
                   
                     rv$mat <- as.matrix(filter(rv$dScaled,cat=="data")[input$variables])
                     rv$p68 <- as.matrix(filter(rv$dScaled,cat=="sampled",pValue==68)[input$variables])
                     rv$p95 <- as.matrix(filter(rv$dScaled,cat=="sampled",pValue==95)[input$variables])
                   if (rv$nums[input$class]){
                     output$numC <- reactive(TRUE)
                     minC <- min(rv$d[input$class])
                     maxC <- max(rv$d[input$class])
                     if((input$cMax >= minC) & (input$cMax <= maxC) ){medC <- input$cMax}
                     else{medC <- median(rv$d[input$class][,1])}
                     stepC <- (max(rv$d[input$class]) - min(rv$d[input$class])) / 100
                     rv$class <- unname(ifelse(filter(rv$d,cat=="data")[input$class] > input$cMax, "Larger", "Smaller"))
                     cl <- rv$class[,1]
                     updateSliderInput(session, "cMax", min=minC, max=maxC, value=medC, step=stepC)
                     updateNumericInput(session, "numCmax", value = medC)
                       
                     }
                   else{
                     rv$class <- unname(filter(rv$d,cat=="data")[input$class])
                     output$numC <- reactive(FALSE)
                     cl <- rv$class[[1]]
                   }
                   outputOptions(output, "numC", suspendWhenHidden = FALSE) 
                   rv$pLabel <- unname(filter(rv$d,cat=="data")[input$point_label])
                 }
                 
                 myColV <- c("p68", "p95", unique(cl))

                 session$sendCustomMessage("newcolours", myColV)
                 
                 
                 rv$tour <-
                   new_tour(as.matrix(rv$d[input$variables]),
                            choose_tour(input$type, input$guidedIndex, cl, input$scagType),
                            NULL)
               }, ignoreInit = TRUE)
  
  
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
  
  
  
  observe({

    if(is.null(rv$d) || is.null(rv$tour)){return()}
    
    tour <- rv$tour
    aps <- rv$aps
    
    step <- tour(aps / fps)
    
    if (!is.null(step)) {
      invalidateLater(1000 / fps)
      
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
