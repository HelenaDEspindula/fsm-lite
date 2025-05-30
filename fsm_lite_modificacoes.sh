#!/bin/bash

INPUT_FILE=/home/joyce.souza/LACTAS-HELISSON-01/Abaumannii/GWAS_OXA-23_OXA-24/fsm_lite/input_fsm-lite_OXA-23_OXA-24_100.txt
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_DIR="logs"
MONITOR_LOG="${LOG_DIR}/fsm_monitor_log_${TIMESTAMP}.txt"
OUTPUT_LOG="${LOG_DIR}/fsm_output_log_${TIMESTAMP}.txt"
OUTPUT_RES="fsm_results_${TIMESTAMP}.txt"
SESSION_RUN="fsm_run"
SESSION_MONITOR="fsm_monitor"
INTERVAL_MONITOR=30

# Criar pasta de logs, se não existir
mkdir -p "$LOG_DIR"

# Criar log inicial de monitoramento
echo "Iniciando monitoramento do fsm-lite em $TIMESTAMP..." > "$MONITOR_LOG"
echo "Iniciando execução do fsm-lite em $TIMESTAMP..." > "$OUTPUT_LOG"
echo "Salvando saída em: $OUTPUT_RES"

# Criar sessão tmux para executar fsm-lite com stdout + stderr no mesmo log
tmux new-session -d -s "$SESSION_RUN" "bash -c '
  echo Iniciando fsm-lite...
  { time ./fsm-lite -l \"${INPUT_FILE}\" -s 6 -S 610 -v -t fsm_kmers_100_m3; } \
    > \"${OUTPUT_RES}\" \
    2> \"${OUTPUT_LOG}\"
'"


# Aguardar e capturar o PID do processo
sleep 2
FSM_PID=$(pgrep -f "./fsm-lite -l ${INPUT_FILE}")

if [ -z "$FSM_PID" ]; then
  echo "Erro: não foi possível identificar o PID de fsm-lite."
  exit 1
fi

# Comando do monitoramento
MONITOR_CMD=$(cat << 'EOF'
while kill -0 $FSM_PID 2>/dev/null; do
  echo "------ $(date) ------" >> "$MONITOR_LOG"
  ps -p $FSM_PID -o pid,ppid,%cpu,%mem,vsz,rss,etime,cmd >> "$MONITOR_LOG"
  echo "" >> "$MONITOR_LOG"
  sleep $INTERVAL_MONITOR
done
echo "Processo fsm-lite finalizado em $(date)." >> "$MONITOR_LOG"
read -p 'Pressione Enter para encerrar o monitoramento...'
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