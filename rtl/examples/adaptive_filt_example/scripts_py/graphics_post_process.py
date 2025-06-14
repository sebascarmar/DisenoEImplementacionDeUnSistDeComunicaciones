import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import os


####################################################################################
#                                   LOAD DATA                                      #
####################################################################################
logs_absPath = os.path.join(os.path.dirname(__file__), 'logs')


#### Simulation data
sim_data   = np.loadtxt(os.path.join(logs_absPath, 'simulation_data.txt'), delimiter=',')
##### Bits generated
#tx_bitI_prbs = np.loadtxt(os.path.join(logs_absPath, 'tx_bitI_prbs.txt'), delimiter=',')
#tx_bitQ_prbs = np.loadtxt(os.path.join(logs_absPath, 'tx_bitQ_prbs.txt'), delimiter=',')
##### Mapper
#tx_symI_map = np.loadtxt(os.path.join(logs_absPath, 'tx_symI_map.txt'), delimiter=',')
#tx_symQ_map = np.loadtxt(os.path.join(logs_absPath, 'tx_symQ_map.txt'), delimiter=',')
##### RRC Filter
#txf_coeff   = np.loadtxt(os.path.join(logs_absPath, 'coeffs_txf.txt'), delimiter=',')
#tx_symI_txf = np.loadtxt(os.path.join(logs_absPath, 'tx_symI_txf.txt'), delimiter=',')
#tx_symQ_txf = np.loadtxt(os.path.join(logs_absPath, 'tx_symQ_txf.txt'), delimiter=',')
##### AWGN
#ch_symI_noisy = np.loadtxt(os.path.join(logs_absPath, 'ch_symI_noisy.txt'), delimiter=',')
#ch_symQ_noisy = np.loadtxt(os.path.join(logs_absPath, 'ch_symQ_noisy.txt'), delimiter=',')
##### Frecuency Offset
#ch_symI_rot = np.loadtxt(os.path.join(logs_absPath, 'ch_symI_rot.txt'), delimiter=',')
#ch_symQ_rot = np.loadtxt(os.path.join(logs_absPath, 'ch_symQ_rot.txt'), delimiter=',')
##### Channel filter
#ch_filt_coeff   = np.loadtxt(os.path.join(logs_absPath, 'coeffs_chfilt.txt'), delimiter=',')
#ch_symI_ch_filt = np.loadtxt(os.path.join(logs_absPath, 'ch_symI_chfilt.txt'), delimiter=',')
#ch_symQ_ch_filt = np.loadtxt(os.path.join(logs_absPath, 'ch_symQ_chfilt.txt'), delimiter=',')
###### Anti-alias filter
#aaf_coeff   = np.loadtxt(os.path.join(logs_absPath, 'coeffs_aafilt.txt'), delimiter=',')
#rx_symI_aaf = np.loadtxt(os.path.join(logs_absPath, 'rx_symI_aaf.txt'), delimiter=',')
#rx_symQ_aaf = np.loadtxt(os.path.join(logs_absPath, 'rx_symQ_aaf.txt'), delimiter=',')
###### Downsampler (rate 2)
rx_symI_dw_r2 = np.loadtxt(os.path.join(logs_absPath, 'rx_symI_dw_rate2.txt'), delimiter=',')
rx_symQ_dw_r2 = np.loadtxt(os.path.join(logs_absPath, 'rx_symQ_dw_rate2.txt'), delimiter=',')
rx_symI_dw_r2_from_ver = np.loadtxt("file_rx_symI_dw_r2.txt", dtype=np.intp)
rx_symQ_dw_r2_from_ver = np.loadtxt("file_rx_symQ_dw_r2.txt", dtype=np.intp)
#convierte al valor correspondiente al formato de punto fijo S(8.7)
frac_bits = 7
rx_symI_dw_r2 = rx_symI_dw_r2_from_ver / (2**frac_bits)
rx_symQ_dw_r2 = rx_symQ_dw_r2_from_ver / (2**frac_bits)
print("Fragmento de salidas del dwsamp tasa2 I y Q")
#print(rx_symI_dw_r2[0:50])
print(rx_symQ_dw_r2[0:50])
##### FSE
fse_coeff   = np.loadtxt(os.path.join(logs_absPath, 'coeffs_fse_I.txt'), delimiter=',')
rx_symI_fse = np.loadtxt(os.path.join(logs_absPath, 'rx_symI_fse.txt'), delimiter=',')
rx_symQ_fse = np.loadtxt(os.path.join(logs_absPath, 'rx_symQ_fse.txt'), delimiter=',')
##### FCR
rx_symI_fcr = np.loadtxt(os.path.join(logs_absPath, 'rx_symI_fcr.txt'), delimiter=',')
rx_symQ_fcr = np.loadtxt(os.path.join(logs_absPath, 'rx_symQ_fcr.txt'), delimiter=',')
#nco_log     = np.loadtxt(os.path.join(logs_absPath, 'nco_out.txt'), delimiter=',')
#int_err_log = np.loadtxt(os.path.join(logs_absPath, 'int_error.txt'), delimiter=',')
###### Downsampler (rate 1)
rx_symI_dw_r1 = np.loadtxt(os.path.join(logs_absPath, 'rx_symI_dw_rate1.txt'), delimiter=',')
rx_symQ_dw_r1 = np.loadtxt(os.path.join(logs_absPath, 'rx_symQ_dw_rate1.txt'), delimiter=',')
###### Slicer
rx_symI_slcr = np.loadtxt(os.path.join(logs_absPath, 'rx_symI_slcr.txt'), delimiter=',')
rx_symQ_slcr = np.loadtxt(os.path.join(logs_absPath, 'rx_symQ_slcr.txt'), delimiter=',')
###### Demapper
rx_bitI_demap = np.loadtxt(os.path.join(logs_absPath, 'rx_bitI_demap.txt'), delimiter=',')
rx_bitQ_demap = np.loadtxt(os.path.join(logs_absPath, 'rx_bitQ_demap.txt'), delimiter=',')


