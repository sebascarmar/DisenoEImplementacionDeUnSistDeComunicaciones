####################################################################################
#   Autor: Juarez Daniel
#   Año: 2025
#   Nombre: uart_test.py  For the communication between the PC and the micro 
#                         embedded in the FPGA
#   Descripcion: 
#               This script communicates between the PC and the FPGA in this way.          
#               you can reset, set, and request data from the FPGA and store them in 
#               csv files to be later plotted either in python or other software.    
#               or other software.    
###################################################################################

#### Library
import time
import serial
import sys
import binascii 
import struct
import numpy    as np
import subprocess

#### set uart port for comunication
portUSB = sys.argv[1]
ser = serial.Serial(
   port='/dev/ttyUSB{}'.format(int(portUSB)),   # pass port as parameter
   baudrate=115200,
   parity=serial.PARITY_NONE,
   stopbits=serial.STOPBITS_ONE,
   bytesize=serial.EIGHTBITS
)
ser.isOpen()
ser.timeout=None
#print(ser.timeout)


#### Codes for options 
enable = b'\x80'
opc_1  = b'\x01' 
opc_2  = b'\x02'
opc_3  = b'\x03'
opc_4  = b'\x04'
opc_5  = b'\x05'
opc_6  = b'\x06'
opc_7  = b'\x07' 
opc_8  = b'\x08' 
opc_9  = b'\x09' 
opc_10 = b'\x0A' 


#|___Function to save the data collected from the filter outputs___|
#| INPUT:                                                          |   
#|       data_I  and data_Q = Data obtained from RAM reading       |
#|       sub_opc_for_reading = Depending on its value, it will be  |
#|       the name used to store the data                           |
#| OUTPUT:                                                         |
#|         None                                                    |
#|_________________________________________________________________|

def save_data(data_Q, data_I, sub_opc_for_reading):

    if (sub_opc_for_reading == b'\x09'): 
        file_I = "file_rx_symI_dwr2_snr_12.txt" 
        file_Q = "file_rx_symQ_dwr2_snr_12.txt" 

    elif (sub_opc_for_reading == b'\x0A'):
        file_I = "file_rx_symI_dwr1_snr_12.txt"
        file_Q = "file_rx_symQ_dwr1_snr_12.txt"

    elif (sub_opc_for_reading == b'\x0B'):     
        file_I = "file_fse_taps_I_snr_12.txt"
        file_Q = "file_fse_taps_Q_snr_12.txt"

    elif (sub_opc_for_reading == ' '):   
        print("Error: invalid sub_opc_for_reading value. No files were created.")

    with open(file_I, 'w') as file:
        for data in data_I:
            file.write(str(data) + '\n')  

    print(f"Writing complete {file_I}")


    with open(file_Q, 'w') as file:
        for data in data_Q:
            file.write(str(data) + '\n') 

    print(f"Writing complete {file_Q}")


#   def save_data(data_I, data_Q, sub_opc_for_reading):
#   
#       if (sub_opc_for_reading == b'\x09'): 
#           np.savetxt('file_rx_symI_dwr2.txt' , data_I , delimiter='\n')
#           np.savetxt('file_rx_symQ_dwr2.txt' , data_Q , delimiter='\n')
#   
#       elif (sub_opc_for_reading == b'\x0A'):
#           np.savetxt('file_rx_symI_dwr1.txt' , data_I , delimiter='\n')
#           np.savetxt('file_rx_symQ_dwr1.txt' , data_Q , delimiter='\n')
#   
#   
#       elif (sub_opc_for_reading == b'\x0B'):     
#           np.savetxt('file_fse_taps_I.txt' , data_I , delimiter='\n')
#           np.savetxt('file_fse_taps_Q.txt' , data_Q , delimiter='\n')
#   
#       elif (sub_opc_for_reading == ' '):   
#           print("Error: invalid sub_opc_for_reading value. No files were created.")
#   

