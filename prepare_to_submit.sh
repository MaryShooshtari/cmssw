#!/usr/bin/env bash
set -euo pipefail

# 1) Fetch the file list from DAS
DATASET="/DYJetsToLL_M-50_TuneCP5_13p6TeV-madgraphMLM-pythia8/Run3Summer22EEMiniAODv4-forPOG_130X_mcRun3_2022_realistic_postEE_v6-v2/MINIAODSIM"
echo "Querying DAS for dataset $DATASET …"
dasgoclient --query="file dataset=${DATASET}" > inputfiles.txt
N=$(wc -l < inputfiles.txt)
echo "Got $N files."

# 2) Dry-run the Condor submit
echo "Performing condor_submit -dry-run…"
condor_submit -dry-run dryrun_report.txt condor_run_nanoAOD.sub
echo "Dry-run written to dryrun_report.txt."
echo

read -p "Ready to submit all $N jobs? [y/N] " go
if [[ "$go" =~ ^[Yy]$ ]]; then
  condor_submit condor_run_nanoAOD.sub
  echo "Submitted $N jobs. Monitor with condor_q."
else
  echo "Aborting. Edit inputfiles.txt / condor_run_nanoAOD.sub as needed."
fi
