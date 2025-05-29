/***********************TRAMAS DE PYTHON A RECIBIR****************************
	
 ======== Definition the finaly menu ========== 
 1 - Reset del DSP
 2 - Enbl or Disable Aaptive filter 
 3 - Log data in RAM 
 		|__ Data FSE (Input)  (Sub options)
			|__ Data input Slcr 
			|__ Data coeffs 
			|__ Data error
	4 - Read data from RAM 
	5 - Capture bits and err from PRBS 
	6 - Read bits and err from PRBS 
	7 - Finish program 
	***************************************************
	1 - 0x01800001 / 0x01800000  
	2 - 0x02800001 / 0x02800000
	3 - 0x03800009 -> FSE 
			0x0380000A -> Slcr
			0x0380000B -> coeffs 
			0x0380000C -> err 	/ 0x03800000 
	4 - 0x04800001 / 0x04800000
	5 - 0x05480001 / 0x05800000
	6 - 0x06800001 / 0x04800000
******************************************************************************/

    /*
     *******************************************************************
    1 - 0x01800001 / 0x01800000			Reset DSP
    2 - 0x02800001 / 0x02800000			Enbl Adaptive Filter
    3 - 0x03800009 -> FSE 			Log FSE Data
    	0x0380000A -> Slcr			Log Slicer
    	0x0380000B -> coeffs 			Log coeffs
    4 - 0x04800000 / 0x04800000			read data RAM
    5 - 0x05480001 / 0x05800000			log bits and errs
    6 - 0x06800001 / 0x06800000			read bits and errs
    ********************************************************************
   */ 



#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xgpio.h"
#include "platform.h"
#include "xuartlite.h"
#include "microblaze_sleep.h"
#include <xil_printf.h>

// Definitions
#define PORT_IN         XPAR_AXI_GPIO_0_DEVICE_ID // Device ID for GPIO input
#define PORT_OUT        XPAR_AXI_GPIO_0_DEVICE_ID // Device ID for GPIO output

// Operation Codes
#define def_SOFT_RST        0
#define def_ENABLE_MODULES  1
#define def_LOG_RUN         2
#define def_LOG_READ        3
#define N                   32768  // Constant used for iteration (size)

// Global Variables
XGpio GpioOutput;   // GPIO instance for outputs
XGpio GpioParameter;// GPIO instance for parameters (not used in this snippet)
XGpio GpioInput;    // GPIO instance for inputs
u32 GPO_Value;      // Output value
u32 GPO_Param;      // Output parameter (unused here)
XUartLite uart_module; // UART instance

/*
*****************************************************************
* Function: void TramaErr(char, char)
* This function is used to send an error message if the received
* frame does not meet the expected parameters.
* INPUTS:
*       dato1 and dato2 -> used to assemble the error frame
* RETURNS:
*       none
*****************************************************************
*/
void TramaErr (char, char);