#|_____Function to verify the frames of transmitted bits and errors as well as filter frames_____|
#| INPUT:                                                                                        |   
#|       frame_ok = A complete frame sent by the FPGA to Python, can be from the filter, bits, or errors |
#| OUTPUT:                                                                                       |
#|         Var OK = 1 for correct frame, OK = 0 for error in received frame                      |
#|______________________________________________________________________________________________ |
def frame_check(frame):

    if len(frame) < 9:
        return False

    vals = []
    for b in frame:
        if isinstance(b, bytes):
            vals.append(b[0])
        else:
            vals.append(int(b))

    # Ahora comparamos
    if vals[0] != 0xA4:
        return False
    if vals[1] != 0x00:
        return False
    if vals[2] != 0x00:
        return False
    if vals[3] != 0x01:
        return False
    if vals[8] != 0x44:
        return False

    return True


#|_______________Function to assemble the frame to send to the FPGA________________|
#| INPUT:                                                                          |   
#|        opc = Variable indicating the operation to perform on the FPGA's RF      |
#|        sub_opc = Sub-option variable for specific operations on the FPGA        |
#|        filler_opc = Variable that can be 0 or a specific value in certain options |
#|        device = Variable indicating the device number being worked with    |
#| OUTPUT:                                                                         |
#|        frame_list = Returns the assembled frame to be written to the UART port  |
#|_________________________________________________________________________________|
def data_frame_assembly(opc, sub_opc , filler_opc, device) :

    data = opc + enable + filler_opc + sub_opc    #for example: 0x03 + 0x80 + 0x00 + 0x01 = 0x203800001
    #   print(f"Data for frame: {data}")
    #   print()
    if (len(data)<=15):
        head = binascii.unhexlify(str(hex(0xA0+eval(hex(len(data))))).split("0x")[1])
        high = b'\x00'
        low  = b'\x00'
        dispo = binascii.unhexlify(device)
        cola = binascii.unhexlify(str(hex(0x40+eval(hex(len(data))))).split("0x")[1])
        
        frame_hex = head + high + low + dispo + data + cola

        frame_list = list(frame_hex)
       # print(f"Frame for gpio: {frame_hex}")        
        print()
        
    return frame_list 


#|____Function to decode any error in sending frames to the FPGA___|
#| INPUT:                                                          |   
#|         frame = the assembled frame to be sent through the port |
#|         and also waits to see if the FPGA microcontroller sends |
#|         an error message                                        |
#| OUTPUT:                                                         |
#|         None                                                    |
#|_________________________________________________________________|
def data_frame_disassembly (frame):

    for i in range (2000):
        ser.write(frame)

    large = ser.inWaiting()
    head = 4   
    read_data = []
    opc = ""

    while (ser.inWaiting() > 0):  
        read_data.append(chr(ord(ser.read(1))))

    opc = "".join(read_data[head:large-1])
    
    if (len(opc) >0):
        print("Message received: ", opc)
    print()
    print()

