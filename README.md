# digital_collections_image_tools

v. 0.0.1

Libraries, museums and other organizations do digitization projects to make visual material available on the web. This repository is a placeholder for scripts to process and manage the images for those projects. 

The first script here uses computer vision to automatically crop color bars and rulers from high resolution scans. 

## Quickstart

```
docker build -t crop https://github.com/johnjung/digital_collections_image_tools.git
docker run --rm -it -p 5000:5000 crop start
curl -X POST -F 'image=@test_image.jpg' -F 'red=120' -F 'green=120' -F 'blue=120' -F 'grayvariation=20' http://0.0.0.0:5000/crop
```

## POST parameters

### image
An image containing a ruler along one edge. (See test_image.jpg for a sample
that has been reduced in size.)

### red
In an rgb pixel describing the ruler's color, the red channel amount from
0-255.

### green
In an rgb pixel describing the ruler's color, the green channel amount from
0-255.

### blue
In an rgb pixel describing the ruler's color, the blue channel amount from
0-255.

### grayvariation
Fuzziness for color matching. If rgb values are 120 and grayvariation is set to
20, the script will search for objects between 100/100/100 and 140/140/140. 

## Contributing

Please contact the author with pull requests, bug reports, and feature
requests.

## Author

John Jung
