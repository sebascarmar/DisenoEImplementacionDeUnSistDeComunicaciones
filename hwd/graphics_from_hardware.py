import numpy as np
import matplotlib.pyplot as plt
import math
from scipy import signal

### Calculate the theoric values of BER in function of SNR
def theoric_ber(SNRdB):
    M = 4
    SNR_slicer  = 10**(SNRdB/10)
    EbNo = SNR_slicer/np.log2(M)
    k    = np.log2(M)
    x    = np.sqrt(3*k*EbNo/(M-1))
    ber  = (4/k)*(1-1/np.sqrt(M))*(1/2)*math.erfc(x/np.sqrt(2))

    return ber



####################################################################################
#                                      MAIN                                        #
####################################################################################

#   sim_data     = np.loadtxt("logs/file_sim_data.txt", dtype=np.intp)
#   
#   NSYMB          = sim_data[ 0]
#   sigma_int      = sim_data[ 1]
#   NBF_SIGMA      = sim_data[ 2]
#   NBF_AAFILT_OUT = sim_data[ 3]
#   lms_step_int   = sim_data[ 4]
#   NBF_LMS_STEP   = sim_data[ 5]
#   lms_leak_int   = sim_data[ 6]
#   NBF_LMS_LEAK   = sim_data[ 7]
#   NTAPS_FSE      = sim_data[ 8]
#   NBT_LMS_TAPS   = sim_data[ 9]
#   NBF_LMS_TAPS   = sim_data[10]
#   NBT_FSE_TAPS   = sim_data[11]
#   NBF_FSE_TAPS   = sim_data[12]
#   NBF_FSE_OUT    = sim_data[13]
#   log_step       = sim_data[14]
#   latency        = sim_data[15]
#   bit_err_I      = sim_data[16]
#   bit_err_Q      = sim_data[17]
#   bit_tot        = sim_data[18]
#   
#   
#   sigma    = sigma_int / (2**NBF_SIGMA)
#   lms_step = lms_step_int / (2**NBF_LMS_STEP)
#   lms_leak = lms_leak_int / (2**NBF_LMS_LEAK)
#   
#   
#   OS = 4
#   var_signal = 0.1251046972473807 # data taken from float-point simulator
#   SNR_slicer  = (var_signal / (2*(sigma**2))) * OS
#   SNR_dB      = 10*np.log10(SNR_slicer)
#   
#   print( "NSYMB =", NSYMB, " | step=", lms_step, " | leak=", lms_leak)
#   print( "SNR = {:.3f} dB".format(SNR_dB)," | LMS_TAPS: S({},{}) ".format(NBT_LMS_TAPS, NBF_LMS_TAPS), " | FSE_TAPS: S({},{}) ".format(NBT_FSE_TAPS, NBF_FSE_TAPS))
#   print( "latency:",latency)
#   print( "BER_I: {:.3e}".format((bit_err_I/bit_tot)) )
#   print( "BER_Q: {:.3e}".format((bit_err_Q/bit_tot)) )
#   print( "theo_ber: {:.3e}".format(theoric_ber(SNR_dB)) )

NBF_AAFILT_OUT = 7   
NBF_FSE_OUT    = 9

#### Downsampler (rate 2)
rx_symI_dw_r2_from_ver = np.loadtxt("file_rx_symI_dwr2.txt")
rx_symQ_dw_r2_from_ver = np.loadtxt("file_rx_symQ_dwr2.txt")

rx_symI_dw_r2 = rx_symI_dw_r2_from_ver / (2**NBF_AAFILT_OUT)
rx_symQ_dw_r2 = rx_symQ_dw_r2_from_ver / (2**NBF_AAFILT_OUT)


#   #### FSE Taps
#   fse_coeff_I = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))
#   fse_coeff_Q = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))
#   
#   fseI_taps_from_ver = np.loadtxt("logs/file_fse_taps_I.txt", dtype=np.intp)
#   fseQ_taps_from_ver = np.loadtxt("logs/file_fse_taps_Q.txt", dtype=np.intp)
#   
#   fseI_taps = fseI_taps_from_ver/(2**NBF_FSE_TAPS)
#   fseQ_taps = fseQ_taps_from_ver/(2**NBF_FSE_TAPS)
#   for i in range(NTAPS_FSE):
#       for j in range((int(NSYMB/log_step))):
#           fse_coeff_I[i][j] = fseI_taps[i + j*NTAPS_FSE]
#           fse_coeff_Q[i][j] = fseQ_taps[i + j*NTAPS_FSE]
#   
#   

  
#### Downsampler (rate 1)
rx_symI_dw_r1_from_ver = np.loadtxt("file_rx_symI_dwr1.txt")
rx_symQ_dw_r1_from_ver = np.loadtxt("file_rx_symQ_dwr1.txt")

