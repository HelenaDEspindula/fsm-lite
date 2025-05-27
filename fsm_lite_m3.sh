#!/bin/bash

INPUT_FILE=/home/joyce.souza/LACTAS-HELISSON-01/Abaumannii/GWAS_OXA-23_OXA-24/fsm_lite/input_fsm-lite_OXA-23_OXA-24_100.txt

# Definir limite de memória virtual (em KB): 800 GB = 800 * 1024 * 1024
ulimit -v 838860800

# Função para monitorar uso de CPU e memória a cada 30s
monitor_usage() {
  while true; do
    echo "------ Resource usage snapshot ------"
    date
    top -b -n1 | head -n 10
    echo ""
    sleep 30
  done
}

# Iniciar monitoramento em background e guardar PID
monitor_usage &
MONITOR_PID=$!

# Executar o comando principal
time ./fsm-lite -l "${INPUT_FILE}" -s 6 -S 610 -v -t fsm_kmers_100_m3 | gzip -c >> fsm_kmers_100_testes_otimiz.txt

# Matar o processo de monitoramento quando o principal terminar
kill ${MONITOR_PID}
