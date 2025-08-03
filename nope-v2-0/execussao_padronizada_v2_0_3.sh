#!/bin/bash

INPUT_FILE="input_fsm-lite_OXA-23_OXA-24_020.txt"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_DIR="logs"
TMP_DIR="tmp"
MONITOR_LOG="${LOG_DIR}/fsm_monitor_log_${TIMESTAMP}.txt"
OUTPUT_LOG="${LOG_DIR}/fsm_output_log_${TIMESTAMP}.txt"
TMP_FILES="${TMP_DIR}/fsm_tmp_files_${TIMESTAMP}"
OUTPUT_RES="fsm_results_${TIMESTAMP}.txt.gz"
SESSION_RUN="fsm_run"
SESSION_MONITOR="fsm_monitor"
INTERVAL_MONITOR=30

# Definir limite de memória virtual (em KB): 800 GB = 800 * 1024 * 1024
ulimit -v 838860800

mkdir -p "$LOG_DIR" "$TMP_DIR"

# Contar número de genomas
if [ ! -f "$INPUT_FILE" ]; then
  echo "Erro: arquivo de entrada $INPUT_FILE não encontrado!"
  exit 1
fi

NUM_GENOMAS=$(wc -l < "$INPUT_FILE")+1
DATA_BR=$(date '+%d/%m/%Y às %H:%M')
echo "Analisando $NUM_GENOMAS genoma(s) com início em $DATA_BR"
echo "Analisando $NUM_GENOMAS genoma(s) com início em $DATA_BR" > "$OUTPUT_LOG"
echo "Iniciando monitoramento do fsm-lite em $TIMESTAMP..." > "$MONITOR_LOG"
echo "Salvando saída em: $OUTPUT_RES" >> "$OUTPUT_LOG"

# Função de monitoramento
monitorar_processo() {
  echo -e "timestamp\tpid\tppid\tcpu\tmem\tvsz\trss\tetime\tcmd" >> "$MONITOR_LOG"
  while kill -0 "$1" 2>/dev/null; do
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    ps -p "$1" -o pid=,ppid=,%cpu=,%mem=,vsz=,rss=,etime=,cmd --no-headers | while read pid ppid cpu mem vsz rss etime cmd; do
      echo -e "$ts\t$pid\t$ppid\t$cpu\t$mem\t$vsz\t$rss\t$etime\t$cmd"
    done >> "$MONITOR_LOG"
    sleep "$INTERVAL_MONITOR"
  done
  echo "Processo fsm-lite finalizado em $(date)" >> "$MONITOR_LOG"
}

# Tenta usar tmux
if command -v tmux &> /dev/null; then
  echo "Executando com tmux..."

  tmux new-session -d -s "$SESSION_RUN" "bash -c '
    ./fsm-lite -l \"$INPUT_FILE\" -s 6 -S 610 -v -t \"$TMP_FILES\" 2> \"$OUTPUT_LOG\" | gzip - > \"$OUTPUT_RES\"
  '"

  sleep 2
  if tmux has-session -t "$SESSION_RUN" 2>/dev/null; then
    PANE_PID=$(tmux list-panes -t "$SESSION_RUN" -F '#{pane_pid}')
    sleep 1
    FSM_PID=$(pgrep -P "$PANE_PID" -f "fsm-lite")

    if [ -z "$FSM_PID" ]; then
      echo "⚠️ Não foi possível identificar o PID de fsm-lite. Execute manualmente com: tmux attach -t $SESSION_RUN"
      exit 1
    fi

    echo "fsm-lite iniciado com PID $FSM_PID"

    MONITOR_CMD=$(declare -f monitorar_processo; echo "monitorar_processo $FSM_PID")
    tmux new-session -d -s "$SESSION_MONITOR" "bash -c '$MONITOR_CMD'"

    echo "Sessões tmux criadas:"
    echo "- Execução:     tmux attach -t $SESSION_RUN"
    echo "- Monitoramento: tmux attach -t $SESSION_MONITOR"

  else
    echo "⚠️ tmux falhou. Executando no terminal..."
    USE_TMUX=0
  fi
else
  echo "⚠️ tmux não disponível. Executando no terminal..."
  USE_TMUX=0
fi

# Execução fora do tmux
if [ "$USE_TMUX" == "0" ]; then
  ./fsm-lite -l "$INPUT_FILE" -s 6 -S 610 -v -t "$TMP_FILES" 2> "$OUTPUT_LOG" | gzip - > "$OUTPUT_RES" &
  FSM_PID=$!
  echo "fsm-lite rodando com PID $FSM_PID"
  monitorar_processo "$FSM_PID" &

  # Aguarda o término do processo principal
  wait "$FSM_PID"
  echo "✅ fsm-lite finalizado com sucesso em $(date '+%d/%m/%Y às %H:%M:%S')"
fi


# Mensagem final
echo "Logs salvos em:"
echo "  - Monitoramento: $MONITOR_LOG"
echo "  - Saída (gzip):  $OUTPUT_RES"
echo "  - Log de erro:   $OUTPUT_LOG"
