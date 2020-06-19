import time
import threading
import cv2
from src.hand_tracker import HandTracker
import urllib
import numpy as np
import msvcrt, time, csv

WINDOW = "Hand Tracking"
PALM_MODEL_PATH = "models/palm_detection_without_custom_op.tflite"
LANDMARK_MODEL_PATH = "models/hand_landmark.tflite"
ANCHORS_PATH = "models/anchors.csv"

POINT_COLOR = (0, 255, 0)
CONNECTION_COLOR = (255, 0, 0)
THICKNESS = 2

cv2.namedWindow(WINDOW)
url = 'http://192.168.0.8:8080/shot.jpg'

connections = [
    (0, 1), (1, 2), (2, 3), (3, 4),
    (5, 6), (6, 7), (7, 8),
    (9, 10), (10, 11), (11, 12),
    (13, 14), (14, 15), (15, 16),
    (17, 18), (18, 19), (19, 20),
    (0, 5), (5, 9), (9, 13), (13, 17), (0, 17)
]

detector = HandTracker(
    PALM_MODEL_PATH,
    LANDMARK_MODEL_PATH,
    ANCHORS_PATH,
    box_shift=0.2,
    box_enlarge=1.3
)

gesture = ["Five_far","Five_near", "Five_back", "Fist", "Three", "Two"]
selection = 0
count = 0
while True:
    count+=1
    print(count)
    if msvcrt.kbhit():
        ch= msvcrt.getwche()
        if(ch == '1'):
            selection = 0
        elif(ch  == '2'):
            selection = 1
        elif(ch == '3'):
            selection = 2
        elif(ch  == '4'):
            selection = 3
        elif(ch  == '5'):
            selection = 4
        elif(ch  == '6'):
            selection = 5  
        elif(ch  == '7'):
            selection = 6

        if(len(coordinatesList) != 0):
            coordinatesList.append(str(selection))
            f = open('./data/train.csv', 'a', newline='')
            wr = csv.writer(f)
            wr.writerow(coordinatesList)
            f.close()

    imgResp = urllib.request.urlopen(url)
    imgNp = np.array(bytearray(imgResp.read()), dtype = np.uint8)
    img = cv2.imdecode(imgNp, -1)
    # image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    coordinatesList = []
    points, _ = detector(img)
    if points is not None:
        for point in points:
            x, y = point
            coordinatesList.append(x)
            coordinatesList.append(y)
            cv2.circle(img, (int(x), int(y)), THICKNESS * 2, POINT_COLOR, THICKNESS)
        for connection in connections:
            x0, y0 = points[connection[0]]
            x1, y1 = points[connection[1]]
            cv2.line(img, (int(x0), int(y0)), (int(x1), int(y1)), CONNECTION_COLOR, THICKNESS)
    cv2.imshow(WINDOW, img)
    key = cv2.waitKey(1)
    if key == 27:
        break