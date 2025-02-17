#!/usr/bin/env python3

import os
import wandb

def main():
    # If you haven't logged in yet, do so here, or rely on an environment variable:
    wandb.login(host=os.environ.get("WANDB_BASE_URL", "http://localhost:8080"))

    project_name = "POC-Project"
    for i in range(10):
        run = wandb.init(project=project_name, name=f"test-run-{i}", reinit=True)
        wandb.log({"iteration": i})
        run.finish()

if __name__ == "__main__":
    main()