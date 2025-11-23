library(shiny)
source("ReConPlotGUI.R")
chromosome_choices <- paste0("chr", c(1:22, "X", "Y"))

ui <- fluidPage(
  titlePanel("ReConPlot GUI"),
  
  sidebarLayout(
    sidebarPanel(

      fileInput("seg_file", "Upload SEG file (.seg)", accept = ".seg"),
      fileInput("vcf_file", "Upload VCF file (.vcf)", accept = ".vcf"),
      selectInput(
        inputId = "chrs",
        label = "Chromosome:",
        choices = chromosome_choices, # Use the defined list of chromosomes
        selected = "chr5", # Default selection
        multiple = F # Allows selecting multiple chromosomes
      ),
      numericInput("start", "Start position:", 1064608),
      numericInput("end", "End position:", 1483627),
      textInput("genes", "Genes (comma separated):", "TERT"),
      
      numericInput("width", "Width (px):", 1080),
      numericInput("height", "Height (px):", 980),
      
      actionButton("run_btn", "Run ReConPlot", class = "btn-primary")
    ),
    
    mainPanel(
      h3("Output PDF:"),
      verbatimTextOutput("status"),
      uiOutput("download_ui")
    )
  )
)

server <- function(input, output, session){
  
  observeEvent(input$run_btn, {
    
    req(input$seg_file)
    req(input$vcf_file)
    
    isolate({
      
      seg_path <- input$seg_file$datapath
      vcf_path <- input$vcf_file$datapath
      
      #chr_vec <- strsplit(input$chrs, ",")[[1]] |> trimws()
      chr_vec <- input$chrs
      gene_vec <- strsplit(input$genes, ",")[[1]] |> trimws()
      
      outfile <- go_ReConPlot(
        seg_file = seg_path,
        seg_filename = input$seg_file$name,
        vcf_file = vcf_path,
        vcf_filename = input$vcf_file$name,
        chrs = chr_vec,
        start = input$start,
        end = input$end,
        genes = gene_vec,
        w = input$width,
        h = input$height
      )
      
      output$status <- renderText({
        paste("Completed! Output file:", outfile)
      })
      
      output$download_ui <- renderUI({
        downloadButton("download_pdf", "Download PDF")
      })
      
      output$download_pdf <- downloadHandler(
        filename = function() outfile,
        content = function(file) {
          file.copy(outfile, file)
        }
      )
    })
  })
}

shinyApp(ui, server)
