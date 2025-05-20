#!/bin/bash
set -euo pipefail
ulimit -s unlimited

# === pick up the job index (0…99) from Condor’s $(Process) ===
JOBID=$1
if [ -z "$JOBID" ]; then
  echo "Usage: $0 JOBID" >&2
  exit 1
fi

INPUT="$2"
BASENAME="$(basename "$INPUT" .root)"

# Work in the Condor sandbox
cd "$PWD"


# === calculate how many events to process ===
NEVENTS=50000

# === dynamic cfg/output names ===
CFG=Run3Summer22EENanoAOD_${JOBID}.py
XML=Run3Summer22EENanoAOD_${JOBID}.xml
OUT=DYJetsToLL_m50_NanoAOD_${JOBID}.root

singularity exec --cleanenv \
    -B /cvmfs,/etc/grid-security \
    cmssw-el8 bash -lc "
  source /cvmfs/cms.cern.ch/cmsset_default.sh
  cmsrel CMSSW_12_4_0
  cd CMSSW_12_4_0/src && cmsenv

  ### ─────────────── Now we’re inside Singularity ───────────────
  # === generate the per‐job config ===
  cmsDriver.py \
    --eventcontent NANOAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier NANOAODSIM \
    --conditions 133X_mcRun3_2022_realistic_postEE_v5 \
    --step NANO:@MUPOG \
    --scenario pp \
    --era run3_nanoAOD_pre142X \
    --geometry DB:Extended \
    --fileout file:${OUT} \
    --filein file:${INPUT}\
    --mc \
    --number ${NEVENTS} \
    --number_out ${NEVENTS} \
    --customise_commands="\
  \; process.MessageLogger.cerr.FwkReport.reportEvery = 1 \
  \; process.MessageLogger.cerr.enable = cms.untracked.bool(True) \
  \; process.MessageLogger.cerr.threshold = 'DEBUG'" \
    --python_filename  cfg_${BASENAME}_\${JOBID}.py \
    --no_exec
  
  # === run it ===
  cmsRun -e -j ${XML} ${CFG}
