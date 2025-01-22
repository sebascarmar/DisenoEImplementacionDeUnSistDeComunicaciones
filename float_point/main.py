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

#### Channel
SNR_db   = 7
f_offset = 10e3 # Hz
NSYMB_CONVERGENCE = 20000   # FSE and FCR convergence (a half for each)
fc_ch_filter      = 0.49*BR # Cut-off frecuency of channel filter [Hz]

#### Receiver
OS_DSP    = 2
NTAPS_FSE = 33
lms_step  = 0.1e-3
lms_leak  = 0
Kp        = 1e-3
Ki        = Kp/1000

#### BER counter
START_SYN = 450191
START_CNT = START_SYN + 511*511

# np.random.seed(2)  # set the seed


############################## TRANSMITTER  #############################

#### Bits generation
tx_bitI_prbs = np.zeros(NSYMB)
tx_bitQ_prbs = np.zeros(NSYMB)

prbs9I = prbs9([0, 1, 0, 1, 0, 1, 0, 1, 1]) # Seed: 0x1AA
prbs9Q = prbs9([0, 1, 1, 1, 1, 1, 1, 1, 1]) # Seed: 0x1FE

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
ch_filt_coeff   = signal.firwin(numtaps=17, cutoff=fc_ch_filter ,window='hamming', fs=4*BR)
ch_symI_ch_filt = signal.lfilter(ch_filt_coeff, [1], ch_symI_rot)
ch_symQ_ch_filt = signal.lfilter(ch_filt_coeff, [1], ch_symQ_rot)


############################### RECEIVER ###############################
#### Anti-alias filter
aaf_coeff   = signal.firwin(numtaps=17, cutoff=BR ,window='hamming', fs=4*BR)
rx_symI_aaf = signal.lfilter(aaf_coeff, [1], ch_symI_ch_filt)
rx_symQ_aaf = signal.lfilter(aaf_coeff, [1], ch_symQ_ch_filt)

#### Downsampler
rx_symI_dw = rx_symI_aaf[0:len(rx_symI_aaf):int(OS_DSP)]
rx_symQ_dw = rx_symQ_aaf[0:len(rx_symQ_aaf):int(OS_DSP)]

#### AGC
target      = 1.4130800626285385# Vrms (EbNo=4 y seed=1)
metric      = np.std(rx_symI_dw+1j*rx_symQ_dw)
agc_gain    = target/metric
rx_symI_agc =  rx_symI_dw * agc_gain
rx_symQ_agc =  rx_symQ_dw * agc_gain

#### DSP
# FSE variables
fseI_buffer = np.zeros(NTAPS_FSE)
fseQ_buffer = np.zeros(NTAPS_FSE)
fseI_coeff  = np.zeros(NTAPS_FSE); fseI_coeff[int(NTAPS_FSE/2)] = 1
fseQ_coeff  = np.zeros(NTAPS_FSE); fseQ_coeff[int(NTAPS_FSE/2)] = 0
rx_symI_fse = np.zeros(NSYMB*OS_DSP)
rx_symQ_fse = np.zeros(NSYMB*OS_DSP)

log_step    = 500
coeffs_log  = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))

# FCR variables
nco_out     = 0
int_err     = 0 
rx_symI_fcr = np.zeros(NSYMB*OS_DSP)
rx_symQ_fcr = np.zeros(NSYMB*OS_DSP)
nco_log = np.zeros(NSYMB*OS_DSP)
int_log = np.zeros(NSYMB*OS_DSP)


# Slicer variables
rx_symI_slcr = np.zeros(NSYMB)
rx_symQ_slcr = np.zeros(NSYMB)

