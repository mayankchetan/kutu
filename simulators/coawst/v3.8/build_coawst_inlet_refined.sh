#!/bin/bash
#
# git $Id$
# svn $Id: build_roms.sh 1151 2023-02-09 03:08:53Z arango $
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Copyright (c) 2002-2023 The ROMS/TOMS Group                           :::
#   Licensed under a MIT/X style license                                :::
#   See License_ROMS.txt                                                :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::: Hernan G. Arango :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::: John C. Warner   :::
#                                                                       :::
# ROMS Compiling Script                                                 :::
# Modified to configure the COAWST Modeling System                      :::
#                                                                       :::
# Script to compile an user application where the application-specific  :::
# files are kept separate from the ROMS source code.                    :::
#                                                                       :::
# Q: How/why does this script work?                                     :::
#                                                                       :::
# A: The ROMS makefile configures user-defined options with a set of    :::
#    flags such as ROMS_APPLICATION. Browse the makefile to see these.  :::
#    If an option in the makefile uses the syntax ?= in setting the     :::
#    default, this means that make will check whether an environment    :::
#    variable by that name is set in the shell that calls make. If so   :::
#    the environment variable value overrides the default (and the      :::
#    user need not maintain separate makefiles, or frequently edit      :::
#    the makefile, to run separate applications).                       :::
#                                                                       :::
# Usage:                                                                :::
#                                                                       :::
#    ./build_roms.sh [options]                                          :::
#                                                                       :::
# Options:                                                              :::
#                                                                       :::
#    -j [N]       Compile in parallel using N CPUs                      :::
#                  omit argument for all available CPUs                 :::
#    -p macro     Prints any Makefile macro value. For example,         :::
#                  build.bash -p FFLAGS                                 :::
#    -noclean     Do not clean already compiled roms objects            :::
#    -nocleanwrf  Do not clean already compiled wrf objects             :::
#    -nocleanww3  Do not clean already compiled ww3 objects             :::
#                                                                       :::
# Notice that sometimes the parallel compilation fail to find MPI       :::
# include file "mpif.h".                                                :::
#                                                                       :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
############################################################################
# Top area here is to set flags from calling this routine. Do not change.
#
parallel=0
clean=1
dprint=0
cleanwrf=1
cleanwrfhydro=1
cleanww3=1
cleanswan=1

export MY_CPP_FLAGS=

while [ $# -gt 0 ]
do
  case "$1" in
    -j )
      shift
      parallel=1
      test=`echo $1 | grep '^[0-9]\+$'`
      if [ "$test" != "" ]; then
        NCPUS="-j $1"
        shift
      else
        NCPUS="-j"
      fi
      ;;

    -p )
      shift
      clean=0
      dprint=1
      debug="print-$1"
      shift
      ;;

    -noclean )
      shift
      clean=0
      ;;

    -nocleanwrf )
      shift
      cleanwrf=0
      ;;

    -nocleanwrfhydro )
      shift
      cleanwrfhydro=0
      ;;

    -nocleanww3 )
      shift
      cleanww3=0
      ;;

    -nocleanswan )
      shift
      cleanswan=0
      ;;

    * )
      echo ""
      echo "$0 : Unknown option [ $1 ]"
      echo ""
      echo "Available Options:"
      echo ""
      echo "-j [N]      Compile in parallel using N CPUs"
      echo "              omit argument for all avaliable CPUs"
      echo "-p macro    Prints any Makefile macro value"
      echo "              For example:  build.bash -p FFLAGS"
      echo "-noclean       Do not clean already compiled objects"
      echo "-nocleanwrf    Do not clean already compiled wrf objects"
      echo "-nocleanwrfhydro Do not clean already compiled wrf objects"
      echo "-nocleanww3    Do not clean already compiled ww3 objects"
      echo ""
      exit 1
      ;;
  esac
done
############################################################################
# Start of USER definitions area:
#
# Set the CPP option defining the particular application. This will
# determine the name of the ".h" header file with the application
# CPP definitions. Also this will activate the switch file for WW3.
export COAWST_APPLICATION=INLET_TEST

# Set the ROMS_APPLICATION to be the same as the COAWST_APP.
# Do not change this. We use the COAWST APP for other checks.
export ROMS_APPLICATION=${COAWST_APPLICATION}

# Set a local environmental variable to define the path to the directories
# where all this project's files are kept.
export MY_ROOT_DIR=/opt/COAWST
export MY_PROJECT_DIR=${MY_ROOT_DIR}

# The path to the user's local current ROMS source code.
#
# If using svn locally, this would be the user's Working Copy Path (WCPATH).
# Note that one advantage of maintaining your source code locally with svn
# is that when working simultaneously on multiple machines (e.g. a local
# workstation, a local cluster and a remote supercomputer) you can checkout
# the latest release and always get an up-to-date customized source on each
# machine. This script is designed to more easily allow for differing paths
# to the code and inputs on differing machines.
export   MY_ROMS_SRC=${MY_ROOT_DIR}/

