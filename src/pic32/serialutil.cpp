#include "serialutil.h"
#include "buffers.h"
#include "log.h"
#include "WProgram.h"

#undef BYTE
#include <plib.h>

#define UART_BAUDRATE 115200
#define GetPeripheralClock() (80000000ul)

// TODO see if we can do this with interrupts on the chipKIT
// http://www.chipkit.org/forum/viewtopic.php?f=7&t=1088
void readFromSerial(SerialDevice* device, bool (*callback)(uint8_t*)) {
    if(device != NULL) {
    }
}

void initializeSerial(SerialDevice* device) {
    if(device != NULL) {
        initializeSerialCommon(device);
        // UARTConfigure(UART2, UART_ENABLE_PINS_CTS_RTS);
        UARTConfigure(UART2, UART_ENABLE_PINS_TX_RX_ONLY);
        UARTSetFifoMode(UART2, (UART_FIFO_MODE)(UART_INTERRUPT_ON_TX_NOT_FULL | UART_INTERRUPT_ON_RX_NOT_EMPTY));
        UARTSetLineControl(UART2, (UART_LINE_CONTROL_MODE)(UART_DATA_SIZE_8_BITS | UART_PARITY_NONE | UART_STOP_BITS_1));
        UARTSetDataRate(UART2, GetPeripheralClock(), UART_BAUDRATE);
        UARTEnable(UART2, (UART_ENABLE_MODE)UART_ENABLE_FLAGS(UART_PERIPHERAL | UART_RX | UART_TX));
    }
}

// The chipKIT version of this function is blocking. It will entirely flush the
// send queue before returning.
void processSerialSendQueue(SerialDevice* device) {
    while(!UARTTransmitterIsReady(UART2));
    UARTSendDataByte(UART2, 'b');
    while(!UARTTransmissionHasCompleted(UART2));
}