# Loop
for i in range(NSYMB*OS_DSP):
    # Filter buffer
    fseI_buffer[1:] = fseI_buffer[:-1]
    fseI_buffer[0]  = rx_symI_agc[i]
    fseQ_buffer[1:] = fseQ_buffer[:-1]
    fseQ_buffer[0]  = rx_symQ_agc[i]

    # Filter output
    rx_symI_fse[i] = np.dot(fseI_buffer,fseI_coeff)-np.dot(fseQ_buffer,fseQ_coeff)
    rx_symQ_fse[i] = np.dot(fseI_buffer,fseQ_coeff)+np.dot(fseQ_buffer,fseI_coeff)
    
    # FCR output: multiplication by e^{-jnco_out}
    rx_symI_fcr[i] = rx_symI_fse[i]*np.cos(-nco_out) - rx_symQ_fse[i]*np.sin(-nco_out)
    rx_symQ_fcr[i] = rx_symI_fse[i]*np.sin(-nco_out) + rx_symQ_fse[i]*np.cos(-nco_out)
    nco_log[i] = nco_out
    int_log[i] = int_err

    if((i+1)%OS_DSP)==0: # Downsampling to BR rate (os=1)
        k = int(i/OS_DSP)
        # Slicer
        rx_symI_slcr[k] = fn.slicer_pam(rx_symI_fcr[i])
        rx_symQ_slcr[k] = fn.slicer_pam(rx_symQ_fcr[i])
        
        # Error for LMS
        coeff_err_I = ((rx_symI_fcr[i]-rx_symI_slcr[k])*np.cos(nco_out) -
                       (rx_symQ_fcr[i]-rx_symQ_slcr[k])*np.sin(nco_out))
        coeff_err_Q = ((rx_symI_fcr[i]-rx_symI_slcr[k])*np.sin(nco_out) +
                       (rx_symQ_fcr[i]-rx_symQ_slcr[k])*np.cos(nco_out))
        
        fseI_coeff = (fseI_coeff*(1-lms_step*lms_leak) - 
                       lms_step*(coeff_err_I*fseI_buffer + coeff_err_Q*fseQ_buffer))
        fseQ_coeff = (fseQ_coeff*(1-lms_step*lms_leak) +
                       lms_step*( coeff_err_I*fseQ_buffer - coeff_err_Q*fseI_buffer))
        if( (((i+1)/OS_DSP)%log_step) == 0 ):
            coeffs_log[:, int(((i+1)/OS_DSP)/log_step)-1] = fseI_coeff
        
        # Phase error
        prod = (rx_symI_fcr[i]+1j*rx_symQ_fcr[i])*(rx_symI_slcr[k]-1j*rx_symQ_slcr[k])
        if( np.abs(prod)!= 0 ):
            prod_norm = prod/np.abs(prod)
        else:
            prod_norm = 0 + 1j*0
        angle_err = prod_norm.imag
        
        # PI loop filter
        Kp2 = Kp if(i>(NSYMB_CONVERGENCE/2)) else 0
        Ki2 = Ki if(i>(NSYMB_CONVERGENCE/2)) else 0
        prop_err =  Kp2 * angle_err
        int_err  = (Ki2 * angle_err) + int_err
        # NCO
        nco_out  = (prop_err+int_err) + nco_out
    

  
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

print("SNR=", SNR_db, " | f_off=",f_offset, " | step=", lms_step, " | Kp=", Kp, " | fc_ch=", fc_ch_filter)
print("BER_I: ", bit_err_I/bit_tot_I)
print("BER_Q: ", bit_err_Q/bit_tot_Q)
print("theo_ber: ", th_ber)


#########################  PRINCIPAL GRAPHICS ##########################
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
plt.plot(rx_symI_fcr[fase:len(rx_symI_fcr)-fase:2],'x')
plt.grid(True)
plt.subplot(2,1,2)
plt.title('FCR Output Q')
plt.plot(rx_symQ_fcr[fase:len(rx_symQ_fcr)-fase:2],'x')
plt.grid(True)
plt.xlabel('Nº símbolos')
plt.ylabel('I')
plt.savefig("fcr_out.png", dpi=300, format='png')
plt.close()

## Salida del NCO vs tiempo
#plt.figure(figsize=[10,6])
#plt.title('NCO Output')
#plt.plot(nco_log[fase:len(nco_log)-fase:2],'.')
#plt.grid(True)
#plt.xlabel('Nº símbolos')
#plt.ylabel('rad')
#plt.savefig("nco_out.png", dpi=300, format='png')
#plt.close()

## Error integral vs tiempo
#plt.figure(figsize=[10,6])
#plt.title('Int error')
#plt.plot(int_log[fase:len(int_log)-fase:2],'.')
#plt.grid(True)
#plt.xlabel('Nº símbolos')
#plt.ylabel('rad/s')
#plt.savefig("int_err.png", dpi=300, format='png')
#plt.close()

## Constelación a la salida del FCR (rangos ajustados para 10k)
#plt.figure(figsize=[6,6])
#plt.title('FCR Const - pre offset')
#plt.plot(rx_symI_fcr[fase:NSYMB_CONVERGENCE:2],
#         rx_symQ_fcr[fase:NSYMB_CONVERGENCE:2],
#         '.')
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.xlabel('Real')
#plt.ylabel('Imag')
#
#plt.figure(figsize=[6,6])
#plt.title('FCR Const - post offset')
#plt.plot(rx_symI_fcr[fase+NSYMB_CONVERGENCE:NSYMB_CONVERGENCE+200000:2],
#         rx_symQ_fcr[fase+NSYMB_CONVERGENCE:NSYMB_CONVERGENCE+200000:2],
#         '.')
#plt.plot(rx_symI_fcr[fase+NSYMB_CONVERGENCE+200000:len(rx_symI_fcr):2],
#         rx_symQ_fcr[fase+NSYMB_CONVERGENCE+200000:len(rx_symQ_fcr):2],
#         '.')
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.xlabel('Real')
#plt.ylabel('Imag')

