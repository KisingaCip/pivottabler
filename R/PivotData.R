#' A class that contains named data frames.
#'
#' The PivotData class stores all of the data frames associated with a pivot
#' table.
#'
#' @docType class
#' @importFrom R6 R6Class
#' @importFrom data.table data.table is.data.table
#' @import jsonlite
#' @return Object of \code{\link{R6Class}} with properties and methods that help
#'   quickly storing and retrieving data frames.
#' @format \code{\link{R6Class}} object.
#' @examples
#' # This class should only be created by the pivot table.
#' # It is not intended to be created outside of the pivot table.
#' @field parentPivot Owning pivot table.

#' @section Methods:
#' \describe{
#'   \item{Documentation}{For more complete explanations and examples please see
#'   the extensive vignettes supplied with this package.}
#'   \item{\code{new(...)}}{Create a new pivot data container, specifying the
#'   field value documented above.}
#'
#'   \item{\code{addData(df, dataName)}}{And a data frame to the pivot table,
#'   specifying a name that can be used to easily retrieve it or refer to it
#'   later.}
#'   \item{\code{getData(dataName)}}{Get the data frame with the specified
#'   name.}
#'   \item{\code{isKnownData(dataName))}}{Check if a data frame exists with the
#'   specified name.}
#'   \item{\code{asList()}}{Get a list representation of the contained data
#'   frames.}
#'   \item{\code{asJSON()}}{Get a JSON representation of the contained data
#'   frames.}
#' }

PivotData <- R6::R6Class("PivotData",
  public = list(
   initialize = function(parentPivot=NULL) {
     if(parentPivot$argumentCheckMode > 0) {
       checkArgument(parentPivot$argumentCheckMode, FALSE, "PivotData", "initialize", parentPivot, missing(parentPivot), allowMissing=FALSE, allowNull=FALSE, allowedClasses="PivotTable")
     }
     private$p_parentPivot <- parentPivot
     if(private$p_parentPivot$traceEnabled==TRUE) private$p_parentPivot$trace("PivotData$new", "Creating new Pivot Data...")
     private$p_data <- list()
     private$p_defaultData <- NULL
     if(private$p_parentPivot$traceEnabled==TRUE) private$p_parentPivot$trace("PivotData$new", "Created new Pivot Data.")
   },
   addData = function(dataFrame=NULL, dataName=NULL) {
     if(private$p_parentPivot$argumentCheckMode > 0) {
       checkArgument(private$p_parentPivot$argumentCheckMode, FALSE, "PivotData", "addData", dataFrame, missing(dataFrame), allowMissing=FALSE, allowNull=FALSE, allowedClasses="data.frame")
       checkArgument(private$p_parentPivot$argumentCheckMode, FALSE, "PivotData", "addData", dataName, missing(dataName), allowMissing=TRUE, allowNull=TRUE, allowedClasses="character")
     }
     if(private$p_parentPivot$traceEnabled==TRUE) private$p_parentPivot$trace("PivotData$addData", "Adding data...", list(dataName=dataName, df=private$getDfStr(df)))
     if(private$p_parentPivot$processingLibrary=="data.table") {
       if(data.table::is.data.table(dataFrame)) data <- dataFrame
       else data <- data.table::as.data.table(dataFrame)
     }
     else {
       if(is.data.frame(dataFrame)) data <- dataFrame
       else stop("PivotData$addData():  The specified data is not a data frame.", call. = FALSE)
     }
     dn <- dataName
     if(is.null(dn)) dn <- deparse(substitute(dataFrame))
     if(is.null(dn)) stop("PivotData$addData(): Please specify a name for the data frame.", call. = FALSE)
     if(length(dn)==0) stop("PivotData$addData(): Please specify a name for the data frame.", call. = FALSE)
     if(is.null(private$p_defaultData)) {
       private$p_defaultData <- data
       private$p_defaultName <- dn
     }
     private$p_data[[dn]] <- data
     if(private$p_parentPivot$traceEnabled==TRUE) private$p_parentPivot$trace("PivotData$addData", "Added data.")
     return(invisible())
   },
   getData = function(dataName=NULL) {
     if(private$p_parentPivot$argumentCheckMode > 0) {
       checkArgument(private$p_parentPivot$argumentCheckMode, FALSE, "PivotData", "getData", dataName, missing(dataName), allowMissing=FALSE, allowNull=FALSE, allowedClasses="character")
     }
     if(private$p_parentPivot$traceEnabled==TRUE) private$p_parentPivot$trace("PivotData$getData", "Getting data...", list(dataName=dataName))
     if (!(dataName %in% names(private$p_data))) stop(paste0("PivotData$getData(): dataName '", dataName, "' not found."), call. = FALSE)
     data <- private$p_data[[dataName]]
     if(private$p_parentPivot$traceEnabled==TRUE) private$p_parentPivot$trace("PivotData$addData", "Got data.")
     return(invisible(data))
   },
   isKnownData = function(dataName=NULL) {
     if(private$p_parentPivot$argumentCheckMode > 0) {
       checkArgument(private$p_parentPivot$argumentCheckMode, FALSE, "PivotData", "isKnownData", dataName, missing(dataName), allowMissing=FALSE, allowNull=FALSE, allowedClasses="character")
     }
     if(private$p_parentPivot$traceEnabled==TRUE) private$p_parentPivot$trace("PivotData$isKnownData", "Checking dataName...", list(dataName=dataName))
     if (!(dataName %in% names(private$p_data))) return(invisible(FALSE))
     if(private$p_parentPivot$traceEnabled==TRUE) private$p_parentPivot$trace("PivotData$isKnownData", "Checked dataName.")
     return(invisible(TRUE))
   },
   asList = function() {
     lst <- list()
     if(length(private$p_data) > 0) {
       for (i in 1:length(private$p_data)) {
         dataname <- names(private$p_data)[i]
         df <- private$p_data[[dataname]]
         dlst <- private$getDfDesc(df)
         lst[[dataname]] = dlst
       }
       lst <- lst[order(names(lst))]
     }
     return(invisible(lst))
   },
   asJSON = function() { return(jsonlite::toJSON(self$asList())) }
  ),
  active = list(
    count = function(value) { return(invisible(length(private$p_data))) },
    defaultData = function(value) { return(invisible(private$p_defaultData)) },
    defaultName = function(value) { return(invisible(private$p_defaultName)) }
  ),
  private = list(
    getDfDesc = function(df) {
      if(missing(df)||is.null(df)) return("")
      return(list(
           rows=nrow(df),
           cols=ncol(df),
           size=paste0(round(object.size(df)/1024/1024, 3), " MB"),
           colNames=names(df)
      ))
    },
    getDfStr = function(df) {
      if(missing(df)||is.null(df)) return("")
      lst <- private$getDfDesc(df)
      dfStr <- paste0(lst$rows, " rows, ", lst$cols, " cols, ", lst$size, ", col names: ", paste(lst$colNames, collapse=", "))
      return(dfStr)
    },
    p_parentPivot = NULL,
    p_defaultData = NULL,
    p_defaultName = NULL,
    p_data = NULL
  )
)
