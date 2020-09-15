#!/bin/bash
set -e

# Needed to point the system towards pytorch CUDA
# export DISPLAY=:0
export LD_LIBRARY_PATH=/usr/local/lib/python3.6/dist-packages/torch/lib:$LD_LIBRARY_PATH

# Main command
if [ "$XPASSTHROUGH" = true ]
then
    echo "Passing through local X server."
    $@
else
    echo "Using Docker virtual X server."
    xvfb-run -a --server-args='-screen 0 640x480x24 +extension GLX +render -noreset' vglrun $@
fi
