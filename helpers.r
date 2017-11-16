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
  else if (type == "Little") {
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
      scagsList <- c("Outlying","Skewed","Clumpy","Sparse","Striated","Convex","Skinny","Stringy","Monotonic")
      scagsIndex <- match(scagTypeIndex,scagsList)
      tourType <- guided_tour(scags(group_variable, scagsIndex))
    }
    
  }
  
  return(tourType)
}

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

