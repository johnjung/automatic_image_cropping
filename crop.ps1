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

$input_directory = Read-Host -Prompt "Enter input directory, e.g. /Volumes/pres/EWM/ewm-0054/Masters"
if (!(Test-Path -Path $input_directory)) {
  "That directory does not exist."
  exit
}

$output_directory = Read-Host -Prompt "Enter output directory, e.g. /Volumes/pres/EWM/ewm-0054/Tiff Crop"
if (!(Test-Path -Path $output_directory)) {
  "That directory does not exist."
  exit
}

$red = Read-Host -Prompt "Enter red channel amount (0-255, e.g. 120)"
$green = Read-Host -Prompt "Enter green channel amount (0-255, e.g. 120)"
$blue = Read-Host -Prompt "Enter blue channel amount (0-255, e.g. 120)"
$grayvariation = Read-Host -Prompt "Enter gray variation amount (0-255, e.g. 20)"

Get-ChildItem $input_directory -Filter *.tif | Foreach-Object {
  # be sure an output file with that name doesn't already exist. 
  $output_filename = "{0}/{1}" -f $output_directory, $_.Name

  If (Test-Path $output_filename -PathType Leaf) {
    $output_filename

    $tmp_imagepath = "{0}/{1}.jpg" -f $output_directory, $_.Name

    # convert the file to jpeg to make processing easier on the server-side.
    & convert "${input_image}[0]" "${tmp_imagepath}"
  
    # request cropping data. 
    $postParams = @{red=$red;green=$green;blue=$blue;grayvariation=$grayvariation}
    $json = Invoke-RestMethod -Uri http://0.0.0.0/crop -Method POST -Body $postParams -InFile $tmp_imagepath -ContentType "multipart/form-data" | ConvertFrom-Json

    # remove tempfile. 
    Remove-Item -path $tmp_imagepath
  
    If ($json[0].Name == 'success') {
      # extract coordinates
      $x1=$json[0]['x1']
      $x2=$json[0]['x2']
      $y1=$json[0]['y1']
      $y2=$json[0]['y2']

      # get the width and height for ImageMagick. 
      $width=`expr "${x2}" - "${x1}"`
      $height=`expr "${y2}" - "${y1}"`
  
      # crop the image.
      convert "${input_image}"[0] -crop "${width}x${height}+${x1}+${y1}" -density 600 "${output_directory}/${filename}"
    } Else {
      $json
    }
  }
}
