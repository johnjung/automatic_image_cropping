"""Usage:
   crop_out_ruler.py [--red=<integer>] [--green=<integer>] [--blue=<integer>] [--grayvariation=<integer>]

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

from docopt import docopt
import cv2
import numpy
import os
import sys

def crop_out_ruler(inputfile, outputfile, ruler_color, grayvariation):
    morph_open_kernel = numpy.ones((5, 5), numpy.uint8)
    morph_close_kernel = numpy.ones((20, 20), numpy.uint8)
    border_width = 100
    nudge_crop_in = 10
    test_color = (255, 0, 0)
    test_width = 20
    
    # load image.
    img = cv2.imread(inputfile)
    if not img.any():
        raise ValueError
    
    # the color bar is gray- so select the gray things only.
    lower_limit_for_gray = numpy.array([ruler_color[0] - grayvariation, ruler_color[1] - grayvariation, ruler_color[2] - grayvariation], dtype = numpy.uint8)
    upper_limit_for_gray = numpy.array([ruler_color[0] + grayvariation, ruler_color[1] + grayvariation, ruler_color[2] + grayvariation], dtype = numpy.uint8)
    gray_only = cv2.inRange(img, lower_limit_for_gray, upper_limit_for_gray)
    
    # remove noise: despeckle.
    gray_only = cv2.morphologyEx(gray_only, cv2.MORPH_OPEN, morph_open_kernel)
    
    # remove noise: fill in gaps. 
    gray_only = cv2.morphologyEx(gray_only, cv2.MORPH_CLOSE, morph_close_kernel)
    
    # add a border.
    gray_only = cv2.copyMakeBorder(gray_only, border_width, border_width, border_width, border_width, cv2.BORDER_CONSTANT, value=[0, 0, 0])
    
    # get a bitonal image. 
    ret, threshold = cv2.threshold(gray_only, 127, 255, cv2.THRESH_BINARY)
    
    # get countours.
    _, contours, hierarchy = cv2.findContours(threshold.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    
    ruler = None
    
    # find the biggest contour with four sides- assume it's the ruler. 
    contours = sorted(contours, key = cv2.contourArea, reverse = True)[:10]
    for c in contours:
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        if len(approx) == 4:
            # remember to take off the 100 pixel boundary we added above. 
            ruler = numpy.array(list(map(lambda c: [[c[0][0] - border_width, c[0][1] - border_width]], approx)))
            break
    
    # if we found a ruler...
    if ruler is not None:
        # draw a box around it. 
        if testing:
            cv2.drawContours(img, [ruler], -1, test_color, test_width)
    
        # get the x coordinates of all points in the ruler. 
        # sort them so that the one that is closest to the center of the image is first.
        height, width, channels = img.shape
        points_x_coordinates = list(map(lambda c: c[0][0], ruler.tolist()))
        points_x_coordinates = list(sorted(points_x_coordinates, key=lambda x: abs(width - x)))
    
        # get the lowest or highest coordinate depending on which side of the page the ruler is on.
        if points_x_coordinates[0] > width / 2:
            x = points_x_coordinates[-1]
        else:
            x = points_x_coordinates[0]
    
        # draw a line there. 
        if testing:
            cv2.line(img, (x, 0), (x, height), test_color, test_width)
    
        # output an image with test lines only, or output a cropped image. 
        if testing:
            cv2.imwrite(outputfile, img)
        else:
            # crop the ruler out of the left or right side of the image.
            if x < width / 2:
                cv2.imwrite(outputfile, img[0:height, x + nudge_crop_in:width])
            else:
                cv2.imwrite(outputfile, img[0:height, 0:x - nudge_crop_in])
    

if __name__ == '__main__':
    args = docopt(__doc__)

    testing = False

    if not (os.path.isdir('/mnt/in') and os.path.isdir('/mnt/out')):
        print('This script requires files in two directories: /mnt/in should')
        print('contain original files. The script will place cropped versions')
        print('of those files in /mnt/out. If you\'re running this script inside')
        print('a docker container, you should create bind mounts from your')
        print('local filesystem to the docker container with the -v option of')
        print('docker run.')
        input('Press Enter to continue.')
        sys.exit()

    defaults = {
        '--red': 120,
        '--green': 120,
        '--blue': 120,
        '--grayvariation': 10
    }

    print('For every image in a directory, this script crops a ruler out of')
    print('each image and saves an image in an output directory. Specify the')
    print('color of the ruler by entering an amount for the red, green and blue')
    print('channels. Then, specify an amount of variance. E.g. specifying the')
    print('defaults, red=120, green=120, and blue=120, with a variance of 10,')
    print('will detect and crop out rulers whose color is anywhere between')
    print('110,110,110 and 130,130,130.')
    print('')

    input_descriptions = {
        '--red': 'Enter the red channel amount, from 0 - 255. Default {}: '.format(defaults['--red']),
        '--green': 'Enter the green channel amount, from 0 - 255. Default {}: '.format(defaults['--green']),
        '--blue': 'Enter the blue channel amount, from 0 - 255. Default {}: '.format(defaults['--blue']),
        '--grayvariation': 'Enter the acceptable amount of variation, from 0-255. Default {}: '.format(defaults['--grayvariation'])
    }

    for a in ('--red', '--green', '--blue', '--grayvariation'):
        if args[a] == None:
            try:
                args[a] = int(input(input_descriptions[a]))
            except ValueError:
                args[a] = defaults[a]
        else:
            args[a] = int(args[a])

    for f in os.listdir('/mnt/in'):
        if os.path.isfile('/mnt/out/{}'.format(os.path.basename(f))):
            print('Skipping {} (file exists in output directory)'.format(f))
        else:
            try:
                crop_out_ruler(
                    '/mnt/in/{}'.format(f),
                    '/mnt/out/{}'.format(f),
                    [args['--red'], args['--green'], args['--blue']],
                    args['--grayvariation']
                )
            except (AttributeError, ValueError):
                print('Problem trying to crop {}'.format(f))
                continue
            print('Cropped {}'.format(f))
