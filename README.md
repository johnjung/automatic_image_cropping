# opencv_cropping

v. 0.0.1

The Preservation department at the University of Chicago Library produces high
resolution images of pages from manuscripts and other items from the Library
Archives. Many of these images are captured with a ruler and color bar along
one edge. 

This script automatically detects and removes that ruler using the computer
vision library OpenCV.

## Quickstart

```
docker build -t opencv_cropping https://github.com/johnjung/opencv_cropping.git
docker run -it -v /local_input_directory:/mnt/in -v /local_output_directory:/mnt/out opencv_cropping python crop_out_ruler.py
```

## Contributing

Please contact the author with pull requests, bug reports, and feature
requests.

## Author

John Jung
