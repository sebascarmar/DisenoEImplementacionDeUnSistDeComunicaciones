import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.io import savemat
import math


def slicer_qpsk(x):
     # Parte real
    if x.real>=0:
        a=1;
    else:
        a=-1;
    # Parte imag
    if x.imag>=0:
        b = 1;
    else:
        b = -1;

    return a, b


def find_delay(signal1, signal2):
    # Calculate cross-correlation
    correlation = np.correlate(signal1, signal2, mode='full')
    # Find the index of the maximum correlation
    delay = np.argmax(correlation) - (len(signal2) - 1)
    return delay


def theoric_ber(M, EbNodB):
    EbNo = 10**(EbNodB/10)
    k    = np.log2(M)
    x    = np.sqrt(3*k*EbNo/(M-1))
    ber  = (4/k)*(1-1/np.sqrt(M))*(1/2)*math.erfc(x/np.sqrt(2))

    return ber


####################################################################################
#                                      MAIN                                        #
####################################################################################

#------------------ Parámetros
# Generales
NSYMB = 1000000 # 1e6
BR    = 25e6    # Baud
OS    = 4       # oversampling
BETA  = 0.5     # roll-off
NBAUD = 16
M     = 4       # orden de modulación

# Canal
EbNo_db  = 0
f_offset = 10e3 # Hz
NSYMB_CONVERGENCE = 100000 # Convergencia de FSE y FCR (mitad y mitad)

# Receptor
OS_DSP    = 2
NTAPS_FSE = 33
lms_step  = 1e-3
lms_leak  = 0
Kp        = 1e-3
Ki        = Kp/1000

# Contador de BER
START_CNT = 400000

np.random.seed(1)  # Establece la semilla

#------------------ Transmisor
tx_symI_rand = np.loadtxt('from_matlab/tx_symb_I.txt')
tx_symQ_rand = np.loadtxt('from_matlab/tx_symb_Q.txt')



#------------------ Receptor
# Downsampler
rx_symI_dw = np.loadtxt('from_matlab/dsp_in_norm_I_00dB_10k.txt')
rx_symQ_dw = np.loadtxt('from_matlab/dsp_in_norm_Q_00dB_10k.txt')

# Variables para FFE
fseI_buffer = np.zeros(NTAPS_FSE)
fseQ_buffer = np.zeros(NTAPS_FSE)
fseI_coeff  = np.zeros(NTAPS_FSE); fseI_coeff[int(NTAPS_FSE/2)] = 1
fseQ_coeff  = np.zeros(NTAPS_FSE); fseQ_coeff[int(NTAPS_FSE/2)] = 0
rx_symI_fse = np.zeros(NSYMB*OS_DSP)
rx_symQ_fse = np.zeros(NSYMB*OS_DSP)

log_step    = 500
coeffs_log  = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))

# Variables para FCR
nco_out     = 0
int_err     = 0 
rx_symIjQ_fcr = np.zeros(NSYMB*OS_DSP, dtype=complex)

# Variables para el slicer
rx_symI_slcr  = np.zeros(NSYMB)
rx_symQ_slcr  = np.zeros(NSYMB)

