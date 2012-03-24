/*
 *  Emulates being plugged into a live CAN network by output randomly valued
 *  JSON messages over USB.
 */

#include "WProgram.h"
#include "chipKITUSBDevice.h"
#include "usbutil.h"
#include "canutil.h"
#include "canemu.h"

#define NUMERICAL_SIGNAL_COUNT 11
#define BOOLEAN_SIGNAL_COUNT 5
#define STATE_SIGNAL_COUNT 2
#define EVENT_SIGNAL_COUNT 1

#define BOOLEAN_EVENT_MESSAGE_FORMAT "{\"name\":\"%s\",\"value\":\"%s\",\"event\":%s}\r\n"
#define BOOLEAN_EVENT_MESSAGE_VALUE_MAX_LENGTH 11

const int BOOLEAN_EVENT_MESSAGE_FORMAT_LENGTH = strlen(
        BOOLEAN_EVENT_MESSAGE_FORMAT);

USBDevice usbDevice(usbCallback);

char* NUMERICAL_SIGNALS[NUMERICAL_SIGNAL_COUNT] = {
    "steering_wheel_angle", // 0
    "powertrain_torque",
    "engine_speed",
    "vehicle_speed", // 3
    "accelerator_pedal_position",
    "odometer",
    "fine_odometer_since_restart", //6
    "latitude",
    "longitude",
    "fuel_level",
    "fuel_consumed_since_restart", // 10
};

char* BOOLEAN_SIGNALS[BOOLEAN_SIGNAL_COUNT] = {
    "parking_brake_status",
    "brake_pedal_status",
    "headlamp_status",
    "high_beam_status",
    "windshield_wiper_status",
};

char* STATE_SIGNALS[STATE_SIGNAL_COUNT] = {
    "transmission_gear_position",
    "ignition_status",
};

char* SIGNAL_STATES[STATE_SIGNAL_COUNT][3] = {
    { "neutral", "first", "second" },
    { "off", "run", "accessory" },
};

char* EVENT_SIGNALS[EVENT_SIGNAL_COUNT] = {
    "door_status",
};

Event EVENT_SIGNAL_STATES[EVENT_SIGNAL_COUNT][3] = {
    { {"driver", false}, {"passenger", true}, {"rear_right", true}},
};

void writeNumericalMeasurement(char* measurementName, float value) {
    int messageLength = NUMERICAL_MESSAGE_FORMAT_LENGTH +
        strlen(measurementName) + NUMERICAL_MESSAGE_VALUE_MAX_LENGTH;
    char message[messageLength];
    sprintf(message, NUMERICAL_MESSAGE_FORMAT, measurementName, value);

    sendMessage(&usbDevice, (uint8_t*) message, strlen(message));
}

void writeBooleanMeasurement(char* measurementName, bool value) {
    int messageLength = BOOLEAN_MESSAGE_FORMAT_LENGTH +
        strlen(measurementName) + BOOLEAN_MESSAGE_VALUE_MAX_LENGTH;
    char message[messageLength];
    sprintf(message, BOOLEAN_MESSAGE_FORMAT, measurementName,
            value ? "true" : "false");

    sendMessage(&usbDevice, (uint8_t*) message, strlen(message));
}

void writeStateMeasurement(char* measurementName, char* value) {
    int messageLength = STRING_MESSAGE_FORMAT_LENGTH +
        strlen(measurementName) + STRING_MESSAGE_VALUE_MAX_LENGTH;
    char message[messageLength];
    sprintf(message, STRING_MESSAGE_FORMAT, measurementName, value);

    sendMessage(&usbDevice, (uint8_t*) message, strlen(message));
}

void writeEventMeasurement(char* measurementName, Event event) {
    int messageLength = BOOLEAN_EVENT_MESSAGE_FORMAT_LENGTH +
        strlen(measurementName) + BOOLEAN_EVENT_MESSAGE_VALUE_MAX_LENGTH;
    char message[messageLength];
    sprintf(message, BOOLEAN_EVENT_MESSAGE_FORMAT, measurementName, event.value,
            event.event ? "true" : "false");

    sendMessage(&usbDevice, (uint8_t*) message, strlen(message));
}

