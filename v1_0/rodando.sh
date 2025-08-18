#!/bin/bash

/usr/bin/time ./fsm-lite -m 1 -s 6 -S 600 -l /home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_100.txt -t temp-test > /home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-results/resultado-teste-v1_0-100g-2025-08-16--00h04.txt

/usr/bin/time ./fsm-lite -m 1 -s 6 -S 600 -l /home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/input_fsm-lite_OXA-23_OXA-24_250.txt -t temp-test > /home/helena.despindula/LACTAS-HELISSON-01/Helena-stuff/fsm-lite-results/resultado-teste-v1_0-250g-2025-08-16--00h30.txt