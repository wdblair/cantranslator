#!/usr/bin/env python

import string
import time
import serial
import datetime

BAUD_RATES = [
    115200,
    230400,
    460800,
    500000,
    576000,
    921600,
    1000000,
    1152000,
    1500000,
    2000000]

MAX_BYTES = 10 * 1000 * 10 * 2

class SerialDevice(object):
    def __init__(self, port="/dev/ttyUSB1"):
        self.port = port
        self.baud_rate_index = 0
        self.device = serial.Serial(port, self.baud_rate(), timeout=5)
        self.device.flushInput()

    def reinitialize_baud_rate(self, baud_rate_index):
        self.baud_rate_index = baud_rate_index
        self.device.close()
        print ("Change the device's baud rate to index %d, please..."
                "press enter to continue" % baud_rate_index)
        raw_input("Press Enter when the device is back online")
        self.device = serial.Serial(self.port, self.baud_rate(), timeout=5)
        print "Baud rate switched to %d" % self.baud_rate()
        self.device.flushInput()
        self.bytes_received = 0
        self.device.readline()
        self.device.readline()
        self.device.readline()

    def read(self):
        data = self.device.readline()
        self.bytes_received += len(data)
        return data

    def baud_rate(self):
        return BAUD_RATES[self.baud_rate_index]

    def total_time(self, elapsed_time):
        return "Reading %s KB at baud %d took %s" % (
                self.bytes_received / 1000, self.baud_rate(), elapsed_time)

    def throughput(self, elapsed_time):
        return (self.bytes_received / 1000 /
                max(1, elapsed_time.seconds + elapsed_time.microseconds /
                    1000000.0))

def run_benchmark(serial_device, baud_rate_index, total_bytes=MAX_BYTES):
    serial_device.reinitialize_baud_rate(baud_rate_index)

    data = serial_device.read()
    starting_time = datetime.datetime.now()

    while serial_device.bytes_received < MAX_BYTES:
        data = serial_device.read()
        for character in string.ascii_lowercase:
            if character not in data:
                print "Corruption occurred, skipping this run"
                return 0
        # TODO validate message
    print
    print "Finished receiving."

    elapsed_time = datetime.datetime.now() - starting_time
    throughput = serial_device.throughput(elapsed_time)
    print serial_device.total_time(elapsed_time)
    print ("The effective throughput at baud %d is %d KB/s" % (
            serial_device.baud_rate(), throughput))
    return throughput


def main():
    device = SerialDevice()
    results = {}
    for baud_rate_index in range(len(BAUD_RATES)):
        results[BAUD_RATES[baud_rate_index]] = run_benchmark(device,
            baud_rate_index)

    print
    for key, value in results.iteritems():
        print "%d byte messages -> %d KB/s" % (key, value)

if __name__ == '__main__':
    main();
