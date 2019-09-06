# Set-Variable -Name "tmp_dir" -Value C:/Windows/Temp

Write-Host @"

.----. .----. .----. .----.  
| {}  }| {}  }| {_  { {__    
| .--' | .-. \| {__ .-._} }  
`-'    `-' `-'`----'`----'   
 .---. .----.  .----. .----. 
/  ___}| {}  }/  {}  \| {}  }
\     }| .-. \\      /| .--' 
 `---' `-' `-' `----' `-'    

Welcome to the preservation cropping script.

"@


$input = Read-Host -Prompt "Enter 'Y' for input directory, 'N' for input file"

If ($input -eq 'Y') {
  $input_directory = Read-Host -Prompt "Enter input directory, e.g. /Volumes/pres/EWM/ewm-0054/Masters"
  if (!(Test-Path -Path $input_directory)) {
    "That directory does not exist."
    exit
  }
} Elseif ($input -eq 'N') {
    $filePath = Read-Host -Prompt "Enter file name: "
    if (!($filePath -like '*.tif*')) {
      "Incorrect file format."
      exit
    } 
    $filename = $filePath.split("/")
    $filename = $filename[-1]
} Else {
    "Invalid input."
    exit
}

$output_directory = Read-Host -Prompt "Enter output directory, e.g. /Volumes/pres/EWM/ewm-0054/Tiff Crop"
If (!(Test-Path -Path $output_directory)) {
  "That directory does not exist."
  exit
}

$red = Read-Host -Prompt "Enter red channel amount (0-255, e.g. 120)"
$green = Read-Host -Prompt "Enter green channel amount (0-255, e.g. 120)"
$blue = Read-Host -Prompt "Enter blue channel amount (0-255, e.g. 120)"
$grayvariation = Read-Host -Prompt "Enter gray variation amount (0-255, e.g. 20)"

