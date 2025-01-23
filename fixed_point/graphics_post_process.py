import numpy as np
import matplotlib.pyplot as plt
from scipy import signal


#### Simulation data
sim_data   = np.loadtxt('./logs/simulation_data.txt', delimiter=',')
#### Bits generated
tx_bitI_prbs = np.loadtxt('./logs/tx_bitI_prbs.txt', delimiter=',')
tx_bitQ_prbs = np.loadtxt('./logs/tx_bitQ_prbs.txt', delimiter=',')
#### Mapper
tx_symI_map = np.loadtxt('./logs/tx_symI_map.txt', delimiter=',')
tx_symQ_map = np.loadtxt('./logs/tx_symQ_map.txt', delimiter=',')
#### RRC Filter
rrc         = np.loadtxt('./logs/coeffs_rrc.txt', delimiter=',')
tx_symI_rrc = np.loadtxt('./logs/tx_symI_rrc.txt', delimiter=',')
tx_symQ_rrc = np.loadtxt('./logs/tx_symQ_rrc.txt', delimiter=',')
#### AWGN
ch_symI_noisy = np.loadtxt('./logs/ch_symI_noisy.txt', delimiter=',')
ch_symQ_noisy = np.loadtxt('./logs/ch_symQ_noisy.txt', delimiter=',')
#### Frecuency Offset
ch_symI_rot = np.loadtxt('./logs/ch_symI_rot.txt', delimiter=',')
ch_symQ_rot = np.loadtxt('./logs/ch_symQ_rot.txt', delimiter=',')
#### Channel filter
ch_filt_coeff   = np.loadtxt('./logs/coeffs_chfilt.txt', delimiter=',')
ch_symI_ch_filt = np.loadtxt('./logs/ch_symI_chfilt.txt', delimiter=',')
ch_symQ_ch_filt = np.loadtxt('./logs/ch_symQ_chfilt.txt', delimiter=',')
##### Anti-alias filter
aaf_coeff   = np.loadtxt('./logs/coeffs_aafilt.txt', delimiter=',')
rx_symI_aaf = np.loadtxt('./logs/rx_symI_aaf.txt', delimiter=',')
rx_symQ_aaf = np.loadtxt('./logs/rx_symQ_aaf.txt', delimiter=',')
##### Downsampler (rate 2)
rx_symI_dw_rate2 = np.loadtxt('./logs/rx_symI_dw_rate2.txt', delimiter=',')
rx_symQ_dw_rate2 = np.loadtxt('./logs/rx_symQ_dw_rate2.txt', delimiter=',')
##### AGC
rx_symI_agc = np.loadtxt('./logs/rx_symI_agc.txt', delimiter=',')
rx_symQ_agc = np.loadtxt('./logs/rx_symQ_agc.txt', delimiter=',')
#### FSE
fse_coeff   = np.loadtxt('./logs/coeffs_fse_I.txt', delimiter=',')
rx_symI_fse = np.loadtxt('./logs/rx_symI_fse.txt' , delimiter=',')
rx_symQ_fse = np.loadtxt('./logs/rx_symQ_fse.txt' , delimiter=',')
#### FCR
rx_symI_fcr = np.loadtxt('./logs/rx_symI_fcr.txt', delimiter=',')
rx_symQ_fcr = np.loadtxt('./logs/rx_symQ_fcr.txt', delimiter=',')
nco_out     = np.loadtxt('./logs/nco_out.txt'    , delimiter=',')
int_error   = np.loadtxt('./logs/int_error.txt'  , delimiter=',')
##### Downsampler (rate 1)
rx_symI_dw_rate1 = np.loadtxt('./logs/rx_symI_dw_rate1.txt', delimiter=',')
rx_symQ_dw_rate1 = np.loadtxt('./logs/rx_symQ_dw_rate1.txt', delimiter=',')
##### Slicer
rx_symI_slcr = np.loadtxt('./logs/rx_symI_slcr.txt'   , delimiter=',')
rx_symQ_slcr = np.loadtxt('./logs/rx_symQ_slcr.txt'   , delimiter=',')
##### Demapper
rx_bitI_demap = np.loadtxt('./logs/rx_bitI_demap.txt'  , delimiter=',')
rx_bitQ_demap = np.loadtxt('./logs/rx_bitQ_demap.txt'  , delimiter=',')