print("Fragmento de salidas del fse I y Q")
#print(rx_symI_fse[0:50])
print(rx_symQ_fse[0:50])

print("Fragmento de salidas del dw tasa1 I y Q")
#print(rx_symI_dw_r1[0:50])
print(rx_symQ_dw_r1[0:50])


dwI_r1_aux = rx_symI_fse[1:len(rx_symI_fse)-1:2]
dwQ_r1_aux = rx_symQ_fse[1:len(rx_symQ_fse)-1:2]
print(dwQ_r1_aux[0:50])
input()
rx_symI_dw_r1 =dwI_r1_aux
rx_symQ_dw_r1 =dwQ_r1_aux
####################################################################################
#                                 SIMULATION DATA                                  #
####################################################################################

BR     = 25e6
OS     = 4
OS_DSP = 2
latency       = sim_data[ 0]
rot_ang_detec = sim_data[ 1]    
SNR_db        = sim_data[ 2]    
f_offset      = sim_data[ 3]    
lms_step      = sim_data[ 4]    
lms_leak      = sim_data[ 5]    
Kp            = sim_data[ 6]    
Ki            = sim_data[ 7]    
fc_ch_filter  = sim_data[ 8]    
fc_aa_filter  = sim_data[ 9]    
rate_I        = sim_data[10]    
rate_Q        = sim_data[11]    
th_ber        = sim_data[12]    
print("latency:",latency, "| ang:",rot_ang_detec)
print("SNR=", SNR_db, " | f_off=",f_offset, " | step=", lms_step, " | leak=", lms_leak)
print("Kp=", Kp, " | Ki=", Ki, " | fc_ch=", fc_ch_filter, " | fc_aaf=",fc_aa_filter, )
print("BER_I: ", rate_I)
print("BER_Q: ", rate_Q)
print("theo_ber: ", th_ber)



