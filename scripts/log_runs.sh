#!/bin/bash
set -e
pip3 install --upgrade wandb
python3 scripts/log_runs.py