################################## LOGS ################################
BR = 25e6
latency       = sim_data[0]
rot_ang_detec = sim_data[1]    
SNR_db        = sim_data[2]    
f_offset      = sim_data[3]    
lms_step      = sim_data[4]    
Kp            = sim_data[5]    
fc_ch_filter  = sim_data[6]    
rate_I        = sim_data[7]    
rate_Q        = sim_data[8]    
th_ber        = sim_data[9]    
print("latency:",latency, "| ang:",rot_ang_detec)
print("SNR=", SNR_db, " | f_off=",f_offset, " | step=", lms_step, " | Kp=", Kp, " | fc_ch=", fc_ch_filter)
print("BER_I: ", rate_I)
print("BER_Q: ", rate_I)
print("theo_ber: ", th_ber)


############## TX BITS, MAPPED TO SYMB AND FILTERED SYM ################

# Generated bits and mapped to symbols 
plt.figure(figsize=[10,6])
plt.subplot(2,1,1)
plt.plot(range(len(tx_bitI_prbs)-40,len(tx_bitI_prbs)),
         tx_bitI_prbs[len(tx_bitI_prbs)-40:],
         color='dimgray', marker='o',linestyle='')
plt.title('Bits and mapped to symbs')
plt.ylabel("bit (I)")
plt.xlim(len(tx_bitI_prbs)-40,len(tx_bitI_prbs)-1)
plt.grid(True)
#------------------------------------------------------
plt.subplot(2,1,2)
plt.plot(range(len(tx_symI_map)-40,len(tx_symI_map)),
         tx_symI_map[len(tx_symI_map)-40:],
         color='black', marker='o', linestyle='')
plt.ylabel("map to sym (I)")
plt.xlim(len(tx_symI_map)-40,len(tx_symI_map)-1)
plt.grid(True)
plt.xlabel('Time [n]')
#plt.show()


# Filtered symbols (RRC filter)
plt.figure(figsize=[10,4])
plt.plot(range(len(tx_symI_rrc)-500,len(tx_symI_rrc)),
         tx_symI_rrc[len(tx_symI_rrc)-500:],
         color='green', linestyle='-',linewidth=2.0)
plt.title('Filtered sym (Tx)')
plt.xlim(len(tx_symI_rrc)-500,len(tx_symI_rrc)-1)
plt.grid(True)
plt.xlabel('Time [n]')
#plt.show()


# Constellation post RRC Filter
plt.figure(figsize=[6,6])
plt.plot(tx_symI_rrc[len(tx_symI_rrc)-1000:],
         tx_symQ_rrc[len(tx_symQ_rrc)-1000:],
         color='green', marker='.', linestyle='')
plt.title('Constellation of filtered symbs (RRC Filter)')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.grid(True)
plt.xlabel('Real (I)')
plt.ylabel('Imag (Q)')
#plt.show()


# Graficos del filtro: tiempo y frecuencia
#
#
#      DO IT
#
#




############################### CHANNEL ################################

# Transmited, noisy, rotated and with ISI symbs vs. time
plt.figure(figsize=[10,9])
#---------------------------------------------------------
plt.subplot(4,1,1)
plt.plot(range(len(tx_symI_rrc)-500,len(tx_symI_rrc)),
         tx_symI_rrc[len(tx_symI_rrc)-500:],
         color='green', linewidth=2.0)
plt.title('Transmited, noisy, rotated and with ISI symbs')
plt.xlim(len(tx_symI_rrc)-500,len(tx_symI_rrc)-1)
plt.grid(True)
#---------------------------------------------------------
plt.subplot(4,1,2)
plt.plot(range(len(ch_symI_noisy)-500,len(ch_symI_noisy)),
         ch_symI_noisy[len(ch_symI_noisy)-500:],
         color='red', linewidth=2.0)
plt.xlim(len(ch_symI_noisy)-500,len(ch_symI_noisy)-1)
plt.grid(True)
#---------------------------------------------------------
plt.subplot(4,1,3)
plt.plot(range(len(ch_symI_rot)-500,len(ch_symI_rot)),
         ch_symI_rot[len(ch_symI_rot)-500:],
         color='blue', linewidth=2.0)
