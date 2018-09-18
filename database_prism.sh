#!/bin/sh
#
# this does a GBS Q/C run on the (GBS related) hiseq output.
# it is run after process_hiseq.sh 
# 

function get_opts() {

help_text="
 examples : \n
 ./database_prism.sh -i -t db_update -r 180914_D00390_0399_ACCVK0ANXX -s SQ0788\n
"

DRY_RUN=no
INTERACTIVE=no
TASK=db_update
RUN=all
MACHINE=hiseq
SAMPLE=""
REUSE_TARGETS="no"

while getopts ":nikht:r:m:s:e:" opt; do
  case $opt in
    n)
      DRY_RUN=yes
      ;;
    k)
      REUSE_TARGETS=yes
      ;;
    i)
      INTERACTIVE=yes
      ;;
    t)
      TASK=$OPTARG
      ;;
    m)
      MACHINE=$OPTARG
      ;;
    r)
      RUN=$OPTARG
      ;;
    s)
      SAMPLE=$OPTARG
      ;;
    h)
      echo -e $help_text
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

HISEQ_ROOT=/dataset/${MACHINE}/active
BUILD_ROOT=/dataset/gseq_processing/scratch/illumina/${MACHINE} 

CANONICAL_HISEQ_ROOT=/dataset/hiseq/active
CANONICAL_BUILD_ROOT=/dataset/gseq_processing/scratch/illumina/hiseq

}


function check_opts() {
if [ -z "$GBS_PRISM_BIN" ]; then
   echo "GBS_PRISM_BIN not set - quitting"
   exit 1
fi

# check args
if [[ ( $TASK != "db_update" ) ]]; then
    echo "Invalid task name - must be db_update" 
    exit 1
fi

# machine must be miseq or hiseq 
if [[ ( $MACHINE != "hiseq" ) && ( $MACHINE != "miseq" ) ]]; then
    echo "machine must be miseq or hiseq"
    exit 1
fi

}


function echo_opts() {
    echo "run to process : $RUN"
    echo "task requested : $TASK"
    echo "dry run : $DRY_RUN"
    echo "interactive : $INTERACTIVE"
    echo "machine : $MACHINE"
}

function get_samples() {
   set -x
   if [ -z $SAMPLE ]; then
      sample_monikers=`psql -U agrbrdf -d agrbrdf -h invincible -v run=\'$RUN\' -f $GBS_PRISM_BIN/get_run_samples.psql -q`
   else
      sample_monikers=$SAMPLE
   fi

   echo DEBUG $sample_monikers
   set +x
}

function update_database() {
   add_run
   get_samples 
   import_keyfiles
   update_fastq_locations
}

function add_run() {
   # add the run 
   echo "** adding Run **"
   set -x
   if [ $DRY_RUN == "no" ]; then
      $GBS_PRISM_BIN/addRun.sh -r $RUN -m $MACHINE
   else
      $GBS_PRISM_BIN/addRun.sh -n -r $RUN -m $MACHINE
   fi
}

function import_keyfiles() {
   # import the keyfiles
   echo "** importing keyfiles **"
   set -x
   for sample_moniker in $sample_monikers; do
      if [ $DRY_RUN == "no" ]; then
         $GBS_PRISM_BIN/importOrUpdateKeyfile.sh -k $sample_moniker -s $sample_moniker
      else
         $GBS_PRISM_BIN/importOrUpdateKeyfile.sh -n -k $sample_moniker -s $sample_moniker
      fi
      if [ $? != "0" ]; then
          echo "importOrUpdateKeyfile.sh  exited with $? - quitting"
          exit 1
      fi
   done
}

function update_fastq_locations() {
   # update the fastq locations 
   echo "** updating fastq locations **"
   set -x
   for sample_moniker in $sample_monikers; do
      # to do : add a check that there is only one fcid - process not tested for 
      # a sample spread over different flowcells
      flowcell_moniker=`$GBS_PRISM_BIN/get_flowcellid_from_database.sh $RUN $sample_moniker`
      flowcell_lanes=`$GBS_PRISM_BIN/get_lane_from_database.sh $RUN $sample_moniker`
      for flowcell_lane in $flowcell_lanes; do
         echo "processing lane '${flowcell_lane}'"
         if [ $DRY_RUN == "no" ]; then
            $GBS_PRISM_BIN/updateFastqLocations.sh -s $sample_moniker -k $sample_moniker -r $RUN -f $flowcell_moniker -l $flowcell_lane 
         else
            $GBS_PRISM_BIN/updateFastqLocations.sh -n -s $sample_moniker -k $sample_moniker -r $RUN -f $flowcell_moniker -l $flowcell_lane 
         fi
         if [ $? != "0" ]; then
            echo "error !! updateFastqLocations.sh  exited with $? for $sample_moniker - continuing to attempt other samples "
         fi
      done
   done
}

get_opts $@

check_opts

echo_opts

update_database 