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

# Caminho para o programa a ser testado
PROGRAMA="fsm-lite"  # ou o nome/caminho correto

# Arquivo com lista de genomas
LISTA="lista.txt"

# Diretório para logs e saídas
mkdir -p logs saidas inputs monitoramento

## fazer sessão tmux

## imprimir conf conda


# Valores de amostras a testar
valores=(1 5 10 25 50 100 150 200 250)

# Função para monitorar uso de recursos
monitorar_recursos() {
    local pid=$1
    local log=$2
    echo -e "timestamp\tcpu\tmem\tvsz\trss" > "$log"
    while kill -0 "$pid" 2>/dev/null; do
        timestamp=$(date +%s)
        top -b -n 1 -p "$pid" | awk -v t="$timestamp" 'NR>7 {printf "%s\t%s\t%s\t%s\t%s\n", t, $9, $10, $5, $6}' >> "$log"
        sleep 30
    done
}

# Loop sobre os valores
for N in "${valores[@]}"; do

##nome arquivos


    echo "============================="
    echo "Testando com $N amostras..."
    
    INPUT_ARQ="inputs/input_${N}.txt"
    OUTPUT_TXT="saidas/output_${N}.txt"
    OUTPUT_ZIP="saidas/output_${N}.zip"
    LOG_TIME_TXT="logs/time_txt_${N}.log"
    LOG_TIME_ZIP="logs/time_zip_${N}.log"
    MONITOR_TXT="monitoramento/monitor_txt_${N}.tsv"
    MONITOR_ZIP="monitoramento/monitor_zip_${N}.tsv"

    # Criar sublista de entrada
    head -n $N "$LISTA" > "$INPUT_ARQ"

    echo "Rodando saída TXT para $N amostras..."
    # Executar programa - TXT
    (
        /usr/bin/time -v -o "$LOG_TIME_TXT" "$PROGRAMA" -l "$INPUT_ARQ" -t "$OUTPUT_TXT"
    ) &
    PID_TXT=$!
    monitorar_recursos "$PID_TXT" "$MONITOR_TXT"
    wait "$PID_TXT"

    echo "Rodando saída GZ para $N amostras..."
    # Executar programa - GZ
    (
        /usr/bin/time -v -o "$LOG_TIME_ZIP" "$PROGRAMA" -l "$INPUT_ARQ" -t "$OUTPUT_ZIP" --zip
    ) &
    PID_ZIP=$!
    monitorar_recursos "$PID_ZIP" "$MONITOR_ZIP"
    wait "$PID_ZIP"

    echo "Finalizado teste com $N amostras."
done

echo "Todos os testes concluídos."