if ($input -eq 'Y') {
  Get-ChildItem $input_directory -Filter *.tif | Foreach-Object {
    # be sure an output file with that name doesn't already exist. 
    $output_filename = "{0}/{1}" -f $output_directory, $_.Name
  
    If (-Not (Test-Path $output_filename -PathType Leaf)) {
  
      $crop_name = $_.Name.Substring(0,$_.Name.Length - 4)
  
      $tmp_imagepath = "{0}/{1}.jpg" -f $output_directory, $crop_name
  
      $input_file = $input_directory + "/" + $_.Name
  
      # convert the file to jpeg to make processing easier on the server-side.
      & magick convert $input_file ${tmp_imagepath}

      # cropping script for ewm files
      If ($_.Name -like '*ewm') {
      # request cropping data. 
      $postParams = @{red=$red;green=$green;blue=$blue;grayvariation=$grayvariation;file=$tmp_imagepath}
      #$json = Invoke-RestMethod -Uri http://0.0.0.0/crop -Method POST -Body $postParams -ContentType "multipart/form-data" | ConvertFrom-Json
      $json = Invoke-WebRequest -Uri http://0.0.0.0/crop_ewm -Method POST -Body $postParams -ContentType "multipart/form-data" | ConvertFrom-Json
      #-InFile $tmp_imagepath
  
      # remove tempfile. 
      Remove-Item -path $tmp_imagepath
    
      #json.Name == 'success'
      If ($json.StatusCode -eq 200) {
        # extract coordinates
        $x1=$json['x1'] # used to be $json[0]['x1] -- kept getting error for null arrays
        $x2=$json['x2']
        $y1=$json['y1'] 
        $y2=$json['y2']
  
        # get the width and height for ImageMagick. 
        $width=`expr "${x2}" - "${x1}"`
        $height=`expr "${y2}" - "${y1}"`
    
        # crop the image.
        & magick convert "${input_file}"[0] -crop "${width}x${height}+${x1}+${y1}" -density 600 "${output_filename}"
      } Else {
        $json
      }
      # cropping script for speculum files
    } Else {
      $postParams = @{file=$tmp_imagepath}
      $json = Invoke-WebRequest -Uri http://0.0.0.0/crop_spec -Method POST -Body $postParams -ContentType "multipart/form-data" | ConvertFrom-Json

      Remove-Item -path $tmp_imagepath

      If ($json.StatusCode -eq 200) {
        # extract coordinates
        $ruler_x1 = $json['ruler_x1']
        $ruler_x2 = $json['ruler_x2']
        $ruler_y1 = $json['ruler_y1']
        $ruler_y2 = $json['ruler_y2']

        $color_x1 = $json['color_x1']
        $color_x2 = $json['color_x2']
        $color_y1 = $json['color_y1']
        $color_y2 = $json['color_y2']

        # crop ruler first
        $width = `expr "${ruler_x2}" - "${ruler_x1}"`
        $height = `expr "${ruler_y2}" - "${ruler_y1}"`

        & magick convert "${input_file}"[0] -crop  "${width}x${height}+${ruler_x1}+${ruler_y1}" -density 600 "${output_filename}"

        #crop color bar
        $width = `expr "${color_x2}" - "${color_x1}"`
        $height = `expr "${color_y2}" - "${color_y1}"`

        & magick convert "${input_file}"[0] - crop "${width}x${height}+${color_x1}+${color_y1}" -density 600 "${output_filename}"
      }
      Else {
        $json
      }
    }
    }
  }
} else {
    $output_filename = "{0}/{1}" -f $output_directory, $filename

    If (-Not (Test-Path $output_filename -PathType Leaf)) {

      $crop_name = $filename.Substring(0,$filename.Length - 4)

      # jpeg conversion makes processing easier on server side
      $tmp_imagepath = "{0}/{1}.jpg" -f $output_directory, $crop_name

      & magick convert $filePath ${tmp_imagepath}

      # cropping script for ewm files
      If ($filename -like '*ewm*') {
        $postParams = @{red=$red;green=$green;blue=$blue;grayvariation=$grayvariation;file=$tmp_imagepath}
        $json = Invoke-WebRequest -Uri http://0.0.0.0/crop_ewm -Method POST -Body $postParams -ContentType "multipart/form-data" | ConvertFrom-Json

        Remove-Item -path $tmp_imagepath

        If ($json.StatusCode -eq 200) {
          $x1=$json[0]['x1']
          $x2=$json[0]['x2']
          $y1=$json[0]['y1'] 
          $y2=$json[0]['y2']
  
          $width=`expr "${x2}" - "${x1}"`
          $height=`expr "${y2}" - "${y1}"`

          & magick convert "${filename}"[0] -crop "${width}x${height}+${x1}+${y1}" -density 600 "${output_filename}"
        } Else {
          $json
      }
      # cropping script for speculum files
      } Else {
          $postParams = @{file=$tmp_imagepath}
          $json = Invoke-WebRequest -Uri http://0.0.0.0/crop_spec -Method POST -Body $postParams -ContentType "multipart/form-data" | ConvertFrom-Json

          Remove-Item -path $tmp_imagepath

          If ($json.StatusCode -eq 200) {
            # extract coordinates
            $ruler_x1 = $json['ruler_x1']
            $ruler_x2 = $json['ruler_x2']
            $ruler_y1 = $json['ruler_y1']
            $ruler_y2 = $json['ruler_y2']

            $color_x1 = $json['color_x1']
            $color_x2 = $json['color_x2']
            $color_y1 = $json['color_y1']
            $color_y2 = $json['color_y2']

            # crop ruler first
            $width = `expr "${ruler_x2}" - "${ruler_x1}"`
            $height = `expr "${ruler_y2}" - "${ruler_y1}"`

            & magick convert "${filename}"[0] -crop  "${width}x${height}+${ruler_x1}+${ruler_y1}" -density 600 "${output_filename}"

            #crop color bar
            $width = `expr "${color_x2}" - "${color_x1}"`
            $height = `expr "${color_y2}" - "${color_y1}"`

            & magick convert "${filename}"[0] - crop "${width}x${height}+${color_x1}+${color_y1}" -density 600 "${output_filename}"
          }
          Else {
            $json
          }
      }
    }
}