void carStop() {
  for (int i=0; i < NUMERICAL_SIGNAL_COUNT; i++) {
    writeNumericalMeasurement(NUMERICAL_SIGNALS[i], 0);
  }
  
  for (int j=0; j < BOOLEAN_SIGNAL_COUNT; j++) {
    if (j > 1) { // there should be a better way to do this
      writeBooleanMeasurement(BOOLEAN_SIGNALS[j], false);
    }
    else {
      writeBooleanMeasurement(BOOLEAN_SIGNALS[j], true);
    }
  }
  
  writeStateMeasurement(STATE_SIGNALS[0],
             SIGNAL_STATES[0][0]);
   
  writeStateMeasurement(STATE_SIGNALS[1],
             SIGNAL_STATES[1][0]);
  
  /* events? */
}

void setup() {
    Serial.begin(115200);
    randomSeed(analogRead(0));

    initializeUsb(&usbDevice);
}

void loop() {
    float lastDist = 0;
    float lastGas = 0;
    float lastSpeed = 0;
    float temps = 0;
    float delayFreq = 100;
    
    while(true) {
      boolean positive;
      if (lastSpeed > 120) {
       random(3) == 0 ? positive = true : positive = false;
      }
      else if (lastSpeed < 20) {
        random(3) == 0 ? positive = false : positive = true;
      }
      else if (lastSpeed == 0) {
        positive = true;
      }
      else {
        random(2) == 0 ? positive = false : positive = true;
      }
        
      if(positive) {
        lastSpeed = lastSpeed + random(2);
      }
      else {
        lastSpeed = lastSpeed - random(2);
      }
      
      float temp = lastSpeed * ((delayFreq/1000)/3600);
      lastDist = lastDist + temp;
      writeNumericalMeasurement(NUMERICAL_SIGNALS[3], lastSpeed); // FIXME, these should not be hardcoded
      writeNumericalMeasurement(NUMERICAL_SIGNALS[6], lastDist);
      
      temp = random(3) * (0.001 * (delayFreq/1000)); // This is probably wrong
      lastGas = lastGas + temp;
      writeNumericalMeasurement(NUMERICAL_SIGNALS[10], lastGas);
      
      int randChoice = random(NUMERICAL_SIGNAL_COUNT);
      if (randChoice == 3) {}
      else if (randChoice == 6) {}
      else if (randChoice == 10) {}
      
      else {   
        writeNumericalMeasurement(
                  NUMERICAL_SIGNALS[randChoice],
                  random(101) + random(100) * .1);
      }
            
      writeBooleanMeasurement(BOOLEAN_SIGNALS[random(BOOLEAN_SIGNAL_COUNT)],
                random(2) == 1 ? true : false);
                
      int stateSignalIndex = random(STATE_SIGNAL_COUNT);
      if (STATE_SIGNALS[stateSignalIndex] == "ignition_status") {
        if (millis() > 300000) {
          int rand = random(1000);
          if (rand == 1) { // and we close. everything.
            carStop();
            break;
          }
        }
      }
      
      else {
        writeStateMeasurement(STATE_SIGNALS[stateSignalIndex],
                SIGNAL_STATES[stateSignalIndex][random(3)]);
      }
      
      int eventSignalIndex = random(EVENT_SIGNAL_COUNT);
      writeEventMeasurement(EVENT_SIGNALS[eventSignalIndex],
              EVENT_SIGNAL_STATES[eventSignalIndex][random(3)]);
    }
}

static boolean usbCallback(USB_EVENT event, void *pdata, word size) {
    usbDevice.DefaultCBEventHandler(event, pdata, size);

    switch(event) {
    case EVENT_CONFIGURED:
        usbDevice.EnableEndpoint(DATA_ENDPOINT,
                USB_IN_ENABLED|USB_HANDSHAKE_ENABLED|USB_DISALLOW_SETUP);
        break;

    default:
        break;
    }
}
