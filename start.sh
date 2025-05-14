#!/bin/bash
killall conky
# Bepaal het pad naar de Conky-map
CONKY_DIR=$(dirname "$(readlink -f "$0")")


sleep 1
conky -c conky.conf &