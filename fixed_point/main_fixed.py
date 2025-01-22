import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.io import savemat
import math
import functions as fn
from classes.prbs9 import prbs9
from classes.poly_filter import poly_filter
from classes.noise_gen import noise_gen
from classes.offset_gen import offset_gen
from classes.fir_filter import fir_filter


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

np.random.seed(2)  # set the seed

############################## TRANSMITTER  #############################

#### Bits generation
tx_bitI_prbs_log = np.zeros(NSYMB)
tx_bitQ_prbs_log = np.zeros(NSYMB)

prbs9I = prbs9([0, 1, 0, 1, 0, 1, 0, 1, 1]) # Seed: 0x1AA
prbs9Q = prbs9([0, 1, 1, 1, 1, 1, 1, 1, 1]) # Seed: 0x1FE

#### Mapper
tx_symI_map_log = np.zeros(NSYMB)
tx_symQ_map_log = np.zeros(NSYMB)

#### RRC Filter (also up-sampler)
(t, rrc, dot) = fn.r_rcosine(fc=BR/2, fs=OS*BR, rolloff=BETA, nbauds=NBAUD, norm=True)
tx_filter_I = poly_filter(rrc, NBAUD, OS, NSYMB)
tx_filter_Q = poly_filter(rrc, NBAUD, OS, NSYMB)
tx_symI_rrc_log = np.zeros(OS*NSYMB)
tx_symQ_rrc_log = np.zeros(OS*NSYMB)

################################ CHANNEL ###############################
#### AWGN
awgn_gen_I = noise_gen(OS, SNR_db)
awgn_gen_Q = noise_gen(OS, SNR_db)
ch_symI_noisy_log = np.zeros(OS*NSYMB)
ch_symQ_noisy_log = np.zeros(OS*NSYMB)

#### Frequency Offset
offset_freq = offset_gen(OS*BR, f_offset)
ch_symI_rot_log = np.zeros(OS*NSYMB)
ch_symQ_rot_log = np.zeros(OS*NSYMB)

#### Channel filter
ch_filt_coeff   = signal.firwin(numtaps=17, cutoff=fc_ch_filter ,window='hamming', fs=4*BR)
chann_filt_I = fir_filter(ch_filt_coeff)
chann_filt_Q = fir_filter(ch_filt_coeff)
ch_symI_chfilt_log = np.zeros(OS*NSYMB)
ch_symQ_chfilt_log = np.zeros(OS*NSYMB)

############################### RECEIVER ###############################
#### Anti-alias filter
aaf_coeff  = signal.firwin(numtaps=17, cutoff=BR ,window='hamming', fs=4*BR)
aaf_filt_I = fir_filter(aaf_coeff)
aaf_filt_Q = fir_filter(aaf_coeff)
rx_symI_aaf_log = np.zeros(OS*NSYMB)
rx_symQ_aaf_log = np.zeros(OS*NSYMB)

#### Downsampler (rate 2)
dw_aaf_shifter_I = np.zeros(OS_DSP)
dw_aaf_shifter_Q = np.zeros(OS_DSP)
rx_symI_dw_log = np.zeros(NSYMB*OS_DSP)
rx_symQ_dw_log = np.zeros(NSYMB*OS_DSP)

#### AGC
agc_gain    = 1
rx_symI_agc_log =  np.zeros(NSYMB*OS_DSP)
rx_symQ_agc_log =  np.zeros(NSYMB*OS_DSP)

#### DSP
# FSE variables
fseI_buffer = np.zeros(NTAPS_FSE)
fseQ_buffer = np.zeros(NTAPS_FSE)
fseI_coeff  = np.zeros(NTAPS_FSE); fseI_coeff[int(NTAPS_FSE/2)] = 1
fseQ_coeff  = np.zeros(NTAPS_FSE); fseQ_coeff[int(NTAPS_FSE/2)] = 0

rx_symI_fse = np.zeros(NSYMB*OS_DSP)
rx_symQ_fse = np.zeros(NSYMB*OS_DSP)
log_step        = 500
coeffs_log      = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))

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

