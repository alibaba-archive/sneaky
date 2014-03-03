#!/bin/bash
BASEDIR="`dirname $0`/.."
cd $BASEDIR

EXEC=./bin/sneaky
CONFIG=./example/.sneakyrc

$EXEC -c $CONFIG d
