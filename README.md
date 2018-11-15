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
docker build -t crop https://github.com/johnjung/opencv_cropping.git
docker run --rm -it -p 5000:5000 crop start
curl -X POST -F 'image=@test_image.jpg' -F 'red=120' -F 'green=120' -F 'blue=120' -F 'grayvariation=20' http://0.0.0.0:5000/crop
```

## Contributing

Please contact the author with pull requests, bug reports, and feature
requests.

## Author

John Jung
