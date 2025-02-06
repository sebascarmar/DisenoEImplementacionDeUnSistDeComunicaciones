import numpy as np
import matplotlib.pyplot as plt
from scipy import signal


####################################################################################
#                                   LOAD DATA                                      #
####################################################################################


# ##### Downsampler (rate 2)
# rx_symI_dw_r2 = np.loadtxt('rx_symI_dw_r2.txt', delimiter=',')
# ##### AGC
# rx_symI_agc = np.loadtxt('rx_symI_agc.txt', delimiter=',')
# #### FSE
# rx_symI_fse = np.loadtxt('rx_symI_fse.txt' , delimiter=',')


# # Group of data vs time: FSE, FCR, Downsampled to rate 1, and Sliced
# plt.figure(figsize=[12,6])
# plt.suptitle('Downsampled to rate 2, AGC, FSE vs time')
# plt.subplot(3,1,1) # FSE Output
# plt.plot(rx_symI_dw_r2,
#         color='black', marker='.', linestyle='',
#         label="DW_r2 Output")
# plt.grid(True)
# plt.ylabel('Real (I)')
# plt.legend(loc=3)
# #-------------------------------------------------------
# plt.subplot(3,1,2) # FSE Output
# plt.plot(rx_symI_agc,
#         color='salmon', marker='.', linestyle='',
#         label="AGC")
# plt.grid(True)
# plt.ylabel('Real (I)')
# plt.legend(loc=3)
# #-------------------------------------------------------
# plt.subplot(3,1,3) # after downsampling to rate 1
# plt.plot(rx_symI_fse,
#         color='seagreen', marker='.', linestyle='',
#         label='FSE')
# plt.grid(True)
# plt.ylabel('Real (I)')
# plt.xlabel('Time [n]')
# plt.legend(loc=3)
# plt.savefig("dwr2_afc_fse.png", dpi=300, format='png')
# plt.close()




# ***********************************************************************************************




# #### Downsampler (rate 1)
# rx_symI_dw_r1 = np.loadtxt('rx_symI_dw_r1.txt', delimiter=',')
# #### FCR
# rx_symI_fcr = np.loadtxt('rx_symI_fcr.txt', delimiter=',')

# plt.figure(figsize=[12,6])
# plt.suptitle(' Downsampled to rate 1, FCR vs time')
# plt.subplot(2,1,1) # FCR Output
# plt.plot(rx_symI_dw_r1,
#         color='dodgerblue', marker='.', linestyle='',
#         label="DW_r1 Output")
# plt.ylabel('Real (I)')
# plt.grid(True)
# plt.legend(loc=3)
# #-------------------------------------------------------
# plt.subplot(2,1,2) # after the slicer
# plt.plot(rx_symI_fcr,
#         color='magenta', marker='.', linestyle='',
#         label="FCR")
# plt.grid(True)
# plt.ylabel('Real (I)')
# plt.xlabel('Time [n]')
# plt.legend(loc=3)
# plt.savefig("dwr1_fcr.png", dpi=300, format='png')
# plt.close()






# ***********************************************************************************************





##### Filtros
BR = 25e6
ch_filt_coeff = np.loadtxt('ch_filt_coeff.txt', delimiter=',')


# Get frequencies and magnitudes
f_cha, h_cha = signal.freqz(ch_filt_coeff, worN=800, fs=4*BR)
# Find the -3 dB point
fc_idx_ch = np.where(20*np.log10(np.abs(h_cha)) <= (20*np.log10(np.abs(h_cha[50]))-3.01))[0][0]
actual_fc_ch = f_cha[fc_idx_ch]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.semilogx(f_cha, 20*np.log10(np.abs(h_cha)), color='fuchsia')
plt.axhline(y=20*np.log10(np.abs(h_cha[50]))-3.01,
            color='black',linestyle='dashed',linewidth=2.0,
            label=f"{20*np.log10(np.abs(h_cha[50]))-3.01:.2f}dB")
plt.axvline(x=actual_fc_ch,color='gray',linewidth=2.0,
            label=f"{actual_fc_ch / 1e6:.2f}MHz")
plt.axvline(x=0.49*BR,color='coral',linewidth=2.0,
            label=f"{0.49*BR / 1e6:.2f}MHz")
plt.title("Bode - Channel Filter ({} taps)".format(len(ch_filt_coeff)))
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend(loc="lower left")
plt.grid(True)
plt.savefig("ch_filt_freq.png", dpi=300, format='png')
plt.close()



aaf_coeff = np.loadtxt('aaf_coeff.txt', delimiter=',')