#####################################################################################
##       PROGRESSION OF SIGNAL PROCESSING STAGES IN THE COMMUNICATION SYSTEM        #
#####################################################################################
#
###################### TX BITS AND MAPPED TO SYMB #######################
## Generated bits and mapped to symbols 
#plt.figure(figsize=[10,4])
#plt.subplot(2,1,1)
#plt.plot(range(len(tx_bitI_prbs)-40,len(tx_bitI_prbs)),
#        tx_bitI_prbs[len(tx_bitI_prbs)-40:],
#        color='dimgray', marker='o',linestyle='')
#plt.title('Bits and mapped to symbs')
#plt.ylabel("bit (I)")
#plt.xlim(len(tx_bitI_prbs)-40,len(tx_bitI_prbs)-1)
#plt.grid(True)
##------------------------------------------------------
#plt.subplot(2,1,2)
#plt.plot(range(len(tx_symI_map)-40,len(tx_symI_map)),
#        tx_symI_map[len(tx_symI_map)-40:],
#        color='black', marker='o', linestyle='')
#plt.ylabel("map to sym (I)")
#plt.xlim(len(tx_symI_map)-40,len(tx_symI_map)-1)
#plt.grid(True)
#plt.xlabel('Time [n]')
##plt.show()
#
#
################################ CHANNEL ################################
## Group of data vs time: Filtered (Tx), Noisy, Rotated and with ISI symbs
#plt.figure(figsize=[10,9])
##---------------------------------------------------------
#plt.subplot(4,1,1)
#plt.plot(range(len(tx_symI_txf)-500,len(tx_symI_txf)),
#        tx_symI_txf[len(tx_symI_txf)-500:],
#        color='green', linewidth=2.0)
#plt.title('Transmited, noisy, rotated and with ISI symbs')
#plt.xlim(len(tx_symI_txf)-500,len(tx_symI_txf)-1)
#plt.grid(True)
##---------------------------------------------------------
#plt.subplot(4,1,2)
#plt.plot(range(len(ch_symI_noisy)-500,len(ch_symI_noisy)),
#        ch_symI_noisy[len(ch_symI_noisy)-500:],
#        color='red', linewidth=2.0)
#plt.xlim(len(ch_symI_noisy)-500,len(ch_symI_noisy)-1)
#plt.grid(True)
##---------------------------------------------------------
#plt.subplot(4,1,3)
#plt.plot(range(len(ch_symI_rot)-500,len(ch_symI_rot)),
#        ch_symI_rot[len(ch_symI_rot)-500:],
#        color='blue', linewidth=2.0)
#plt.xlim(len(ch_symI_rot)-500,len(ch_symI_rot)-1)
#plt.grid(True)
##---------------------------------------------------------
#plt.subplot(4,1,4)
#plt.plot(range(len(ch_symI_ch_filt)-500,len(ch_symI_ch_filt)),
#        ch_symI_ch_filt[len(ch_symI_ch_filt)-500:],
#        color='blueviolet', linewidth=2.0)
#plt.xlim(len(ch_symI_ch_filt)-500,len(ch_symI_ch_filt)-1)
#plt.grid(True)
#plt.xlabel('Time [n]')
##plt.show()
#
#
## Group of constellations: Filtered (Tx), Noisy, Rotated, and with ISI symbs
#plt.figure(figsize=[8,8])
#plt.suptitle('Constellation Diagrams: Filtered, Noisy, Rotated, and with ISI')
#plt.subplot(2,2,1)
#plt.plot(tx_symI_txf[len(tx_symI_txf)-1000:],
#        tx_symQ_txf[len(tx_symQ_txf)-1000:],
#        color='green', marker='.', linestyle='',
#        label="RRC Filt. Output")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.axis('equal')
#plt.grid(True)
#plt.ylabel('Imag (Q)')
#plt.legend(loc="upper left")
##-------------------------------------------------------
#plt.subplot(2,2,2) # after adding noise
#plt.plot(ch_symI_noisy[len(ch_symI_noisy)-2000:],
#        ch_symQ_noisy[len(ch_symQ_noisy)-2000:],
#        color='red', marker='.', linestyle='',
#        label="with noise")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.axis('equal')
#plt.grid(True)
#plt.legend(loc="upper left")
##-------------------------------------------------------
#plt.subplot(2,2,3) # after adding noise and apply rotation
#plt.plot(ch_symI_rot[len(ch_symI_rot)-2000:],
#        ch_symQ_rot[len(ch_symQ_rot)-2000:],
#        color='blue', marker='.', linestyle='',
#        label="with noise and rotated")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.axis('equal')
#plt.grid(True)
#plt.xlabel('Real (I)')
#plt.ylabel('Imag (Q)')
#plt.legend(loc="upper left")
##-------------------------------------------------------
#plt.subplot(2,2,4) # after noise+rotation+isi
#plt.plot(ch_symI_ch_filt[len(ch_symI_ch_filt)-2000:],
#        ch_symQ_ch_filt[len(ch_symQ_ch_filt)-2000:],
#        color='blueviolet', marker='.', linestyle='',
#        label="with noise, rotated and with isi")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.axis('equal')
#plt.grid(True)
#plt.xlabel('Real (I)')
#plt.legend(loc="upper left")
##plt.show()
#
#
############## RX AA-FILTER AND RX DOWNSAMP. (RATE 2) ##################
#
## Filtered symbols (anti-alias filter) and downsamp. symbols
#plt.figure(figsize=[10,6])
#plt.subplot(2,1,1)
#plt.plot(range(len(rx_symI_aaf)-500,len(rx_symI_aaf)),
#       rx_symI_aaf[len(rx_symI_aaf)-500:],
#       color='orange', linestyle='-',linewidth=2.0)
#plt.title('Filtered sym (AAF) and Downsampled symbs (rate 2)')
#plt.xlim(len(rx_symI_aaf)-500,len(rx_symI_aaf)-1)
#plt.grid(True)
##------------------------------------------------------
#plt.subplot(2,1,2)
#plt.plot(range(len(rx_symI_dw_r2)-500,len(rx_symI_dw_r2)),
#       rx_symI_dw_r2[len(rx_symI_dw_r2)-500:],
#       color='chocolate', linestyle='-', linewidth=2.0)
#plt.xlim(len(rx_symI_dw_r2)-500,len(rx_symI_dw_r2)-1)
#plt.grid(True)
#plt.xlabel('Time [n]')
##plt.show()


