import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.io import savemat
import math
import functions as fn
from classes.prbs9 import prbs9


####################################################################################
#                                      MAIN                                        #
####################################################################################

############################### PARAMETERS #############################

#### General
NSYMB = 1300000 # 1e6
BR    = 25e6    # Baud
OS    = 4       # oversampling
BETA  = 0.5     # roll-off
NBAUD = 5
M     = 4       # modulation order
SEED_I =  0x1AA
SEED_Q =  0x1FE

#### Channel
SNR_db   = 7
f_offset = 10e3 # Hz
NSYMB_CONVERGENCE = 20000   # FSE and FCR convergence (a half for each)
fc_ch_filter      = 0.49*BR # Cut-off frecuency of channel filter [Hz]

#### Receiver
fc_aa_filter = 1.0*BR # Cut-off frecuency of anti-alias filter [Hz]
OS_DSP       = 2
NTAPS_FSE    = 33
lms_step     = 0.1e-3
lms_leak     = 0
Kp           = 1e-3
Ki           = Kp/1000

#### BER counter
START_SYN = 450191
START_CNT = START_SYN + 511*511

# np.random.seed(2)  # set the seed


############################## TRANSMITTER  #############################

#### Bits generation
tx_bitI_prbs = np.zeros(NSYMB)
tx_bitQ_prbs = np.zeros(NSYMB)

prbs9I = prbs9(SEED_I) 
prbs9Q = prbs9(SEED_Q)

for i in range(NSYMB):
    tx_bitI_prbs[i] = prbs9I.get_new_bit()
    tx_bitQ_prbs[i] = prbs9Q.get_new_bit()

#### Mapper
tx_symI_map = 2*(tx_bitI_prbs != 1)-1
tx_symQ_map = 2*(tx_bitQ_prbs != 1)-1

#### Up-sampler
tx_symI_up = np.zeros(OS*NSYMB); tx_symI_up[0:len(tx_symI_up):int(OS)]=tx_symI_map
tx_symQ_up = np.zeros(OS*NSYMB); tx_symQ_up[0:len(tx_symQ_up):int(OS)]=tx_symQ_map


#### RRC Filter
(t, rrc, dot) = fn.r_rcosine(fc=BR/2, fs=OS*BR, rolloff=BETA, nbauds=NBAUD, norm=True)

tx_symI_rrc = signal.lfilter(rrc, [1], tx_symI_up)
tx_symQ_rrc = signal.lfilter(rrc, [1], tx_symQ_up)



################################ CHANNEL ###############################
#### AWGN
SNR_slicer = 10**(SNR_db/10)
SNR_ch     = SNR_slicer/OS
noise_var  = np.var(tx_symI_rrc+1j*tx_symQ_rrc)/SNR_ch
noise_I    = np.sqrt(noise_var/2)*np.random.normal(loc=0, scale=1, size=tx_symI_rrc.shape)
noise_Q    = np.sqrt(noise_var/2)*np.random.normal(loc=0, scale=1, size=tx_symQ_rrc.shape)

ch_symI_noisy = tx_symI_rrc + noise_I
ch_symQ_noisy = tx_symQ_rrc + noise_Q


#### Frequency Offset
Ts = 1/(OS*BR)
time_vector    = np.arange(NSYMB_CONVERGENCE*OS*Ts, NSYMB*OS*Ts, Ts)
titas          = np.array(2*np.pi*f_offset * time_vector, dtype=np.float32)
ch_symI_rot    = np.array(ch_symI_noisy, dtype=np.float32)
ch_symQ_rot    = np.array(ch_symQ_noisy, dtype=np.float32)

# Force a fixed size
if( len(titas) > (NSYMB*OS-NSYMB_CONVERGENCE*OS) ):
    titas = titas[0:(NSYMB*OS-NSYMB_CONVERGENCE*OS)]
else:
    titas = titas

ch_symI_rot[NSYMB_CONVERGENCE*OS: ] = (ch_symI_noisy[NSYMB_CONVERGENCE*OS: ]*np.cos(titas)-
                                       ch_symQ_noisy[NSYMB_CONVERGENCE*OS: ]*np.sin(titas))
