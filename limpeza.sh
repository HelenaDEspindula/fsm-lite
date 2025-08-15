#!/bin/bash

FILES_OUTPUT="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite/*/logs/output/fsm_output_log_v1_0_5*.txt"
FILES_MONITOR="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite/*/logs/monitor/fsm_monitor_log_v1_0_5*.txt"
FILES_RESULTS="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-results/*/fsm_results_v1_0_5g*.txt"
FILES_TEMP="/home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-temp/"

rm $FILES_OUTPUT
rm $FILES_MONITOR
rm $FILES_RESULTS
rm -R $FILES_TEMP