############################ BIT-ERROR RATE ############################
#### Bits generation
prbs9I_rx = prbs9([0, 1, 0, 1, 0, 1, 0, 1, 1]) # Seed: 0x1AA
prbs9Q_rx = prbs9([0, 1, 1, 1, 1, 1, 1, 1, 1]) # Seed: 0x1FE

#### Synchronization
# PRBS regster and data
shftr_berI = np.zeros(511, dtype=int)
shftr_berQ = np.zeros(511, dtype=int)

# Synchro variables
min_error   = len(shftr_berQ)
err_sym_0   = 0
err_sym_90  = 0
err_sym_180 = 0
err_sym_270 = 0
BER_IDX       = 0
latency       = 0
rot_ang_detec = 0

#### Counting errors after synchronization
# BER (Lane I)
bit_err_I = 0
bit_tot_I = 0

# BER (Lane Q)
bit_err_Q = 0
bit_tot_Q = 0


for i in range(NSYMB*OS):

    ############################## TRANSMITTER  #############################
    if( i%OS ==0 ): # Downsampling to BR rate (os=1)
        n = int(i/OS)
        #### Bits generation
        tx_bitI_prbs = prbs9I.get_new_bit()
        tx_bitQ_prbs = prbs9Q.get_new_bit()
        #tx_bitI_prbs_log[n] = tx_bitI_prbs
        #tx_bitQ_prbs_log[n] = tx_bitQ_prbs
        
        #### Mapper
        tx_symI_map = 1 if(tx_bitI_prbs == 0) else -1
        tx_symQ_map = 1 if(tx_bitQ_prbs == 0) else -1
        #tx_symI_map_log[n]=tx_symI_map
        #tx_symQ_map_log[n]=tx_symQ_map

    #### Up-sampler & Tx Filter
    tx_symI_rrc = tx_filter_I.convol(i, tx_symI_map) 
    tx_symQ_rrc = tx_filter_Q.convol(i, tx_symQ_map) 
    #tx_symI_rrc_log[i] = tx_symI_rrc
    #tx_symQ_rrc_log[i] = tx_symQ_rrc

    ################################ CHANNEL ###############################
    #### Noise
    ch_symI_noisy = awgn_gen_I.add_noise(tx_symI_rrc)
    ch_symQ_noisy = awgn_gen_Q.add_noise(tx_symQ_rrc)
    #ch_symI_noisy_log[i] = ch_symI_noisy
    #ch_symQ_noisy_log[i] = ch_symQ_noisy

    #### Frequency Offset
    if( i>(NSYMB_CONVERGENCE*OS-1) ):
        ch_symI_rot, ch_symQ_rot = offset_freq.get_offset(ch_symI_noisy, ch_symQ_noisy)
    else:
        ch_symI_rot, ch_symQ_rot = offset_freq.get_no_offset(ch_symI_noisy, ch_symQ_noisy)
    ch_symI_rot_log[i] = ch_symI_rot
    ch_symQ_rot_log[i] = ch_symQ_rot

    #### Channel filter (ISI)
    ch_symI_chfilt = chann_filt_I.convol(ch_symI_rot)
    ch_symQ_chfilt = chann_filt_Q.convol(ch_symQ_rot)
    ch_symI_chfilt_log[i] = ch_symI_chfilt
    ch_symQ_chfilt_log[i] = ch_symQ_chfilt

    ############################### RECEIVER ###############################
    #### Anti-alias filter
    rx_symI_aaf = aaf_filt_I.convol(ch_symI_chfilt)
    rx_symQ_aaf = aaf_filt_Q.convol(ch_symQ_chfilt)
    #rx_symI_aaf_log[i] = rx_symI_aaf
    #rx_symQ_aaf_log[i] = rx_symQ_aaf

    #### Downsamplers (rate 2)
    dw_aaf_shifter_I    = np.roll(dw_aaf_shifter_I,1)
    dw_aaf_shifter_Q    = np.roll(dw_aaf_shifter_Q,1)
    dw_aaf_shifter_I[0] = rx_symI_aaf
    dw_aaf_shifter_Q[0] = rx_symQ_aaf

    rx_symI_dw = dw_aaf_shifter_I[0]
    rx_symQ_dw = dw_aaf_shifter_Q[0]

    if( i%OS_DSP ==0 ): # Downsampling to OS_DSP*BR rate
        j = int(i/OS_DSP)
        #rx_symI_dw_log[j] = rx_symI_dw
        #rx_symQ_dw_log[j] = rx_symQ_dw
        
        #### AGC
        rx_symI_agc =  rx_symI_dw * agc_gain
        rx_symQ_agc =  rx_symQ_dw * agc_gain
        rx_symI_agc_log[j] = rx_symI_agc
        rx_symQ_agc_log[j] = rx_symQ_agc
        
        #### DSP
        # Filter buffer
        fseI_buffer[1:] = fseI_buffer[:-1]
        fseI_buffer[0]  = rx_symI_agc
        fseQ_buffer[1:] = fseQ_buffer[:-1]
        fseQ_buffer[0]  = rx_symQ_agc
        
        # Filter output
        rx_symI_fse[j] = np.dot(fseI_buffer,fseI_coeff)-np.dot(fseQ_buffer,fseQ_coeff)
        rx_symQ_fse[j] = np.dot(fseI_buffer,fseQ_coeff)+np.dot(fseQ_buffer,fseI_coeff)
        
        # FCR output: multiplication by e^{-jnco_out}
        rx_symI_fcr[j] = rx_symI_fse[j]*np.cos(-nco_out) - rx_symQ_fse[j]*np.sin(-nco_out)
        rx_symQ_fcr[j] = rx_symI_fse[j]*np.sin(-nco_out) + rx_symQ_fse[j]*np.cos(-nco_out)
        #nco_log[j] = nco_out
        #int_log[j] = int_err
        
        if((j+1)%OS_DSP)==0: # Downsampling to BR rate (os=1)
            k = int(j/OS_DSP)
            # Slicer
            rx_symI_slcr[k] = fn.slicer_pam(rx_symI_fcr[j])
            rx_symQ_slcr[k] = fn.slicer_pam(rx_symQ_fcr[j])
            
            # Error for LMS
            coeff_err_I = ((rx_symI_fcr[j]-rx_symI_slcr[k])*np.cos(nco_out) -
                           (rx_symQ_fcr[j]-rx_symQ_slcr[k])*np.sin(nco_out))
            coeff_err_Q = ((rx_symI_fcr[j]-rx_symI_slcr[k])*np.sin(nco_out) +
                           (rx_symQ_fcr[j]-rx_symQ_slcr[k])*np.cos(nco_out))
            
            fseI_coeff = (fseI_coeff*(1-lms_step*lms_leak) - 
                           lms_step*(coeff_err_I*fseI_buffer + coeff_err_Q*fseQ_buffer))
            fseQ_coeff = (fseQ_coeff*(1-lms_step*lms_leak) +
                           lms_step*( coeff_err_I*fseQ_buffer - coeff_err_Q*fseI_buffer))
            if( (((j+1)/OS_DSP)%log_step) == 0 ):
                coeffs_log[:, int(((j+1)/OS_DSP)/log_step)-1] = fseI_coeff
            
            # Phase error
            prod = (rx_symI_fcr[j]+1j*rx_symQ_fcr[j])*(rx_symI_slcr[k]-1j*rx_symQ_slcr[k])
            if( np.abs(prod)!= 0 ):
                prod_norm = prod/np.abs(prod)
            else:
                prod_norm = 0 + 1j*0
            angle_err = prod_norm.imag
            
            # PI loop filter
            Kp2 = Kp if(j>(NSYMB_CONVERGENCE/2)) else 0
            Ki2 = Ki if(j>(NSYMB_CONVERGENCE/2)) else 0
            prop_err =  Kp2 * angle_err
            int_err  = (Ki2 * angle_err) + int_err
            # NCO
            nco_out  = (prop_err+int_err) + nco_out
            
            # Demapper
            rx_bitI_demap = 0 if(rx_symI_slcr[k]==1) else 1
            rx_bitQ_demap = 0 if(rx_symQ_slcr[k]==1) else 1
         
            ######################## BIT-ERROR RATE ########################
            if( k>=START_SYN and k<START_CNT ):
                if( k%511 == 0 and k>START_SYN ):
                    #print(BER_IDX,k, min(err_sym_0,err_sym_90,err_sym_180,err_sym_270))
                    # Store data for the minimum case and reset accumulators
                    if( err_sym_0<min_error   and err_sym_0<err_sym_90 and
                        err_sym_0<err_sym_180 and err_sym_0<err_sym_270):
                        min_error     = err_sym_0
                        err_sym_0     = 0
                        latency       = BER_IDX
                        rot_ang_detec = 0
                        print(BER_IDX,i,"latency:",latency, "| ang:",rot_ang_detec, "| error_min:", min_error)
                    elif( err_sym_90<min_error and err_sym_90<err_sym_180 and
                          err_sym_90<err_sym_270 ):
                        min_error     = err_sym_90
                        err_sym_90    = 0
                        latency       = BER_IDX
                        rot_ang_detec = 90
                        print(BER_IDX,i,"latency:",latency, "| ang:",rot_ang_detec, "| error_min:", min_error)
                    elif( err_sym_180<min_error and err_sym_180<err_sym_270 ):
                        min_error     = err_sym_180
                        err_sym_180   = 0
                        latency       = BER_IDX
                        rot_ang_detec = 180
                        print(BER_IDX,i,"latency:",latency, "| ang:",rot_ang_detec, "| error_min:", min_error)
                    elif( err_sym_270<min_error ):
                        min_error     = err_sym_270
                        err_sym_270   = 0
                        latency       = BER_IDX
                        rot_ang_detec = 270
                        print(BER_IDX,i,"latency:",latency, "| ang:",rot_ang_detec, "| error_min:", min_error)
                    else:
                        err_sym_0   = 0
                        err_sym_90  = 0
                        err_sym_180 = 0
                        err_sym_270 = 0
                        min_error     = min_error    
                        latency       = latency  
                        rot_ang_detec = rot_ang_detec
                    
                    # Update the pointer to the BER shifter 
                    BER_IDX += 1
                else:
                    err_sym_0   = err_sym_0  
                    err_sym_90  = err_sym_90 
                    err_sym_180 = err_sym_180
                    err_sym_270 = err_sym_270
                    BER_IDX = BER_IDX
             
                # Shift and update register used for PRBS 
                shftr_berI = np.roll(shftr_berI,1)
                shftr_berQ = np.roll(shftr_berQ,1)
                shftr_berI[0] = prbs9I_rx.get_new_bit()
                shftr_berQ[0] = prbs9Q_rx.get_new_bit()
              
                # Compare PRBS with received data rotated by 0º (BER_IDX refers to a fixed position)
                err_sym_0   += (shftr_berI[BER_IDX]^rx_bitI_demap) | (shftr_berQ[BER_IDX]^rx_bitQ_demap)
                # Compare PRBS with received data rotated by 90º (BER_IDX refers to a fixed position)
                err_sym_90  += (shftr_berI[BER_IDX]^fn.inv(rx_bitQ_demap)) | (shftr_berQ[BER_IDX]^rx_bitI_demap)
                # Compare PRBS with received data rotated by 180º (BER_IDX refers to a fixed position)
                err_sym_180 += (shftr_berI[BER_IDX]^fn.inv(rx_bitI_demap)) | (shftr_berQ[BER_IDX]^fn.inv(rx_bitQ_demap))
                # Compare PRBS with received data rotated by 270º (BER_IDX refers to a fixed position)
                err_sym_270 += (shftr_berI[BER_IDX]^rx_bitQ_demap) | (shftr_berQ[BER_IDX]^fn.inv(rx_bitI_demap))
                
                
            else: ############################## Error counting (k<START_CNT)
                
                # Apply the detected rotation
                if( rot_ang_detec == 0 ):
                    rx_bitI_rot =        rx_bitI_demap
                    rx_bitQ_rot =        rx_bitQ_demap
                elif( rot_ang_detec == 90 ):
                    rx_bitI_rot = fn.inv(rx_bitQ_demap)
                    rx_bitQ_rot =        rx_bitI_demap
                elif( rot_ang_detec == 180 ):
                    rx_bitI_rot = fn.inv(rx_bitI_demap)
                    rx_bitQ_rot = fn.inv(rx_bitQ_demap)
                else: # rot_ang_detec=270
                    rx_bitI_rot =        rx_bitQ_demap
                    rx_bitQ_rot = fn.inv(rx_bitI_demap)
                
                # Shift and update register used for PRBS 
                shftr_berI = np.roll(shftr_berI,1)
                shftr_berQ = np.roll(shftr_berQ,1)
                shftr_berI[0] = prbs9I_rx.get_new_bit()
                shftr_berQ[0] = prbs9Q_rx.get_new_bit()
             
                # Lane I
                bit_err_I += shftr_berI[latency] ^ rx_bitI_rot
                bit_tot_I += 1
                
                # Lane Q
                bit_err_Q += shftr_berQ[latency] ^ rx_bitQ_rot
                bit_tot_Q += 1
                


