library(tidyverse)
source(file.path("script", "source","pipe_function.R"))

{
  lx.raw.df <- read_csv(file.path("raw", "Lx", "Lx_00_raw.csv"))
  mx.raw.df <- read_csv(file.path("raw", "Mx", "Mx_00_raw.csv"))
  
  protein.df <- read_csv(file.path("raw", "ProteinConc.csv"))
  
  lx.is.df <- read_csv(file.path("raw","Lx", "Lx_00_IS.csv")) %>% select(-starts_with("PB"))
  mx.is.df <- read_csv(file.path("raw","Mx", "Mx_00_IS.csv")) %>% select(-starts_with("PB"))
}

{
  master.raw.df <- lx.raw.df %>% mutate(exp = "Lx") %>%
    bind_rows(mx.raw.df %>% mutate(exp = "Mx")) %>%
    mutate(negpos = ifelse(str_detect(ColID, "^P"), "pos", "neg")) %>%
    select(exp, negpos, everything())
  
  master.is.df <- lx.is.df %>% select(-IS, -mz, -rt) %>%
    mutate(exp = "Lx") %>%
    bind_rows(mx.is.df %>% select(-IS, -mz, -rt) %>% mutate(exp = "Mx")) %>%
    mutate(negpos = ifelse(str_detect(ColID, "^P"), "pos", "neg")) %>%
    select(exp, negpos, everything()) %>%
    select(-starts_with("PB"))
  
  master.info <- master.raw.df %>% select(-exp, -negpos, -ColID) %>% colnames() %>% as_tibble() %>% rename(sample = value) %>%
    mutate(exp = str_extract(sample, "^([A-Z]+)")) %>% mutate(isBlank = exp == "PB", grps = as.factor(exp))
}

{
  master.br.df <- master.raw.df %>% group_by(exp, negpos) %>%
    group_modify(~blankReduce(.x, data.info = master.info)) %>% ungroup()
}

{
  master.df <- c()
  master.df$raw <- master.raw.df %>% na_if(0)
  master.df$blank_reduced <- master.br.df
  master.df$internal_standard <- master.is.df
  master.df$protein <- protein.df
  master.df$master_info <- master.info
}

{
  thres <- 3
  value_count <- master.br.df %>% rowwise() %>% mutate(count = sum(!is.na(c_across(where(is.numeric)))))
  
  master.filtered.df <- value_count %>% filter(count > thres) %>% select(-count)
  master.na.count <- value_count %>% select(ColID, count)
}

{
  master.shifted.df <- master.filtered.df %>% group_by(exp, negpos) %>% 
    group_modify(~shift_zero(.x)) %>% ungroup()
  
  master.log.df <- master.shifted.df %>% mutate_if(is.numeric, log2)
}

{
  master.is.df <- master.df$internal_standard
  master.is.log.df <- master.is.df %>% mutate_if(is.numeric, log2)
  
  master.prep.df <- master.log.df %>% bind_rows(master.is.log.df)
}

{
  master.df$filtered <- master.filtered.df
  master.df$logged <- master.log.df
  master.df$preprocessed <- master.prep.df
  master.df$case_count <- master.na.count
  master.df$filter_threshold <- thres
}

library(preprocessCore)
{
  master.quantile.df <- master.prep.df %>% group_by(exp, negpos) %>%
    group_modify(~norm_quantile(.x)) %>% ungroup()
}

{
  master.df$quantile <- master.quantile.df
}

library(crmn)
{
  master.nomis.df <- master.prep.df %>% group_by(exp, negpos) %>%
    group_modify(~norm_nomis(.x)) %>% ungroup()
  master.crmn.df <- master.prep.df %>% group_by(exp, negpos) %>%
    group_modify(~norm_crmn(.x)) %>% ungroup()
}

{
  master.df$nomis <- master.nomis.df
  master.df$crmn <- master.crmn.df
}

library(ProteoMM)
{
  master.eigenMS.df <- master.prep.df %>% group_by(exp, negpos) %>%
    group_modify(~norm_eigenMS(.x, master.info)) %>% ungroup()
}

{
  master.df$eigenMS <- master.eigenMS.df
}

{
  master.eigenMS.quantile.df <- master.eigenMS.df %>% group_by(exp, negpos) %>%
    group_modify(~norm_quantile(.x)) %>% ungroup()
}

{
  master.df$eigenMS_quantile <- master.eigenMS.quantile.df
}

{
  master.eigenMS.median.df <- master.eigenMS.df %>% group_by(exp, negpos) %>%
    group_modify(~norm_median(.x)) %>% ungroup()
}

{
  master.df$eigenMS_median <- master.eigenMS.median.df
}

save(master.df, file = file.path("output","data", "data.RData"))

