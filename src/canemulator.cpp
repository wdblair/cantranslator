#ifdef CAN_EMULATOR

#include "usbutil.h"
#include "canread.h"
#include "serialutil.h"
#include "ethernetutil.h"
#include "log.h"
#include <stdlib.h>

#define NUMERICAL_SIGNAL_COUNT 11
#define BOOLEAN_SIGNAL_COUNT 5
#define STATE_SIGNAL_COUNT 2
#define EVENT_SIGNAL_COUNT 1

extern Listener listener;

const char* NUMERICAL_SIGNALS[NUMERICAL_SIGNAL_COUNT] = {
    "steering_wheel_angle",
    "torque_at_transmission",
    "engine_speed",
    "vehicle_speed",
    "accelerator_pedal_position",
    "odometer",
    "fine_odometer_since_restart",
    "latitude",
    "longitude",
    "fuel_level",
    "fuel_consumed_since_restart",
};

const char* BOOLEAN_SIGNALS[BOOLEAN_SIGNAL_COUNT] = {
    "parking_brake_status",
    "brake_pedal_status",
    "headlamp_status",
    "high_beam_status",
    "windshield_wiper_status",
};

const char* STATE_SIGNALS[STATE_SIGNAL_COUNT] = {
    "transmission_gear_position",
    "ignition_status",
};

const char* SIGNAL_STATES[STATE_SIGNAL_COUNT][3] = {
    { "neutral", "first", "second" },
    { "off", "run", "accessory" },
};

const char* EVENT_SIGNALS[EVENT_SIGNAL_COUNT] = {
    "door_status",
};

struct Event {
    const char* value;
    bool event;
};

Event EVENT_SIGNAL_STATES[EVENT_SIGNAL_COUNT][3] = {
    { {"driver", false}, {"passenger", true}, {"rear_right", true}},
};

void carStop() {
  for (int i=0; i < NUMERICAL_SIGNAL_COUNT; i++) {
    sendNumericalMessage(NUMERICAL_SIGNALS[i], 0, &listener);
  }

  for (int j=0; j < BOOLEAN_SIGNAL_COUNT; j++) {
    if (j > 1) { // there should be a better way to do this
      sendBooleanMessage(BOOLEAN_SIGNALS[j], false, &listener);
    }
    else {
      sendBooleanMessage(BOOLEAN_SIGNALS[j], true, &listener);
    }
  }

  sendStringMessage(STATE_SIGNALS[0], SIGNAL_STATES[0][0], &listener);

  sendStringMessage(STATE_SIGNALS[1], SIGNAL_STATES[1][0], &listener);

  /* events? */
}

void carStart() {
  sendStringMessage(STATE_SIGNALS[1], SIGNAL_STATES[1][1], &listener);
}

bool usbWriteStub(uint8_t* buffer) {
    debug("Ignoring write request -- running an emulator\r\n");
    return true;
}

float lastDist = 0;
float lastGas = 0;
float lastSpeed = 0;
float temps = 0;
float dataFreq = 100;
float targetSpeed = 50;
unsigned long timeAtEachSpeed = 7000;  //In milliseconds.
unsigned long timeForSpeedChange;
bool cruising = false;
unsigned long nextUpdate = 1000;
float acceleration = 80.0/400;  //In kph per 100th of a second.

void setup() {
    srand(42);
    carStart();
}

void loop() {
    while (millis() < nextUpdate) {}

    nextUpdate += 10;

    float signedAcceleration = acceleration;
    if(targetSpeed < lastSpeed) {
      signedAcceleration *= -1;
    }

    lastSpeed = lastSpeed + signedAcceleration;

    if (cruising) {
      //We're cruising at targetSpeed.
      if (millis() > timeForSpeedChange) {
        //We've cruised at this speed long enough.  Time to change it up.
        cruising = false;
        targetSpeed += 30;
        if(targetSpeed > 130) {
          targetSpeed = 50;
        }
        /*
        int newSpeed = random(3);
        switch(newSpeed) {
        case 0:
          targetSpeed = 50;  //A little more than 30mph.
          break;
        case 1:
          targetSpeed = 80;  //50mph.
          break;
        case 2:
          targetSpeed = 120;  //75mph.
          break;
        default:
          //Shouldn't've gotten here.  Hrm.
          targetSpeed = 144;  //90mph.
          break;
        }
        */
      }
    } else {
      //We haven't reached targetSpeed.
      if (abs(lastSpeed - targetSpeed) <= 2.0) {
        //We've reached targetSpeed!
        timeForSpeedChange = millis() + timeAtEachSpeed;
        cruising = true;
      }
    }

    float temp = lastSpeed / 360;  //kph * 1000m / 60 min / 60 sec / 100 packets/s.
    lastDist = lastDist + temp;
    sendNumericalMessage(NUMERICAL_SIGNALS[3], lastSpeed, &listener); // FIXME, these should not be hardcoded
    sendNumericalMessage(NUMERICAL_SIGNALS[5], lastDist, &listener);
    sendNumericalMessage(NUMERICAL_SIGNALS[6], lastDist, &listener);

    //Gas is calculated with three constants that have no basis in experimentation or reality.
#define IDLE_FUEL  0.000001   //Fuel spent just running the engine.
#define SPEED_FUEL 0.0000000001  //Fuel burned to fight air drag and road friction.
#define ACC_FUEL 0.00001    //Fuel burned to accelerate the car

    lastGas += IDLE_FUEL;
    if (signedAcceleration > 0) {
      lastGas += SPEED_FUEL * lastSpeed * lastSpeed * lastSpeed;  //We're fighting drag
      lastGas += ACC_FUEL;  //And we're adding momentum to the car.
    }  //else, we're not accelerating, and we're letting drag slow the car.

    sendNumericalMessage(NUMERICAL_SIGNALS[10], lastGas, &listener);

    long randomNumerical;
    do {
      randomNumerical =  random(NUMERICAL_SIGNAL_COUNT);
    } while ((randomNumerical == 3) || (randomNumerical == 5) || 
             (randomNumerical == 6) || (randomNumerical == 10));

    sendNumericalMessage(
                         NUMERICAL_SIGNALS[randomNumerical],
                         rand() % 50 + rand() % 100 * .1, &listener);
    sendBooleanMessage(BOOLEAN_SIGNALS[rand() % BOOLEAN_SIGNAL_COUNT],
                       rand() % 2 == 1 ? true : false, &listener);

    int eventSignalIndex = rand() % EVENT_SIGNAL_COUNT;
    Event randomEvent = EVENT_SIGNAL_STATES[eventSignalIndex][rand() % 3];
    sendEventedBooleanMessage(EVENT_SIGNALS[eventSignalIndex],
                              randomEvent.value, randomEvent.event, &listener);

    readFromHost(listener.usb, usbWriteStub);
    readFromSerial(listener.serial, usbWriteStub);
}

void reset() { }

const char* getMessageSet() {
    return "emulator";
}

#endif // CAN_EMULATOR
