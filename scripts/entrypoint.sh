#!/bin/bash

# Network latency simulation (run as root first)
if [ "$LATENCY_MS" != "0" ] && [ -n "$LATENCY_MS" ]; then
  echo "Setting up network latency simulation: ${LATENCY_MS}ms"
  echo "Executing: tc qdisc add dev eth0 root netem delay ${LATENCY_MS}ms (as root)"
  tc qdisc add dev eth0 root netem delay ${LATENCY_MS}ms || echo 'tc command failed - continuing without latency simulation'
fi

# Now switch to postgres user and run the original command
exec gosu postgres "$@"