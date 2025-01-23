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
from classes.ber import ber


####################################################################################
#                                      MAIN                                        #
####################################################################################

############################### PARAMETERS #############################

#### General
NSYMB = 1000000 # 1e6
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
TX_BITI_PRBS_LOG = np.zeros(NSYMB)
TX_BITQ_PRBS_LOG = np.zeros(NSYMB)

prbs9I = prbs9(SEED_I)
prbs9Q = prbs9(SEED_Q)

#### Mapper
TX_SYMI_MAP_LOG = np.zeros(NSYMB)
TX_SYMQ_MAP_LOG = np.zeros(NSYMB)

#### RRC Filter (also up-sampler)
(t, rrc, dot) = fn.r_rcosine(fc=BR/2, fs=OS*BR, rolloff=BETA, nbauds=NBAUD, norm=True)
tx_filter_I = poly_filter(rrc, NBAUD, OS, NSYMB)
tx_filter_Q = poly_filter(rrc, NBAUD, OS, NSYMB)
TX_SYMI_RRC_LOG = np.zeros(OS*NSYMB)
TX_SYMQ_RRC_LOG = np.zeros(OS*NSYMB)

################################ CHANNEL ###############################
#### AWGN
awgn_gen_I = noise_gen(OS, SNR_db)
awgn_gen_Q = noise_gen(OS, SNR_db)
CH_SYMI_NOISY_LOG = np.zeros(OS*NSYMB)
CH_SYMQ_NOISY_LOG = np.zeros(OS*NSYMB)

#### Frequency Offset
offset_freq = offset_gen(OS*BR, f_offset)
CH_SYMI_ROT_LOG = np.zeros(OS*NSYMB)
CH_SYMQ_ROT_LOG = np.zeros(OS*NSYMB)

#### Channel filter
ch_filt_coeff   = signal.firwin(numtaps=17, cutoff=fc_ch_filter ,window='hamming', fs=4*BR)
chann_filt_I = fir_filter(ch_filt_coeff)
chann_filt_Q = fir_filter(ch_filt_coeff)
CH_SYMI_CHFILT_LOG = np.zeros(OS*NSYMB)
CH_SYMQ_CHFILT_LOG = np.zeros(OS*NSYMB)

############################### RECEIVER ###############################
#### Anti-alias filter
aaf_coeff  = signal.firwin(numtaps=17, cutoff=BR ,window='hamming', fs=4*BR)
aaf_filt_I = fir_filter(aaf_coeff)
aaf_filt_Q = fir_filter(aaf_coeff)
RX_SYMI_AAF_LOG = np.zeros(OS*NSYMB)
RX_SYMQ_AAF_LOG = np.zeros(OS*NSYMB)

#### Downsampler (rate 2)
dw_aaf_shifter_I = np.zeros(OS_DSP)
dw_aaf_shifter_Q = np.zeros(OS_DSP)
RX_SYMI_DW_RATE2_LOG = np.zeros(NSYMB*OS_DSP)
RX_SYMQ_DW_RATE2_LOG = np.zeros(NSYMB*OS_DSP)

#### AGC
agc_gain    = 1
RX_SYMI_AGC_LOG =  np.zeros(NSYMB*OS_DSP)
RX_SYMQ_AGC_LOG =  np.zeros(NSYMB*OS_DSP)

#### DSP
# FSE variables
fseI_buffer = np.zeros(NTAPS_FSE)
fseQ_buffer = np.zeros(NTAPS_FSE)
fseI_coeff  = np.zeros(NTAPS_FSE); fseI_coeff[int(NTAPS_FSE/2)] = 1
fseQ_coeff  = np.zeros(NTAPS_FSE); fseQ_coeff[int(NTAPS_FSE/2)] = 0

rx_symI_fse = 0.0
rx_symQ_fse = 0.0
RX_SYMI_FSE_LOG = np.zeros(NSYMB*OS_DSP)
RX_SYMQ_FSE_LOG = np.zeros(NSYMB*OS_DSP)

log_step     = 500
FSE_I_COEFFS_LOG = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))

# FCR variables
nco_out     = 0
int_err     = 0 
rx_symI_fcr = 0.0
rx_symQ_fcr = 0.0
RX_SYMI_FCR_LOG = np.zeros(NSYMB*OS_DSP)
RX_SYMQ_FCR_LOG = np.zeros(NSYMB*OS_DSP)
NCO_OUT_LOG     = np.zeros(NSYMB*OS_DSP)
INT_ERR_LOG     = np.zeros(NSYMB*OS_DSP)

