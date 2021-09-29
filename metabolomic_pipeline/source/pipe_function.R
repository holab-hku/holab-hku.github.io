blankReduce <- function(raw.df, data.info) {
  blank.df <- raw.df %>% select(ColID, data.info %>% filter(isBlank) %>% .$sample)
  data.df <- raw.df %>% select(ColID, data.info %>% filter(!isBlank) %>% .$sample)
  
  data.pivot <- data.df %>% pivot_longer(-ColID,
                                         names_to = "sample",
                                         values_to = "abundance")
  blank.pivot <- blank.df %>% pivot_longer(-ColID,
                                           names_to = "blank",
                                           values_to = "blank_abundance")
  
  join.pivot <- data.pivot %>% inner_join(blank.pivot, by = "ColID")
  
  br.pivot <- join.pivot %>% mutate(d = abundance - blank_abundance) %>%
    group_by(ColID, sample) %>%
    summarise(.groups = "drop",
              intensity = ifelse(var(d) == 0,
                                 mean(d),
                                 ifelse(t.test(d, alternative = "greater")$p.value < 0.05,
                                        mean(d),
                                        0)
              )
    )
  
  br.df <- br.pivot %>% na_if(0) %>%
    ungroup() %>%
    filter(!is.na(intensity)) %>%
    pivot_wider(names_from = "sample", values_from = "intensity") %>%
    select(ColID, sort(colnames(.)))
  
  return(br.df)
}

shift_zero <- function(df) {
  data.matrix <- df %>% column_to_rownames("ColID") %>% as.matrix()
  global.min <- min(data.matrix, na.rm = TRUE)
  impute.value <- global.min / 2
  data.matrix[is.na(data.matrix)] <- 0
  shifted.matrix <- data.matrix + impute.value
  return(shifted.matrix %>% as_tibble(rownames = "ColID"))
}

norm_quantile <- function(df) {
  data.matrix <- df %>% column_to_rownames("ColID") %>% as.matrix()
  normalize.quantiles(data.matrix,copy=FALSE)
  return(data.matrix %>% as_tibble(rownames = "ColID"))
}

norm_nomis <- function(df) {
  is.df <- df %>% filter(str_detect(ColID, "IS")) %>% mutate(ColID = paste0(ColID, "_tmp"))
  pre.nomis.df <- df %>% mutate(isIS = FALSE) %>% bind_rows(is.df %>% mutate(isIS = TRUE))
  
  data.matrix <- pre.nomis.df %>% select(-isIS) %>% column_to_rownames("ColID") %>% as.matrix()
  isIS <- pre.nomis.df$isIS
  nomis.matrix <- data.matrix %>% crmn::normalize("nomis", standards = isIS, lg = FALSE)
  
  return(nomis.matrix %>% as_tibble(rownames = "ColID"))
}

norm_crmn <- function(df) {
  is.df <- df %>% filter(str_detect(ColID, "IS")) %>% mutate(ColID = paste0(ColID, "_tmp"))
  pre.nomis.df <- df %>% mutate(isIS = FALSE) %>% bind_rows(is.df %>% mutate(isIS = TRUE))
  
  data.matrix <- pre.nomis.df %>% select(-isIS) %>% column_to_rownames("ColID") %>% as.matrix()
  isIS <- pre.nomis.df$isIS
  
  exp.factor <- data.matrix %>% t() %>% as_tibble(rownames = "sample") %>%
    separate(sample, c("exp", "sampleID"), sep = "_", remove = FALSE) %>%
    mutate(exp = as.factor(exp)) %>% .$exp
  factor.matrix <- model.matrix(~-1+exp.factor)
  
  crmn.matrix <- data.matrix %>% 
    crmn::normalize("crmn", standards = isIS, factors = factor.matrix, ncomp=2, lg = FALSE)
  
  return(crmn.matrix %>% as_tibble(rownames = "ColID"))
}

norm_eigenMS <- function(data.df, data.info) {
  m_logInts <- data.df %>% column_to_rownames("ColID") %>% as.data.frame()
  m_prot.info <- data.df %>% select(ColID) %>% as.data.frame()
  
  grps <- data.info %>% filter(sample %in% colnames(data.df)) %>%
    mutate(grps = as.factor(as.character(grps))) %>% .$grps
  
  hs_m_ints_eig1 <- eig_norm1(m=m_logInts,treatment=grps,prot.info=m_prot.info)
  hs_m_ints_norm <- eig_norm2(rv=hs_m_ints_eig1) 
  norm.eig.df <- hs_m_ints_norm$norm_m %>% as_tibble(rownames = "ColID")
  
  return(norm.eig.df)
}

norm_median <- function(df) {
  median.df <- df %>% summarise_if(is.numeric, median) %>%
    pivot_longer(everything(), names_to = "sample", values_to = "median")
  
  overall_median <- median.df %>% summarise(mean = mean(median))
  
  df.pivot <- df %>% pivot_longer(-ColID, names_to = "sample") %>% inner_join(
    median.df, by = "sample"
  )
  
  output <- df.pivot %>% mutate(norm = value - median + overall_median$mean) %>% select(ColID, sample, norm) %>%
    pivot_wider(names_from = "sample", values_from = "norm")
  
  return(output)
}