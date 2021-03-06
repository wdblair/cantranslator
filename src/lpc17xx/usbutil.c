#include "usbutil.h"
#include "log.h"
#include "buffers.h"
#include <stdio.h>

#include "bsp.h"
#include "LPC17xx.h"
#include "lpc17xx_gpio.h"

extern UsbDevice USB_DEVICE;
extern bool handleControlRequest(uint8_t);

void configureEndpoints() {
    Endpoint_ConfigureEndpoint(OUT_ENDPOINT_NUMBER, EP_TYPE_BULK,
            ENDPOINT_DIR_OUT, DATA_ENDPOINT_SIZE, ENDPOINT_BANK_DOUBLE);
    Endpoint_ConfigureEndpoint(IN_ENDPOINT_NUMBER, EP_TYPE_BULK,
            ENDPOINT_DIR_IN, DATA_ENDPOINT_SIZE, ENDPOINT_BANK_DOUBLE);
}

void EVENT_USB_Device_ControlRequest() {
    if(!(Endpoint_IsSETUPReceived())) {
        return;
    }

    handleControlRequest(USB_ControlRequest.bRequest);
}

void EVENT_USB_Device_ConfigurationChanged(void) {
    configureEndpoints();
}

static void sendToHost(UsbDevice* usbDevice) {
    uint8_t previousEndpoint = Endpoint_GetCurrentEndpoint();
    Endpoint_SelectEndpoint(IN_ENDPOINT_NUMBER);
    if(!Endpoint_IsINReady() || QUEUE_EMPTY(uint8_t, &usbDevice->sendQueue)) {
        return;
    }

    // get bytes from transmit FIFO into intermediate buffer
    int byteCount = 0;
    while(!QUEUE_EMPTY(uint8_t, &usbDevice->sendQueue)
            && byteCount < USB_SEND_BUFFER_SIZE) {
        usbDevice->sendBuffer[byteCount++] = QUEUE_POP(uint8_t, &usbDevice->sendQueue);
    }

    if(byteCount > 0) {
        Endpoint_Write_Stream_LE(usbDevice->sendBuffer, byteCount, NULL);
    }
    Endpoint_ClearIN();
    Endpoint_SelectEndpoint(previousEndpoint);
}

void sendControlMessage(uint8_t* data, uint8_t length) {
    uint8_t previousEndpoint = Endpoint_GetCurrentEndpoint();
    Endpoint_SelectEndpoint(ENDPOINT_CONTROLEP);

    Endpoint_ClearSETUP();
    Endpoint_Write_Control_Stream_LE(data, length);
    Endpoint_ClearOUT();

    Endpoint_SelectEndpoint(previousEndpoint);
}

void processUsbSendQueue(UsbDevice* usbDevice) {
    USB_USBTask();
    if(USB_DeviceState != DEVICE_STATE_Configured) {
        usbDevice->configured = false;
        return;
    }
    usbDevice->configured = true;

    sendToHost(usbDevice);
}


void initializeUsb(UsbDevice* usbDevice) {
    initializeUsbCommon(usbDevice);
    USB_Init();
    USB_Connect();

    debug("Done.\r\n");
}

void readFromHost(UsbDevice* usbDevice, bool (*callback)(uint8_t*)) {
    uint8_t previousEndpoint = Endpoint_GetCurrentEndpoint();
    Endpoint_SelectEndpoint(OUT_ENDPOINT_NUMBER);

    while(Endpoint_IsOUTReceived()) {
        for(int i = 0; i < usbDevice->outEndpointSize; i++) {
            if(!QUEUE_PUSH(uint8_t, &usbDevice->receiveQueue,
                        Endpoint_Read_8())) {
                debug("Dropped write from host -- queue is full\r\n");
            }
        }
        processQueue(&usbDevice->receiveQueue, callback);
        Endpoint_ClearOUT();
    }
    Endpoint_SelectEndpoint(previousEndpoint);
}
