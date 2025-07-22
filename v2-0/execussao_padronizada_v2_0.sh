#!/bin/bash

INPUT_FILE=/input_fsm-lite_OXA-23_OXA-24_010.txt
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_DIR="logs"
TMP_DIR="tmp"
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

# Inicia fsm-lite dentro do tmux
tmux new-session -d -s "$SESSION_RUN" "bash -c '
  { time ./fsm-lite -l \"${INPUT_FILE}\" -s 6 -S 610 -v -t \"${TMP_FILES}\ ; } \
    > \"${OUTPUT_RES}\" \
    2> \"${OUTPUT_LOG}\"
'"

# Aguarda o tmux iniciar a sessão
sleep 1

# Captura o PID do processo bash dentro do tmux
PANE_PID=$(tmux list-panes -t "$SESSION_RUN" -F '#{pane_pid}')

# Aguarda 1 segundo para garantir que o fsm-lite foi chamado
sleep 1

# Captura o PID do fsm-lite filho do bash dentro do tmux
FSM_PID=$(pgrep -P "$PANE_PID" -f "fsm-lite")

# Verifica se o PID foi encontrado
if [ -z "$FSM_PID" ]; then
  echo "Erro: não foi possível identificar o PID de fsm-lite."
  echo "Use: tmux attach -t $SESSION_RUN para depurar."
  exit 1
fi

echo "fsm-lite iniciado com PID $FSM_PID"


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
