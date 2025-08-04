require(ggplot2)
require(lubridate)
require(stringr)
require(dplyr)

# Caminho dos logs
log_dir <- "original/logs/output/"
log_files <- list.files(log_dir, pattern = "fsm_output_log_.*\\.txt$", full.names = TRUE)

print("Foram encontrados os arquivos")
print(log_files)


tempo_para_segundos <- function(t) {
  if (grepl(":", t)) {
    partes <- as.numeric(unlist(strsplit(t, ":")))
    if (length(partes) == 3) return(partes[1]*3600 + partes[2]*60 + partes[3])
    if (length(partes) == 2) return(partes[1]*60 + partes[2])
  }
  return(as.numeric(t))
}

extrair_dados_log <- function(arquivo) {
  linhas <- readLines(arquivo)
  nome <- basename(arquivo)
  
  # Extrair metadados do nome do arquivo
  versao <- str_match(nome, "fsm_output_log_(v[0-9_]+)")[,2]
  genomas <- as.numeric(str_match(nome, "_([0-9]+)genomas")[,2])
  max_param <- as.numeric(str_match(nome, "_([0-9]+)_max")[,2])
  tipo_output <- str_match(nome, "_(TXT|GZ)--")[,2]
  timestamp <- str_match(nome, "--([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9-]{8})")[,2]
  
  get_valor <- function(chave) {
    linha <- grep(chave, linhas, value = TRUE)
    if (length(linha) > 0) {
      return(str_trim(gsub(".*:\\s*", "", linha)))
    } else {
      return(NA)
    }
  }
  
  # Extrai tempo decorrido como string tipo "4:31.51"
  get_elapsed <- function(linhas) {
    linha <- grep("Elapsed \\(wall clock\\) time", linhas, value = TRUE)
    if (length(linha) > 0) {
      tempo <- str_match(linha, ":\\s*(\\d+:\\d+(\\.\\d+)?)")[,2]
      return(tempo)
    } else {
      return(NA)
    }
  }
  
  # Extração dos dados do conteúdo
  elapsed <- tempo_para_segundos(get_elapsed(linhas))
  user <- as.numeric(get_valor("User time"))
  system <- as.numeric(get_valor("System time"))
  cpu_pct <- as.numeric(gsub("%", "", get_valor("Percent of CPU")))
  max_mem_kb <- as.numeric(get_valor("Maximum resident set size"))
  max_mem_mb <- round(max_mem_kb / 1024, 2)
  
  print(elapsed)
  
  data.frame(
    arquivo = nome,
    versao = versao,
    genomas = genomas,
    max_param = max_param,
    tipo_output = tipo_output,
    timestamp = timestamp,
    elapsed_sec = elapsed,
    user_time = user,
    system_time = system,
    cpu_percent = cpu_pct,
    max_rss_mb = max_mem_mb
  )
}

# Aplicar a função
tabela_logs <- bind_rows(lapply(log_files, extrair_dados_log))

# Visualizar
print(tabela_logs)
View(tabela_logs)

# Exportar se quiser
write.csv(tabela_logs, "original/resumo_execucoes_v1_0.csv", row.names = FALSE)