#___Function to decode transmitted errors and bits___#  
#| INPUT:                                                                       |   
#|       frame_I and frame_Q = Data obtained from RAM reading                   |
#|       sub_opc_for_reading = Depending on its value, it will be the name      |
#|       used to store the data                                                 |
#| OUTPUT:                                                                      |
#|         None                                                                 |
#|______________________________________________________________________________|   
def data_ber_disassembly (frame):
    # send frame
    ser.write(frame)
    time.sleep(2)

    head = 4
    read_data = []
    
    # read data from serial port
    while ser.in_waiting > 0:
        read_data.append(ser.read(1)) 

   # print(f"Read data (raw): {[b.hex() for b in read_data]}")

    # Valid frame check
    count = 0
    for _ in range(8):
        frame_aux = read_data[count:count + 9]
        frame_ok = frame_check(frame_aux)
        #print(f"Frame with total bits and errors {frame_aux}")
        if frame_ok != 1:
            print("Frame Error:", [b.hex() for b in frame_aux])
            exit()
        count += 9

    # Adjusted range according to head
    low_total_data_I  = b''.join(read_data[63 + head: 72 - 1])
    high_total_data_I = b''.join(read_data[54 + head: 63 - 1])
    low_err_data_I    = b''.join(read_data[45 + head: 54 - 1])
    high_err_data_I   = b''.join(read_data[36 + head: 45 - 1])
    low_total_data_Q  = b''.join(read_data[27 + head: 36 - 1])
    high_total_data_Q = b''.join(read_data[18 + head: 27 - 1])
    low_err_data_Q    = b''.join(read_data[9  + head: 18 - 1])
    high_err_data_Q   = b''.join(read_data[0  + head: 9  - 1])

    # Combine high and low parts
    total_data_I = high_total_data_I + low_total_data_I
    err_data_I   = high_err_data_I   + low_err_data_I
    total_data_Q = high_total_data_Q + low_total_data_Q
    err_data_Q   = high_err_data_Q   + low_err_data_Q

    print()
    print("Bits I:", int.from_bytes( total_data_I, byteorder='little'))
    print("Bits Q:", int.from_bytes( total_data_Q, byteorder='little'))
    print("Errores I:", int.from_bytes(err_data_I, byteorder='little'))
    print("Errores Q:", int.from_bytes(err_data_Q, byteorder='little'))
 
    print("\nBER_I: {:.3e}".format((int.from_bytes(err_data_I, byteorder='little')/int.from_bytes(total_data_I, byteorder='little'))))
    print("BER_Q: {:.3e}".format((int.from_bytes(err_data_Q, byteorder='little')/int.from_bytes(total_data_Q, byteorder='little'))))
    print()

#|____________Function to decode filter data__________________________|
#| INPUT:                                                             |   
#|        frame = Frame sent for reading data stored in RAM.          |
#|        It also decodes the data sent by the FPGA per frame         |
#|        and retrieves the output values of the filter.              |
#|        sub_opc_for_reading = Auxiliary variable passed to another  |
#|        function responsible for saving the data sent to Python.    |
#| OUTPUT:                                                            |
#|         None                                                       |
#|____________________________________________________________________|
def data_frame_IQ_disassembly  (frame_request, sub_opc_for_reading):
 
    if (sub_opc_for_reading == b'\x09' or sub_opc_for_reading == b'\x0A'):
        N = 32768
    else: 
        N = 32760
    # Clean buffer
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    # set list for storage values 
    frame_int_I = []
    frame_int_Q = []    
    frame_payload = []

    for idx in range(N):
        # 2) Request the frame from the FPGA
        ser.write(frame_request)

        # 3) Wait to receive exactly 9 bytes (or timeout)
        buf = ser.read(9)
        # print(f"Frame {idx} with data from RAM: {buf}")    

        if len(buf) != 9:
                print(f"[Warning] frame {idx}: received {len(buf)} bytes, skipping…")
                print(f"[ {buf} ]")
                continue

        # 4) Verify header and tail
        if frame_check(list(buf)) != 1:
                print(f"[Warning] frame {idx}: checksum failed, skipping…")
                continue

        # 5) Extract the 4 bytes of payload
        payload = buf[4:8]
        raw = [b for b in payload]
        
        frame_payload.append(raw)

        Q = int.from_bytes(raw[0:2], byteorder='little', signed=True)
        I = int.from_bytes(raw[2:4], byteorder='little', signed=True)

        # 6) Store integer and float values
        frame_int_Q.append(Q)
        frame_int_I.append(I)

        # Sleep for 0.1s every 200 frames
        if (idx+1) % 200 == 0:
                time.sleep(0.1)
            
    print("Reading complete\n")
    print("Data Q :", frame_int_Q)
    print("Data I: ", frame_int_I)
    #   print("Payload: ", frame_payload)
    print() 

    save_data(frame_int_Q, frame_int_I, sub_opc_for_reading)


