# For Window user you need to install Rtools for corresponding R version
# https://cran.r-project.org/bin/windows/Rtools/

# List of required CRAN/Bioconductor packages
packages <- c("shiny", "ggplot2", "dplyr", "remotes")

# Install missing packages only
install_if_missing <- function(pkgs) {
  missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing_pkgs)) install.packages(missing_pkgs)
}
install_if_missing(packages)

# --- Install BiocManager if necessary ---
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
# Install VariantAnnotation. For first time user, this will take 20 min.
# You may need to execute this command twice in case some of files failed in the first compiling. 
if (!requireNamespace("VariantAnnotation", quietly = FALSE)) {
  BiocManager::install("VariantAnnotation")
}

# Run the app
shiny::runApp("shinyApp")
