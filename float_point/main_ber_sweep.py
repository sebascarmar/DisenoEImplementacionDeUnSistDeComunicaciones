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

#### Sweep
SWEEP_TIMES = 7
START_SWP   = 7

#### General
NSYMB = 850000
BR    = 25e6    # Baud
OS    = 4       # oversampling
BETA  = 0.5     # roll-off
NBAUD = 5
M     = 4       # modulation order
SEED_I =  0x1AA
SEED_Q =  0x1FE

#### Channel
NSYMB_CONVERGENCE = 20000   # FSE and FCR convergence (a half for each)
f_offset     = 12e3 # Hz
fc_ch_filter = 0.48*BR # Cut-off frecuency of channel filter [Hz]

#### Receiver
fc_aa_filter = 0.5*BR # Cut-off frecuency of anti-alias filter [Hz]
OS_DSP       = 2
NTAPS_FSE    = 33
lms_step     = 0.5e-3
lms_leak     = 1e-3
Kp           = 1e-3
Ki           = Kp/1000

#### BER counter
START_SYN = 249879 
prbs9_cycles = 16  # right value: 511
START_CNT = START_SYN + 511*prbs9_cycles

# np.random.seed(1)  # set the seed: 3-0-4-1


bersI_contadas = np.zeros(SWEEP_TIMES+START_SWP)
bersQ_contadas = np.zeros(SWEEP_TIMES+START_SWP)
th_ber         = np.zeros(SWEEP_TIMES+START_SWP)
for SNR_db in range(START_SWP, SWEEP_TIMES+START_SWP):
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
    (t, txf_coeff, dot) = fn.r_rcosine(fc=BR/2, fs=OS*BR, rolloff=BETA, nbauds=NBAUD, norm=True)
    
    tx_symI_txf = signal.lfilter(txf_coeff, [1], tx_symI_up)
    tx_symQ_txf = signal.lfilter(txf_coeff, [1], tx_symQ_up)
    
    
    
    ################################ CHANNEL ###############################
    #### AWGN
    SNR_slicer = 10**(SNR_db/10)
    SNR_ch     = SNR_slicer/OS
    noise_var  = np.var(tx_symI_txf+1j*tx_symQ_txf)/SNR_ch
    noise_I    = np.sqrt(noise_var/2)*np.random.normal(loc=0, scale=1, size=tx_symI_txf.shape)
    noise_Q    = np.sqrt(noise_var/2)*np.random.normal(loc=0, scale=1, size=tx_symQ_txf.shape)
    
    ch_symI_noisy = tx_symI_txf + noise_I
    ch_symQ_noisy = tx_symQ_txf + noise_Q
    
    
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
    (t2, ch_filt_coeff, dot) = fn.r_rcosine(fc=fc_ch_filter, fs=OS*BR, rolloff=BETA, nbauds=4, norm=True)
    ch_symI_ch_filt = signal.lfilter(ch_filt_coeff, [1], ch_symI_rot)
    ch_symQ_ch_filt = signal.lfilter(ch_filt_coeff, [1], ch_symQ_rot)
    
    
    ############################### RECEIVER ###############################
    #### Anti-alias filter
    (t3, aaf_coeff, dot) = fn.r_rcosine(fc=fc_aa_filter, fs=OS*BR, rolloff=BETA, nbauds=4, norm=True)
    rx_symI_aaf = signal.lfilter(aaf_coeff, [1], ch_symI_ch_filt)
    rx_symQ_aaf = signal.lfilter(aaf_coeff, [1], ch_symQ_ch_filt)
    
    #### Downsampler (rate 2)
    rx_symI_dw_r2 = rx_symI_aaf[0:len(rx_symI_aaf):int(OS_DSP)]
    rx_symQ_dw_r2 = rx_symQ_aaf[0:len(rx_symQ_aaf):int(OS_DSP)]
    
    
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
        fseI_buffer[0]  = rx_symI_dw_r2[j]
        fseQ_buffer[1:] = fseQ_buffer[:-1]
        fseQ_buffer[0]  = rx_symQ_dw_r2[j]
    
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
    shifter_ber_I = np.full(511,1)
    shifter_ber_Q = np.full(511,1)
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
    for BER_IDX in range(prbs9_cycles):
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
    
    
    bersI_contadas[SNR_db] = bit_err_I/bit_tot_I
    bersQ_contadas[SNR_db] = bit_err_Q/bit_tot_Q
    th_ber[SNR_db] = fn.theoric_ber(M, SNR_db)

    print("SNR=", SNR_db, " | f_off=",f_offset)
    print("BER_I: ", bit_err_I/bit_tot_I)
    print("BER_Q: ", bit_err_Q/bit_tot_Q)
    print("theo_ber: ", th_ber[SNR_db], "\n")


############################ GRAPHICS #############################

# Create a full range for the x axis, starting from 0
x_axis_full = np.arange(0, SWEEP_TIMES+START_SWP)
# Create a new array for counted errors aligned with x_axis_full,
#filling with NaN where there is no data
bersI_full = np.full_like(x_axis_full, np.nan, dtype=float)
bersI_full[START_SWP: len(bersI_contadas)] = bersI_contadas[START_SWP:] 

bersQ_full = np.full_like(x_axis_full, np.nan, dtype=float)
bersQ_full[START_SWP: len(bersQ_contadas)] = bersQ_contadas[START_SWP:] 

th_ber_full = np.full_like(x_axis_full, np.nan, dtype=float)
th_ber_full[START_SWP: len(th_ber)] = th_ber[START_SWP:] 

# Plot
plt.figure(figsize=[14,6])
plt.title('BER vs SNR')
plt.semilogy(x_axis_full, th_ber_full, 'r', linewidth=2.0)
plt.semilogy(x_axis_full, bersI_full, 'b', linewidth=2.0)
plt.semilogy(x_axis_full, bersQ_full, 'g', linewidth=2.0)
plt.xlabel('SNR(dB)')
plt.ylabel('BER')
plt.grid(True)
# plt.xlim(0,SWEEP_TIMES+START_SWP)
# plt.ylim(0.0001,1)
plt.legend(['SNR theo','SNR I','SNR Q'])
plt.show()