#|____________________Function to get snr for hw______________________|
#| INPUT:                                                             |  
#|          index from snr value                                      |   
#| OUTPUT:                                                            |
#|          snr value in hex                                          |
#|____________________________________________________________________|
def get_snr_for_hw(snr_idx):
    # SNR values: 1 dB to 20 dB
    snr_values = np.array([
                  0.4453125, 0.390625, 0.3515625, 0.3125   ,
                  0.28125  , 0.25    , 0.21875  , 0.1953125,
                  0.171875 , 0.15625 , 0.140625 , 0.125    , 
                  0.109375 , 0.09375 , 0.0859375, 0.078125 ,
                  0.0703125, 0.0625  , 0.0546875, 0.046875
                 ])
    
    scaled_val = int(snr_values[(snr_idx-1)]*2**7)

    return scaled_val.to_bytes(1, byteorder='big')
    

#|_____________________Function for sub-options________________________|
#| INPUT:                                                              |
#|        opc = Variable indicating the chosen option. Some options    |
#|        have a submenu for sub-options, such as the option to set    |
#|        parts of the system.                                         |
#| OUTPUT:                                                             |
#|         sub_opc = Variable indicating a sub-option depending on     |
#|         the main option selected.                                   |
#|         filler_opc = Returns a value, either zero or a specific one,|
#|         depending on the chosen option and sub-option.              |
#|_____________________________________________________________________|
def sub_menu(opc):

    if( opc == '2' ):
        print("|( 2 ): Turn receiver ON/OFF_______|")
        print("|    ( 1 ): ON                     |")
        print("|    ( 2 ): OFF                    |")
        print("|    ( 3 ): Return to Main Menu    |")
        print("|__________________________________|")
        option = input("Enter an option: ")

        while (option != '1' and option != '2' and option != '3'): 
            option = input("Invalid option. Enter an option (1-3): ")   
        print()
        if (option == '1'): return b'\x01' # [1] enbl + [2:0] subop = 1|001
        if (option == '2'): return b'\x00' # [1] enbl + [2:0] subop = 1|010 
        if (option == '3'): return b'\xFF'
    
    elif( opc == '3' ):
        print("|( 3 ): Select SNR______________|")
        print("|    ( 1 ): Enter values (7-17) |")
        print("|    ( 2 ): Return to Main Menu |")
        print("|_______________________________|")
        option = input("Enter an option: ")

        while (option != '1' and option != '2'): 
            option = input("Invalid option. Enter an option (1-2): ")   
        print()

        if (option == '1'): 
            snr_opc = int (input("Enter an int. value (7-17): "))

            while snr_opc < 7 or snr_opc > 17: 
                snr_opc = int(input("Invalid option. Enter a value between 7 and 20: "))  
            print()
            snr_value = get_snr_for_hw(snr_opc)
            
            return snr_value

        if (option == '2'): return b'\xFF'

    elif( opc == '4' ):
        print("|( 4 ): Select channel filter______|")
        print("|    ( 1 ): fc = 12 MHz            |")
        print("|    ( 2 ): impulse                |")
        print("|    ( 3 ): fc = 10 MHz            |")
        print("|    ( 4 ): Return to Main Menu    |")
        print("|__________________________________|")
        option = input("Enter an option: ")

        while (option != '1' and option != '2' and option != '3' and option != '4'): 
            option = input("Invalid option. Enter an option (1-4): ")   
        print()
        if (option == '1'): return b'\x00' # [1] enbl + [2:0] subop = 1|001
        if (option == '2'): return b'\x01' # [1] enbl + [2:0] subop = 1|010 
        if (option == '3'): return b'\x02' # [1] enbl + [2:0] subop = 1|011  
        if (option == '4'): return b'\xFF'

    elif( opc == '6' ):
        print("|( 6 ): Store DSP data in memory___|")
        print("|    ( 1 ): Store DSP input        |")
        print("|    ( 2 ): Store DSP output       |")
        print("|    ( 3 ): Store FSE taps         |")
        print("|    ( 4 ): Return to Main Menu    |")
        print("|__________________________________|")
        option = input("Enter an option: ")

        while (option != '1' and option != '2' and option != '3' and option != '4'): 
            option = input("Invalid option. Enter an option (1-4): ")   
        print()
        if (option == '1'): return b'\x09' # [1] enbl + [2:0] subop = 1|001
        if (option == '2'): return b'\x0A' # [1] enbl + [2:0] subop = 1|010 
        if (option == '3'): return b'\x0B' # [1] enbl + [2:0] subop = 1|011  
        if (option == '4'): return b'\xFF'
    