rx_symI_dw_r1 = rx_symI_dw_r1_from_ver / (2**NBF_FSE_OUT)
rx_symQ_dw_r1 = rx_symQ_dw_r1_from_ver / (2**NBF_FSE_OUT)
  



#####################################################################################
##                                      PLOTS                                       #
#####################################################################################

############################ PRE-FSE ###############################
# Group of constellations: Downsampled to rate 2 and downsampled to rate 1
plt.figure(figsize=[8,4])
plt.suptitle('Constellation Diagrams: Equalizer input and output')
plt.subplot(1,2,1) # after downsampling to rate 2
plt.plot(rx_symI_dw_r2, rx_symQ_dw_r2,
         color='chocolate', marker='.', linestyle='',
         label='dowsamp. (rate 2)')
plt.xlim((-3, 3))
plt.ylim((-3, 3))
plt.gca().set_aspect('equal', adjustable='box')
plt.grid(True)
plt.ylabel('Imag (Q)')
plt.xlabel('Real (I)')
plt.legend(loc="upper left")
#-------------------------------------------------------
plt.subplot(1,2,2) # after downsampling to rate 1
plt.plot(rx_symI_dw_r1, rx_symQ_dw_r1,
         color='seagreen', marker='.', linestyle='',
         label='dowsamp. (rate 1)')
plt.xlim((-3, 3))
plt.ylim((-3, 3))
plt.gca().set_aspect('equal', adjustable='box')
plt.grid(True)
plt.xlabel('Real (I)')
plt.legend(loc="upper left")
#plt.show()


# Downsamp. symbols at rate 1 and FSE Output vs. Time
plt.figure(figsize=[10,6])
plt.suptitle('Equalizer input and output')
plt.subplot(2,1,1)
plt.plot(rx_symI_dw_r2 ,
         color='chocolate', marker='.', linestyle='',
         label="Dws - rate 2")
plt.ylabel('Real (I)')
plt.ylim((-3, 3))
plt.grid(True)
plt.legend(loc="upper right")
#-------------------------------------------------------
plt.subplot(2,1,2) # after downsampling to rate 1
plt.plot(rx_symI_dw_r1,
        color='seagreen', marker='.', linestyle='',
        label='dowsamp. (rate 1)')
plt.ylabel('Real (I)')
plt.xlabel('Time [n]')
plt.ylim((-3, 3))
plt.grid(True)
plt.legend(loc="upper right")
plt.show()


