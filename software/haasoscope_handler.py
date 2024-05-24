import sys
import signal
import subprocess
import serial
from time import sleep


# Define a signal handler function
def signal_handler(sig, frame):
    print("SIGINT received. Exiting...")
    ser.close()
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)

ser = serial.Serial('COM5')
print(f'connected to {ser.name}')


def power_cycle():
    print('sending haasoscope off')
    ser.write(b'haasoscope off')
    sleep(5)
    print('sending haasoscope on')
    ser.write(b'haasoscope on')
    sleep(10)


def run():
    # Command to run
    cmd = 'python HaasoscopeQt.py -r13 -b6 -fastusb -scriptcern.py'.split(' ')

    while True:
        sleep(5)
        power_cycle()

        p = subprocess.Popen(cmd)
        # completed_process = subprocess.run(cmd, capture_output=False, subprocess.HIGH_PRIORITY_CLASS)
        p.wait()
        sleep(3)
        if p.returncode == 0:
            print("HaasoscopeQt.py has exited successfully.")
            ser.close()
            exit()
        else:
            print("HaasoscopeQt.py has exited with an error.")


if __name__ == '__main__':
    run()