// Main function
int main(){

    init_platform();  // Initialize FPGA platform peripherals

    // Local variables
    int Status;
    int indice = 0;
    int error = 0;
    int contador_BE = 0;
    int addr_read_limit = 0;
    unsigned char dato[4];
    
    u32 byte_dato_3;   // Variables for received frame data
    u32 byte_dato_2;
    u32 byte_dato_1;
    u32 byte_dato_0;
    u32 Error_bits[8];
    u32 resultado_dato;
    u32 value;

    // UART and GPIO initialization
    XUartLite_Initialize(&uart_module, 0); // Initialize UART module
    GPO_Value = 0x00000000;
    GPO_Param = 0x00000000;
    
    Status = XGpio_Initialize(&GpioInput, PORT_IN);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    Status = XGpio_Initialize(&GpioOutput, PORT_OUT);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    // Set GPIO directions: output and input
    XGpio_SetDataDirection(&GpioOutput, 1, 0x00000000); // All output
    XGpio_SetDataDirection(&GpioInput, 1, 0xFFFFFFFF);  // All input

    // Main loop
    while (1) {
        read(stdin, &dato[0], 1); // Read one byte from serial port

        switch (indice) {
        case 0: // Header check
            if (dato[0] == 0xA4) break;
            else error = 1; // If wrong header, set error
            break;

        case 1: // Field 1 check
            if (dato[0] == 0x00 && error == 0) break;
            else error = 1;
            break;

        case 2: // Field 2 check
            if (dato[0] == 0x00 && error == 0) break;
            else error = 1;
            break;

        case 3: // Field 3 check
            if (dato[0] == 0x01 && error == 0) break;
            else error = 1;
            break;

        case 4: // Save 4th byte of data
            byte_dato_3 = dato[0];
            break;

        case 5: // Save 3rd byte of data
            byte_dato_2 = dato[0];
            break;

        case 6: // Save 2nd byte of data
            byte_dato_1 = dato[0];
            break;

        case 7: // Save 1st byte of data
            byte_dato_0 = dato[0];
            break;

        case 8: // Final check and processing
            if (dato[0] == 0x44 && error == 0) { // End of frame detected
                // Concatenate all data bytes
                resultado_dato = (byte_dato_3 << 24) + (byte_dato_2 << 16) + (byte_dato_1 << 8) + byte_dato_0;

                // Case 1: Soft Reset DSP
                if (resultado_dato == 0x01800001) {
                    // Perform reset sequence
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800000 & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) 0x01800000);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800000 & (0xFF7FFFFF)));

                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) resultado_dato);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));
                }
                // Case 2: Enable adaptive filter
                if (resultado_dato == 0x02800001 || resultado_dato == 0x02800000) {
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) resultado_dato);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));
                }
                // Case 3: Set SNR value 
                if ((resultado_dato & 0xFFFFFF00) == 0x03800000) {
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) resultado_dato);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));

                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800000 & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) 0x01800000);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800000 & (0xFF7FFFFF)));

                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800001 & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) 0x01800001);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800001 & (0xFF7FFFFF)));
                }
                // Case 4: select coeff for ch filter 
                if ((resultado_dato & 0xFFFFFF00) == 0x04800000) {
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) resultado_dato);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));

                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800000 & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) 0x01800000);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800000 & (0xFF7FFFFF)));

                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800001 & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) 0x01800001);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x01800001 & (0xFF7FFFFF)));
                }
                // Case 6: Write data to RAM
                if ((resultado_dato & 0xFFFFFFF0) == 0x06800000) {
//                if (resultado_dato == 0x06800009 || resultado_dato == 0x0680000A || resultado_dato == 0x0680000B) {
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32) resultado_dato);
                    XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(resultado_dato & (0xFF7FFFFF)));
                    // Determine which operation (sub-opcode) to use for writing
                    if (resultado_dato == 0x06800009) {
                        // Input slicer data
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x06800001 & (0xFF7FFFFF)));
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32) 0x06800001);
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x06800001 & (0xFF7FFFFF)));
                        addr_read_limit = 32768;
                    } else if (resultado_dato == 0x0680000A) {
                        // Output slicer data
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x06800002 & (0xFF7FFFFF)));
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32) 0x06800002);
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x06800002 & (0xFF7FFFFF)));
                        addr_read_limit = 32768;
                    } else {
                        // Bit error data
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x06800003 & (0xFF7FFFFF)));
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32) 0x06800003);
                        XGpio_DiscreteWrite(&GpioOutput, 1, (u32)(0x06800003 & (0xFF7FFFFF)));
                        addr_read_limit = 32760; // because 32760 is a multiple of 9
                    }
                }
    		// Case 7: Read data from RAM
    		if (resultado_dato == 0x07800001) {
    		    for (int j = 0; j < addr_read_limit; j ++ ){
    		        XGpio_DiscreteWrite(&GpioOutput,1, (u32) ((0x07810000 | (j & 0x0000FFFF)) & (0xFF7FFFFF)));
    		        XGpio_DiscreteWrite(&GpioOutput,1, (u32)   0x07810000  | (j & 0x0000FFFF)                );
    		        XGpio_DiscreteWrite(&GpioOutput,1, (u32) ((0x07810000 | (j & 0x0000FFFF)) & (0xFF7FFFFF)));
   
    		        value = XGpio_DiscreteRead(&GpioInput, 1);

                        unsigned char trama_filtro [] = {0xA4, 0x00, 0x00, 0x01, (value & 0xFF), ((value >> 8) & 0xFF), ((value >> 16) & 0xFF), ((value >> 24) & 0xFF), 0x44};
                            
    		 	XUartLite_Send(&uart_module,trama_filtro,9);
    		 	for (volatile int i = 0; i < 70000; i++); // waiting 700us
    		 	XUartLite_ResetFifos(&uart_module);

                    } // end for ()
    		    
    		    XGpio_DiscreteWrite(&GpioOutput,1, (u32) (0x07800000 & (0xFF7FFFFF)));
    		    XGpio_DiscreteWrite(&GpioOutput,1, (u32)  0x07800000                );
    		    XGpio_DiscreteWrite(&GpioOutput,1, (u32) (0x07800000 & (0xFF7FFFFF)));
    		    XUartLite_ResetFifos(&uart_module);
    		} // end if (resultado_dato == 0x04800001)    
    		// Case 8: Store totals and error bits
    		if (resultado_dato == 0x08800001) {
    		    XGpio_DiscreteWrite(&GpioOutput,1, (u32) (resultado_dato & (0xFF7FFFFF)));
    		    XGpio_DiscreteWrite(&GpioOutput,1, (u32)  resultado_dato                );
    		    XGpio_DiscreteWrite(&GpioOutput,1, (u32) (resultado_dato & (0xFF7FFFFF)));
    		}
                // Case 9: Read totals and error bits   
    		if (resultado_dato == 0x09800001) {
    		     while (contador_BE < 8){
    		       XGpio_DiscreteWrite(&GpioOutput,1, (u32) (0x09810000 | (contador_BE & 0x0000000F)));
    		       XGpio_DiscreteWrite(&GpioOutput,1, (u32) (0x09810000 | (contador_BE & 0x0000000F)));
    		       XGpio_DiscreteWrite(&GpioOutput,1, (u32) (0x09810000 | (contador_BE & 0x0000000F)));
    		       Error_bits[contador_BE] = XGpio_DiscreteRead(&GpioInput, 1);
    
    		       unsigned char trama_EB [] = {0xA4, 0x00, 0x00, 0x01, (Error_bits[contador_BE] & 0xFF), ((Error_bits[contador_BE]>>8) & 0xFF), ((Error_bits[contador_BE]>>16) & 0xFF), ((Error_bits[contador_BE]>>24) & 0xFF), 0x44};

    		       for (volatile int i = 0; i < 1000; i++);
    		       while(XUartLite_IsSending(&uart_module)){};
    		          XUartLite_Send(&uart_module,trama_EB,9);
    			  contador_BE += 1;
    		     } // end while
    		} // end if (0x07800000)
    	    }// end if (dato[0] == 0x44 && error == 0)
    	    else {
    	        TramaErr('0','F'); // Data for frame error
    		break;
    	    }
    	} // end case
    	indice += 1;
    	if (indice == 9 ){
    	    indice      = 0;
    	    error       = 0;
    	    contador_BE = 0;
    	}
    
    }  // end while(1)
    cleanup_platform();
    return 0;
} // end main()

// Function for sending frame after an error
void TramaErr (char dato1, char dato2){
    unsigned char trama [7] = {0xA4, 0x00, 0x00, 0x01, dato1, dato2, 0x44};
    while(XUartLite_IsSending(&uart_module)){};
	XUartLite_Send(&uart_module,trama,7);
}