plt.xlim(len(ch_symI_rot)-500,len(ch_symI_rot)-1)
plt.grid(True)
#---------------------------------------------------------
plt.subplot(4,1,4)
plt.plot(range(len(ch_symI_ch_filt)-500,len(ch_symI_ch_filt)),
         ch_symI_ch_filt[len(ch_symI_ch_filt)-500:],
         color='blueviolet', linewidth=2.0)
plt.xlim(len(ch_symI_ch_filt)-500,len(ch_symI_ch_filt)-1)
plt.grid(True)
plt.xlabel('Time [n]')
#plt.show()

# Constellation after adding noise
plt.figure(figsize=[6,6])
plt.plot(ch_symI_noisy[len(ch_symI_noisy)-2000:],
         ch_symQ_noisy[len(ch_symQ_noisy)-2000:],
         color='red', marker='.', linestyle='')
plt.title('Constellation of symbs with noise')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.grid(True)
plt.xlabel('Real (I)')
plt.ylabel('Imag (Q)')
#plt.show()

# Constellation after adding noise and apply rotation
plt.figure(figsize=[6,6])
plt.plot(ch_symI_rot[len(ch_symI_rot)-2000:],
         ch_symQ_rot[len(ch_symQ_rot)-2000:],
         color='blue', marker='.', linestyle='')
plt.title('Constellation of symbs with noise+offset')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.grid(True)
plt.xlabel('Real (I)')
plt.ylabel('Imag (Q)')
#plt.show()

# Constellation after noise+rotation+isi
plt.figure(figsize=[6,6])
plt.plot(ch_symI_ch_filt[len(ch_symI_ch_filt)-2000:],
         ch_symQ_ch_filt[len(ch_symQ_ch_filt)-2000:],
         color='blueviolet', marker='.', linestyle='')
plt.title('Constellation of symbs with noise+offset+isi')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.grid(True)
plt.xlabel('Real (I)')
plt.ylabel('Imag (Q)')
#plt.show()

## Channel Filter graphics: frequency response and time

# Get frequencies and magnitudes
f_cha, h_cha = signal.freqz(ch_filt_coeff, worN=800, fs=4*BR)
# Find the -3 dB point
cutoff_idx = np.where(20*np.log10(np.abs(h_cha)) <= -3.01)[0][0]
actual_cutoff_fc = f_cha[cutoff_idx]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.semilogx(f_cha, 20*np.log10(np.abs(h_cha)), 'b')
plt.axvline(x=fc_ch_filter,color='k',linewidth=2.0,label=f"{fc_ch_filter / 1e6:.2f}")
plt.axvline(x=actual_cutoff_fc,color='r',linewidth=2.0,label=f"{actual_cutoff_fc / 1e6:.2f}")
plt.axhline(y=-3,color='r',linewidth=2.0)
plt.title("Bode - Channel Filter ({} taps)".format(len(ch_filt_coeff)))
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend()
plt.grid(True)
#plt.show()


# Time axis (centered around zero)
t = np.linspace(-0.5*(1/BR)*(len(ch_filt_coeff)-1),
                0.5*(1/BR)*(len(ch_filt_coeff)-1),
                len(ch_filt_coeff))
# Impulse response of the channel filter
plt.figure(figsize=[8, 5])
plt.plot(t, ch_filt_coeff, 'ro-', linewidth=2.0, label=f"{len(ch_filt_coeff)} taps")
plt.axvline(0, color='k', linestyle='--', linewidth=1.5)
plt.title('Filter Coefficients - Channel Filter')
plt.xlabel('Time (s)')
plt.ylabel('Magnitud')
plt.legend()
plt.grid(True)
#plt.show()


########################### RX AA-FILTER ###############################
# Filtered symbols (anti-alias filter)
plt.figure(figsize=[10,4])
plt.plot(range(len(rx_symI_aaf)-500,len(rx_symI_aaf)),
         rx_symI_aaf[len(rx_symI_aaf)-500:],
         color='orange', linestyle='-',linewidth=2.0)
plt.title('Filtered sym (AAF)')
plt.xlim(len(rx_symI_aaf)-500,len(rx_symI_aaf)-1)
plt.grid(True)
plt.xlabel('Time [n]')
#plt.show()


