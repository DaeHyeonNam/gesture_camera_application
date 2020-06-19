## Hand gesture detection

![Alt Text](./image/demo1.gif)

### 1. Hand tracking
The real-time hand tracking is implemented using https://github.com/metalwhale/hand_tracking.

### 2. Hand gesture recognition
In the data folder, we will be able to find train and test csv files. These files consist of 43 columns. First 42 columns are representing coordinates of x, y of 21 hand landmarks. And the last column is label. Label consists of Five_near, Five_far, Five_back, Fist, Two, Three, Background. 

I trained data using small neural net. You can find the codes in the train file. And the accuracy I got was 91%.
Since the neural net is small, real-time prediciton could be possible. The most of big latency in demo file is from hand tracking not from gesture recognition procedure.

### 3. To run it

#### Dependency

opencv2

numpy

tensorflow > 2.0


#### execute
python real-time_prediction.py
