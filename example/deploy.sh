#!/bin/bash
BASEDIR="`dirname $0`/.."
cd $BASEDIR

EXEC=./bin/sneaky
CONFIG=./example/.sneakyrc.json

$EXEC -c $CONFIG d
