from src.hand_tracker import HandTracker
import urllib
import numpy as np
import tensorflow as tf
from tensorflow import keras
import cv2

#Gesture Model
model = keras.models.load_model('./models/gesture_model.h5')

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

gesture = ["Five_far","Five_near", "Five_back", "Fist", "Three", "Two","Background"]
selection = 0
while True:
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
    if(len(coordinatesList) != 0):
        predict_dataset = tf.convert_to_tensor([coordinatesList])
        prediction_ = model(predict_dataset)
        prediction = np.argmax(prediction_.numpy())
        print(gesture[prediction])
    key = cv2.waitKey(1)
    if key == 27:
        break