ch_symQ_rot[NSYMB_CONVERGENCE*OS: ] = (ch_symI_noisy[NSYMB_CONVERGENCE*OS: ]*np.sin(titas)+
                                       ch_symQ_noisy[NSYMB_CONVERGENCE*OS: ]*np.cos(titas))


#### Channel filter
ch_filt_coeff   = signal.firwin(numtaps=17, cutoff=fc_ch_filter ,window='hamming', fs=OS*BR)
ch_symI_ch_filt = signal.lfilter(ch_filt_coeff, [1], ch_symI_rot)
ch_symQ_ch_filt = signal.lfilter(ch_filt_coeff, [1], ch_symQ_rot)


############################### RECEIVER ###############################
#### Anti-alias filter
aaf_coeff  = signal.firwin(numtaps=17, cutoff=fc_aa_filter ,window='hamming', fs=OS*BR)
rx_symI_aaf = signal.lfilter(aaf_coeff, [1], ch_symI_ch_filt)
rx_symQ_aaf = signal.lfilter(aaf_coeff, [1], ch_symQ_ch_filt)

#### Downsampler (rate 2)
rx_symI_dw_r2 = rx_symI_aaf[0:len(rx_symI_aaf):int(OS_DSP)]
rx_symQ_dw_r2 = rx_symQ_aaf[0:len(rx_symQ_aaf):int(OS_DSP)]

#### AGC
target      = 1.4130800626285385# Vrms (EbNo=4 y seed=1)
metric      = np.std(rx_symI_dw_r2+1j*rx_symQ_dw_r2)
agc_gain    = target/metric
rx_symI_agc =  rx_symI_dw_r2 * agc_gain
rx_symQ_agc =  rx_symQ_dw_r2 * agc_gain

#### DSP
# FSE variables
fseI_buffer = np.zeros(NTAPS_FSE)
fseQ_buffer = np.zeros(NTAPS_FSE)
fseI_coeff  = np.zeros(NTAPS_FSE); fseI_coeff[int(NTAPS_FSE/2)] = 1
fseQ_coeff  = np.zeros(NTAPS_FSE); fseQ_coeff[int(NTAPS_FSE/2)] = 0
rx_symI_fse = np.zeros(NSYMB*OS_DSP)
rx_symQ_fse = np.zeros(NSYMB*OS_DSP)

log_step    = 500
fse_coeff  = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))

# Downsampler (rate 1)
rx_symI_dw_r1 = np.zeros(NSYMB)
rx_symQ_dw_r1 = np.zeros(NSYMB)

# FCR variables
nco_out     = 0
int_err     = 0 
rx_symI_fcr = np.zeros(NSYMB)
rx_symQ_fcr = np.zeros(NSYMB)
nco_log     = np.zeros(NSYMB)
int_err_log = np.zeros(NSYMB)

# Slicer variables
rx_symI_slcr = np.zeros(NSYMB)
rx_symQ_slcr = np.zeros(NSYMB)