# Get frequencies and magnitudes
f_aaf, h_aaf = signal.freqz(aaf_coeff, worN=800, fs=4*BR)
# Find the -3 dB point
fc_idx_aaf    = np.where(20*np.log10(np.abs(h_aaf)) <= (20*np.log10(np.abs(h_aaf[50]))-3.01))[0][0]
actual_fc_aaf = f_aaf[fc_idx_aaf]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.semilogx(f_aaf, 20*np.log10(np.abs(h_aaf)), color='mediumblue')
plt.axhline(y=20*np.log10(np.abs(h_aaf[50]))-3.01,
            color='black',linestyle='dashed',linewidth=2.0,
            label=f"{20*np.log10(np.abs(h_aaf[50]))-3.01:.2f}dB")
plt.axvline(x=actual_fc_aaf,color='gray',linewidth=2.0,
            label=f"{actual_fc_aaf / 1e6:.2f}MHz")
plt.axvline(x=BR,color='coral',linewidth=2.0,
            label=f"{BR / 1e6:.2f}MHz")
plt.title("Bode - Anti-Alias Filter ({} taps)".format(len(aaf_coeff)))
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend(loc="lower left")
plt.grid(True)
plt.savefig("aa_filt_freq.png", dpi=300, format='png')
plt.close()

# ***********************************************************************************************





##### Coeffs
fse_coeff_050k = np.loadtxt('fse_coeff_050k.txt', delimiter=',')
fse_coeff_100k = np.loadtxt('fse_coeff_100k.txt', delimiter=',')
fse_coeff_150k = np.loadtxt('fse_coeff_150k.txt', delimiter=',')
fse_coeff_200k = np.loadtxt('fse_coeff_200k.txt', delimiter=',')


# fse_coeff_120k = np.loadtxt('fse_coeff_120k.txt', delimiter=',')
MAX_Y = 20
MIN_Y = -40

# 50ksym (decimated)
OS_DSP = 2
BR = 25e6 
t = np.linspace(-0.5*(1/(OS_DSP*BR))*(len(fse_coeff_050k)-1),
                0.5*(1/(OS_DSP*BR))*(len(fse_coeff_050k)-1),
                len(fse_coeff_050k))
# Impulse response of the transmitter filter
plt.figure(figsize=[7,4])
plt.plot(t, fse_coeff_050k, color='darkcyan', marker='o',
         linestyle='-', linewidth=2.0, label="50k")
plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
plt.title('FSE Coefficients')
plt.xlabel('Sample')
plt.ylabel('Magnitud')
plt.legend(loc="upper right")
plt.grid(True)
plt.savefig("fse_coeff_050k_time.png", dpi=300, format='png')
plt.close()

# Get frequencies and magnitudes
f_fse, h_fse = signal.freqz(fse_coeff_050k, worN=800, fs=OS_DSP*BR)
# Find the -3 dB point
fc_idx = np.where(20*np.log10(np.abs(h_fse)) <= (20*np.log10(np.abs(h_fse[50])) - 3.01))[0][0]
actual_fc_fse = f_fse[fc_idx]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.semilogx(f_fse, 20*np.log10(np.abs(h_fse)), color='darkcyan')
plt.axhline(y=20*np.log10(np.abs(h_fse[50]))-3.01,
            color='black',linestyle='dashed',linewidth=2.0,
            label=f"{20*np.log10(np.abs(h_fse[50]))-3.01:.2f}dB")
plt.axvline(x=actual_fc_fse,color='gray',linewidth=2.0,
            label=f"{actual_fc_fse / 1e6:.2f}MHz")
plt.axvline(x=0.5*BR,color='coral',linewidth=2.0,
            label=f"{0.5*BR / 1e6:.2f}MHz")
plt.title("Bode - FSE (50k)")
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend(loc="lower left")
plt.ylim(MIN_Y,MAX_Y)
plt.grid(True)
plt.savefig("fse_coeff_050k_freq.png", dpi=300, format='png')
plt.close()


# 100ksym (decimated)
t = np.linspace(-0.5*(1/(OS_DSP*BR))*(len(fse_coeff_100k)-1),
                0.5*(1/(OS_DSP*BR))*(len(fse_coeff_100k)-1),
                len(fse_coeff_100k))
# Impulse response of the transmitter filter
plt.figure(figsize=[7,4])
plt.plot(t, fse_coeff_100k, color='darkcyan', marker='o',
         linestyle='-', linewidth=2.0, label="100k")
plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
plt.title('FSE Coefficients')
plt.xlabel('Sample')
plt.ylabel('Magnitud')
plt.legend(loc="upper right")
plt.grid(True)
plt.savefig("fse_coeff_100k_time.png", dpi=300, format='png')
plt.close()

# Get frequencies and magnitudes
f_fse, h_fse = signal.freqz(fse_coeff_100k, worN=800, fs=OS_DSP*BR)
# Find the -3 dB point
fc_idx = np.where(20*np.log10(np.abs(h_fse)) <= (20*np.log10(np.abs(h_fse[50])) - 3.01))[0][0]
actual_fc_fse = f_fse[fc_idx]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.semilogx(f_fse, 20*np.log10(np.abs(h_fse)), color='darkcyan')
plt.axhline(y=20*np.log10(np.abs(h_fse[50]))-3.01,
            color='black',linestyle='dashed',linewidth=2.0,
            label=f"{20*np.log10(np.abs(h_fse[50]))-3.01:.2f}dB")