#|___________________Main script entry point_____________________________|
#| This is the starting point of the Main Menu where the desired option  |
#| to perform is selected.                                               |
#|_______________________________________________________________________|
#___Variables___#
device              = '01' # Device number being used
sub_opc             = ''   # Sub-option variable, used only for some options
sub_opc_for_reading = ''   # Auxiliary variable used only for logged data storage  

while 1 :

    print("|******************* MAIN MENU ********************|")
    print("| (  1 ): Reset                                    |")
    print("| (  2 ): Turn receiver ON/OFF                     |") 
    print("| (  3 ): Select SNR                               |") 
    print("| (  4 ): Select channel filter                    |")
    print("| (  5 ): Comming soon ...                         |")  
    print("| (  6 ): Store DSP data in memory                 |")  
    print("| (  7 ): Read stored data                         |")
    print("| (  8 ): Store total and error bits               |")
    print("| (  9 ): Read total and error bits                |")
    print("| ( 10 ): Exit                                     |")
    print("|__________________________________________________|")
    input_opc = input("Enter an option: ")


    while (input_opc != '1' and input_opc != '2' and input_opc != '3' and input_opc != '4' and 
           input_opc != '5' and input_opc != '6' and input_opc != '7' and input_opc != '8' and 
           input_opc != '9' and input_opc != '10'): 
        input_opc = input("Invalid option. Enter and option (1-10): ")   
    print()


    if(input_opc == '1'):                                              # 1 - Reset para el sistema                                         
        frame = data_frame_assembly (opc_1, b'\x01', b'\x00', device)  
        data_frame_disassembly (frame)  

    elif(input_opc == '2'):                                            # 2 - Turn receiver ON/OFF               
        sub_opc = sub_menu(input_opc) 
        if (sub_opc != b'\xFF'):
            frame = data_frame_assembly (opc_2, sub_opc, b'\x00', device)  
            data_frame_disassembly (frame)   

    elif(input_opc == '3'):                                            # 3 - Select snr 
        sub_opc = sub_menu(input_opc) 
        if (sub_opc != b'\xFF'):
            frame = data_frame_assembly (opc_3, sub_opc, b'\x00', device)  
            data_frame_disassembly (frame)   

    elif(input_opc == '4'):                                            # 4 - Select channel filter 
        sub_opc = sub_menu(input_opc) 
        if (sub_opc != b'\xFF'):
            frame = data_frame_assembly (opc_4, sub_opc, b'\x00', device)  
            data_frame_disassembly (frame)   

    elif(input_opc == '5'):
        print("Todavia no hay nada maquinola....\n")

    elif(input_opc == '6'):                                            # 6 - Store DSP data in memory          
        sub_opc = sub_menu(input_opc)  
        if (sub_opc != b'\xFF'):
            frame = data_frame_assembly (opc_6, b'\x00', b'\x00', device) # Set option
            data_frame_disassembly (frame)
            frame = data_frame_assembly (opc_6, sub_opc, b'\x00', device) # Set option and store option
            data_frame_disassembly (frame)  
       
            sub_opc_for_reading = sub_opc

    elif(input_opc == '7'):                                            # 7 - Read stored data         
        frame = data_frame_assembly (opc_7, b'\x01', b'\x00', device)   
        
        print("Receiving data. Please wait...\n")
        data_frame_IQ_disassembly  (frame,sub_opc_for_reading) # cambiar nombre a leer datos

    elif(input_opc == '8'):                                            # 8 - Store total and error bits           
        frame = data_frame_assembly (opc_8, b'\x01', b'\x00', device)          
        data_frame_disassembly (frame)

    elif(input_opc == '9'):                                            # 9 - Read total and error bits            
        frame = data_frame_assembly (opc_9, b'\x01', b'\x00', device)         
        data_ber_disassembly (frame)

    elif (input_opc  == '10'): 
        ser.close(); break                                             # 10 - End program

    else: 
        print("Invalid option (1 - 10)")
        print()


