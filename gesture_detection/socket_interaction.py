
from src.hand_tracker import HandTracker
import urllib
import numpy as np
import tensorflow as tf
from tensorflow import keras
import cv2
import socket

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
Host = "192.168.0.9"
port = 9008
print (Host)
print (port)
serversocket.bind((Host, port))

serversocket.listen(5)
print ('server started and listening')
while 1:
    (clientsocket, address) = serversocket.accept()
    print ("connection found!")
    break;

#Gesture Model
model = keras.models.load_model('./models/gesture_model.h5')

WINDOW = "Hand Tracking"
PALM_MODEL_PATH = "models/palm_detection_without_custom_op.tflite"
LANDMARK_MODEL_PATH = "models/hand_landmark.tflite"
ANCHORS_PATH = "models/anchors.csv"

POINT_COLOR = (0, 255, 0)
CONNECTION_COLOR = (255, 0, 0)
THICKNESS = 2

COOLTIME = 5

cv2.namedWindow(WINDOW)
url = 'http://192.168.0.16:8080/shot.jpg'

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

history = ['Background','Background','Background', 'Background']
coolTime = [0, 0, 0, 0, 0, 0, 0]
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
#       print(gesture[prediction])
        history[3] = history[2]
        history[2] = history[1]
        history[1] = history[0]
        history[0] = gesture[prediction]

	#coolTime down
        for i in range(len(coolTime)):
            if(coolTime[i] != 0):
                coolTime[i]-=1

        #gesture recog
        if(history[2] == "Five_far" and history[0] == "Five_near" and coolTime[0] == 0): 
            msg = "zoom in"
            print(msg)
            coolTime[0]= COOLTIME
            clientsocket.send(msg.encode())
        elif(history[0] == "Five_far" and history[2] == "Five_near"and coolTime[1] == 0):
            msg = "zoom out"
            coolTime[1]= COOLTIME
            print(msg)
            clientsocket.send(msg.encode())
        elif(history[0] == "Fist" and (history[2] == "Five_near" or history[2] == "Five_far")and coolTime[2] == 0):
            msg = "capture"
            coolTime[2]= COOLTIME
            print(msg)
            clientsocket.send(msg.encode())
        elif(history[0] == "Fist" and history[2] == "Two" and coolTime[3] == 0):
            msg = "resume"
            coolTime[3]= COOLTIME
            print(msg)
            clientsocket.send(msg.encode())
        elif(history[0] == "Three" and history[1] == "Three" and history[2] == "Three" and history[3] == "Three" and coolTime[4] == 0):
            msg = "timer 3s"
            coolTime[4]= COOLTIME
            print(msg)
            clientsocket.send(msg.encode())
        elif(history[0] == "Five_back" and history[1] == "Five_back" and history[2] == "Five_back" and history[3] == "Five_back"and coolTime[5] == 0):
            msg = "timer 5s"
            coolTime[5]= COOLTIME
            print(msg)
            clientsocket.send(msg.encode())
        elif((history[2] == "Five_far" or history[2] == "Five_near") and history[0] == "Five_back" and coolTime[6] == 0):
            msg = "switch"
            coolTime[6]= COOLTIME
            print(msg)
            clientsocket.send(msg.encode())
	

    key = cv2.waitKey(1)
    if key == 27:
        break
