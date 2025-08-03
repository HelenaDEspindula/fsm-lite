#!/bin/bash

INPUT_FILE=/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_temp.txt
LISTA=/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_100.txt
LOG_DIR="logs"
TMP_DIR="tmp"
SESSION_RUN="fsm_run"
SESSION_MONITOR="fsm_monitor"
INTERVAL_MONITOR=30
GENOMAS=(5 10)

# Criar pasta de logs, se não existir
mkdir -p "$LOG_DIR"
mkdir -p "$TMP_DIR"

# Criar log inicial de monitoramento
echo "Iniciando monitoramento do fsm-lite em $TIMESTAMP..." > "$MONITOR_LOG"
echo "Iniciando execução do fsm-lite em $TIMESTAMP..." > "$OUTPUT_LOG"
echo "Salvando saída em: $OUTPUT_RES"

# Criar sessão tmux para executar fsm-lite com stdout + stderr no mesmo log
tmux new-session -d -s "$SESSION_RUN" "bash -c '

  echo "Iniciando fsm-lite...""
  for N in "${GENOMAS[@]}"; do
  
    echo "============================="
    echo "Testando com $N amostras..."
    
    TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
    MONITOR_LOG="${LOG_DIR}/fsm_monitor_log_${TIMESTAMP}.txt"
    OUTPUT_LOG="${LOG_DIR}/fsm_output_log_${TIMESTAMP}.txt"
    TMP_FILES="${TMP_DIR}/fsm_tmp_files_${TIMESTAMP}"
    OUTPUT_RES_TXT="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm_results_${TIMESTAMP}.txt"
    OUTPUT_RES_GZ="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm_results_${TIMESTAMP}.txt.gz"
    
    # Criar sublista de entrada
    head -n $N "$LISTA" > "$INPUT_FILE"
    
    echo "Rodando saída TXT para $N amostras..."
    
    { time ./fsm-lite -l \"${INPUT_FILE}\" -s 6 -S 60 --debug -v -t \"${TMP_FILES}\" ; } \
      > \"${OUTPUT_RES}\" \
      2> \"${OUTPUT_LOG}\"
      
    echo "Finalizado teste com $N amostras."
done
'"

# Aguardar e capturar o PID do processo
sleep 3
FSM_PID=$(pgrep "fsm-lite")

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
