see#!/bin/bash

# Corrige o PATH para garantir acesso aos comandos mesmo dentro do Conda
export PATH="$CONDA_PREFIX/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

INPUT_FILE="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_temp.txt"
LISTA="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_todos.txt"
LOG_DIR="logs"
INTERVAL_MONITOR=30
GENOMAS=5
SMINUSCULO=6
SMAIUSCULO=600
MMINUSCULO=1
VERSION="2_5"
TMP_DIR="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-temp"
RES_DIR="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-results/${VERSION}"
PROGRAMA="./fsm-lite"

mkdir -p "$LOG_DIR/monitor" "$LOG_DIR/output" "$TMP_DIR" "$RES_DIR"

for N in "${GENOMAS[@]}"; do
  head -n "$N" "$LISTA" > "$INPUT_FILE"

  for J in "${SMAIUSCULO[@]}"; do
    TIMESTAMP=$($CONDA_PREFIX/bin/date +%Y-%m-%d_%H-%M-%S)
    MONITOR_LOG="${LOG_DIR}/monitor/fsm_monitor_log_v${VERSION}_${N}genomas_${J}_max_TXT--${TIMESTAMP}.txt"
    OUTPUT_LOG="${LOG_DIR}/output/fsm_output_log_v${VERSION}_${N}genomas_${J}_max_TXT--${TIMESTAMP}.txt"
    TMP_FILES="${TMP_DIR}/fsm_tmp_files_v${VERSION}_${N}genomas_${J}_max_TXT--${TIMESTAMP}"
    OUTPUT_RES="${RES_DIR}/fsm_results_v${VERSION}_${N}genomas_${J}_max_TXT--${TIMESTAMP}.txt"

    echo "Rodando fsm-lite v${VERSION} saída TXT para $N amostras com $J máximo às ${TIMESTAMP}." | tee "$MONITOR_LOG" > "$OUTPUT_LOG"
    echo -e "timestamp\tcpu\tmem\tvsz\trss" >> "$MONITOR_LOG"

    ( /usr/bin/time -v "$PROGRAMA" -l "$INPUT_FILE" -s $SMINUSCULO -S $SMAIUSCULO -m $MMINUSCULO -t "$TMP_FILES" > "$OUTPUT_RES" 2> "$OUTPUT_LOG" ) &
    FSM_PID=$!

    echo "[INFO] Monitorando PID: $FSM_PID"

    while kill -0 "$FSM_PID" 2>/dev/null; do
    

timestamp=$(/bin/date +%s)
/bin/ps -p "$FSM_PID" -o %cpu,%mem,vsz,rss --no-headers | \
  /usr/bin/awk -v t="$timestamp" '{print t"\t"$1"\t"$2"\t"$3"\t"$4}' >> "$MONITOR_LOG"
/usr/bin/pidstat -h -r -u -p $FSM_PID 1 1 | \
  /usr/bin/awk -v t="$timestamp" 'NR==4 {print t"\t"$8"\t"$9"\t"$10"\t"$11}' >> "$MONITOR_LOG"
/bin/sleep "$INTERVAL_MONITOR"


    done

    wait "$FSM_PID"
    echo "[INFO] Finalizado testes com $N amostras com $J máximo às ${TIMESTAMP}."
  done
done

echo "============================="
echo "Todos os testes foram concluídos."