############################################################################
# WRF : Needs to have the env variable NETCDF set.
#export  NETCDF=${NETCDF_INCDIR}/../
#
############################################################################
# Wave Watch 3: Here we provide 5 environment variables for WW3.
#
# 1) COAWST_WW3_DIR is a pointer to root WW3 code, do not change.
export   COAWST_WW3_DIR=${MY_ROOT_DIR}/WW3
#
# 2) WW3_SWITCH_FILE is like cpp options for WW3. You need to create it and
#    provide the full path and file name here.
#export  WW3_SWITCH_FILE=${MY_PROJECT_DIR}/Projects/Inlet_test/WW3/switch_inlet_test
 export  WW3_SWITCH_FILE=${MY_PROJECT_DIR}/Projects/Sandy/WW3/switch_sandy
############################################################################

# Set path of the directory containing makefile configuration (*.mk) files.
# The user has the option to specify a customized version of these files
# in a different directory than the one distributed with the source code,
# ${MY_ROMS_SRC}/Compilers. If this is the case, you need to keep these
# configurations files up-to-date.

 export         COMPILERS=${MY_ROMS_SRC}/Compilers

#--------------------------------------------------------------------------
# Set tunable CPP options.
#--------------------------------------------------------------------------
#
# Sometimes it is desirable to activate one or more CPP options to run
# different variants of the same application without modifying its header
# file. If this is the case, specify each options here using the -D syntax.
# Notice also that you need to use shell's quoting syntax to enclose the
# definition.  Both single or double quotes work. For example,
#
#export      MY_CPP_FLAGS="${MY_CPP_FLAGS} -DAVERAGES"
#export      MY_CPP_FLAGS="${MY_CPP_FLAGS} -DDEBUGGING"
#
# can be used to write time-averaged fields. Notice that you can have as
# many definitions as you want by appending values.

#export      MY_CPP_FLAGS="${MY_CPP_FLAGS} -D"

#--------------------------------------------------------------------------
# Compiler options.
#--------------------------------------------------------------------------
#
# Other user defined environmental variables. See the ROMS makefile for
# details on other options the user might want to set here. Be sure to
# leave the switches meant to be off set to an empty string or commented
# out. Any string value (including off) will evaluate to TRUE in
# conditional if-statements.

 export USE_MPI=on
 export USE_MPIF90=on
# export         which_MPI=intel         # compile with mpiifort library
#export         which_MPI=mpich         # compile with MPICH library
#export         which_MPI=mpich2        # compile with MPICH2 library
#export         which_MPI=mvapich2      # compile with MVAPICH2 library
export         which_MPI=openmpi       # compile with OpenMPI library

#export        USE_OpenMP=on            # shared-memory parallelism

#export FORT=gfortran
export FORT=gfortran
#export FORT=gfortran

 export         USE_DEBUG=              # use Fortran debugging flags
 export         USE_LARGE=on            # activate 64-bit compilation

#--------------------------------------------------------------------------
# Building the ROMS executable using the shared library is not recommended
# because it requires keeping track of the matching libROMS.{so|dylib}
# which is located in the Build_roms or Build_romsG directory and will be
# lost and/or replaced with each new build. The option to build the shared
# version of libROMS was introduced for use in model coupling systems.
#--------------------------------------------------------------------------

#export            SHARED=on            # build libROMS.{so|dylib}
 export            STATIC=on            # build libROMS.a

 export              EXEC=on            # build roms{G|M|O|S} executable

# ROMS I/O choices and combinations. A more complete description of the
# available options can be found in the wiki (https://myroms.org/wiki/IO).
# Most users will want to enable at least USE_NETCDF4 because that will
# instruct the ROMS build system to use nf-config to determine the
# necessary libraries and paths to link into the ROMS executable.

 export       USE_NETCDF4=on            # compile with NetCDF-4 library
#export   USE_PARALLEL_IO=on            # Parallel I/O with NetCDF-4/HDF5
#export           USE_PIO=on            # Parallel I/O with PIO library
#export       USE_SCORPIO=on            # Parallel I/O with SCORPIO library

# If any of the coupling component use the HDF5 Fortran API for primary
# I/O, we need to compile the main driver with the HDF5 library.

#export          USE_HDF5=on            # compile with HDF5 library

#--------------------------------------------------------------------------
# If coupling Earth System Models (ESM), set the location of the ESM
# component libraries and modules. The strategy is to compile and link
# each ESM component separately first, and then ROMS since it is driving
# the coupled system. Only the ESM components activated are considered
# and the rest are ignored.  Some components like WRF cannot be built
# in a directory specified by the user but in its own root directory,
# and cannot be moved when debugging with tools like TotalView.
#--------------------------------------------------------------------------

