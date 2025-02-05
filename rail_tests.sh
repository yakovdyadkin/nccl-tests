#!/bin/bash

TIMEOUT=3600 # Run command for 1hr
KILL_TIMEOUT=5 # How much time to wait before sending kills signal if procs run after timeout

# Start n-rail nccl-tests all_gather_perf runs
for n in $(seq 1 8)
do
    echo "##### Number of rails: $n #####"
    nn=$(( n - 1))

    test_mask="0x$n"

    #timeout --kill-after $KILL_TIMEOUT $TIMEOUT ./run_rails_correct-topo.sh ~/tor_hosts.txt 2 $n $test_mask 2>&1 | tee ~/yakov/nccl_logs/rails/allgather_${n}rails_$(date +%Y%m%d%H%M%S).txt

    # use mpirun option --timeout 3600 to specify the timeout
    ./run_rails_correct-topo.sh ~/tor_hosts.txt 2 $n $test_mask 2>&1 | tee ~/yakov/nccl_logs/rails/allgather_${n}rails_$(date +%Y%m%d%H%M%S).txt
    # Wait for all MPI procs to die out
    sleep 30
done
