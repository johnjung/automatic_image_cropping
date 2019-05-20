#!/bin/bash

# usage:
# sh test.sh <red> <green> <blue> <variance> <inputfile> <outputfile>
#
# example:
# sh test.sh 120 120 120 20 input.jpg output.jpg

# request cropping data. 
json=`curl -s -X POST -F image="@${5}" -F red="$1" -F green="$2" -F blue="$3" -F grayvariation="$4" http://0.0.0.0:5000/crop`

if [[ "${json}" == *"success"* ]]; then
  # extract coordinates
  x1=`echo $json | grep -o 'x1..\s*[0-9]*' | cut -d: -f2 | sed -e 's/[^0-9]//'`
  x2=`echo $json | grep -o 'x2..\s*[0-9]*' | cut -d: -f2 | sed -e 's/[^0-9]//'`
  y1=`echo $json | grep -o 'y1..\s*[0-9]*' | cut -d: -f2 | sed -e 's/[^0-9]//'`
  y2=`echo $json | grep -o 'y2..\s*[0-9]*' | cut -d: -f2 | sed -e 's/[^0-9]//'`

  # draw a box around the ruler for troubleshooting.
  convert "$5" -stroke pink -fill none -draw "rectangle $x1,$y1 $x2,$y2" -density 600 "$6"
fi