# Loop
for j in range(NSYMB*OS_DSP):
    # Filter buffer
    fseI_buffer[1:] = fseI_buffer[:-1]
    fseI_buffer[0]  = rx_symI_agc[j]
    fseQ_buffer[1:] = fseQ_buffer[:-1]
    fseQ_buffer[0]  = rx_symQ_agc[j]

    # Filter output
    rx_symI_fse[j] = (np.dot(fseI_buffer,fseI_coeff)-
                      np.dot(fseQ_buffer,fseQ_coeff))
    rx_symQ_fse[j] = (np.dot(fseI_buffer,fseQ_coeff)+
                      np.dot(fseQ_buffer,fseI_coeff))

    if((j+1)%OS_DSP)==0: # Downsampling to BR rate (os=1)
        k = int(j/OS_DSP)
        # Downsampler (rate 1)
        rx_symI_dw_r1[k] = rx_symI_fse[j]
        rx_symQ_dw_r1[k] = rx_symQ_fse[j]
        
        # FCR output: multiplication by e^{-jnco_out}
        rx_symI_fcr[k] = (rx_symI_dw_r1[k]*np.cos(-nco_out) -
                          rx_symQ_dw_r1[k]*np.sin(-nco_out))
        rx_symQ_fcr[k] = (rx_symI_dw_r1[k]*np.sin(-nco_out) + 
                          rx_symQ_dw_r1[k]*np.cos(-nco_out))
        
        # Slicer
        rx_symI_slcr[k] = fn.slicer_pam(rx_symI_fcr[k])
        rx_symQ_slcr[k] = fn.slicer_pam(rx_symQ_fcr[k])
        
        # Error for LMS
        coeff_err_I = ((rx_symI_fcr[k]-rx_symI_slcr[k])*np.cos(nco_out) -
                       (rx_symQ_fcr[k]-rx_symQ_slcr[k])*np.sin(nco_out))
        coeff_err_Q = ((rx_symI_fcr[k]-rx_symI_slcr[k])*np.sin(nco_out) +
                       (rx_symQ_fcr[k]-rx_symQ_slcr[k])*np.cos(nco_out))
        # Phase error
        angle_err = ( np.angle(rx_symI_fcr[k]+1j*rx_symQ_fcr[k])
                     -np.angle(rx_symI_slcr[k]+1j*rx_symQ_slcr[k]) )
        
        # LMS
        fseI_coeff = (fseI_coeff*(1-lms_step*lms_leak) - 
                       lms_step*(coeff_err_I*fseI_buffer + coeff_err_Q*fseQ_buffer))
        fseQ_coeff = (fseQ_coeff*(1-lms_step*lms_leak) +
                       lms_step*( coeff_err_I*fseQ_buffer - coeff_err_Q*fseI_buffer))
        if( (((j+1)/OS_DSP)%log_step) == 0 ):
            fse_coeff[:, int(((j+1)/OS_DSP)/log_step)-1] = fseI_coeff
      
        # PI loop filter
        Kp2 = Kp if(i>(NSYMB_CONVERGENCE/2)) else 0
        Ki2 = Ki if(i>(NSYMB_CONVERGENCE/2)) else 0
        prop_err =  Kp2 * angle_err
        int_err  = (Ki2 * angle_err) + int_err
        # NCO
        nco_out  = (prop_err+int_err) + nco_out
        nco_log[k]     = nco_out
        int_err_log[k] = int_err
#----- DSP end

  
############################ BIT-ERROR RATE ############################
#### Synchronzation
# PRBS regster and data
shifter_ber_I = np.zeros(511)
shifter_ber_Q = np.zeros(511)
rx_prbs_I     = tx_symI_map[START_SYN-1:START_CNT-1]
rx_prbs_Q     = tx_symQ_map[START_SYN-1:START_CNT-1]

# Rotate the received data
rx_slcr_I_0   =        rx_symI_slcr[START_SYN-1 : START_CNT-1]
rx_slcr_Q_0   =        rx_symQ_slcr[START_SYN-1 : START_CNT-1]
rx_slcr_I_90  = fn.inv(rx_symQ_slcr[START_SYN-1 : START_CNT-1])
rx_slcr_Q_90  =        rx_symI_slcr[START_SYN-1 : START_CNT-1]
rx_slcr_I_180 = fn.inv(rx_symI_slcr[START_SYN-1 : START_CNT-1])
rx_slcr_Q_180 = fn.inv(rx_symQ_slcr[START_SYN-1 : START_CNT-1])
rx_slcr_I_270 =        rx_symQ_slcr[START_SYN-1 : START_CNT-1]
rx_slcr_Q_270 = fn.inv(rx_symI_slcr[START_SYN-1 : START_CNT-1])

# Synchro variables
min_error   = len(shifter_ber_Q)
err_sym_0   = 0
err_sym_90  = 0
err_sym_180 = 0
err_sym_270 = 0
latency       = 0
rot_ang_detec = 0

