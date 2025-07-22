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

mkdir -p "$LOG_DIR" "$TMP_DIR"


./fsm-lite -l "$INPUT_FILE" -s 6 -S 610 -v -t "$TMP_FILES" 2> "$OUTPUT_LOG" | gzip - > "$OUTPUT_RES" 