import serial

# Replace 'COMx' with your actual COM port
ser = serial.Serial('COM8', 115200, timeout=1)

while True:
    if ser.in_waiting > 0:
        line = ser.readline().decode('utf-8').rstrip()
        print(line)