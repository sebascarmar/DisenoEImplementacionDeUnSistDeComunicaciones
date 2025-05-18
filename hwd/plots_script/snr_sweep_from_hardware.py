import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator
import math
from scipy import signal
from scipy.special import erfc
import os
import glob
import re


def get_snr_th (variance):
    #### Variables
    OS = 4  # oversampling
    var_signal = 0.1251046972473807     # data taken from float-point simulator

    SNR_slicer  = (var_signal / (2*(variance**2))) * OS
    SNR_dB      = round(10*np.log10(SNR_slicer), 3)

    # Conversión de dB a V/V
    SNR_linear = 10**(SNR_dB/10)
    # Eb/N0 para M-QAM
    EbNo = SNR_linear / np.log2(OS)
    k = np.log2(OS)
    x = np.sqrt(3 * k * EbNo / (OS - 1))
    # Fórmula de BER teórica para M-QAM
    ber = (4/k) * (1 - 1/np.sqrt(OS)) * 0.5 * erfc(x / np.sqrt(2))

    return ber, SNR_dB

####################################################################################
#                                      MAIN                                        #
####################################################################################
# Listas para almacenar los datos
snr_exact = []
bits_I    = []
bits_Q    = []
errs_I    = []
errs_Q    = []
ber_th    = []

# Create folder
if not os.path.exists("plots"):
    os.makedirs("plots")

### Variables
folder_save = "plots"
folder      = "logs"
snr_min     = 7 
snr_max     = 17

for snr in range(snr_min, (snr_max+1)):

    try: 
        snr_list = np.loadtxt(os.path.join(folder, f"sweep_with_snr_{snr}.txt"))
            
        ber_aux,snr_aux = get_snr_th(float(snr_list[0]))

        ber_th.append(ber_aux)
        snr_exact.append(snr_aux)
        bits_I.append(int(snr_list[1]))
        bits_Q.append(int(snr_list[2]))
        errs_I.append(int(snr_list[3]))
        errs_Q.append(int(snr_list[4]))
        print(f"Found logs for SNR = {snr} dB")

    except FileNotFoundError as e:
        continue
       

#################  BER calculation based on hardware logged data #################
ber_i_hwd = np.array([err / ber for err, ber in zip(errs_I, bits_I)])
ber_q_hwd = np.array([err / ber for err, ber in zip(errs_Q, bits_Q)])

for i in range(len(ber_i_hwd)):
    ber_i_hwd[i] = round(ber_i_hwd[i],3)
    ber_q_hwd[i] = round(ber_q_hwd[i],3)


################## plots 
plt.figure(figsize=[7, 7])  
plt.title('BER vs SNR (data from hardware)')
plt.semilogy(snr_exact, ber_th, color='red', linewidth=2.0)
plt.semilogy(snr_exact, (ber_i_hwd+ber_q_hwd)/2, color='blue', linewidth=2.0)
plt.xlabel('SNR [dB]')
plt.ylabel('BER')
plt.grid(True, which='both')
#plt.xlim(snr_exact[0]-1, snr_exact[len(snr_exact)-1]+1)
#plt.ylim([6e-4, 2e-2])
ax = plt.gca()
ax.yaxis.set_minor_locator(LogLocator(base=10.0, subs=np.arange(2, 10)*0.1, numticks=100))
ax.grid(True, which='major', linestyle='-', linewidth=0.8)
ax.grid(True, which='minor', linestyle='--', linewidth=0.5)

plt.legend(['BER theo','BER hwd'])
plt.tight_layout()
plt.savefig(os.path.join(folder_save, f"ber_vs_snr_from_hwd.png"))
plt.close()

print("Plot saved")

