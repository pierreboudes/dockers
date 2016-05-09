#!/bin/sh
timeout=${1:-20} # default to 20 seconds
service postgresql start
sleep ${timeout}
service scodoc start
/bin/bash
