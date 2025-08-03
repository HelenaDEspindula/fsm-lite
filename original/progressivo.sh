#!/bin/bash

INPUT_FILE="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_temp.txt"
LISTA="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_100.txt"
LOG_DIR="logs"
TMP_DIR="tmp"
INTERVAL_MONITOR=30
GENOMAS=(5 10 25 50 100)
SMINUSCULO=6
SMAIUSCULO=60
MMINUSCULO=1
LOG_DIR="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-temp"
TMP_DIR="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-results"


PROGRAMA="./fsm-lite"

for N in "${GENOMAS[@]}"; do
  echo "============================="
  echo "Testando com $N amostras..."

  TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
  MONITOR_LOG="${LOG_DIR}/fsm_monitor_log_${TIMESTAMP}.tsv"
  OUTPUT_LOG="${LOG_DIR}/fsm_output_log_${TIMESTAMP}.txt"
  TMP_FILES="${TMP_DIR}/fsm_tmp_files_${TIMESTAMP}"
  OUTPUT_RES="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm_results_${TIMESTAMP}.txt"

  # Criar sublista
  head -n "$N" "$LISTA" > "$INPUT_FILE"

  echo "Rodando fsm-lite para $N amostras." > "$MONITOR_LOG"
  echo -e "timestamp\tcpu\tmem\tvsz\trss" >> "$MONITOR_LOG"
  
  echo "Rodando fsm-lite para $N amostras." > "$OUTPUT_RES"

  echo "Rodando fsm-lite para $N amostras..."
  
  # Executar fsm-lite em background
  ( /usr/bin/time -v "$PROGRAMA" -l "$INPUT_FILE" -s $SMINUSCULO -S $SMAIUSCULO -m $MMINUSCULO --debug -v -t "$TMP_FILES" >> "$OUTPUT_RES" 2> "$OUTPUT_LOG" ) &
  FSM_PID=$!

  echo "Monitorando PID: $FSM_PID"

  # Monitorar enquanto o processo estiver rodando
  while kill -0 "$FSM_PID" 2>/dev/null; do
    timestamp=$(date +%s)
    ps -p "$FSM_PID" -o %cpu,%mem,vsz,rss --no-headers | \
      awk -v t="$timestamp" '{print t"\t"$1"\t"$2"\t"$3"\t"$4}' >> "$MONITOR_LOG"
    pidstat -h -r -u -p $FSM_PID 1 1 | awk -v t="$timestamp" 'NR==4 {print t"\t"$8"\t"$9"\t"$10"\t"$11}' >> "$MONITOR_LOG"
    sleep "$INTERVAL_MONITOR"
  done

  wait "$FSM_PID"
  echo "Finalizado teste com $N amostras."
done

echo "Todos os testes foram concluídos."