th_ber = fn.theoric_ber(M, SNR_db)
print("latency:",latency, "| ang:",rot_ang_detec, "| error_min:", min_error)
print("SNR=", SNR_db, " | f_off=",f_offset, " | step=", lms_step, " | Kp=", Kp, " | fc_ch=", fc_ch_filter)
print("BER_I: ", bit_err_I/bit_tot_I)
print("BER_Q: ", bit_err_Q/bit_tot_Q)
print("theo_ber: ", th_ber)
# Guardar el array en un archivo de texto
#np.savetxt('tx_symI_map.txt', tx_symI_map_log, delimiter=',')
#np.savetxt('tx_symQ_map.txt', tx_symQ_map_log, delimiter=',')
#np.savetxt('tx_symI_rrc.txt', tx_symI_rrc_log, delimiter=',')
#np.savetxt('tx_symQ_rrc.txt', tx_symQ_rrc_log, delimiter=',')
#np.savetxt('ch_symI_noisy.txt', ch_symI_noisy_log, delimiter=',')
#np.savetxt('ch_symQ_noisy.txt', ch_symQ_noisy_log, delimiter=',')
#np.savetxt('ch_symI_rot.txt', ch_symI_rot_log, delimiter=',')
#np.savetxt('ch_symQ_rot.txt', ch_symQ_rot_log, delimiter=',')
#np.savetxt('ch_symI_chfilt.txt', ch_symI_chfilt_log, delimiter=',')
#np.savetxt('ch_symQ_chfilt.txt', ch_symQ_chfilt_log, delimiter=',')
#np.savetxt('rx_symI_aaf.txt', rx_symI_aaf_log, delimiter=',')
#np.savetxt('rx_symQ_aaf.txt', rx_symQ_aaf_log, delimiter=',')
#np.savetxt('rx_symI_dw.txt', rx_symI_dw_log, delimiter=',')
#np.savetxt('rx_symQ_dw.txt', rx_symQ_dw_log, delimiter=',')
#np.savetxt('rx_symI_agc.txt', rx_symI_agc_log, delimiter=',')
#np.savetxt('rx_symQ_agc.txt', rx_symQ_agc_log, delimiter=',')
#np.savetxt('rx_symI_fse.txt', rx_symI_fse, delimiter=',')
#np.savetxt('rx_symQ_fse.txt', rx_symQ_fse, delimiter=',')
#np.savetxt('rx_symI_fcr.txt', rx_symI_fcr, delimiter=',')
#np.savetxt('rx_symQ_fcr.txt', rx_symQ_fcr, delimiter=',')
np.savetxt('rx_symI_slcr.txt', rx_symI_slcr, delimiter=',')
np.savetxt('rx_symQ_slcr.txt', rx_symQ_slcr, delimiter=',')

#-------------------------------------------