# Downsampler (rate 1)
RX_SYMI_DW_RATE1_LOG = np.zeros(NSYMB)
RX_SYMQ_DW_RATE1_LOG = np.zeros(NSYMB)

# Slicer variables     np.zeros(NSYMB
RX_SYMI_SLCR_LOG = np.zeros(NSYMB)
RX_SYMQ_SLCR_LOG = np.zeros(NSYMB)

#### Demapper
RX_BITI_DEMAP_LOG= np.zeros(NSYMB)
RX_BITQ_DEMAP_LOG= np.zeros(NSYMB)

############################ BIT-ERROR RATE ############################
ber_IjQ = ber(SEED_I, SEED_Q, START_SYN, START_CNT)



################################## LOOP ################################
for i in range(NSYMB*OS):

    ############################## TRANSMITTER  #############################
    if( i%OS ==0 ): # Downsampling to BR rate (os=1)
        n = int(i/OS)
        #### Bits generation
        tx_bitI_prbs = prbs9I.get_new_bit()
        tx_bitQ_prbs = prbs9Q.get_new_bit()
        TX_BITI_PRBS_LOG[n] = tx_bitI_prbs
        TX_BITQ_PRBS_LOG[n] = tx_bitQ_prbs
        
        #### Mapper
        tx_symI_map = 1 if(tx_bitI_prbs == 0) else -1
        tx_symQ_map = 1 if(tx_bitQ_prbs == 0) else -1
        TX_SYMI_MAP_LOG[n]=tx_symI_map
        TX_SYMQ_MAP_LOG[n]=tx_symQ_map

    #### Up-sampler & Tx Filter
    tx_symI_rrc = tx_filter_I.convol(i, tx_symI_map) 
    tx_symQ_rrc = tx_filter_Q.convol(i, tx_symQ_map) 
    TX_SYMI_RRC_LOG[i] = tx_symI_rrc
    TX_SYMQ_RRC_LOG[i] = tx_symQ_rrc

    ################################ CHANNEL ###############################
    #### Noise
    ch_symI_noisy = awgn_gen_I.add_noise(tx_symI_rrc)
    ch_symQ_noisy = awgn_gen_Q.add_noise(tx_symQ_rrc)
    CH_SYMI_NOISY_LOG[i] = ch_symI_noisy
    CH_SYMQ_NOISY_LOG[i] = ch_symQ_noisy

    #### Frequency Offset
    if( i>(NSYMB_CONVERGENCE*OS-1) ):
        ch_symI_rot, ch_symQ_rot = offset_freq.get_offset(ch_symI_noisy, ch_symQ_noisy)
    else:
        ch_symI_rot, ch_symQ_rot = offset_freq.get_no_offset(ch_symI_noisy, ch_symQ_noisy)
    CH_SYMI_ROT_LOG[i] = ch_symI_rot
    CH_SYMQ_ROT_LOG[i] = ch_symQ_rot

    #### Channel filter (ISI)
    ch_symI_chfilt = chann_filt_I.convol(ch_symI_rot)
    ch_symQ_chfilt = chann_filt_Q.convol(ch_symQ_rot)
    CH_SYMI_CHFILT_LOG[i] = ch_symI_chfilt
    CH_SYMQ_CHFILT_LOG[i] = ch_symQ_chfilt

    ############################### RECEIVER ###############################
    #### Anti-alias filter
    rx_symI_aaf = aaf_filt_I.convol(ch_symI_chfilt)
    rx_symQ_aaf = aaf_filt_Q.convol(ch_symQ_chfilt)
    RX_SYMI_AAF_LOG[i] = rx_symI_aaf
    RX_SYMQ_AAF_LOG[i] = rx_symQ_aaf

    #### Downsamplers (rate 2)
    dw_aaf_shifter_I    = np.roll(dw_aaf_shifter_I,1)
    dw_aaf_shifter_Q    = np.roll(dw_aaf_shifter_Q,1)
    dw_aaf_shifter_I[0] = rx_symI_aaf
    dw_aaf_shifter_Q[0] = rx_symQ_aaf

    rx_symI_dw = dw_aaf_shifter_I[0]
    rx_symQ_dw = dw_aaf_shifter_Q[0]

    if( i%OS_DSP ==0 ): # Downsampling to OS_DSP*BR rate
        j = int(i/OS_DSP)
        RX_SYMI_DW_RATE2_LOG[j] = rx_symI_dw
        RX_SYMQ_DW_RATE2_LOG[j] = rx_symQ_dw
        
        #### AGC
        rx_symI_agc =  rx_symI_dw * agc_gain
        rx_symQ_agc =  rx_symQ_dw * agc_gain
        RX_SYMI_AGC_LOG[j] = rx_symI_agc
        RX_SYMQ_AGC_LOG[j] = rx_symQ_agc
        
        #### DSP
        # Filter buffer
        fseI_buffer[1:] = fseI_buffer[:-1]
        fseI_buffer[0]  = rx_symI_agc
        fseQ_buffer[1:] = fseQ_buffer[:-1]
        fseQ_buffer[0]  = rx_symQ_agc
        
        # Filter output
        rx_symI_fse = np.dot(fseI_buffer,fseI_coeff)-np.dot(fseQ_buffer,fseQ_coeff)
        rx_symQ_fse = np.dot(fseI_buffer,fseQ_coeff)+np.dot(fseQ_buffer,fseI_coeff)
        RX_SYMI_FSE_LOG[j] = rx_symI_fse 
        RX_SYMQ_FSE_LOG[j] = rx_symQ_fse 
        
        # FCR output: multiplication by e^{-jnco_out}
        rx_symI_fcr = rx_symI_fse*np.cos(-nco_out) - rx_symQ_fse*np.sin(-nco_out)
        rx_symQ_fcr = rx_symI_fse*np.sin(-nco_out) + rx_symQ_fse*np.cos(-nco_out)
        RX_SYMI_FCR_LOG[j] = rx_symI_fcr 
        RX_SYMQ_FCR_LOG[j] = rx_symQ_fcr 
        NCO_OUT_LOG[j]     = nco_out
        INT_ERR_LOG[j]     = int_err
        
        if((j+1)%OS_DSP)==0: # Downsampling to BR rate (os=1)
            k = int(j/OS_DSP)
            RX_SYMI_DW_RATE1_LOG[k] = rx_symI_fcr
            RX_SYMQ_DW_RATE1_LOG[k] = rx_symQ_fcr
            # Slicer
            rx_symI_slcr = fn.slicer_pam(rx_symI_fcr)
            rx_symQ_slcr = fn.slicer_pam(rx_symQ_fcr)
            RX_SYMI_SLCR_LOG[k] = rx_symI_slcr
            RX_SYMQ_SLCR_LOG[k] = rx_symQ_slcr
            
            # Error for LMS
            coeff_err_I = ((rx_symI_fcr-rx_symI_slcr)*np.cos(nco_out) -
                           (rx_symQ_fcr-rx_symQ_slcr)*np.sin(nco_out))
            coeff_err_Q = ((rx_symI_fcr-rx_symI_slcr)*np.sin(nco_out) +
                           (rx_symQ_fcr-rx_symQ_slcr)*np.cos(nco_out))
            
            fseI_coeff = (fseI_coeff*(1-lms_step*lms_leak) - 
                           lms_step*(coeff_err_I*fseI_buffer + coeff_err_Q*fseQ_buffer))
            fseQ_coeff = (fseQ_coeff*(1-lms_step*lms_leak) +
                           lms_step*( coeff_err_I*fseQ_buffer - coeff_err_Q*fseI_buffer))
            if( (((j+1)/OS_DSP)%log_step) == 0 ):
                FSE_I_COEFFS_LOG[:, int(((j+1)/OS_DSP)/log_step)-1] = fseI_coeff
            
            # Phase error
            prod = (rx_symI_fcr+1j*rx_symQ_fcr)*(rx_symI_slcr-1j*rx_symQ_slcr)
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
            rx_bitI_demap = 0 if(rx_symI_slcr==1) else 1
            rx_bitQ_demap = 0 if(rx_symQ_slcr==1) else 1
            RX_BITI_DEMAP_LOG[k] = rx_bitI_demap
            RX_BITQ_DEMAP_LOG[k] = rx_bitQ_demap
         
            ######################## BIT-ERROR RATE ########################
            if( k<START_SYN ): ### Wait for convergence before start synchronization
                ber_IjQ.reset_values()
                
            elif( k>=START_SYN and k<START_CNT ): ########## Synchronization
                latency, rot_ang_detec = ber_IjQ.synchronize(k, rx_bitI_demap, rx_bitQ_demap) 
                
            else: ###################### Perform error counting (k<START_CNT)
                rate_I, rate_Q = ber_IjQ.count_errors(rx_bitI_demap, rx_bitQ_demap) 
                