# ########################### POST-FSE ###############################
# 
# # Group of constellations: Downsampled to rate 1, and Sliced
# plt.figure(figsize=[8,4])
# plt.suptitle('Constellation Diagrams: Downsampled to rate 2 and FSE Output')
# plt.subplot(1,2,1) # after downsampling to rate 1
# plt.plot(rx_symI_dw_r1[len(rx_symI_dw_r1)-4000:],
#          rx_symQ_dw_r1[len(rx_symQ_dw_r1)-4000:],
#          color='seagreen', marker='.', linestyle='',
#          label='dowsamp. (rate 1)')
# plt.xlim((-3, 3))
# plt.ylim((-3, 3))
# plt.gca().set_aspect('equal', adjustable='box')
# plt.grid(True)
# plt.ylabel('Imag (Q)')
# plt.xlabel('Real (I)')
# plt.legend(loc="upper left")
# #-------------------------------------------------------
# plt.subplot(1,2,2) # after the slicer
# plt.plot(rx_symI_slcr[len(rx_symI_slcr)-4000:],
#          rx_symQ_slcr[len(rx_symQ_slcr)-4000:],
#          color='magenta', marker='.', linestyle='',
#          label="sliced")
# plt.xlim((-3, 3))
# plt.ylim((-3, 3))
# plt.gca().set_aspect('equal', adjustable='box')
# plt.grid(True)
# plt.xlabel('Real (I)')
# plt.legend(loc="upper left")
# # plt.show()
# 
# 
# # Group of data vs time: Downsampled to rate 1 and Sliced
# plt.figure(figsize=[10,6])
# plt.suptitle('Downsampled to rate 1 and Sliced vs time')
# plt.subplot(2,1,1) # after downsampling to rate 1
# plt.plot(rx_symI_dw_r1,
#         color='seagreen', marker='.', linestyle='',
#         label='dowsamp. (rate 1)')
# plt.ylabel('Real (I)')
# plt.ylim((-3, 3))
# plt.grid(True)
# plt.legend(loc="upper right")
# #-------------------------------------------------------
# plt.subplot(2,1,2) # after the slicer
# plt.plot(rx_symI_slcr,
#         color='magenta', marker='.', linestyle='',
#         label="sliced")
# plt.ylabel('Real (I)')
# plt.xlabel('Time [n]')
# plt.ylim((-3, 3))
# plt.grid(True)
# plt.legend(loc="upper right")
# plt.show()
# 
# 
# 
# ##################### Adapatvie Filter graphics ####################
# 
# # Get frequencies and magnitudes
# last_fse_taps = fse_coeff_I[:NTAPS_FSE, (int(NSYMB/log_step))-1]
# 
# f_fse, h_fse = signal.freqz(last_fse_taps, worN=800, fs=50e6)
# # Find the -3 dB point
# fc_idx = np.where(20*np.log10(np.abs(h_fse)) <= (20*np.log10(np.abs(h_fse[50])) - 3.01))[0][0]
# actual_fc_fse = f_fse[fc_idx]
# 
# ## Frequency response of the channel filter
# plt.figure(figsize=(8, 5))
# plt.plot(f_fse, 20*np.log10(np.abs(h_fse)), color='saddlebrown')
# plt.axhline(y=20*np.log10(np.abs(h_fse[50]))-3.01,
#             color='black',linestyle='dashed',linewidth=2.0,
#             label=f"{20*np.log10(np.abs(h_fse[50]))-3.01:.2f}dB")
# plt.axvline(x=actual_fc_fse,color='gray',linewidth=2.0,
#             label=f"{actual_fc_fse / 1e6:.2f}MHz")
# plt.axvline(x=12.5e6,color='coral',linewidth=2.0,
#             label=f"{12.5e6 / 1e6:.2f}MHz")
# plt.title("Bode - FSE I")
# plt.xlabel("Frequency [Hz]")
# plt.ylabel("Magnitud [dB]")
# plt.legend(loc="lower left")
# plt.ylim(-6.0,16.0)
# plt.grid(True)
# #plt.show()
# 
# 
# ## Time axis (centered around zero)
# t = np.linspace(-0.5*(1/(50e6))*(len(last_fse_taps)-1),
#                 0.5*(1/(50e6))*(len(last_fse_taps)-1),
#                 len(last_fse_taps))
# # Impulse response of the transmitter filter
# plt.figure(figsize=[7,4])
# plt.plot(t, last_fse_taps, color='saddlebrown', marker='o',
#          linestyle='-', linewidth=2.0)
# plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
# plt.title('FSE I Coefficients')
# plt.xlabel('Sample [s]')
# plt.ylabel('Magnitud')
# plt.ylim(-1.5,3.0)
# plt.grid(True)
# plt.show()
# 
# 
# 
# ## Evolution of FSE coeffcients over time
# plt.figure(figsize=[10,6])
# plt.plot(fse_coeff_I.T)
# plt.title('FSE coefficients (I lane) - decimated')
# plt.xlabel('Time [n]')
# plt.ylim(-1.5,3.0)
# plt.grid(True)
# 
# plt.figure(figsize=[10,6])
# plt.plot(fse_coeff_Q.T)
# plt.title('FSE coefficients (Q lane) - decimated')
# plt.xlabel('Time [n]')
# plt.ylim(-1.5,3.0)
# plt.grid(True)
# plt.show()
# 
# 
# ## Evolution error for LMS over time
# plt.figure(figsize=[10,6])
# plt.plot(rx_err_lms_I)
# plt.title('LMS-Error - Lane I')
# plt.xlabel('Time [n]')
# plt.ylim(-2.0,2.0)
# plt.grid(True)
# 
# plt.figure(figsize=[10,6])
# plt.plot(rx_err_lms_Q)
# plt.title('LMS-Error - Lane Q')
# plt.ylim(-2.0,2.0)
# plt.xlabel('Time [n]')
# plt.grid(True)
# plt.show()
