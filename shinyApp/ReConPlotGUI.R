library(ggplot2)
library(ReConPlot)
library(VariantAnnotation)
library(dplyr)

# ---- Extract sample name from SEG or VCF filename -------------------------
extract_sample_name <- function(filepath) {
  fname <- basename(filepath)
  
  # SEG patterns
  if (grepl("\\.seg$", fname)) {
    return(sub("\\.seg$", "", fname))
  }
}

# ---- Convert SEG to CN data ---------------------------------------------
seg2cn_data <- function(seg_file){
  seg_df <- read.table(
    seg_file,
    header = TRUE,
    comment.char = "@",
    stringsAsFactors = FALSE
  )
  
  copyNumber = round(2 * (2 ^ seg_df$MEAN_LOG2_COPY_RATIO))
  minorAlleleCopyNumber = round(copyNumber / 2)
  
  cn_data <- data.frame(
    chr = seg_df$CONTIG,
    start = seg_df$START,
    end = seg_df$END,
    copyNumber = copyNumber,
    minorAlleleCopyNumber = minorAlleleCopyNumber
  )
  
  conventional_chrs <- c(paste0("chr", 1:22), "chrX", "chrY")
  cn_data <- cn_data[cn_data$chr %in% conventional_chrs, ]
  
  cn_data
}

# ---- Convert VCF to SV data for ReConPlot --------------------------------
vcf2sv_data <- function(vcf_file){
  vcf <- readVcf(vcf_file)
  
  sv_gr <- rowRanges(vcf)
  sv_info <- info(vcf)
  
  sv_data <- data.frame(
    chr1 = as.character(seqnames(sv_gr)),
    pos1 = start(sv_gr),
    chr2 = ifelse(!is.na(sv_info$END), as.character(seqnames(sv_gr)), NA),
    pos2 = ifelse(!is.na(sv_info$END), sv_info$END, NA),
    strands = sv_info$SVTYPE,
    CT = sv_info$CT
  )
  
  sv_data <- sv_data %>%
    mutate(
      strands = case_when(
        strands == "DEL" ~ "+-",
        strands == "DUP" ~ "-+",
        strands == "INV" & CT == "3to3" ~ "--",
        strands == "INV" & CT == "5to5" ~ "++",
        strands == "BND" ~ "SBE",
        TRUE ~ "INS"
      )
    )
  
  sv_data
}

# ---- Main plotting function ----------------------------------------------
go_ReConPlot <- function(seg_file, seg_filename,
                         vcf_file, vcf_filename,
                         chrs, start, end, genes="TERT",
                         w=1080, h=980){
  
  # Extract sample name from *original filename*
  sample_name <- extract_sample_name(seg_filename)
  if (is.null(sample_name)) sample_name <- "sample"
  print(sample_name)
  
  cn_data <- seg2cn_data(seg_file)
  sv_data <- vcf2sv_data(vcf_file)
  
  chr_selection = data.frame(chr=chrs, start=start, end=end)
  
  sub_cn_data <- subset(cn_data, cn_data$chr %in% chrs)
  sub_sv_data <- subset(sv_data, sv_data$chr1 %in% chrs)
  
  p <- ReConPlot(
    sub_sv_data,
    sub_cn_data,
    chr_selection = chr_selection,
    legend_SV_types = TRUE,
    pos_SVtype_description = 1000,
    scale_ticks = 5000000,
    scale_separation_SV_type_labels = 1/23,
    title = paste0(sample_name, " ", chr_selection$chr[1]),
    max.cn = 20,
    genes = genes,
    genome_version = "hg38"
  )
  
  out_pdf <- paste0(sample_name, "-ReConPlot.pdf")
  ggsave(filename = out_pdf, plot = p, width = w, height = h, units = "px")
  return(out_pdf)
}
