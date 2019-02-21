#!/bin/bash
#
# Submission script for extracting charges from gpaw caclulations
#MSUB -N job
#MSUB -m abe
#MSUB -M elfleinl@cs.uni-freiburg.de
#MSUB -l nodes=20:ppn=20
#MSUB -l pmem=5900mb       # not more than 6GB
#MSUB -l walltime=00:15:00  #72:00:00  

echo " "
echo "### Setting up shell environment ..."
echo " "
if test -e "/etc/profile"; then source "/etc/profile"; fi;
if test -e "$HOME/.bash_profile"; then source "$HOME/.bash_profile"; fi;
unset LANG; export LC_ALL="C"; export MKL_NUM_THREADS=1; export OMP_NUM_THREADS=1
export USER=${USER:=`logname`}
export MOAB_JOBID=${MOAB_JOBID:=`date +%s`}
export MOAB_SUBMITDIR=${MOAB_SUBMITDIR:=`pwd`}
export MOAB_JOBNAME=${MOAB_JOBNAME:=`basename "$0"`}
export MOAB_JOBNAME=$(echo "${MOAB_JOBNAME}" | sed 's/[^a-zA-Z0-9._-]/_/g')
export MOAB_NODECOUNT=${MOAB_NODECOUNT:=1}
export MOAB_PROCCOUNT=${MOAB_PROCCOUNT:=1}
ulimit -s unlimited
ulimit -u unlimited

echo " "
echo "### Printing basic job infos to stdout ..."
echo " "
echo "START_TIME           = `date +'%y-%m-%d %H:%M:%S %s'`"
echo "HOSTNAME             = ${HOSTNAME}"
echo "USER                 = ${USER}"
echo "MOAB_JOBNAME         = ${MOAB_JOBNAME}"
echo "MOAB_JOBID           = ${MOAB_JOBID}"
echo "MOAB_SUBMITDIR       = ${MOAB_SUBMITDIR}"
echo "MOAB_NODECOUNT       = ${MOAB_NODECOUNT}"
echo "MOAB_PROCCOUNT       = ${MOAB_PROCCOUNT}"
echo "SLURM_NODELIST       = ${SLURM_NODELIST}"
echo "PBS_NODEFILE         = ${PBS_NODEFILE}"
if test -f "${PBS_NODEFILE}"; then
  echo "PBS_NODEFILE (begin) ---------------------------------"
  cat "${PBS_NODEFILE}"
  echo "PBS_NODEFILE (end) -----------------------------------"
fi
echo "---------------- ulimit -a -S ----------------"
ulimit -a -S
echo "---------------- ulimit -a -H ----------------"
ulimit -a -H
echo "----------------------------------------------"

echo " "
echo "### Loading software necessary for gpaw:"
echo " "

module purge
module load gpaw/1.3.0
module list

echo "$MOAB_PROCCOUNT"

set -e

cd ${MOAB_SUBMITDIR}

# Re-run gpaw on the structure file (molecule.traj) to extract densities
mpirun -n $MOAB_PROCCOUNT gpaw-python gpw_from_traj.py -c 0 molecule.traj restart.gpw 2>&1 > gpw_from_traj.log

# Extract the electrostatic potential from restart file (restart.gpw)
mpirun -n $MOAB_PROCCOUN gpaw-python esp_from_gpw.py system.gpw 2>&1 > esp_from_gpw.log
