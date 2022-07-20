#!/bin/bash
# SPDX-FileCopyrightText: 2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT

# Default version 2020.1
XILVER=${1:-2020.1}

# Check if the petalinux installer exists
PLNX="petalinux-v${XILVER}-final-installer.run"
if [ ! -f "$PLNX" ] ; then
#    wget https://xilinx-ax-dl.entitlenow.com/dl/ul/2020/06/01/R210329522/petalinux-v2020.1-final-installer.run?hash=ZDls6EIe6wJXMoOQpS9p4w&expires=1657373842&filename=petalinux-v2020.1-final-installer.run
    echo "$PLNX installer not found"
    exit 1
fi

INSTALL_VIVADO=""
VIVADO_INSTALLER=$(ls | grep Xilinx_Unified_${XILVER}* | tail -1)
if [ ${VIVADO_INSTALLER} ] ; then
    echo "Vivado installer found: ${VIVADO_INSTALLER}"
    echo "It will be installed in the Docker image"
    INSTALL_VIVADO="--build-arg VIVADO_INSTALLER=${VIVADO_INSTALLER}"
#else
 #   wget https://xilinx-ax-dl.entitlenow.com/dl/ul/2020/06/03/R210329635/Xilinx_Unified_2020.1_0602_1208.tar.gz?hash=wxDo2pA5nScil_Sviz0-jw&expires=1657369003&filename=Xilinx_Unified_2020.1_0602_1208.tar.gz
#    echo "Vivado installer found: ${VIVADO_INSTALLER}"
#    echo "It will be installed in the Docker image"
#    INSTALL_VIVADO="--build-arg VIVADO_INSTALLER=${VIVADO_INSTALLER}"
fi

export DOCKER_BUILDKIT=1

echo "Creating Docker image docker_petalinux2:$XILVER..."
time docker build --build-arg PETA_VERSION=${XILVER} --build-arg PETA_RUN_FILE=${PLNX} ${INSTALL_VIVADO} -t docker_petalinux2:${XILVER} .
