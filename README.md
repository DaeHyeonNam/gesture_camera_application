# gesture_camera_application

You can use hand gesture to control the camera application.
The gestures I implemented are zoom in/out, timer 3s/5s, resume/pause, switching to record/camera, capture.

## To run
What you need to have two phones and a desktop. Since streaming and camera application was not implemented in a application I had to use two phones instead of one. It can be upgraded soon. But now we need 2 phones and a desktop.


### For application : Phone A
Flutter

### For streaming current view : Phone B
ip webcam android application

### For socket interaction : Desktop
opencv

tensorflow


### How to run
Start streaming from Phone B to desktop. In socket_interaction.py file, you need to modify the ip address and port to the provided from the IP webcam.
Modify the ip address and port number for socket communication in socket_interaction.py and flutter camera_view.dart file. 
Run socket_interaction.py and run a camera application.


