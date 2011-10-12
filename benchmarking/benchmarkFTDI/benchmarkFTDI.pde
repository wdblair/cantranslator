#include <stdio.h>

int baudRates[14] = {
    115200,
    230400,
    460800,
    500000,
    576000,
    921600,
    1000000,
    1152000,
    1500000,
    2000000};

int currentBaudRateIndex = 9;

void setup() {
    Serial.begin(baudRates[currentBaudRateIndex]);
}

void loop() {
    Serial.println("abcdefghijklmnopqrstuvwxyz");
}
