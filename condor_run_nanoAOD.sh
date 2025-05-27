#!/bin/bash
set -euo pipefail
ulimit -s unlimited

# === pick up the job index (0…99) from Condor’s $(Process) ===
JOBID=$1
if [ -z "$JOBID" ]; then
  echo "Usage: $0 JOBID INPUT" >&2
  exit 1
fi

INPUT="$2"
BASENAME="$(basename "$INPUT" .root)"

# Work in the Condor sandbox
cd "$PWD"


# === calculate how many events to process ===
NEVENTS=-1

# === dynamic cfg/output names ===
CFG=Run3Summer22EENanoAOD_${JOBID}.py
XML=Run3Summer22EENanoAOD_${JOBID}.xml
OUT=/pnfs/iihe/cms/store/user/mshoosht/RunIII/DY_m50/DYJetsToLL_m50_NanoAOD_${JOBID}.root

#cat /etc/os-release
#voms-proxy-info
export X509_USER_PROXY=$(pwd)/x509up_u$(id -u)
#echo "Running with INPUT=${INPUT}, JOBID=${JOBID}"
echo "Working dir: $PWD"
echo "Proxy file: $X509_USER_PROXY"

singularity exec -B /cvmfs -B /pnfs -B /ada_mnt -B /user -B $(pwd)/x509up_u$(id -u):/tmp/x509up_u$(id -u) -B /scratch /cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el8:latest bash -lc "
  ### ─────────────── Now we’re inside Singularity ───────────────
  cat /etc/os-release
  # Sanity check: print VOMS info inside the container
  export X509_USER_PROXY=\$PWD/x509up_u23259
  ls -l \$X509_USER_PROXY
  echo 'Inside Singularity: X509_USER_PROXY=' \$X509_USER_PROXY
  voms-proxy-info

   
  #cmsrel CMSSW_14_2_2
  cd /ada_mnt/ada/user/mshoosht/work/CMSSW_14_2_2/src
  export SCRAM_ARCH=el8_amd64_gcc11
  source /cvmfs/cms.cern.ch/cmsset_default.sh
  eval \`scramv1 runtime -sh\` 
  cmsenv

  # === generate the per‐job config ===
  cmsDriver.py \
    --eventcontent NANOAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier NANOAODSIM \
    --conditions 133X_mcRun3_2022_realistic_postEE_v5 \
    --step NANO \
    --scenario pp \
    --era run3_nanoAOD_pre142X \
    --geometry DB:Extended \
    --fileout file:${OUT} \
    --filein root://xrootd-cms.infn.it/${INPUT}\
    --mc \
    --number ${NEVENTS} \
    --number_out ${NEVENTS} \
    --python_filename  ${CFG} \
    --no_exec\
  
  # === run it ===
  cmsRun -e -j ${XML} ${CFG}"

  #  --customise_commands= \"'process.MessageLogger.cerr.FwkReport.reportEvery = 1;process.MessageLogger.cerr.enable = cms.untracked.bool(True);'\" \
  
