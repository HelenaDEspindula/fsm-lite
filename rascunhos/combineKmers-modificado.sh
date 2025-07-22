#!/bin/bash

SAMPLES_FILE="/home/joyce.souza/LACTAS-HELISSON-01/fsm-lite/mudancas/fsm-lite/samples.txt"
OUTPUT_PREFIX="combined_kmers"
MIN_SAMPLES=2
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_DIR="logs/combineKmers"
MONITOR_LOG="${LOG_DIR}/combine_monitor_log_${TIMESTAMP}.txt"
OUTPUT_LOG="${LOG_DIR}/combine_output_log_${TIMESTAMP}.txt"
OUTPUT_RES="${OUTPUT_PREFIX}_${TIMESTAMP}.tsv"
SESSION_RUN="combine_run"
SESSION_MONITOR="combine_monitor"
INTERVAL_MONITOR=30

# Verificar se o arquivo samples.txt existe
if [ ! -f "$SAMPLES_FILE" ]; then
  echo "[ERRO] O arquivo de amostras \"$SAMPLES_FILE\" não foi encontrado."
  exit 1
fi

# Criar pasta de logs, se não existir
mkdir -p "$LOG_DIR"

# Criar logs iniciais
echo "Iniciando monitoramento do combineKmers em $TIMESTAMP..." > "$MONITOR_LOG"
echo "Iniciando execução do combineKmers em $TIMESTAMP..." > "$OUTPUT_LOG"
echo "Saída final em: $OUTPUT_RES"

# Iniciar execução em sessão tmux
tmux new-session -d -s "$SESSION_RUN" "bash -c '
  echo Iniciando combineKmers...
  { time ./combineKmers -r \"$SAMPLES_FILE\" -o \"$OUTPUT_RES\" --min_samples $MIN_SAMPLES ; } > \"$OUTPUT_LOG\" 2>&1
'"

# Esperar e capturar o PID
sleep 2
COMBINE_PID=$(pgrep -f "./combineKmers -r ${SAMPLES_FILE}")

if [ -z "$COMBINE_PID" ]; then
  echo "[ERRO] Não foi possível identificar o PID de combineKmers. Verifique se o binário foi iniciado corretamente."
  exit 1
fi

# Comando do monitoramento
MONITOR_CMD=$(cat << 'EOF'
while kill -0 $COMBINE_PID 2>/dev/null; do
  echo "------ $(date) ------" >> "$MONITOR_LOG"
  ps -p $COMBINE_PID -o pid,ppid,%cpu,%mem,vsz,rss,etime,cmd >> "$MONITOR_LOG"
  echo "" >> "$MONITOR_LOG"
  sleep $INTERVAL_MONITOR
done
echo "Processo combineKmers finalizado em $(date)." >> "$MONITOR_LOG"
read -p 'Pressione Enter para encerrar o monitoramento...'
EOF
)

# Iniciar sessão tmux de monitoramento
tmux new-session -d -s "$SESSION_MONITOR" "COMBINE_PID=$COMBINE_PID MONITOR_LOG=$MONITOR_LOG INTERVAL_MONITOR=$INTERVAL_MONITOR bash -c '$MONITOR_CMD'"

# Mensagem final
echo "Sessões tmux criadas:"
echo "- Execução:     tmux attach -t $SESSION_RUN"
echo "- Monitoramento: tmux attach -t $SESSION_MONITOR"
echo "Logs salvos em:"
echo "  - Monitoramento: $MONITOR_LOG"
echo "  - Saída + Erros do programa: $OUTPUT_LOG"
echo "  - Resultado combinado: $OUTPUT_RES"