for i in range(NSYMB*OS_DSP):
    # Filter buffer
    fseI_buffer[1:] = fseI_buffer[:-1]
    fseI_buffer[0]  = rx_symI_dw[i]
    fseQ_buffer[1:] = fseQ_buffer[:-1]
    fseQ_buffer[0]  = rx_symQ_dw[i]

    # Filter output
    rx_symI_fse[i] = np.dot(fseI_buffer,fseI_coeff)-np.dot(fseQ_buffer,fseQ_coeff)
    rx_symQ_fse[i] = np.dot(fseI_buffer,fseQ_coeff)+np.dot(fseQ_buffer,fseI_coeff)
    
    # FCR output
    rx_symIjQ_fcr[i] = (rx_symI_fse[i]+1j*rx_symQ_fse[i]) * np.exp(-1j*nco_out)

    if((i+1)%OS_DSP)==0: # Downsampling to BR rate (os=1)
        k = int(i/OS_DSP)
        # Slicer
        rx_symI_slcr[k],rx_symQ_slcr[k] = slicer_qpsk(rx_symIjQ_fcr[i])
        
        # Error for LMS
        coeff_err   = (rx_symIjQ_fcr[i]-rx_symI_slcr[k]-1j*rx_symQ_slcr[k]) * np.exp(1j*nco_out)
        
        fseI_coeff = (fseI_coeff*(1-lms_step*lms_leak) - 
                       lms_step*(coeff_err.real*fseI_buffer + coeff_err.imag*fseQ_buffer))
        fseQ_coeff = (fseQ_coeff*(1-lms_step*lms_leak) +
                       lms_step*( coeff_err.real*fseQ_buffer - coeff_err.imag*fseI_buffer))
        if (((i+1)/OS_DSP)%log_step) == 0:
            coeffs_log[:, int(((i+1)/OS_DSP)/log_step)-1] = fseI_coeff
        
        # Phase error
        angle_err = np.angle(rx_symIjQ_fcr[i])-np.angle(rx_symI_slcr[k]+1j*rx_symQ_slcr[k])
        # PI loop filter
        Kp = 1e-3 if(i>(NSYMB_CONVERGENCE/2)) else 0
        Ki = Kp/1000
        prop_err = Kp * angle_err
        int_err  = Ki*angle_err + int_err
        # NCO
        nco_out  = (prop_err+int_err) + nco_out
    

#####################  Bit-Error Rate
# Syncro
#LAT =  -find_delay(tx_symI_rand,rx_symI_slcr)
LAT=28
rx_symI_ber_sync = rx_symI_slcr[LAT:]
rx_symQ_ber_sync = rx_symQ_slcr[LAT:]

# Counter
phases = np.array([0, np.pi/2, np.pi, (3/2)*np.pi])
ber_I  = np.zeros(4)
ber_Q  = np.zeros(4)
for i in range(len(phases)):
    # Rotation of constellation
    rx_symIjQ_rot_4_ber = (rx_symI_ber_sync+1j*rx_symQ_ber_sync) * np.exp(1j*phases[i])
    rx_symI_rot_4_ber   = 2*(rx_symIjQ_rot_4_ber.real>0.0)-1
    rx_symQ_rot_4_ber   = 2*(rx_symIjQ_rot_4_ber.imag>0.0)-1

    # Demapper
    rx_bit_I = np.where(rx_symI_rot_4_ber == 1, 0, 1)
    rx_bit_Q = np.where(rx_symQ_rot_4_ber == 1, 0, 1)
    tx_bit_I = np.where(tx_symI_rand == 1, 0, 1)
    tx_bit_Q = np.where(tx_symQ_rand == 1, 0, 1)

    # BER counter
    error_I=0
    total_I=0
    error_Q=0
    total_Q=0
    for k in range(START_CNT,NSYMB-LAT):
        if (rx_bit_I[k] != tx_bit_I[k]):
            error_I = error_I + 1
        total_I = total_I + 1 
        if (rx_bit_Q[k] != tx_bit_Q[k]):
            error_Q = error_Q + 1
        total_Q = total_Q + 1 
    
    ber_I[i] = error_I/total_I
    ber_Q[i] = error_Q/total_Q

th_ber = theoric_ber(M, EbNo_db)

print("BER_I: ", ber_I)
print("BER_I: ", ber_Q)
print("theo_ber: ", th_ber)




fase = 1
plt.figure(figsize=[6,6])
plt.title('FSE Output I')
plt.plot(rx_symI_fse[fase:len(rx_symI_fse)-fase:2],'x')
plt.grid(True)
plt.xlabel('Nº símbolos')
plt.ylabel('I')

plt.figure(figsize=[6,6])
plt.title('FCR Output I')
plt.plot(rx_symIjQ_fcr.real[fase:len(rx_symIjQ_fcr)-fase:2],'x')
plt.grid(True)
plt.xlabel('Nº símbolos')
plt.ylabel('I')

#plt.figure(figsize=[6,6])
#plt.title('Slicer Output I')
#plt.plot(rx_symI_slcr,'x')
#plt.grid(True)
#plt.xlabel('Nº símbolos')
#plt.ylabel('I')

plt.figure(figsize=[10,6])
plt.plot(coeffs_log.T)
plt.title('Coeficientes FFE')
plt.grid(True)

plt.show()

