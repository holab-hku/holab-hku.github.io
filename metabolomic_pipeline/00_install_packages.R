if (!requireNamespace("tidyverse", quietly = TRUE))
  install.packages("tidyverse")

if (!requireNamespace("cowplot", quietly = TRUE))
  install.packages("cowplot")

if (!requireNamespace("crmn", quietly = TRUE))
  install.packages("crmn")

if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

if (!requireNamespace("limma", quietly = TRUE))
  BiocManager::install("limma")

if (!requireNamespace("ProteoMM", quietly = TRUE))
  BiocManager::install("ProteoMM")

if (!requireNamespace("preprocessCore", quietly = TRUE))
  BiocManager::install("preprocessCore")

# The installation guide on NetID is on
# https://github.com/LiChenPU/NetID/blob/main/get%20started/UserGuideMD/User_guide_pdf.pdf