#!/bin/bash

INPUT_LIST=$1
TMP_PREFIX=$2
MINLEN=6
MAXLEN=610

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
LOGDIR="logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/fsm_output_log_${DATE}.txt"

ulimit -v 838860800

TMUX_SESSION="fsm_run_$DATE"
tmux new-session -d -s $TMUX_SESSION "./fsm-lite -l $INPUT_LIST -t $TMP_PREFIX -s $MINLEN -S $MAXLEN -v > $LOGFILE 2>&1"
tmux split-window -h -t $TMUX_SESSION "watch -n 1 'ps -o pid,vsz,comm -C fsm-lite'"
tmux attach -t $TMUX_SESSION