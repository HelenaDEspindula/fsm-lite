#!/bin/bash

INPUT_FILE="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_temp.txt"
LISTA="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_todos.txt"
LOG_DIR="logs"
INTERVAL_MONITOR=30
GENOMAS=(25 100 250)
SMINUSCULO=6
SMAIUSCULO=600
MMINUSCULO=1
VERSION="2_2"
TMP_DIR="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-temp"
RES_DIR="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-results/${VERSION}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

PROGRAMA="./fsm-lite"

rm *.sdsl

# Criar pastas
mkdir -p "$LOG_DIR/monitor"
mkdir -p "$LOG_DIR/output"
mkdir -p "$TMP_DIR"
mkdir -p "$RES_DIR"

for N in "${GENOMAS[@]}"; do

  # Criar sublista
  head -n "$N" "$LISTA" > "$INPUT_FILE"

  for J in "${SMAIUSCULO[@]}"; do
  
    echo "============================="
  
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    MONITOR_LOG="${LOG_DIR}/monitor/fsm_monitor_log_v${VERSION}_${N}genomas_${J}_max_TXT--${TIMESTAMP}.txt"
    OUTPUT_LOG="${LOG_DIR}/output/fsm_output_log_v${VERSION}_${N}genomas_${J}_max_TXT--${TIMESTAMP}.txt"
    TMP_FILES="${TMP_DIR}/fsm_tmp_files_v${VERSION}_${N}genomas_${J}_max_TXT--${TIMESTAMP}"
    OUTPUT_RES="${RES_DIR}/fsm_results_v${VERSION}_${N}genomas_${J}_max_TXT--${TIMESTAMP}.txt"



    echo "Rodando fsm-lite v${VERSION} saida TXT: para $N amostras com $J de maximo as ${TIMESTAMP}." > "$MONITOR_LOG"
    echo "Rodando fsm-lite v${VERSION} saida TXT: para $N amostras com $J de maximo as ${TIMESTAMP}." > "$OUTPUT_LOG"
    echo -e "timestamp\tcpu\tmem\tvsz\trss" >> "$MONITOR_LOG"

    echo "Rodando fsm-lite v${VERSION} saida TXT: para $N amostras com $J de maximo as ${TIMESTAMP}."

    # Executar fsm-lite em background
    ( /usr/bin/time -v "$PROGRAMA" -l "$INPUT_FILE" -s $SMINUSCULO -S $SMAIUSCULO -m $MMINUSCULO -t "$TMP_FILES" > "$OUTPUT_RES" 2> "$OUTPUT_LOG" ) &
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
    
    # echo "============================="
    # 
    # TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    # MONITOR_LOG="${LOG_DIR}/monitor/fsm_monitor_log_v${VERSION}_${N}genomas_${J}_max_GZ--${TIMESTAMP}.txt"
    # OUTPUT_LOG="${LOG_DIR}/output/fsm_output_log_v${VERSION}_${N}genomas_${J}_max_GZ--${TIMESTAMP}.txt"
    # TMP_FILES="${TMP_DIR}/fsm_tmp_files_v${VERSION}_${N}genomas_${J}_max_GZ--${TIMESTAMP}"
    # OUTPUT_RES="${RES_DIR}/fsm_results_v${VERSION}_${N}genomas_${J}_max_GZ--${TIMESTAMP}.txt.gz"
    # 
    # 
    # 
    # echo "Rodando fsm-lite v${VERSION} saida GZ: para $N amostras com $J de maximo as ${TIMESTAMP}." > "$MONITOR_LOG"
    # echo "Rodando fsm-lite v${VERSION} saida GZ: para $N amostras com $J de maximo as ${TIMESTAMP}." > "$OUTPUT_LOG"
    # echo -e "timestamp\tcpu\tmem\tvsz\trss" >> "$MONITOR_LOG"
    # 
    # 
    # echo "Rodando fsm-lite v${VERSION} saida GZ: para $N amostras com $J de maximo as ${TIMESTAMP}."
    # 
    # # Executar fsm-lite em background
    # ( ( /usr/bin/time -v "$PROGRAMA" -l "$INPUT_FILE" -s $SMINUSCULO -S $SMAIUSCULO -m $MMINUSCULO -t "$TMP_FILES" | gzip -c > "$OUTPUT_RES" ) 2> "$OUTPUT_LOG" ) &
    # FSM_PID=$!
    # 
    # echo "Monitorando PID: $FSM_PID"
    # 
    #   # Monitorar enquanto o processo estiver rodando
    #   while kill -0 "$FSM_PID" 2>/dev/null; do
    #     timestamp=$(date +%s)
    #     ps -p "$FSM_PID" -o %cpu,%mem,vsz,rss --no-headers | \
    #       awk -v t="$timestamp" '{print t"\t"$1"\t"$2"\t"$3"\t"$4}' >> "$MONITOR_LOG"
    #     pidstat -h -r -u -p $FSM_PID 1 1 | awk -v t="$timestamp" 'NR==4 {print t"\t"$8"\t"$9"\t"$10"\t"$11}' >> "$MONITOR_LOG"
    #     sleep "$INTERVAL_MONITOR"
    #   done
    
  done

  wait "$FSM_PID"
  echo "Finalizado testes com $N amostras com $J de maximo as ${TIMESTAMP}."
done

echo "============================="
echo "============================="
echo "Todos os testes foram concluídos."