#export        WRF_SRC_DIR=${HOME}/ocean/repository/WRF
export        WRF_SRC_DIR=${MY_ROOT_DIR}/WRF

if [ -n "${USE_DEBUG:+1}" ]; then
  export     CICE_LIB_DIR=${MY_PROJECT_DIR}/Build_ciceG
  export   COAMPS_LIB_DIR=${MY_PROJECT_DIR}/Build_coampsG
  export    REGCM_LIB_DIR=${MY_PROJECT_DIR}/Build_regcmG
  export      WAM_LIB_DIR=${MY_PROJECT_DIR}/Build_wamG
# export      WRF_LIB_DIR=${MY_PROJECT_DIR}/Build_wrfG
  export      WRF_LIB_DIR=${WRF_SRC_DIR}
else
  export     CICE_LIB_DIR=${MY_PROJECT_DIR}/Build_cice
  export   COAMPS_LIB_DIR=${MY_PROJECT_DIR}/Build_coamps
  export    REGCM_LIB_DIR=${MY_PROJECT_DIR}/Build_regcm
  export      WAM_LIB_DIR=${MY_PROJECT_DIR}/Build_wam
# export      WRF_LIB_DIR=${MY_PROJECT_DIR}/Build_wrf
  export      WRF_LIB_DIR=${WRF_SRC_DIR}
fi

#--------------------------------------------------------------------------
# If applicable, use my specified library paths.
#--------------------------------------------------------------------------

 export USE_MY_LIBS=no            # use system default library paths
#export USE_MY_LIBS=yes           # use my customized library paths

MY_PATHS=${COMPILERS}/my_build_paths.sh

if [ "${USE_MY_LIBS}" == "yes" ]; then
  source ${MY_PATHS} ${MY_PATHS}
fi

############################################################################
# Header and other source directories selections.
#
# The rest of this script sets the path to the users header file and
# analytical source files, if any. See the templates in User/Functionals.
#
# If applicable, use the MY_ANALYTICAL_DIR directory to place your
# customized biology model header file (like fennel.h, nemuro.h, ecosim.h,
# etc).

   export MY_HEADER_DIR=${MY_PROJECT_DIR}/Projects/Inlet_test/Refined
   export MY_ANALYTICAL_DIR=${MY_PROJECT_DIR}/Projects/Inlet_test/Refined

# Put the binary to execute in the following directory.

# export            BINDIR=${MY_PROJECT_DIR}
  export            BINDIR=./

# Put the f90 files in a project specific Build directory to avoid conflict
# with other projects.

if [ -n "${USE_DEBUG:+1}" ]; then
#export       SCRATCH_DIR=${MY_PROJECT_DIR}/Build_romsG
 export       SCRATCH_DIR=./Build_romsG
else
#export       SCRATCH_DIR=${MY_PROJECT_DIR}/Build_roms
 export       SCRATCH_DIR=./Build_roms
fi

# Go to the users source directory to compile. The options set above will
# pick up the application-specific code from the appropriate place.

############################################################################
# End of USER definitions area.  You really should not change anything 
# down here.
#
 cd ${MY_ROMS_SRC}

# Stop if activating both MPI and OpenMP at the same time.

if [ -n "${USE_MPI:+1}" ] && [ -n "${USE_OpenMP:+1}" ]; then
  echo "You cannot activate USE_MPI and USE_OpenMP at the same time!"
  exit 1
fi

#--------------------------------------------------------------------------
# Compile.
#--------------------------------------------------------------------------

# Remove build directory.

if [ $clean -eq 1 ]; then
  make clean
fi

# Compile (the binary will go to BINDIR set above).

export WRF_DIR=${MY_ROMS_SRC}/WRF
export WRFHYDRO_DIR=${MY_ROMS_SRC}/WRF/hydro_v5.0

# first go to make some coupler files
if [ $clean -eq 1 ] && [ $cleanwrf -eq 1 ] && [ $cleanwrfhydro -eq 1 ] && [ $cleanww3 -eq 1 ]  && [ $cleanswan -eq 1 ]; then
  make mct_params
fi
  cd ${SCRATCH_DIR}
  export MCT_PARAMS_DIR=${PWD}
  cd ${MY_ROMS_SRC}

if [ $cleanwrf -eq 1 ]; then
  make wrfclean
  cd ${MY_ROMS_SRC}
fi
  make wrf

if [ $cleanwrfhydro -eq 1 ]; then
  make wrfhydroclean
  cd ${MY_ROMS_SRC}
fi
  make wrfhydro

if [ $cleanww3 -eq 1 ]; then
  make ww3clean
  cd ${MY_ROMS_SRC}
fi
  make ww3

if [ $cleanswan -eq 1 ]; then
  make swanclean
  cd ${MY_ROMS_SRC}
fi
  make swan

if [ $dprint -eq 1 ]; then
  make $debug
else
  if [ $parallel -eq 1 ]; then
    make $NCPUS
  else
    make
  fi
fi