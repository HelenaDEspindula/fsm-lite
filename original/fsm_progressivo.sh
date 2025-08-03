#!/bin/bash

INPUT_FILE="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_temp.txt"
LISTA="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_100.txt"
LOG_DIR="logs"
TMP_DIR="tmp"
SESSION_RUN="fsm_run"
SESSION_MONITOR="fsm_monitor"
INTERVAL_MONITOR=30
GENOMAS=(5 10)

# Criar pastas
mkdir -p "$LOG_DIR"
mkdir -p "$TMP_DIR"

# Criar sessão tmux para execução do fsm-lite
tmux new-session -d -s "$SESSION_RUN" "bash -c '
PROGRAMA=./fsm-lite
INPUT_FILE=\"$INPUT_FILE\"
LISTA=\"$LISTA\"
LOG_DIR=\"$LOG_DIR\"
TMP_DIR=\"$TMP_DIR\"
GENOMAS=(${GENOMAS[@]})

for N in \"\${GENOMAS[@]}\"
do
    echo \"=============================\"
    echo \"Testando com \$N amostras...\"
    
    TIMESTAMP=\$(date +%Y-%m-%d_%H-%M-%S)
    MONITOR_LOG=\"\${LOG_DIR}/fsm_monitor_log_\${TIMESTAMP}.txt\"
    OUTPUT_LOG=\"\${LOG_DIR}/fsm_output_log_\${TIMESTAMP}.txt\"
    TMP_FILES=\"\${TMP_DIR}/fsm_tmp_files_\${TIMESTAMP}\"
    OUTPUT_RES_TXT=\"/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm_results_\${TIMESTAMP}.txt\"

    # Criar sublista de entrada
    head -n \$N \"\$LISTA\" > \"\$INPUT_FILE\"

    echo \"Rodando saída TXT para \$N amostras...\"
    
    { /usr/bin/time -v \"\$PROGRAMA\" -l \"\$INPUT_FILE\" -s 6 -S 60 --debug -v -t \"\$TMP_FILES\" ; } \
        > \"\$OUTPUT_RES_TXT\" \
        2> \"\$OUTPUT_LOG\"


    sleep 3

    FSM_PID=$(pgrep -f "./fsm-lite")

    echo \"Finalizado teste com \$N amostras.\"
done
'"



if [ -z "$FSM_PID" ]; then
  echo "Erro: não foi possível identificar o PID de fsm-lite."
  exit 1
fi

# Variáveis para monitoramento
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
MONITOR_LOG="${LOG_DIR}/fsm_monitor_log_${TIMESTAMP}.txt"

# Comando do monitoramento (tmux ignora variáveis externas, por isso passamos dentro do comando)
tmux new-session -d -s "$SESSION_MONITOR" "bash -c '
FSM_PID=$FSM_PID
MONITOR_LOG=\"$MONITOR_LOG\"
INTERVAL_MONITOR=$INTERVAL_MONITOR

echo \"Iniciando monitoramento do PID \$FSM_PID...\" > \"\$MONITOR_LOG\"
while kill -0 \$FSM_PID 2>/dev/null; do
  echo \"------ \$(date) ------\" >> \"\$MONITOR_LOG\"
  ps -p \$FSM_PID -o pid,ppid,%cpu,%mem,vsz,rss,etime,cmd >> \"\$MONITOR_LOG\"
  echo \"\" >> \"\$MONITOR_LOG\"
  sleep \$INTERVAL_MONITOR
done
echo \"Processo \$FSM_PID finalizado em \$(date).\" >> \"\$MONITOR_LOG\"
'"

# Mensagem final
echo "Sessões tmux criadas:"
echo "- Execução:     tmux attach -t $SESSION_RUN"
echo "- Monitoramento: tmux attach -t $SESSION_MONITOR"
echo "Logs salvos em:"
echo "  - Monitoramento: $MONITOR_LOG"