#!/bin/bash

DATETIME=$(date +"%d/%m/%Y %H:%M:%S")
echo "Start at ${DATETIME}"

yum update -yum
yum install -y jq git curl wget telnet perl-Digest-SHA

DATETIME=$(date +"%d/%m/%Y %H:%M:%S")
echo "Finish at ${DATETIME}"