#!/bin/bash

INPUT_FILE=/home/joyce.souza/LACTAS-HELISSON-01/Abaumannii/GWAS_OXA-23_OXA-24/fsm_lite/input_fsm-lite_OXA-23_OXA-24_100.txt
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/fsm_monitor_log_${TIMESTAMP}.txt"
SESSION_RUN="fsm_run"
SESSION_MONITOR="fsm_monitor"

# Criar pasta de logs, se não existir
mkdir -p "$LOG_DIR"

# Definir limite de memória virtual (800 GB)
ulimit -v 838860800

# Criar log inicial
echo "Iniciando monitoramento do fsm-lite em $TIMESTAMP..." > "$LOG_FILE"

# Criar sessão tmux para rodar o fsm-lite
tmux new-session -d -s $SESSION_RUN "bash -c './fsm-lite -l \"${INPUT_FILE}\" -s 6 -S 610 -v -t fsm_kmers_100_m3 | gzip -c >> fsm_kmers_100_testes_otimiz.txt'"

# Aguardar a inicialização e capturar PID
sleep 2
FSM_PID=$(pgrep -f "./fsm-lite -l ${INPUT_FILE}")

if [ -z "$FSM_PID" ]; then
  echo "Erro: não foi possível identificar o PID de fsm-lite."
  exit 1
fi

# Comando de monitoramento (salva no arquivo de log)
MONITOR_CMD=$(cat <<EOF
while kill -0 $FSM_PID 2>/dev/null; do
  echo "------ \$(date) ------" >> "$LOG_FILE"
  ps -p $FSM_PID -o pid,ppid,%cpu,%mem,vsz,rss,etime,cmd >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
  sleep 30
done
echo "Processo fsm-lite finalizado em \$(date)." >> "$LOG_FILE"
read -p 'Pressione Enter para encerrar o monitoramento...'
EOF
)

# Criar sessão de monitoramento
tmux new-session -d -s $SESSION_MONITOR "bash -c '$MONITOR_CMD'"

# Informações ao usuário
echo "Sessões tmux criadas:"
echo "- Execução:     tmux attach -t $SESSION_RUN"
echo "- Monitoramento: tmux attach -t $SESSION_MONITOR"
echo "Log salvo em: $LOG_FILE"