# Loop
for BER_IDX in range(len(shifter_ber_I)):
    # Reste accumulators
    err_sym_0   = 0
    err_sym_90  = 0
    err_sym_180 = 0
    err_sym_270 = 0
    # Count errors for each BER_IDX
    for i in range(len(shifter_ber_I)):
        # Shift and update register used for PRBS 
        shifter_ber_I = np.roll(shifter_ber_I,1)
        shifter_ber_Q = np.roll(shifter_ber_Q,1)
        shifter_ber_I[0] = rx_prbs_I[i+511*BER_IDX]
        shifter_ber_Q[0] = rx_prbs_Q[i+511*BER_IDX]
        
        # BER_IDX refers to a fixed position during counting
        new_bit_prbs_I = shifter_ber_I[BER_IDX]
        new_bit_prbs_Q = shifter_ber_Q[BER_IDX]
        
        # Compare PRBS with received data (rotated by 0º)
        if( (new_bit_prbs_I!=rx_slcr_I_0[i+511*BER_IDX]) or (new_bit_prbs_Q!=rx_slcr_Q_0[i+511*BER_IDX]) ):
            err_sym_0 += 1
        else:
            err_sym_0 = err_sym_0
        # Compare PRBS with received data (rotated by 90º)
        if( (new_bit_prbs_I!=rx_slcr_I_90[i+511*BER_IDX]) or (new_bit_prbs_Q!=rx_slcr_Q_90[i+511*BER_IDX]) ):
            err_sym_90 += 1
        else:
            err_sym_90 = err_sym_90
        # Compare PRBS with received data (rotated by 180º)
        if( (new_bit_prbs_I!=rx_slcr_I_180[i+511*BER_IDX]) or (new_bit_prbs_Q!=rx_slcr_Q_180[i+511*BER_IDX]) ):
            err_sym_180 += 1
        else:
            err_sym_180 = err_sym_180
        # Compare PRBS with received data (rotated by 270º)
        if( (new_bit_prbs_I!=rx_slcr_I_270[i+511*BER_IDX]) or (new_bit_prbs_Q!=rx_slcr_Q_270[i+511*BER_IDX]) ):
            err_sym_270 += 1
        else:
            err_sym_270 = err_sym_270
    
    # Store data for the minimum case
    if( err_sym_0<min_error   and err_sym_0<err_sym_90 and
        err_sym_0<err_sym_180 and err_sym_0<err_sym_270):
        min_error     = err_sym_0
        latency       = BER_IDX
        rot_ang_detec = 0
    elif( err_sym_90<min_error and err_sym_90<err_sym_180 and
          err_sym_90<err_sym_270 ):
        min_error     = err_sym_90
        latency       = BER_IDX
        rot_ang_detec = 90
    elif( err_sym_180<min_error and err_sym_180<err_sym_270 ):
        min_error     = err_sym_180
        latency       = BER_IDX
        rot_ang_detec = 180
    elif( err_sym_270<min_error ):
        min_error     = err_sym_270
        latency       = BER_IDX
        rot_ang_detec = 270
    else:
        min_error     = min_error    
        latency       = latency  
        rot_ang_detec = rot_ang_detec


#### Counting
print("latency:",latency, "| ang:",rot_ang_detec)
rx_prbs_I = tx_symI_map
rx_prbs_Q = tx_symQ_map

# Select the detected rotation
if( rot_ang_detec == 0 ):
    rx_slcr_I =     rx_symI_slcr
    rx_slcr_Q =     rx_symQ_slcr
elif( rot_ang_detec == 90 ):
    rx_slcr_I = fn.inv(rx_symQ_slcr)
    rx_slcr_Q =     rx_symI_slcr
elif( rot_ang_detec == 180 ):
    rx_slcr_I = fn.inv(rx_symI_slcr)
    rx_slcr_Q = fn.inv(rx_symQ_slcr)
else: # rot_ang_detec=270
    rx_slcr_I =     rx_symQ_slcr
    rx_slcr_Q = fn.inv(rx_symI_slcr)

lat_comp = 511-latency
# BER (Lane I)
bit_err_I = 0
bit_tot_I = 0
for i in range(START_CNT,len(rx_slcr_I)-lat_comp):
    if( rx_prbs_I[lat_comp+i] != rx_slcr_I[i] ):
        bit_err_I +=1
    bit_tot_I += 1

# BER (Lane Q)
bit_err_Q = 0
bit_tot_Q = 0
for i in range(START_CNT,len(rx_slcr_Q)-lat_comp):
    if( rx_prbs_Q[lat_comp+i] != rx_slcr_Q[i] ):
        bit_err_Q +=1
    bit_tot_Q += 1