# Graficos del filtro: tiempo y frecuencia
#
#
#      DO IT
#
#

## Anti Alias Filter graphics: frequency response and time

# Get frequencies and magnitudes
f_aaf, h_aaf = signal.freqz(aaf_coeff, worN=800, fs=4*BR)
# Find the -3 dB point
cutoff_idx = np.where(20*np.log10(np.abs(h_aaf)) <= -3.01)[0][0]
actual_cutoff_fc = f_aaf[cutoff_idx]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.semilogx(f_aaf, 20*np.log10(np.abs(h_aaf)), 'b')
plt.axvline(x=BR,color='k',linewidth=2.0,label=f"{BR / 1e6:.2f}")
plt.axvline(x=actual_cutoff_fc,color='r',linewidth=2.0,label=f"{actual_cutoff_fc / 1e6:.2f}")
plt.axhline(y=-3,color='r',linewidth=2.0)
plt.title("Bode - Anti-Alias Filter ({} taps)".format(len(aaf_coeff)))
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend()
plt.grid(True)
#plt.show()


# Time axis (centered around zero)
t = np.linspace(-0.5*(1/BR)*(len(aaf_coeff)-1),
                0.5*(1/BR)*(len(aaf_coeff)-1),
                len(aaf_coeff))
# Impulse response of the channel filter
plt.figure(figsize=[8, 5])
plt.plot(t, aaf_coeff, 'ro-', linewidth=2.0, label=f"{len(aaf_coeff)} taps")
plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
plt.title('Filter Coefficients - Anti-Alias Filter')
plt.xlabel('Time (s)')
plt.ylabel('Magnitud')
plt.legend()
plt.grid(True)
plt.show()


############### RX DOWNSAMP. (RATE 2) AND AGC PROCESS ###################

#Downsamp. symbols and symbols after AGC
plt.figure(figsize=[10,6])
plt.subplot(2,1,1)
plt.plot(range(len(rx_symI_dw_rate2)-500,len(rx_symI_dw_rate2)),
         rx_symI_dw_rate2[len(rx_symI_dw_rate2)-500:],
         color='chocolate', linestyle='-', linewidth=2.0)
plt.xlim(len(rx_symI_dw_rate2)-500,len(rx_symI_dw_rate2)-1)
plt.title('Downsampled symbs (rate 2) and symbs after AGC')
plt.xlim(len(rx_symI_dw_rate2)-500,len(rx_symI_dw_rate2)-1)
plt.grid(True)
#------------------------------------------------------
plt.subplot(2,1,2)
plt.plot(range(len(rx_symI_agc)-500,len(rx_symI_agc)),
         rx_symI_agc[len(rx_symI_agc)-500:],
         color='brown', linestyle='-', linewidth=2.0)
plt.ylabel("map to sym (I)")
plt.xlim(len(rx_symI_agc)-500,len(rx_symI_agc)-1)
plt.grid(True)
plt.xlabel('Time [n]')
#plt.show()


##############################  FSE AND FCR #############################
# FSE&FCR output vs time
plt.figure(figsize=[10,6])
plt.subplot(2,1,1)
plt.title('FSE Output I')
plt.plot(rx_symI_fse,
         color='salmon', marker='.', linestyle='')
plt.grid(True)
plt.subplot(2,1,2)
plt.title('FCR Output I')
plt.plot(rx_symI_fcr,
         color='dodgerblue', marker='.', linestyle='')
plt.grid(True)
plt.xlabel('Time [n]')
#plt.show()

# Constellation of FSE output
plt.figure(figsize=[6,6])
plt.plot(rx_symI_fse[len(rx_symI_fse)-8000:],
         rx_symQ_fse[len(rx_symQ_fse)-8000:],
         color='salmon', marker='.', linestyle='')
plt.title('Constellation of FSE output')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.grid(True)
plt.xlabel('Real (I)')
plt.ylabel('Imag (Q)')
#plt.show()

# Constellation of FCR output
plt.figure(figsize=[6,6])
plt.plot(rx_symI_fcr[len(rx_symI_fcr)-8000:],
         rx_symQ_fcr[len(rx_symQ_fcr)-8000:],
         color='dodgerblue', marker='.', linestyle='')
