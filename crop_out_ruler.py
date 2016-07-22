import cv2
import numpy
import sys

testing = False

ruler_color = [120, 120, 120]
morph_open_kernel = numpy.ones((5, 5), numpy.uint8)
morph_close_kernel = numpy.ones((20, 20), numpy.uint8)
border_width = 100
nudge_crop_in = 10
test_color = (255, 0, 0)
test_width = 20

if len(sys.argv) < 3:
    print(sys.argv[0])
    print("A program to automatically detect rulers in digitized page images and crop them out.")
    sys.exit()

# load image.
img = cv2.imread(sys.argv[1])

# the color bar is gray- so select the gray things only.
lower_limit_for_gray = numpy.array([ruler_color[0] - 10, ruler_color[1] - 10, ruler_color[2] - 10], dtype = "uint8")
upper_limit_for_gray = numpy.array([ruler_color[0] + 10, ruler_color[1] + 10, ruler_color[2] + 10], dtype = "uint8")
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
im2, contours, hierarchy = cv2.findContours(threshold.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

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
        cv2.imwrite(sys.argv[2], img)
    else:
        # crop the ruler out of the left or right side of the image.
        if x < width / 2:
            cv2.imwrite(sys.argv[2], img[0:height, x + nudge_crop_in:width])
        else:
            cv2.imwrite(sys.argv[2], img[0:height, 0:x - nudge_crop_in])

