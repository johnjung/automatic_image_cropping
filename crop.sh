#!/bin/bash

tmp_dir="/tmp"

cat << "EOF"

.----. .----. .----. .----.  
| {}  }| {}  }| {_  { {__    
| .--' | .-. \| {__ .-._} }  
`-'    `-' `-'`----'`----'   
 .---. .----.  .----. .----. 
/  ___}| {}  }/  {}  \| {}  }
\     }| .-. \\      /| .--' 
 `---' `-' `-' `----' `-'    

Welcome to the preservation cropping script.

EOF

read -p "Enter input directory, e.g. /Volumes/pres/EWM/ewm-0054/Masters: " input_directory
if [ ! -d "${input_directory}" ]; then
  echo "That directory does not exist."
  exit
fi

read -p "Enter output directory, e.g. /Volumes/pres/EWM/ewm-0054/Tiff Crop: " output_directory
if [ ! -d "${output_directory}" ]; then
  echo "That directory does not exist."
  exit
fi

read -p "Enter red channel amount (0-255, e.g. 120): " red
read -p "Enter green channel amount (0-255, e.g. 120): " green
read -p "Enter blue channel amount (0-255, e.g. 120): " blue
read -p "Enter gray variation amount (0-255, e.g. 20): " grayvariation

input_images=("${input_directory}"/*.tif)
for input_image in "${input_images[@]}"; do
  filename=`basename "${input_image}"`
  echo "${filename}"

  # be sure an output file with that name doesn't already exist. 
  if [ ! -f "${output_directory}/${filename}" ]; then
    # convert the file to jpeg to make processing easier on the server-side.
    convert "${input_image}[0]" "${tmp_dir}/${filename}.jpg"
  
    # request cropping data. 
    json=`curl -s -X POST -F image="@${tmp_dir}/${filename}.jpg" -F red="${red}" -F green="${green}" -F blue="${blue}" -F grayvariation="${grayvariation}" http://0.0.0.0:5000/crop`

    # remove tempfile. 
    rm "${tmp_dir}/${input_image}.jpg"
  
    if [[ "${json}" == *"success"* ]]; then
      # extract coordinates
      x1=`echo $json | grep -o 'x1..\s*[0-9]*' | cut -d: -f2 | sed -e 's/[^0-9]//'`
      x2=`echo $json | grep -o 'x2..\s*[0-9]*' | cut -d: -f2 | sed -e 's/[^0-9]//'`
      y1=`echo $json | grep -o 'y1..\s*[0-9]*' | cut -d: -f2 | sed -e 's/[^0-9]//'`
      y2=`echo $json | grep -o 'y2..\s*[0-9]*' | cut -d: -f2 | sed -e 's/[^0-9]//'`

      # get the width and height for ImageMagick. 
      width=`expr "${x2}" - "${x1}"`
      height=`expr "${y2}" - "${y1}"`
  
      # crop the image.
      convert "${input_image}"[0] -crop "${width}x${height}+${x1}+${y1}" -density 600 "${output_directory}/${filename}"
    else
      echo "${json}"
    fi
  fi
done