plt.title('Constellation of FCR output')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.grid(True)
plt.xlabel('Real')
plt.ylabel('Imag')
#plt.show()

#################################  FSE #################################

# Evolution of FSE coeffcients over time
plt.figure(figsize=[10,6])
plt.plot(fse_coeff.T)
plt.title('Coeficientes FSE')
plt.grid(True)
#plt.show()

#################################  FCR #################################

# NCO (phase) vs time
fase = 1
plt.figure(figsize=[10,4])
plt.title('NCO Output')
plt.plot(nco_out[fase:len(nco_out)-fase:2],
        color='gold', marker='.')
plt.grid(True)
plt.xlabel('Time [n]')
plt.ylabel('rad')
#plt.show()

# Integral error vs time
plt.figure(figsize=[10,4])
plt.title('Integral error')
plt.plot(int_error[fase:len(int_error)-fase:2]*BR/(2*np.pi),
         color='olive', marker='.')
plt.grid(True)
plt.xlabel('Time [n]')
plt.ylabel('[Hz]')
#plt.show()


################### DOWNSAMP., SLICER AND DEMAPPER #####################
# Downsampled symbs and sliced vs time
plt.figure(figsize=[10,6])
plt.subplot(2,1,1)
plt.plot(rx_symI_dw_rate1,
         color='seagreen', marker='.', linestyle='')
plt.title('Downsampled symbs and sliced symbs')
plt.grid(True)
plt.subplot(2,1,2)
plt.plot(rx_symI_slcr,
         color='magenta', marker='.', linestyle='')
plt.grid(True)
plt.xlabel('Time [n]')
#plt.show()


# Downsampled symbs, sliced, and demapped to bit (dots)
plt.figure(figsize=[10,6])
#--------------------------------------------------------------
plt.subplot(3,1,1)
plt.plot(range(len(rx_symI_dw_rate1)-40,len(rx_symI_dw_rate1)),
         rx_symI_dw_rate1[len(rx_symI_dw_rate1)-40:],
         color='seagreen', marker='o', linestyle='')
plt.title('Downsampled symbs (rate 1), sliced, and demapped to bit')
plt.grid(True)
plt.ylabel("dwsam. (I)")
plt.xlim(len(rx_symI_dw_rate1)-40,len(rx_symI_dw_rate1)-1)
#--------------------------------------------------------------
plt.subplot(3,1,2)
plt.plot(range(len(rx_symI_slcr)-40,len(rx_symI_slcr)),
         rx_symI_slcr[len(rx_symI_slcr)-40:],
         color='magenta', marker='o', linestyle='')
plt.grid(True)
plt.ylabel("sliced (I)")
plt.xlim(len(rx_symI_slcr)-40,len(rx_symI_slcr)-1)
#--------------------------------------------------------------
plt.subplot(3,1,3)
plt.plot(range(len(rx_bitI_demap)-40,len(rx_bitI_demap)),
         rx_bitI_demap[len(rx_bitI_demap)-40:],
         color='teal', marker='o', linestyle='')
plt.grid(True)
plt.ylabel("demap to bit (I)")
plt.xlabel('Time [n]')
plt.xlim(len(rx_bitI_demap)-40,len(rx_bitI_demap)-1)
#plt.show()


# Constellation of dowsampled symbols (rate 1)
plt.figure(figsize=[6,6])
plt.plot(rx_symI_dw_rate1[len(rx_symI_dw_rate1)-4000:],
         rx_symQ_dw_rate1[len(rx_symQ_dw_rate1)-4000:],
         color='seagreen', marker='.', linestyle='')
plt.title('Constellation of dowsamp. symbs (rate 1)')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.grid(True)
plt.xlabel('Real (I)')
plt.ylabel('Imag (Q)')
#plt.show()


# Constellation of sliced symbols
plt.figure(figsize=[6,6])
plt.plot(rx_symI_slcr[len(rx_symI_slcr)-4000:],
         rx_symQ_slcr[len(rx_symQ_slcr)-4000:],
         color='magenta', marker='.', linestyle='')
plt.title('Constellation of sliced symbs')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.grid(True)
plt.xlabel('Real (I)')
plt.ylabel('Imag (Q)')
plt.show()

