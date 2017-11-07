#!/bin/bash

sudo -v
RESULT=$?

if [[ ${RESULT} -gt 0 ]]; then
    echo Installing drifter requires admin rights.  Please try again.
    exit 1;
fi;

sudo cp drifter.sh /usr/local/bin/drifter
sudo chmod +x /usr/local/bin/drifter

sudo cp drifter.1 /usr/local/share/man/man1

if [[ ! -d "/usr/local/bin/driftermacros" ]]; then
    sudo mkdir /usr/local/bin/driftermacros;
fi;

if [[ -d "./driftermacros" ]]; then
    sudo cp driftermacros/* /usr/local/bin/driftermacros;
    sudo chmod +x /usr/local/bin/driftermacros/*;
fi;

sudo -k