############################## DSP #################################
# Group of constellations: FSE, FCR, Downsampled to rate 1, and Sliced
plt.figure(figsize=[8,8])
plt.suptitle('Constellation Diagrams: FSE, FCR, Downsampled to rate 1, and Sliced')
plt.subplot(2,2,1) # FSE Output
plt.plot(rx_symI_fse[len(rx_symI_fse)-8000:],
        rx_symQ_fse[len(rx_symQ_fse)-8000:],
        color='salmon', marker='.', linestyle='',
        label="FSE Output")
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.axis('equal')
plt.grid(True)
plt.ylabel('Imag (Q)')
plt.legend()
#-------------------------------------------------------
plt.subplot(2,2,2) # after downsampling to rate 1
plt.plot(rx_symI_dw_r1[len(rx_symI_dw_r1)-4000:],
        rx_symQ_dw_r1[len(rx_symQ_dw_r1)-4000:],
        color='seagreen', marker='.', linestyle='',
        label='dowsamp. (rate 1)')
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.axis('equal')
plt.grid(True)
plt.legend(loc="upper left")
#-------------------------------------------------------
plt.subplot(2,2,3) # FCR Output
plt.plot(rx_symI_fcr[len(rx_symI_fcr)-4000:],
        rx_symQ_fcr[len(rx_symQ_fcr)-4000:],
        color='dodgerblue', marker='.', linestyle='',
        label="FCR Output")
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.axis('equal')
plt.grid(True)
plt.xlabel('Real (I)')
plt.ylabel('Imag (Q)')
plt.legend(loc="upper left")
#-------------------------------------------------------
plt.subplot(2,2,4) # after the slicer
plt.plot(rx_symI_slcr[len(rx_symI_slcr)-4000:],
        rx_symQ_slcr[len(rx_symQ_slcr)-4000:],
        color='magenta', marker='.', linestyle='',
        label="sliced")
