#!/bin/bash

INPUT_FILE="input_fsm-lite_OXA-23_OXA-24_010.txt"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_DIR="logs"
TMP_DIR="tmp"
MONITOR_LOG="${LOG_DIR}/fsm_monitor_log_${TIMESTAMP}.tsv"
OUTPUT_LOG="${LOG_DIR}/fsm_output_log_${TIMESTAMP}.txt"
TMP_FILES="${TMP_DIR}/fsm_tmp_files_${TIMESTAMP}"
OUTPUT_RES="fsm_results_${TIMESTAMP}.txt.gz"
SESSION_RUN="fsm_run"
SESSION_MONITOR="fsm_monitor"
INTERVAL_MONITOR=1
USE_TMUX=1

mkdir -p "$LOG_DIR" "$TMP_DIR"

echo "Salvando saída em: $OUTPUT_RES"

# Função de monitoramento
run_monitoring() {
  echo -e "timestamp\tpid\tppid\tcpu_percent\tmem_percent\tvsz_kb\trss_kb\telapsed\tcmd" > "$MONITOR_LOG"
  while kill -0 $1 2>/dev/null; do
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    ps -p "$1" -o pid=,ppid=,%cpu=,%mem=,vsz=,rss=,etime=,cmd= | while read pid ppid cpu mem vsz rss elapsed cmd; do
      echo -e "$ts\t$pid\t$ppid\t$cpu\t$mem\t$vsz\t$rss\t$elapsed\t$cmd"
    done >> "$MONITOR_LOG"
    sleep "$INTERVAL_MONITOR"
  done
  echo "Monitoramento encerrado em $(date)" >> "$MONITOR_LOG"
}

# Tenta usar tmux
if command -v tmux &> /dev/null; then
  echo "Executando com tmux..."

  tmux new-session -d -s "$SESSION_RUN" "bash -c '
    ./fsm-lite -l \"${INPUT_FILE}\" -s 6 -S 610 -v -t \"${TMP_FILES}\" 2> \"${OUTPUT_LOG}\" | gzip - > \"${OUTPUT_RES}\"
  '"

  sleep 1

  if tmux has-session -t "$SESSION_RUN" 2>/dev/null; then
    PANE_PID=$(tmux list-panes -t "$SESSION_RUN" -F '#{pane_pid}')
    sleep 1
    FSM_PID=$(pgrep -P "$PANE_PID" -f "fsm-lite")

    if [ -z "$FSM_PID" ]; then
      echo "Erro: não foi possível identificar o PID de fsm-lite."
      echo "Use: tmux attach -t $SESSION_RUN para depurar."
      exit 1
    fi

    echo "fsm-lite iniciado com PID $FSM_PID"

    MONITOR_CMD=$(declare -f run_monitoring; echo "run_monitoring $FSM_PID")
    tmux new-session -d -s "$SESSION_MONITOR" "FSM_PID=$FSM_PID MONITOR_LOG=$MONITOR_LOG bash -c '$MONITOR_CMD'"

    echo "Sessões tmux criadas:"
    echo "- Execução:      tmux attach -t $SESSION_RUN"
    echo "- Monitoramento: tmux attach -t $SESSION_MONITOR"
  else
    echo "⚠️ Falha ao criar sessão tmux. Usando modo alternativo..."
    USE_TMUX=0
  fi
else
  echo "⚠️ tmux não encontrado. Usando modo alternativo..."
  USE_TMUX=0
fi

# Se não usar tmux, executa no fundo diretamente
if [ "$USE_TMUX" == "0" ]; then
  ./fsm-lite -l "$INPUT_FILE" -s 6 -S 610 -v -t "$TMP_FILES" 2> "$OUTPUT_LOG" | gzip - > "$OUTPUT_RES" &
  FSM_PID=$!
  echo "fsm-lite rodando em segundo plano com PID $FSM_PID"
  run_monitoring "$FSM_PID" &
fi

# Mensagem final
echo "Logs salvos em:"
echo "  - Monitoramento: $MONITOR_LOG"
echo "  - Saída compactada: $OUTPUT_RES"
echo "  - Log de erro: $OUTPUT_LOG"