plt.figure(figsize=[10,6])
plt.plot(coeffs_log.T)
plt.title('Coeficientes FFE')
plt.grid(True)
plt.savefig("coeff.png", dpi=300, format='png')
plt.close()



###########################  OTHER GRAPHICS ############################
# Símbolos generados, up-sampleados y filtrados
#plt.figure(figsize=[10,6])
#plt.subplot(3,1,1)
#plt.plot(tx_symI_map,'o')
#plt.xlim(0,20)
#plt.grid(True)
#plt.subplot(3,1,2)
#plt.plot(tx_symI_up,'o')
#plt.xlim(0,20)
#plt.grid(True)
#plt.subplot(3,1,3)
#plt.plot(tx_symI_rrc,'g-',linewidth=2.0)
#plt.xlim(0,500)
#plt.grid(True)
#plt.show()
#---------------
# Conteslación de símbolos post filtro RRC
#plt.figure(figsize=[6,6])
#plt.plot(tx_symI_rrc,
#         tx_symQ_rrc,
#         '.',linewidth=2.0)
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.xlabel('Real')
#plt.ylabel('Imag')
#plt.show()
#---------------
# Constelación de símbolos con ruido agregado
#plt.figure(figsize=[6,6])
#plt.plot(ch_symI_noisy[0:10000],
#         ch_symQ_noisy[0:10000],
#         '.')
#plt.xlim((-2, 2))
#plt.ylim((-2, 2))
#plt.grid(True)
#plt.xlabel('Real')
#plt.ylabel('Imag')
#plt.show()
#---------------
# Símbolos con ruidos pre y post rotación
#plt.figure(figsize=[6,6])
#plt.plot(ch_symIjQ_rot.real[0:NSYMB_CONVERGENCE*OS],
#         ch_symIjQ_rot.imag[0:NSYMB_CONVERGENCE*OS],
#         '.')
#plt.xlim((-6, 6))
#plt.ylim((-6, 6))
#plt.grid(True)
#plt.xlabel('Real')
#plt.ylabel('Imag')
#
#plt.figure(figsize=[6,6])
#plt.plot(ch_symIjQ_rot.real[NSYMB_CONVERGENCE*OS:],
#         ch_symIjQ_rot.imag[NSYMB_CONVERGENCE*OS:],
#         '.')
#plt.xlim((-6, 6))
#plt.ylim((-6, 6))
#plt.grid(True)
#plt.xlabel('Real')
#plt.ylabel('Imag')
#plt.show()
#---------------
# Símbolos downsampleados pre y post offset de protadora
#plt.figure(figsize=[6,6])
#plt.plot(rx_symI_dw[0:NSYMB_CONVERGENCE-1],
#         rx_symQ_dw[0:NSYMB_CONVERGENCE-1],
#         '.')
#plt.xlim((-6, 6))
#plt.ylim((-6, 6))
#plt.grid(True)
#plt.xlabel('Real')
#plt.ylabel('Imag')
#
#plt.figure(figsize=[6,6])
#plt.plot(rx_symI_dw[NSYMB_CONVERGENCE:],
#         rx_symQ_dw[NSYMB_CONVERGENCE:],
#         '.')
#plt.xlim((-6, 6))
#plt.ylim((-6, 6))
#plt.grid(True)
#plt.xlabel('Real')
#plt.ylabel('Imag')
#plt.show()
#---------------
## Respuesta en frecuencia de los filtros
#w_cha, h_cha = signal.freqz(ch_filt_coeff, worN=8000, fs=4*BR)
#w_aaf, h_aaf = signal.freqz(aaf_coeff, worN=8000, fs=4*BR)
## Gráfica de la respuesta en frecuencia
#plt.figure(figsize=(8, 4))
#plt.plot(w_cha, 20 * np.log10(np.abs(h_cha)), 'b')
#plt.axvline(x=(0.49*BR),color='k',linewidth=2.0)
#plt.axhline(y=20*np.log10(0.5),color='k',linewidth=2.0)
#plt.title("Respuesta en frecuencia del filtro de canal")
#plt.xlabel("Frecuencia [Hz]")
#plt.ylabel("Magnitud [dB]")
#plt.xlim(0, 2*BR)
#plt.grid()
#
#plt.figure(figsize=(8, 4))
#plt.plot(w_aaf, 20 * np.log10(np.abs(h_aaf)), 'r')
#plt.axvline(x=(1.*BR),color='k',linewidth=2.0)
#plt.axhline(y=20*np.log10(0.5),color='k',linewidth=2.0)
#plt.title("Respuesta en frecuencia del filtro anti alias")
#plt.xlabel("Frecuencia [Hz]")
#plt.ylabel("Magnitud [dB]")
#plt.xlim(0, 2*BR)
#plt.grid()
#
#plt.show()
#
