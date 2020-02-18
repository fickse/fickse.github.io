#' ---
#' title: Using Synthetic Controls for assessing land management practices - SRM 2020 Poster Presentation
#' author: Stephen Fick
#' output:
#'    rmdformats::readthedown:
#'      includes:
#'        in_header: gstag.html
#' ---


#+ label=preamble 
#+ warning=FALSE
#+ echo=FALSE


############################################################################################
############################################################################################
############################################################################################


knitr::opts_knit$set(root.dir = '.' )
knitr::opts_chunk$set(fig.width=8, fig.height=6)
knitr::opts_chunk$set( warning=FALSE, message=FALSE)


############################################################################################
############################################################################################
############################################################################################
# to run:

#  setwd( "C:\\PROJECTS\\fickse.github.io\\synthetic.controls\\" ) # local directory
#  rmarkdown::render(file.path(getwd(), 'index.R'))

#reference : http://brooksandrew.github.io/simpleblog/articles/render-reports-directly-from-R-scripts/

#' ---  
#'  
#' # [ >>> Go To Web Tool <<< ](http://webdart.hopto.org:3838/app/webdart) 
#' 
#' 
#' # References  
#'   
#' * [Soil Geomorphic Reference Matching Algorithm](https://pubs.er.usgs.gov/publication/70178097)
#' * [Synthetic Control Algorithm](https://research.google/pubs/pub41854/)
#' * [Soil Maps](https://pubs.er.usgs.gov/publication/70205612)
#' * [Application example](https://www.sciencedirect.com/science/article/pii/S0303243418303027)
#'  


#' # how to  
#' ## Step 1.  
#' Select area of interest (Within Upper Colorado River Basin North of Lake Meade)  
#' ![instructions](step1.gif)  
#'
#' ## Step 2.
#' Click on target area
#' ![instructions2](step2.gif)
#' 
#' ## Step 3. 
#' Choose reference selection parameters
#' ![instructions3](step3.gif)
#' 
#' ## Step 4. 
#' Run DART and view reference pixels
#' ![instructions4](step4.gif)
#' 
#' ## Step 5. 
#' Analyze results and Export
#' ![instructions5](step5.gif)
#' 
#' ### [Github](https://fickse.github.com/webDART/)  
#' 
#'  
#' 
#' 
