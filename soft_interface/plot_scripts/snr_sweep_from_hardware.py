import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator
import math
from scipy import signal
from scipy.special import erfc
import os
import glob
import re


def get_ber_th (SNR_dB):
    #### Variables
    OS = 4  # oversampling

    # Conversión de dB a V/V
    SNR_linear = 10**(SNR_dB/10)
    # Eb/N0 para M-QAM
    EbNo = SNR_linear / np.log2(OS)
    k = np.log2(OS)
    x = np.sqrt(3 * k * EbNo / (OS - 1))
    # Fórmula de BER teórica para M-QAM
    ber = (4/k) * (1 - 1/np.sqrt(OS)) * 0.5 * erfc(x / np.sqrt(2))

    return ber

def get_snr_float (idx):
    snr_float_values = np.array([7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0])  

    return snr_float_values[idx-1]

def get_snr_hwd (variance):
    #### Variables
    OS = 4  # oversampling
    var_signal = 0.1251046972473807     # data taken from float-point simulator

    SNR_slicer  = (var_signal / (2*(variance**2))) * OS
    SNR_dB      = round(10*np.log10(SNR_slicer), 3)

    return SNR_dB

def load_data(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        ch_data = lines[0].strip()  # Lee el primer string
        data = np.array([float(line.strip()) for line in lines[1:]])  # Resto como float
    return ch_data, data




####################################################################################
#                                      MAIN                                        #
####################################################################################
# Listas para almacenar los datos
snr_exact = []
snr_hwd   = []
bits_I    = []
bits_Q    = []
errs_I    = []
errs_Q    = []
ber_th    = []
index_snr_th = 0
ch_filter = ""

# Create folder
if not os.path.exists("plots/snr_sweep"):
    os.makedirs("plots/snr_sweep")

### Variables
folder_save = "plots/snr_sweep"
folder      = "logs/snr_sweep"
snr_min     = 7 
snr_max     = 17

for snr in range(snr_min, (snr_max+1)):

    try: 
        ch_filter, snr_list = load_data(os.path.join(folder, f"sweep_with_snr_{snr}.txt"))

        index_snr_th = index_snr_th+1

        ber_th.append(get_ber_th(get_snr_float(index_snr_th)))
        snr_exact.append(get_snr_float(index_snr_th))
        snr_hwd.append(get_snr_hwd(snr_list[0]))    

        bits_I.append(int(snr_list[1]))
        bits_Q.append(int(snr_list[2]))
        errs_I.append(int(snr_list[3]))
        errs_Q.append(int(snr_list[4]))
        print(f"Found logs for SNR = {snr}dB")

    except FileNotFoundError as e:
        continue



#################  BER calculation based on hardware logged data #################
ber_i_hwd = np.array([err / ber for err, ber in zip(errs_I, bits_I)])
ber_q_hwd = np.array([err / ber for err, ber in zip(errs_Q, bits_Q)])


################## plots 
plt.figure(figsize=[7, 7])  
plt.suptitle(f'BER vs SNR | BWch={ch_filter} (hwd data)', fontsize=18)
plt.semilogy(snr_exact, ber_th, color='red', marker='x', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd, (ber_i_hwd+ber_q_hwd)/2, color='darkviolet', linestyle='--', marker='D', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.xlabel('SNR [dB]', fontsize=15)
plt.ylabel('BER', fontsize=15)
plt.grid(True, which='both')
#plt.xlim(snr_exact[0]-1, snr_exact[len(snr_exact)-1]+1)
#plt.ylim([6e-4, 2e-2])
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)
ax = plt.gca()
ax.yaxis.set_minor_locator(LogLocator(base=10.0, subs=np.arange(2, 10)*0.1, numticks=100))
ax.grid(True, which='major', linestyle='-', linewidth=0.8)
ax.grid(True, which='minor', linestyle='--', linewidth=0.5)

plt.legend(['BER theo','BER hwd'], fontsize=12)
plt.tight_layout()
plt.savefig(os.path.join(folder_save, f"ber_vs_snr_from_hwd.png"))
plt.close()

print("Plot saved")
