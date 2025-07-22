#!/bin/bash

INPUT_FILE=/input_fsm-lite_OXA-23_OXA-24_100.txt
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_DIR="logs/fsm-lite"
TMP_DIR="tmp/fsm-lite"
MONITOR_LOG="${LOG_DIR}/fsm_monitor_log_${TIMESTAMP}.txt"
OUTPUT_LOG="${LOG_DIR}/fsm_output_log_${TIMESTAMP}.txt"
TMP_FILES="${TMP_DIR}/fsm_tmp_files_${TIMESTAMP}"
OUTPUT_RES="fsm_results_${TIMESTAMP}.txt"
SESSION_RUN="fsm_run"
SESSION_MONITOR="fsm_monitor"
INTERVAL_MONITOR=30

# Criar pasta de logs, se não existir
mkdir -p "$LOG_DIR"
mkdir -p "$TMP_DIR"

# Criar log inicial de monitoramento
echo "Iniciando monitoramento do fsm-lite em $TIMESTAMP..." > "$MONITOR_LOG"
echo "Iniciando execução do fsm-lite em $TIMESTAMP..." > "$OUTPUT_LOG"
echo "Salvando saída em: $OUTPUT_RES"

# Criar sessão tmux para executar fsm-lite com stdout + stderr no mesmo log
tmux new-session -d -s "$SESSION_RUN" "bash -c '
  echo Iniciando fsm-lite...
  { time ./fsm-lite -l \"${INPUT_FILE}\" -s 6 -S 610 -v -t \"${TMP_FILES}\" ; } \
    > \"${OUTPUT_RES}\" \
    2> \"${OUTPUT_LOG}\"
'"

# Aguardar e capturar o PID do processo
sleep 3
FSM_PID=$(pgrep -f "./fsm-lite -l ${INPUT_FILE}")

if [ -z "$FSM_PID" ]; then
  echo "Erro: não foi possível identificar o PID de fsm-lite."
  exit 1
fi

# Comando do monitoramento
# Comando do monitoramento
MONITOR_CMD=$(cat << 'EOF'
# Escreve cabeçalho uma vez
echo -e "timestamp\tpid\tppid\tcpu_percent\tmem_percent\tvsz_kb\trss_kb\telapsed\tcmd" > "$MONITOR_LOG"

while kill -0 $FSM_PID 2>/dev/null; do
  ts="\$(date '+%Y-%m-%d %H:%M:%S')"
  ps -p \$FSM_PID -o pid=,ppid=,%cpu=,%mem=,vsz=,rss=,etime=,cmd= | while read pid ppid cpu mem vsz rss elapsed cmd; do
    echo -e "\$ts\t\$pid\t\$ppid\t\$cpu\t\$mem\t\$vsz\t\$rss\t\$elapsed\t\$cmd"
  done >> "\$MONITOR_LOG"
  sleep \$INTERVAL_MONITOR
done

echo "Monitoramento encerrado em \$(date)" >> "\$MONITOR_LOG"
EOF
)


# Criar sessão de monitoramento
tmux new-session -d -s "$SESSION_MONITOR" "FSM_PID=$FSM_PID MONITOR_LOG=$MONITOR_LOG INTERVAL_MONITOR=$INTERVAL_MONITOR bash -c '$MONITOR_CMD'"

# Mensagem final
echo "Sessões tmux criadas:"
echo "- Execução:     tmux attach -t $SESSION_RUN"
echo "- Monitoramento: tmux attach -t $SESSION_MONITOR"
echo "Logs salvos em:"
echo "  - Monitoramento: $MONITOR_LOG"
echo "  - Saída + Erros do programa: $OUTPUT_LOG"