th_ber = fn.theoric_ber(M, SNR_db)

print("SNR=", SNR_db, " | f_off=",f_offset, " | step=", lms_step, " | leak=", lms_leak)
print("Kp=", Kp, " | Ki=", Ki, " | fc_ch=", fc_ch_filter, " | fc_aaf=",fc_aa_filter, )
print("BER_I: ", bit_err_I/bit_tot_I)
print("BER_Q: ", bit_err_Q/bit_tot_Q)
print("theo_ber: ", th_ber)


################  PRINCIPAL GRAPHICS TO ANALYZE CONVERGENCE ISSUE #################
fase = 1
# Salida del FSE vs tiempo
plt.figure(figsize=[10,6])
plt.subplot(2,1,1)
plt.title('FSE Output I')
plt.plot(rx_symI_fse[fase:len(rx_symI_fse)-fase:2],'x')
plt.grid(True)
plt.subplot(2,1,2)
plt.title('FSE Output Q')
plt.plot(rx_symQ_fse[fase:len(rx_symQ_fse)-fase:2],'x')
plt.grid(True)
plt.xlabel('Nº símbolos')
plt.savefig("fse_out.png", dpi=300, format='png')
plt.close()

# Salida del FCR vs tiempo
plt.figure(figsize=[10,6])
plt.subplot(2,1,1)
plt.title('FCR Output I')
plt.plot(rx_symI_fcr,'x')
plt.grid(True)
plt.subplot(2,1,2)
plt.title('FCR Output Q')
plt.plot(rx_symQ_fcr,'x')
plt.grid(True)
plt.xlabel('Nº símbolos')
plt.ylabel('I')
plt.savefig("fcr_out.png", dpi=300, format='png')
plt.close()

plt.figure(figsize=[10,6])
plt.plot(fse_coeff.T)
plt.title('Coeficientes FFE')
plt.grid(True)
plt.savefig("fse_coeff.png", dpi=300, format='png')
plt.close()

