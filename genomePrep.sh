#!/bin/sh

if [ "$1" = "--help" ] || [  -z $1  ] || [  "$1" = "-h"  ] || [ "$1" = "help" ]; then
    echo ""
    echo "--------------------------------------------------------------------------------------"
    echo "  To run this script, use the following syntax:"
    echo "     bash" $0 "<path to .fa folder>"
    echo "--------------------------------------------------------------------------------------"
    echo ""
    echo ""
    echo ""
    exit 1

else

source ~/.bash_profile

bismark_genome_preparation $1 

fi


