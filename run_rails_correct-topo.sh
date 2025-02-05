#!/bin/bash

if [ $# -ne 4 ]
then
    echo "Usage: $0 <hostfile> <num nodes> <num GPU per node> <NCCL_TESTS_SPLIT_MASK>"
    exit 1
fi

module load mpi/hpcx

HOSTFILE=$1
NUM_NODES=$2
GPU_PER_NODE=$3
MASK=$4

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)

CUDA_VISIBLE_DEVICES=""
NCCL_IB_HCA=""

# Create GPU and IB device lists
for i in $(seq 0 $(( GPU_PER_NODE - 1 )))
do
    CUDA_VISIBLE_DEVICES+="$i,"
    NCCL_IB_HCA+="mlx5_ib$i,"
done

# Strip trailing comma
CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES%,}"
NCCL_IB_HCA="${NCCL_IB_HCA%,}"

mpi_cmd="mpirun \
--timeout 3600 \
-np $(( NUM_NODES * GPU_PER_NODE )) \
-hostfile $HOSTFILE \
-bind-to none \
--map-by ppr:$GPU_PER_NODE:node -x LD_LIBRARY_PATH \
-mca coll_hcoll_enable 0 \
-x UCX_TLS=tcp \
-x UCX_NET_DEVICES=eth0 \
-x CUDA_DEVICE_ORDER=PCI_BUS_ID \
-x NCCL_SOCKET_IFNAME=eth0 \
-x NCCL_DEBUG=warn \
-x NCCL_TOPO_FILE=/home/azhpcuser/correct-topo.xml \
-x NCCL_TESTS_SPLIT_MASK=$MASK \
-x NCCL_IB_HCA=$NCCL_IB_HCA \
-x CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES \
-x NCCL_IGNORE_CPU_AFFINITY=1 \
${SCRIPT_DIR}/build/all_gather_perf -N0 -n1 -b4G -e4G -f2 -g1"

# Run
echo "# $mpi_cmd"
eval $mpi_cmd