#####################################################################################
##       PROGRESSION OF SIGNAL PROCESSING STAGES IN THE COMMUNICATION SYSTEM        #
#####################################################################################
#
###################### TX BITS AND MAPPED TO SYMB #######################
## Generated bits and mapped to symbols 
#plt.figure(figsize=[10,4])
#plt.subplot(2,1,1)
#plt.plot(range(len(tx_bitI_prbs)-40,len(tx_bitI_prbs)),
#         tx_bitI_prbs[len(tx_bitI_prbs)-40:],
#         color='dimgray', marker='o',linestyle='')
#plt.title('Bits and mapped to symbs')
#plt.ylabel("bit (I)")
#plt.xlim(len(tx_bitI_prbs)-40,len(tx_bitI_prbs)-1)
#plt.grid(True)
##------------------------------------------------------
#plt.subplot(2,1,2)
#plt.plot(range(len(tx_symI_map)-40,len(tx_symI_map)),
#         tx_symI_map[len(tx_symI_map)-40:],
#         color='black', marker='o', linestyle='')
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
#plt.plot(range(len(tx_symI_rrc)-500,len(tx_symI_rrc)),
#         tx_symI_rrc[len(tx_symI_rrc)-500:],
#         color='green', linewidth=2.0)
#plt.title('Transmited, noisy, rotated and with ISI symbs')
#plt.xlim(len(tx_symI_rrc)-500,len(tx_symI_rrc)-1)
#plt.grid(True)
##---------------------------------------------------------
#plt.subplot(4,1,2)
#plt.plot(range(len(ch_symI_noisy)-500,len(ch_symI_noisy)),
#         ch_symI_noisy[len(ch_symI_noisy)-500:],
#         color='red', linewidth=2.0)
#plt.xlim(len(ch_symI_noisy)-500,len(ch_symI_noisy)-1)
#plt.grid(True)
##---------------------------------------------------------
#plt.subplot(4,1,3)
#plt.plot(range(len(ch_symI_rot)-500,len(ch_symI_rot)),
#         ch_symI_rot[len(ch_symI_rot)-500:],
#         color='blue', linewidth=2.0)
#plt.xlim(len(ch_symI_rot)-500,len(ch_symI_rot)-1)
#plt.grid(True)
##---------------------------------------------------------
#plt.subplot(4,1,4)
#plt.plot(range(len(ch_symI_ch_filt)-500,len(ch_symI_ch_filt)),
#         ch_symI_ch_filt[len(ch_symI_ch_filt)-500:],
#         color='blueviolet', linewidth=2.0)
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
#plt.plot(tx_symI_rrc[len(tx_symI_rrc)-1000:],
#         tx_symQ_rrc[len(tx_symQ_rrc)-1000:],
#         color='green', marker='.', linestyle='',
#         label="RRC Filt. Output")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.ylabel('Imag (Q)')
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,2) # after adding noise
#plt.plot(ch_symI_noisy[len(ch_symI_noisy)-2000:],
#         ch_symQ_noisy[len(ch_symQ_noisy)-2000:],
#         color='red', marker='.', linestyle='',
#         label="with noise")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,3) # after adding noise and apply rotation
#plt.plot(ch_symI_rot[len(ch_symI_rot)-2000:],
#         ch_symQ_rot[len(ch_symQ_rot)-2000:],
#         color='blue', marker='.', linestyle='',
#         label="with noise and rotated")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.xlabel('Real (I)')
#plt.ylabel('Imag (Q)')
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,4) # after noise+rotation+isi
#plt.plot(ch_symI_ch_filt[len(ch_symI_ch_filt)-2000:],
#         ch_symQ_ch_filt[len(ch_symQ_ch_filt)-2000:],
#         color='blueviolet', marker='.', linestyle='',
#         label="with noise, rotated and with isi")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.xlabel('Real (I)')
#plt.legend()
##plt.show()
#
#
############################ RX AA-FILTER ###############################
## Filtered symbols (anti-alias filter)
#plt.figure(figsize=[10,4])
#plt.plot(range(len(rx_symI_aaf)-500,len(rx_symI_aaf)),
#         rx_symI_aaf[len(rx_symI_aaf)-500:],
#         color='orange', linestyle='-',linewidth=2.0)
#plt.title('Filtered sym (AAF)')
#plt.xlim(len(rx_symI_aaf)-500,len(rx_symI_aaf)-1)
#plt.grid(True)
#plt.xlabel('Time [n]')
##plt.show()
#
#
################ RX DOWNSAMP. (RATE 2) AND AGC PROCESS ###################
## Downsamp. symbols and symbols after AGC
#plt.figure(figsize=[10,6])
#plt.subplot(2,1,1)
#plt.plot(range(len(rx_symI_dw_r2)-500,len(rx_symI_dw_r2)),
#         rx_symI_dw_r2[len(rx_symI_dw_r2)-500:],
#         color='chocolate', linestyle='-', linewidth=2.0)
#plt.xlim(len(rx_symI_dw_r2)-500,len(rx_symI_dw_r2)-1)
#plt.title('Downsampled symbs (rate 2) and symbs after AGC')
#plt.xlim(len(rx_symI_dw_r2)-500,len(rx_symI_dw_r2)-1)
#plt.grid(True)
##------------------------------------------------------
#plt.subplot(2,1,2)
#plt.plot(range(len(rx_symI_agc)-500,len(rx_symI_agc)),
#         rx_symI_agc[len(rx_symI_agc)-500:],
#         color='brown', linestyle='-', linewidth=2.0)
#plt.ylabel("map to sym (I)")
#plt.xlim(len(rx_symI_agc)-500,len(rx_symI_agc)-1)
#plt.grid(True)
#plt.xlabel('Time [n]')
##plt.show()
#
#
############################### DSP #################################
## Group of constellations: FSE, FCR, Downsampled to rate 1, and Sliced
#plt.figure(figsize=[8,8])
#plt.suptitle('Constellation Diagrams: FSE, FCR, Downsampled to rate 1, and Sliced')
#plt.subplot(2,2,1) # FSE Output
#plt.plot(rx_symI_fse[len(rx_symI_fse)-8000:],
#         rx_symQ_fse[len(rx_symQ_fse)-8000:],
#         color='salmon', marker='.', linestyle='',
#         label="FSE Output")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.ylabel('Imag (Q)')
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,2) # after downsampling to rate 1
#plt.plot(rx_symI_dw_r1[len(rx_symI_dw_r1)-4000:],
#         rx_symQ_dw_r1[len(rx_symQ_dw_r1)-4000:],
#         color='seagreen', marker='.', linestyle='',
#         label='dowsamp. (rate 1)')
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,3) # FCR Output
#plt.plot(rx_symI_fcr[len(rx_symI_fcr)-4000:],
#         rx_symQ_fcr[len(rx_symQ_fcr)-4000:],
#         color='dodgerblue', marker='.', linestyle='',
#         label="FCR Output")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.xlabel('Real (I)')
#plt.ylabel('Imag (Q)')
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,4) # after the slicer
#plt.plot(rx_symI_slcr[len(rx_symI_slcr)-4000:],
#         rx_symQ_slcr[len(rx_symQ_slcr)-4000:],
#         color='magenta', marker='.', linestyle='',
#         label="sliced")
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.xlabel('Real (I)')
#plt.legend()
##plt.show()
#
#
## Group of data vs time: FSE, FCR, Downsampled to rate 1, and Sliced
#plt.figure(figsize=[12,6])
#plt.suptitle('FSE, FCR, Downsampled to rate 1, and Sliced vs time')
#plt.subplot(2,2,1) # FSE Output
#plt.plot(rx_symI_fse,
#         color='salmon', marker='.', linestyle='',
#         label="FSE Output")
#plt.grid(True)
#plt.ylabel('Real (I)')
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,2) # after downsampling to rate 1
#plt.plot(rx_symI_dw_r1,
#         color='seagreen', marker='.', linestyle='',
#         label='dowsamp. (rate 1)')
#plt.grid(True)
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,3) # FCR Output
#plt.plot(rx_symI_fcr,
#         color='dodgerblue', marker='.', linestyle='',
#         label="FCR Output")
#plt.ylabel('Real (I)')
#plt.xlabel('Time [n]')
#plt.grid(True)
#plt.legend()
##-------------------------------------------------------
#plt.subplot(2,2,4) # after the slicer
#plt.plot(rx_symI_slcr,
#         color='magenta', marker='.', linestyle='',
#         label="sliced")
#plt.grid(True)
#plt.xlabel('Time [n]')
#plt.legend()
#plt.show()
#
#
#
#####################################################################################
##            FREQUENCY RESPONSE AND COEFFICIENTS OF THE SYSTEM FILTERS             #
#####################################################################################
#
############################## TX FILTER ###############################
### Transmitter Filter graphics: frequency response and time
#
## Get frequencies and magnitudes
#f_rrc, h_rrc = signal.freqz(rrc, worN=800, fs=OS*BR)
## Find the -3 dB point
#fc_idx_rrc = np.where(20*np.log10(np.abs(h_rrc)) <= (20*np.log10(np.abs(h_rrc[50]))-3.01))[0][0]
#actual_fc_rrc = f_rrc[fc_idx_rrc]
### Frequency response of the channel filter
#plt.figure(figsize=(8, 5))
#plt.semilogx(f_rrc, 20*np.log10(np.abs(h_rrc)), color='darkcyan')
#plt.axhline(y=20*np.log10(np.abs(h_rrc[50]))-3.01,
#            color='black',linestyle='dashed',linewidth=2.0,
#            label=f"{20*np.log10(np.abs(h_rrc[50]))-3.01:.2f}dB")
#plt.axvline(x=actual_fc_rrc,color='gray',linewidth=2.0,
#            label=f"{actual_fc_rrc / 1e6:.2f}MHz")
#plt.axvline(x=0.5*BR,color='coral',linewidth=2.0,
#            label=f"{0.5*BR / 1e6:.2f}MHz")
#plt.title("Bode - Transmitter Filter ({} taps)".format(len(rrc)))
#plt.xlabel("Frequency [Hz]")
#plt.ylabel("Magnitud [dB]")
#plt.legend(loc="lower left")
#plt.grid(True)
##plt.show()
#
#
## Time axis (centered around zero)
#t = np.linspace(-0.5*(1/(OS*BR))*(len(rrc)-1),
#                0.5*(1/(OS*BR))*(len(rrc)-1),
#                len(rrc))
## Impulse response of the transmitter filter
#plt.figure(figsize=[7,4])
#plt.plot(t, rrc, color='darkcyan', marker='o',
#         linestyle='-', linewidth=2.0, label=f"{len(rrc)} taps")
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
#plt.semilogx(f_cha, 20*np.log10(np.abs(h_cha)), color='fuchsia')
#plt.axhline(y=20*np.log10(np.abs(h_cha[50]))-3.01,
#            color='black',linestyle='dashed',linewidth=2.0,
#            label=f"{20*np.log10(np.abs(h_cha[50]))-3.01:.2f}dB")
#plt.axvline(x=actual_fc_ch,color='gray',linewidth=2.0,
#            label=f"{actual_fc_ch / 1e6:.2f}MHz")
#plt.axvline(x=fc_ch_filter,color='coral',linewidth=2.0,
#            label=f"{fc_ch_filter / 1e6:.2f}MHz")
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
#                0.5*(1/(OS*BR))*(len(ch_filt_coeff)-1),
#                len(ch_filt_coeff))
## Impulse response of the channel filter
#plt.figure(figsize=[7, 4])
#plt.plot(t, ch_filt_coeff, color='fuchsia', marker='o',
#         linestyle='-', linewidth=2.0, label=f"{len(ch_filt_coeff)} taps")
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
## Find the -3 dB point
#fc_idx_aaf    = np.where(20*np.log10(np.abs(h_aaf)) <= (20*np.log10(np.abs(h_aaf[50]))-3.01))[0][0]
#actual_fc_aaf = f_aaf[fc_idx_aaf]
### Frequency response of the channel filter
#plt.figure(figsize=(8, 5))
#plt.semilogx(f_aaf, 20*np.log10(np.abs(h_aaf)), color='mediumblue')
#plt.axhline(y=20*np.log10(np.abs(h_aaf[50]))-3.01,
#            color='black',linestyle='dashed',linewidth=2.0,
#            label=f"{20*np.log10(np.abs(h_aaf[50]))-3.01:.2f}dB")
#plt.axvline(x=actual_fc_aaf,color='gray',linewidth=2.0,
#            label=f"{actual_fc_aaf / 1e6:.2f}MHz")
#plt.axvline(x=fc_aa_filter,color='coral',linewidth=2.0,
#            label=f"{fc_aa_filter / 1e6:.2f}MHz")
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
#                0.5*(1/(OS*BR))*(len(aaf_coeff)-1),
#                len(aaf_coeff))
## Impulse response of the channel filter
#plt.figure(figsize=[7, 4])
#plt.plot(t, aaf_coeff, color='mediumblue', marker='o',
#         linestyle='-', linewidth=2.0, label=f"{len(aaf_coeff)} taps")
#plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
#plt.title('Anti-Alias Filter Coefficients')
#plt.xlabel('Time (s)')
#plt.ylabel('Magnitud')
#plt.legend(loc="upper right")
#plt.grid(True)
#plt.show()
#
#
#
#####################################################################################
##                 EVOLUTION OF INTERNAL VARIABLES IN THE DSP SYSTEM                #
#####################################################################################
#
##################################  FSE #################################
#
## Evolution of FSE coeffcients over time
#plt.figure(figsize=[10,6])
#plt.plot(fse_coeff.T)
#plt.title('Coeficientes FSE')
#plt.grid(True)
##plt.show()
#
##################################  FCR #################################
#
## NCO (phase) vs time
#fase = 1
#plt.figure(figsize=[10,4])
#plt.title('NCO Output')
#plt.plot(nco_log[fase:len(nco_log)-fase:2],
#        color='darkolivegreen', marker='.')
#plt.grid(True)
#plt.xlabel('Time [n]')
#plt.ylabel('rad')
##plt.show()
#
## Integral error vs time
#plt.figure(figsize=[10,4])
#plt.title('Integral error')
#plt.plot(int_err_log[fase:len(int_err_log)-fase:2]*BR/(2*np.pi),
#         color='olive', marker='.')
#plt.grid(True)
#plt.xlabel('Time [n]')
#plt.ylabel('[Hz]')
#plt.show()
#
#