plt.xlim((-2, 2))
plt.ylim((-2, 2))
plt.axis('equal')
plt.grid(True)
plt.xlabel('Real (I)')
plt.legend(loc="upper left")
#plt.show()


# Group of data vs time: FSE, FCR, Downsampled to rate 1, and Sliced
plt.figure(figsize=[12,6])
plt.suptitle('FSE, FCR, Downsampled to rate 1, and Sliced vs time')
plt.subplot(2,2,1) # FSE Output
plt.plot(rx_symI_fse,
        color='salmon', marker='.', linestyle='',
        label="FSE Output")
plt.grid(True)
plt.ylabel('Real (I)')
plt.legend(loc="upper left")
#-------------------------------------------------------
plt.subplot(2,2,2) # after downsampling to rate 1
plt.plot(rx_symI_dw_r1,
        color='seagreen', marker='.', linestyle='',
        label='dowsamp. (rate 1)')
plt.grid(True)
plt.legend(loc="upper left")
#-------------------------------------------------------
plt.subplot(2,2,3) # FCR Output
plt.plot(rx_symI_fcr,
        color='dodgerblue', marker='.', linestyle='',
        label="FCR Output")
plt.ylabel('Real (I)')
plt.xlabel('Time [n]')
plt.grid(True)
plt.legend(loc="upper left")
#-------------------------------------------------------
plt.subplot(2,2,4) # after the slicer
plt.plot(rx_symI_slcr,
        color='magenta', marker='.', linestyle='',
        label="sliced")
plt.grid(True)
plt.xlabel('Time [n]')
plt.legend(loc="upper left")
plt.show()



####################################################################################
#            FREQUENCY RESPONSE AND COEFFICIENTS OF THE SYSTEM FILTERS             #
####################################################################################