plt.axvline(x=actual_fc_fse,color='gray',linewidth=2.0,
            label=f"{actual_fc_fse / 1e6:.2f}MHz")
plt.axvline(x=0.5*BR,color='coral',linewidth=2.0,
            label=f"{0.5*BR / 1e6:.2f}MHz")
plt.title("Bode - FSE (100k)")
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend(loc="lower left")
plt.ylim(MIN_Y,MAX_Y)
plt.grid(True)
plt.savefig("fse_coeff_100k_freq.png", dpi=300, format='png')
plt.close()


# 150ksym (decimated)
t = np.linspace(-0.5*(1/(OS_DSP*BR))*(len(fse_coeff_150k)-1),
                0.5*(1/(OS_DSP*BR))*(len(fse_coeff_150k)-1),
                len(fse_coeff_150k))
# Impulse response of the transmitter filter
plt.figure(figsize=[7,4])
plt.plot(t, fse_coeff_150k, color='darkcyan', marker='o',
         linestyle='-', linewidth=2.0, label="150k")
plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
plt.title('FSE Coefficients')
plt.xlabel('Sample')
plt.ylabel('Magnitud')
plt.legend(loc="upper right")
plt.grid(True)
plt.savefig("fse_coeff_150k_time.png", dpi=300, format='png')
plt.close()

# Get frequencies and magnitudes
f_fse, h_fse = signal.freqz(fse_coeff_150k, worN=800, fs=OS_DSP*BR)
# Find the -3 dB point
fc_idx = np.where(20*np.log10(np.abs(h_fse)) <= (20*np.log10(np.abs(h_fse[50])) - 3.01))[0][0]
actual_fc_fse = f_fse[fc_idx]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.semilogx(f_fse, 20*np.log10(np.abs(h_fse)), color='darkcyan')
plt.axhline(y=20*np.log10(np.abs(h_fse[50]))-3.01,
            color='black',linestyle='dashed',linewidth=2.0,
            label=f"{20*np.log10(np.abs(h_fse[50]))-3.01:.2f}dB")
plt.axvline(x=actual_fc_fse,color='gray',linewidth=2.0,
            label=f"{actual_fc_fse / 1e6:.2f}MHz")
plt.axvline(x=0.5*BR,color='coral',linewidth=2.0,
            label=f"{0.5*BR / 1e6:.2f}MHz")
plt.title("Bode - FSE (150k)")
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend(loc="lower left")
plt.ylim(MIN_Y,MAX_Y)
plt.grid(True)
plt.savefig("fse_coeff_150k_freq.png", dpi=300, format='png')
plt.close()


# 100ksym (decimated)
t = np.linspace(-0.5*(1/(OS_DSP*BR))*(len(fse_coeff_100k)-1),
                0.5*(1/(OS_DSP*BR))*(len(fse_coeff_100k)-1),
                len(fse_coeff_100k))
# Impulse response of the transmitter filter
plt.figure(figsize=[7,4])
plt.plot(t, fse_coeff_200k, color='darkcyan', marker='o',
         linestyle='-', linewidth=2.0, label="200k")
plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
plt.title('FSE Coefficients')
plt.xlabel('Sample')
plt.ylabel('Magnitud')
plt.legend(loc="upper right")
plt.grid(True)
plt.savefig("fse_coeff_200k_time.png", dpi=300, format='png')
plt.close()

# Get frequencies and magnitudes
f_fse, h_fse = signal.freqz(fse_coeff_200k, worN=800, fs=OS_DSP*BR)
# Find the -3 dB point
fc_idx = np.where(20*np.log10(np.abs(h_fse)) <= (20*np.log10(np.abs(h_fse[50])) - 3.01))[0][0]
actual_fc_fse = f_fse[fc_idx]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.semilogx(f_fse, 20*np.log10(np.abs(h_fse)), color='darkcyan')
plt.axhline(y=20*np.log10(np.abs(h_fse[50]))-3.01,
            color='black',linestyle='dashed',linewidth=2.0,
            label=f"{20*np.log10(np.abs(h_fse[50]))-3.01:.2f}dB")
plt.axvline(x=actual_fc_fse,color='gray',linewidth=2.0,
            label=f"{actual_fc_fse / 1e6:.2f}MHz")
plt.axvline(x=0.5*BR,color='coral',linewidth=2.0,
            label=f"{0.5*BR / 1e6:.2f}MHz")
plt.title("Bode - FSE (200k)")
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend(loc="lower left")
plt.ylim(MIN_Y,MAX_Y)
plt.grid(True)
plt.savefig("fse_coeff_200k_freq.png", dpi=300, format='png')
plt.close()

