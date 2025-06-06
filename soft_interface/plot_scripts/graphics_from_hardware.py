import numpy as np
import matplotlib.pyplot as plt
import math
from scipy import signal
import os


def get_snr_accurate (snr_idx):

    snr_float_values = np.array([7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0])  

    return  snr_float_values[snr_idx-8]

def load_data(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        ch_data = lines[0].strip()  # Lee el primer string
        data = np.array([float(line.strip()) for line in lines[1:]])  # Resto como float
    return ch_data, data



####################################################################################
#                                      MAIN                                        #
####################################################################################

# Parameters
NBF_AAFILT_OUT = 7   
NBF_FSE_OUT    = 9
NTAPS_FSE      = 9
NBF_FSE_TAPS   = 7
NSYMB          = 32759

# Create folder
if not os.path.exists("plots/dsp_data"):
    os.makedirs("plots/dsp_data")

### Variables
folder_save = f"plots/dsp_data"
folder = "logs/dsp_data"
snr_min = 7 
snr_max = 17
ch_fil_dws2 = ""
ch_fil_dw1  = ""
ch_fil_taps = ""

for snr in range(snr_min, (snr_max+1)):
    # Read files
    try:
        
        ch_fil_dws2, rx_symI_dw_r2_from_ver = load_data(os.path.join(folder, f"file_rx_symI_dwr2_snr_{snr}.txt"))
        ch_fil_dws2, rx_symQ_dw_r2_from_ver = load_data(os.path.join(folder, f"file_rx_symQ_dwr2_snr_{snr}.txt"))
        
        rx_symI_dw_r2 = rx_symI_dw_r2_from_ver / (2**NBF_AAFILT_OUT)
        rx_symQ_dw_r2 = rx_symQ_dw_r2_from_ver / (2**NBF_AAFILT_OUT)
        

        ch_fil_taps, fseI_taps_from_ver = load_data(os.path.join(folder, f"file_fse_taps_I_snr_{snr}.txt")) 
        ch_fil_taps, fseQ_taps_from_ver = load_data(os.path.join(folder, f"file_fse_taps_Q_snr_{snr}.txt")) 
        
        fseI_taps = fseI_taps_from_ver / (2**NBF_FSE_TAPS)
        fseQ_taps = fseQ_taps_from_ver / (2**NBF_FSE_TAPS)
        
        fse_coeff_I = np.zeros((NTAPS_FSE, int(NSYMB/NTAPS_FSE)))
        fse_coeff_Q = np.zeros((NTAPS_FSE, int(NSYMB/NTAPS_FSE)))
        for i in range(NTAPS_FSE):
            for j in range(int(NSYMB/NTAPS_FSE)):
                fse_coeff_I[i][j] = fseI_taps[i + j*NTAPS_FSE]
                fse_coeff_Q[i][j] = fseQ_taps[i + j*NTAPS_FSE]
        

        ch_fil_dws1, rx_symI_dw_r1_from_ver = load_data(os.path.join(folder, f"file_rx_symI_dwr1_snr_{snr}.txt")) 
        ch_fil_dws1, rx_symQ_dw_r1_from_ver = load_data(os.path.join(folder, f"file_rx_symQ_dwr1_snr_{snr}.txt")) 
        
        rx_symI_dw_r1 = rx_symI_dw_r1_from_ver / (2**NBF_FSE_OUT)
        rx_symQ_dw_r1 = rx_symQ_dw_r1_from_ver / (2**NBF_FSE_OUT)
        
        ############################################################################
        ##                                  PLOTS                                  #
        ############################################################################
        
        ############################# DSP signals ##########################
        snr_exact = snr


        # DSP input and output constellations
        plt.figure(figsize=[10,5])
        plt.suptitle(f'Constellation Diagrams | SNR={snr_exact}dB and BWch={ch_fil_dws2} (hwd data)', fontsize=18)
        plt.subplot(1,2,1)
        plt.plot(rx_symI_dw_r2, rx_symQ_dw_r2, color='chocolate', marker='.', linestyle='', label='DSP in')
        plt.xlim((-3, 3))
        plt.ylim((-3, 3))
        plt.xticks(fontsize=14)
        plt.yticks(fontsize=14)
        plt.gca().set_aspect('equal', adjustable='box')
        plt.grid(True)
        plt.xlabel('Real (I)', fontsize=15)
        plt.ylabel('Imag (Q)', fontsize=15)
        plt.legend(fontsize=12)
        plt.subplot(1,2,2)
        plt.plot(rx_symI_dw_r1, rx_symQ_dw_r1, color='seagreen', marker='.', linestyle='', label='DSP out')
        plt.xlim((-3, 3))
        plt.ylim((-3, 3))
        plt.xticks(fontsize=14)
        plt.yticks(fontsize=14)      
        plt.gca().set_aspect('equal', adjustable='box')
        plt.grid(True)
        plt.xlabel('Real (I)', fontsize=15)
        plt.legend(fontsize=12)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"constellation_snr{snr}.png"))
        plt.close()
        
        # DSP input and output vs. time
        plt.figure(figsize=[12,8])
        plt.suptitle(f'DSP input and output | SNR={snr_exact}dB and BWch={ch_fil_dws2} (hwd data)', fontsize=18)
        plt.subplot(2,1,1)
        plt.plot(rx_symI_dw_r2, color='chocolate', marker='.', linestyle='', label="DSP in")
        plt.ylim((-3, 3))
        plt.xticks(fontsize=14)
        plt.yticks(fontsize=14)      
        plt.ylabel('Real (I)', fontsize=15)
        plt.grid(True)
        plt.legend(fontsize=12)
        plt.subplot(2,1,2)
        plt.plot(rx_symI_dw_r1, color='seagreen', marker='.', linestyle='', label="DSP out")
        plt.ylim((-3, 3))
        plt.xticks(fontsize=14)
        plt.yticks(fontsize=14)      
        plt.xlabel('Time [n]' ,fontsize=15)
        plt.ylabel('Real (I)' ,fontsize=15)
        plt.grid(True)
        plt.legend(fontsize=12)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"symbols_time_snr{snr}.png"))
        plt.close()
        
        
        ################# Frequency and impulse response  ##################
        # Get frequencies and magnitudes
        last_fse_taps = fse_coeff_I[:NTAPS_FSE, (int(NSYMB/NTAPS_FSE))-1]
        
        f_fse, h_fse = signal.freqz(last_fse_taps, worN=800, fs=50e6)
        # Find the -3 dB point
        fc_idx = np.where(20*np.log10(np.abs(h_fse)) <= (20*np.log10(np.abs(h_fse[50])) - 3.01))[0][0]
        actual_fc_fse = f_fse[fc_idx]
        
        ## Frequency response
        plt.figure(figsize=(11, 7))
        plt.plot(f_fse, 20*np.log10(np.abs(h_fse)), color='saddlebrown')
        plt.axhline(y=20*np.log10(np.abs(h_fse[50]))-3.01,
                    color='black',linestyle='dashed',linewidth=2.0,
                    label=f"{20*np.log10(np.abs(h_fse[50]))-3.01:.2f}dB")
        plt.axvline(x=actual_fc_fse,color='gray',linewidth=2.0,
                    label=f"{actual_fc_fse / 1e6:.2f}MHz")
        plt.axvline(x=12.5e6,color='coral',linewidth=2.0,
                    label=f"{12.5e6 / 1e6:.2f}MHz")
        plt.suptitle(f'Re{"{FSE Taps}"} Bode | SNR={snr_exact}dB and BWch={ch_fil_taps} (hwd data)', fontsize=18)
        plt.xlabel("Frequency [Hz]",fontsize=15)
        plt.ylabel("Magnitud [dB]",fontsize=15)
        plt.legend(loc="lower left",fontsize=12)
        plt.ylim(-30.0,20.0)
        plt.yticks(fontsize=14)
        plt.xticks(fontsize=14)
        plt.grid(True)
        plt.legend(fontsize=12)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"bode_fse_I_snr{snr}.png"))   
        plt.close()
        
        
        ## Time axis (centered around zero)
        t = np.linspace(-0.5*(1/(50e6))*(len(last_fse_taps)-1),
                        0.5*(1/(50e6))*(len(last_fse_taps)-1),
                        len(last_fse_taps))
        # Impulse response of the transmitter filter
        plt.figure(figsize=[9,6])
        plt.plot(t, last_fse_taps, color='saddlebrown', marker='o',
                linestyle='-', linewidth=2.0)
        plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
        plt.suptitle(f'Re{"{FSE Taps}"} | SNR={snr_exact}dB and BWch={ch_fil_taps} (hwd data)', fontsize=18)    
        plt.xlabel('Sample [s]',fontsize=15)
        plt.ylabel('Magnitud',fontsize=15)
        plt.ylim(-1.5,4.0)
        plt.yticks(fontsize=14)
        plt.xticks(fontsize=14)
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"fse_coeff_impulse_snr{snr}.png"))
        plt.close()
        
        
        ## Evolution of FSE taps over time
        plt.figure(figsize=[10,6])
        plt.plot(fse_coeff_I.T)
        plt.suptitle(f'Decimated Re{"{FSE Taps}"} | SNR={snr_exact}dB and BWch={ch_fil_taps} (hwd data)',fontsize=18)        
        plt.xlabel('Time [n]',fontsize=15)
        plt.ylim(-1.5, 4.0)
        plt.yticks(fontsize=14)
        plt.xticks(fontsize=14)
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"fse_coeff_I_snr{snr}.png"))
        plt.close()
        
        plt.figure(figsize=[10,6])
        plt.plot(fse_coeff_Q.T)
        plt.suptitle(f'Decimated Im{"{FSE Taps}"} | SNR={snr_exact}dB and BWch={ch_fil_taps} (hwd data)',fontsize=18)
        plt.xlabel('Time [n]',fontsize=15)
        plt.ylim(-1.5, 4.0)
        plt.yticks(fontsize=14)
        plt.xticks(fontsize=14)
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"fse_coeff_Q_snr{snr}.png"))
        plt.close()
        
        print(f"Found logs for SNR = {snr} dB")

    except FileNotFoundError as e:
        continue


print("All plots were saved")