th_ber = fn.theoric_ber(M, SNR_db)
print("latency:",latency, "| ang:",rot_ang_detec)
print("SNR=", SNR_db, " | f_off=",f_offset, " | step=", lms_step, " | Kp=", Kp, " | fc_ch=", fc_ch_filter)
print("BER_I: ", rate_I)
print("BER_Q: ", rate_I)
print("theo_ber: ", th_ber)
SIMULATION_DATA = [latency, rot_ang_detec, SNR_db, f_offset, lms_step, Kp, fc_ch_filter, rate_I, rate_Q, th_ber]


################################## LOGS ################################
np.savetxt('./logs/simulation_data.txt' , SIMULATION_DATA      , delimiter=',')
np.savetxt('./logs/tx_bitI_prbs.txt'    , TX_BITI_PRBS_LOG     , delimiter=',')
np.savetxt('./logs/tx_bitQ_prbs.txt'    , TX_BITQ_PRBS_LOG     , delimiter=',')
np.savetxt('./logs/tx_symI_map.txt'     , TX_SYMI_MAP_LOG      , delimiter=',')
np.savetxt('./logs/tx_symQ_map.txt'     , TX_SYMQ_MAP_LOG      , delimiter=',')
np.savetxt('./logs/coeffs_rrc.txt'      , rrc                  , delimiter=',')
np.savetxt('./logs/tx_symI_rrc.txt'     , TX_SYMI_RRC_LOG      , delimiter=',')
np.savetxt('./logs/tx_symQ_rrc.txt'     , TX_SYMQ_RRC_LOG      , delimiter=',')
np.savetxt('./logs/ch_symI_noisy.txt'   , CH_SYMI_NOISY_LOG    , delimiter=',')
np.savetxt('./logs/ch_symQ_noisy.txt'   , CH_SYMQ_NOISY_LOG    , delimiter=',')
np.savetxt('./logs/ch_symI_rot.txt'     , CH_SYMI_ROT_LOG      , delimiter=',')
np.savetxt('./logs/ch_symQ_rot.txt'     , CH_SYMQ_ROT_LOG      , delimiter=',')
np.savetxt('./logs/coeffs_chfilt.txt'   , ch_filt_coeff        , delimiter=',')
np.savetxt('./logs/ch_symI_chfilt.txt'  , CH_SYMI_CHFILT_LOG   , delimiter=',')
np.savetxt('./logs/ch_symQ_chfilt.txt'  , CH_SYMQ_CHFILT_LOG   , delimiter=',')
np.savetxt('./logs/coeffs_aafilt.txt'   , aaf_coeff            , delimiter=',')
np.savetxt('./logs/rx_symI_aaf.txt'     , RX_SYMI_AAF_LOG      , delimiter=',')
np.savetxt('./logs/rx_symQ_aaf.txt'     , RX_SYMQ_AAF_LOG      , delimiter=',')
np.savetxt('./logs/rx_symI_dw_rate2.txt', RX_SYMI_DW_RATE2_LOG , delimiter=',')
np.savetxt('./logs/rx_symQ_dw_rate2.txt', RX_SYMQ_DW_RATE2_LOG , delimiter=',')
np.savetxt('./logs/rx_symI_agc.txt'     , RX_SYMI_AGC_LOG      , delimiter=',')
np.savetxt('./logs/rx_symQ_agc.txt'     , RX_SYMQ_AGC_LOG      , delimiter=',')
np.savetxt('./logs/coeffs_fse_I.txt'    , FSE_I_COEFFS_LOG     , delimiter=',')
np.savetxt('./logs/rx_symI_fse.txt'     , RX_SYMI_FSE_LOG      , delimiter=',')
np.savetxt('./logs/rx_symQ_fse.txt'     , RX_SYMQ_FSE_LOG      , delimiter=',')
np.savetxt('./logs/rx_symI_fcr.txt'     , RX_SYMI_FCR_LOG      , delimiter=',')
np.savetxt('./logs/rx_symQ_fcr.txt'     , RX_SYMQ_FCR_LOG      , delimiter=',')
np.savetxt('./logs/nco_out.txt'         , NCO_OUT_LOG          , delimiter=',')
np.savetxt('./logs/int_error.txt'       , INT_ERR_LOG          , delimiter=',')
np.savetxt('./logs/rx_symI_dw_rate1.txt', RX_SYMI_DW_RATE1_LOG , delimiter=',')
np.savetxt('./logs/rx_symQ_dw_rate1.txt', RX_SYMQ_DW_RATE1_LOG , delimiter=',')
np.savetxt('./logs/rx_symI_slcr.txt'    , RX_SYMI_SLCR_LOG     , delimiter=',')
np.savetxt('./logs/rx_symQ_slcr.txt'    , RX_SYMQ_SLCR_LOG     , delimiter=',')
np.savetxt('./logs/rx_bitI_demap.txt'   , RX_BITI_DEMAP_LOG    , delimiter=',')
np.savetxt('./logs/rx_bitQ_demap.txt'   , RX_BITQ_DEMAP_LOG    , delimiter=',')