############################## TX FILTER ###############################
### Transmitter Filter graphics: frequency response and time
#
## Get frequencies and magnitudes
#f_txf, h_txf = signal.freqz(txf_coeff[:-3], worN=800, fs=OS*BR)
## Find the -3 dB point
#fc_idx_txf = np.where(20*np.log10(np.abs(h_txf)) <= (20*np.log10(np.abs(h_txf[50]))-3.01))[0][0]
#actual_fc_txf = f_txf[fc_idx_txf]
### Frequency response of the channel filter
#plt.figure(figsize=(8, 5))
#plt.plot(f_txf, 20*np.log10(np.abs(h_txf)), color='darkcyan')
#plt.axhline(y=20*np.log10(np.abs(h_txf[50]))-3.01,
#           color='black',linestyle='dashed',linewidth=2.0,
#           label=f"{20*np.log10(np.abs(h_txf[50]))-3.01:.2f}dB")
#plt.axvline(x=actual_fc_txf,color='gray',linewidth=2.0,
#           label=f"{actual_fc_txf / 1e6:.2f}MHz")
#plt.axvline(x=0.5*BR,color='coral',linewidth=2.0,
#           label=f"{0.5*BR / 1e6:.2f}MHz")
#plt.title("Bode - Transmitter Filter ({} taps)".format(len(txf_coeff[:-3])))
#plt.xlabel("Frequency [Hz]")
#plt.ylabel("Magnitud [dB]")
#plt.legend(loc="lower left")
#plt.grid(True)
##plt.show()
#
#
## Time axis (centered around zero)
#t = np.linspace(-0.5*(1/(OS*BR))*(len(txf_coeff[:-3])-1),
#                0.5*(1/(OS*BR))*(len(txf_coeff[:-3])-1),
#                len(txf_coeff[:-3]))
## Impulse response of the transmitter filter
#plt.figure(figsize=[7,4])
#plt.plot(t, txf_coeff[:-3], color='darkcyan', marker='o',
#         linestyle='-', linewidth=2.0, label=f"{len(txf_coeff[:-3])} taps")
#plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
#plt.title('Transmitter Filter Coefficients')
#plt.xlabel('Time (s)')
#plt.ylabel('Magnitud')
#plt.legend(loc="upper right")
#plt.grid(True)
##plt.show()
#
#
########################### CHANNEL FILTER ##############################
### Channel Filter graphics: frequency response and time
#
## Get frequencies and magnitudes
#f_cha, h_cha = signal.freqz(ch_filt_coeff, worN=800, fs=4*BR)
## Find the -3 dB point
#fc_idx_ch = np.where(20*np.log10(np.abs(h_cha)) <= (20*np.log10(np.abs(h_cha[50]))-3.01))[0][0]
#actual_fc_ch = f_cha[fc_idx_ch]
### Frequency response of the channel filter
#plt.figure(figsize=(8, 5))
#plt.plot(f_cha, 20*np.log10(np.abs(h_cha)), color='fuchsia')
#plt.axhline(y=20*np.log10(np.abs(h_cha[50]))-3.01,
#           color='black',linestyle='dashed',linewidth=2.0,
#           label=f"{20*np.log10(np.abs(h_cha[50]))-3.01:.2f}dB")
#plt.axvline(x=actual_fc_ch,color='gray',linewidth=2.0,
#           label=f"{actual_fc_ch / 1e6:.2f}MHz")
#plt.axvline(x=fc_ch_filter,color='coral',linewidth=2.0,
#           label=f"{fc_ch_filter / 1e6:.2f}MHz")
#plt.title("Bode - Channel Filter ({} taps)".format(len(ch_filt_coeff)))
#plt.xlabel("Frequency [Hz]")
#plt.ylabel("Magnitud [dB]")
#plt.legend(loc="lower left")
#plt.grid(True)
##plt.show()
#
#
## Time axis (centered around zero)
#t = np.linspace(-0.5*(1/(OS*BR))*(len(ch_filt_coeff)-1),
#               0.5*(1/(OS*BR))*(len(ch_filt_coeff)-1),
#               len(ch_filt_coeff))
## Impulse response of the channel filter
#plt.figure(figsize=[7, 4])
#plt.plot(t, ch_filt_coeff, color='fuchsia', marker='o',
#        linestyle='-', linewidth=2.0, label=f"{len(ch_filt_coeff)} taps")
#plt.axvline(0, color='k', linestyle='--', linewidth=1.5)
#plt.title('Channel Filter Coefficients')
#plt.xlabel('Time (s)')
#plt.ylabel('Magnitud')
#plt.legend(loc="upper right")
#plt.grid(True)
##plt.show()
#
#
############################ RX AA-FILTER ###############################
### Anti Alias Filter graphics: frequency response and time
#
## Get frequencies and magnitudes
#f_aaf, h_aaf = signal.freqz(aaf_coeff, worN=800, fs=4*BR)
#h_aaf = np.where(np.abs(h_aaf)<=1e-12, 1e-12, h_aaf)  # Replace zeros
## Find the -3 dB point
#fc_idx_aaf    = np.where(20*np.log10(np.abs(h_aaf)) <= (20*np.log10(np.abs(h_aaf[50]))-3.01))[0][0]
#actual_fc_aaf = f_aaf[fc_idx_aaf]
### Frequency response of the channel filter
#plt.figure(figsize=(8, 5))
#plt.plot(f_aaf, 20*np.log10(np.abs(h_aaf)), color='mediumblue')
#plt.axhline(y=20*np.log10(np.abs(h_aaf[50]))-3.01,
#           color='black',linestyle='dashed',linewidth=2.0,
#           label=f"{20*np.log10(np.abs(h_aaf[50]))-3.01:.2f}dB")
#plt.axvline(x=actual_fc_aaf,color='gray',linewidth=2.0,
#           label=f"{actual_fc_aaf / 1e6:.2f}MHz")
#plt.axvline(x=fc_aa_filter,color='coral',linewidth=2.0,
#           label=f"{fc_aa_filter / 1e6:.2f}MHz")
#plt.title("Bode - Anti-Alias Filter ({} taps)".format(len(aaf_coeff)))
#plt.xlabel("Frequency [Hz]")
#plt.ylabel("Magnitud [dB]")
#plt.legend(loc="lower left")
#plt.grid(True)
##plt.show()
#
#
## Time axis (centered around zero)
#t = np.linspace(-0.5*(1/(OS*BR))*(len(aaf_coeff)-1),
#               0.5*(1/(OS*BR))*(len(aaf_coeff)-1),
#               len(aaf_coeff))
## Impulse response of the channel filter
#plt.figure(figsize=[7, 4])
#plt.plot(t, aaf_coeff, color='mediumblue', marker='o',
#        linestyle='-', linewidth=2.0, label=f"{len(aaf_coeff)} taps")
#plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
#plt.title('Anti-Alias Filter Coefficients')
#plt.xlabel('Time (s)')
#plt.ylabel('Magnitud')
#plt.legend(loc="upper right")
#plt.grid(True)
##plt.show()


################################# FSE ##################################

## Adapatvie Filter graphics: frequency response and time

# Get frequencies and magnitudes
last_fse_taps = fse_coeff[:,len(fse_coeff)-1]

f_fse, h_fse = signal.freqz(last_fse_taps, worN=800, fs=OS_DSP*BR)
# Find the -3 dB point
fc_idx = np.where(20*np.log10(np.abs(h_fse)) <= (20*np.log10(np.abs(h_fse[50])) - 3.01))[0][0]
actual_fc_fse = f_fse[fc_idx]
## Frequency response of the channel filter
plt.figure(figsize=(8, 5))
plt.plot(f_fse, 20*np.log10(np.abs(h_fse)), color='saddlebrown')
plt.axhline(y=20*np.log10(np.abs(h_fse[50]))-3.01,
            color='black',linestyle='dashed',linewidth=2.0,
            label=f"{20*np.log10(np.abs(h_fse[50]))-3.01:.2f}dB")
plt.axvline(x=actual_fc_fse,color='gray',linewidth=2.0,
            label=f"{actual_fc_fse / 1e6:.2f}MHz")
plt.axvline(x=0.5*BR,color='coral',linewidth=2.0,
            label=f"{0.5*BR / 1e6:.2f}MHz")
plt.title("Bode - FSE I")
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitud [dB]")
plt.legend(loc="lower left")
plt.grid(True)
#plt.show()


# Time axis (centered around zero)
t = np.linspace(-0.5*(1/(OS_DSP*BR))*(len(last_fse_taps)-1),
                0.5*(1/(OS_DSP*BR))*(len(last_fse_taps)-1),
                len(last_fse_taps))
# Impulse response of the transmitter filter
plt.figure(figsize=[7,4])
plt.plot(t, last_fse_taps, color='saddlebrown', marker='o',
         linestyle='-', linewidth=2.0)
plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
plt.title('FSE Coefficients')
plt.xlabel('Sample')
plt.ylabel('Magnitud')
plt.grid(True)
plt.show()


####################################################################################
#                 EVOLUTION OF INTERNAL VARIABLES IN THE DSP SYSTEM                #
####################################################################################

#################################  FSE #################################

# Evolution of FSE coeffcients over time
plt.figure(figsize=[10,6])
plt.plot(fse_coeff.T)
plt.title('FSE coefficients (I lane) - decimated')
plt.grid(True)
plt.show()

#################################  FCR #################################

## NCO (phase) vs time
#plt.figure(figsize=[10,4])
#plt.title('NCO Output')
#plt.plot(nco_log,
#       color='darkolivegreen', marker='.')
#plt.grid(True)
#plt.xlabel('Time [n]')
#plt.ylabel('rad')
##plt.show()
#
## Integral error vs time
#plt.figure(figsize=[10,4])
#plt.title('Integral error')
#plt.plot(int_err_log*BR/(2*np.pi),
#        color='olive', marker='.')
#plt.grid(True)
#plt.xlabel('Time [n]')
#plt.ylabel('[Hz]')
#plt.show()
