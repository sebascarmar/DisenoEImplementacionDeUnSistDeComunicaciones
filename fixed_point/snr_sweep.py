import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.io import savemat
import math
import functions as fn
from classes.prbs9       import prbs9
from classes.poly_filter import poly_filter
from classes.noise_gen   import noise_gen
from classes.offset_gen  import offset_gen
from classes.fir_filter  import fir_filter
from classes.ber         import ber
from classes.fse_class   import fse_class
from classes.lms_class   import lms_class
from classes.fcr_class   import fcr_class
from tool._fixedInt      import *

import os


####################################################################################
#                                      MAIN                                        #
####################################################################################

############################### PARAMETERS #############################

#### Sweep
SWEEP_TIMES = 4
START_SWP   = 7

#### General
NSYMB = 400000
BR    = 25e6    # Baud
OS    = 4       # oversampling
BETA  = 0.5     # roll-off
NBAUD = 5
M     = 4       # modulation order
SEED_I =  0x1AA
SEED_Q =  0x1FE

#### Channel
SNR_db   = 8
NSYMB_CONVERGENCE = 20000 # FSE and FCR convergence (a half for each)
f_offset = 0.0 # Hz (0.0, 12e3, 24e3 o 48e3)
fc_ch_filter      = 0.48*BR # Cut-off frecuency of channel filter [Hz]

#### Receiver
fc_aa_filter = 0.5*BR # Cut-off frecuency of anti-alias filter [Hz]
OS_DSP       = 2
NTAPS_FSE    = 9
lms_step     = 0.5e-3
lms_leak     = 1e-3
Kp           = 0 if(f_offset==0) else 1e-3
Ki           = Kp/1000

#### BER counter
START_SYN = 352590
prbs9_cycles = 16  # right value: 511
START_CNT = START_SYN + 511*prbs9_cycles

seedddd=5
np.random.seed(seedddd)  # set the seed: 11,12,14,16,17 - 1,3,4,6,7,8 - 0,2,5,9,13 - 10,15
                         # set the seed: 3,4 - 2 - 0,1 - 5
print("seeeeed:", seedddd)

#### Fixed Point formats
# Tx & Channel
NTOT =  8; NFRA =  7
# FSE & LMS
NTOT_LMS_TAPS = 20; NFRA_LMS_TAPS = 17
NTOT_FSE_TAPS = 10; NFRA_FSE_TAPS = 7
NTOT_STEP = 12; NFRA_STEP = 11
NTOT_LEAK = 11; NFRA_LEAK = 10
NTOT_SHI =  8; NFRA_SHI =  7
NTOT_OUT = 12; NFRA_OUT =  9
NTOT_ERR  =  9; NFRA_ERR  =  7
# FCR
NTOT_KP      = 11; NFRA_KP      = 10
NTOT_KI      = 21; NFRA_KI      = 20
NTOT_ANG_ER  =  7; NFRA_ANG_ER  =  6
NTOT_PRO_ER  = 13; NFRA_PRO_ER  = 12
NTOT_INT_ER  = 27; NFRA_INT_ER  = 26
NTOT_NCO_O   = 29; NFRA_NCO_O   = 26
NTOT_OUT_FCR = 12; NFRA_OUT_FCR =  9
NTOT_ER_UROT = 12; NFRA_ER_UROT =  9
NTOT_TAB     =  8; NFRA_TAB     =  7



bersI_contadas = np.zeros(SWEEP_TIMES+START_SWP)
bersQ_contadas = np.zeros(SWEEP_TIMES+START_SWP)
th_ber         = np.zeros(SWEEP_TIMES+START_SWP)
for SNR_db in range(START_SWP, SWEEP_TIMES+START_SWP):
    ############################## TRANSMITTER  #############################
    
    #### Bits generation
    
    prbs9I = prbs9(SEED_I)
    prbs9Q = prbs9(SEED_Q)
    
    #### Mapper
    
    #### RRC Filter (also up-sampler)
    (t, txf_coeff, dot) = fn.r_rcosine(fc=BR/2, fs=OS*BR, rolloff=BETA, nbauds=NBAUD, norm=True)
    tx_filter_I = poly_filter(txf_coeff, NBAUD, OS, NSYMB, NTOT, NFRA)
    tx_filter_Q = poly_filter(txf_coeff, NBAUD, OS, NSYMB, NTOT, NFRA)
    
    ################################ CHANNEL ###############################
    #### AWGN
    awgn_gen_I = noise_gen(OS, SNR_db)
    awgn_gen_Q = noise_gen(OS, SNR_db)
    
    #### Frequency Offset
    offset_freq = offset_gen(f_offset, NTOT, NFRA)
    
    #### Channel filter
    (t2, ch_filt_coeff, dot2) = fn.r_rcosine(fc=fc_ch_filter, fs=OS*BR, rolloff=BETA, nbauds=4, norm=True)
    chann_filt_I = fir_filter(ch_filt_coeff, NTOT, NFRA)
    chann_filt_Q = fir_filter(ch_filt_coeff, NTOT, NFRA)
    
    ############################### RECEIVER ###############################
    #### Anti-alias filter
    (t3, aaf_coeff, dot3) = fn.r_rcosine(fc=fc_aa_filter, fs=OS*BR, rolloff=BETA, nbauds=4, norm=True)
    aaf_filt_I = fir_filter(aaf_coeff, NTOT, NFRA)
    aaf_filt_Q = fir_filter(aaf_coeff, NTOT, NFRA)
    
    #### Downsampler (rate 2)
    dw_r2_shftr_I = np.zeros(OS_DSP)
    dw_r2_shftr_Q = np.zeros(OS_DSP)
    
    #### DSP
    # FSE variables
    fse = fse_class(NTAPS_FSE, NTOT_FSE_TAPS, NFRA_FSE_TAPS, NTOT_SHI, NFRA_SHI, NTOT_OUT, NFRA_OUT)
    
    rx_symI_fse = 0.0
    rx_symQ_fse = 0.0
    
    log_step     = 500
    FSE_I_COEFFS_LOG = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))
    
    # LMS variables
    lms = lms_class(lms_step, lms_leak, NTAPS_FSE, NTOT_STEP, NFRA_STEP, NTOT_LEAK, NFRA_LEAK,
                     NTOT_LMS_TAPS, NFRA_LMS_TAPS, NTOT_SHI, NFRA_SHI, NTOT_ERR, NFRA_ERR)
    coeff_err_I       = DeFixedInt(NTOT_ERR, NFRA_ERR, 'S', 'trunc', 'saturate')
    coeff_err_Q       = DeFixedInt(NTOT_ERR, NFRA_ERR, 'S', 'trunc', 'saturate')
    coeff_err_I.value = 0.0
    coeff_err_Q.value = 0.0
    
    # Downsampler (rate 1)
    dw_r1_shftr_I     = np.zeros(OS_DSP)
    dw_r1_shftr_Q     = np.zeros(OS_DSP)
    
    # FCR variables
    fcr = fcr_class(Kp, Ki, NSYMB_CONVERGENCE/2, NTOT_KP, NFRA_KP, NTOT_KI, NFRA_KI, NTOT_ANG_ER, NFRA_ANG_ER,
                    NTOT_PRO_ER , NFRA_PRO_ER , NTOT_INT_ER , NFRA_INT_ER , NTOT_NCO_O, NFRA_NCO_O,
                    NTOT_OUT_FCR, NFRA_OUT_FCR, NTOT_ER_UROT, NFRA_ER_UROT, NTOT_TAB  , NFRA_TAB  )
    rx_symI_fcr = 0.0
    rx_symQ_fcr = 0.0
    
    # Slicer variables
    
    #### Demapper
    
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
            
            #### Mapper
            tx_symI_map = 1 if(tx_bitI_prbs == 0) else -1
            tx_symQ_map = 1 if(tx_bitQ_prbs == 0) else -1
    
        #### Up-sampler & Tx Filter
        tx_symI_txf = tx_filter_I.convol(i, tx_symI_map) 
        tx_symQ_txf = tx_filter_Q.convol(i, tx_symQ_map) 
    
        ################################ CHANNEL ###############################
        #### Noise
        ch_symI_noisy = awgn_gen_I.add_noise(tx_symI_txf)
        ch_symQ_noisy = awgn_gen_Q.add_noise(tx_symQ_txf)
    
        #### Frequency Offset
        if( i>(NSYMB_CONVERGENCE*OS-1) ):
            if( f_offset>0.0 ):
                ch_symI_rot, ch_symQ_rot = offset_freq.get_offset(ch_symI_noisy, ch_symQ_noisy)
            else:
                ch_symI_rot, ch_symQ_rot = offset_freq.get_no_offset(ch_symI_noisy, ch_symQ_noisy)
        else:
            ch_symI_rot, ch_symQ_rot = offset_freq.get_no_offset(ch_symI_noisy, ch_symQ_noisy)
    
        #### Channel filter (ISI)
        ch_symI_chfilt = chann_filt_I.convol(ch_symI_rot)
        ch_symQ_chfilt = chann_filt_Q.convol(ch_symQ_rot)
    
        ############################### RECEIVER ###############################
        #### Anti-alias filter
        rx_symI_aaf = aaf_filt_I.convol(ch_symI_chfilt)
        rx_symQ_aaf = aaf_filt_Q.convol(ch_symQ_chfilt)
    
        #### Downsamplers (rate 2)
        dw_r2_shftr_I    = np.roll(dw_r2_shftr_I,1)
        dw_r2_shftr_Q    = np.roll(dw_r2_shftr_Q,1)
        dw_r2_shftr_I[0] = rx_symI_aaf
        dw_r2_shftr_Q[0] = rx_symQ_aaf
    
        rx_symI_dw_r2 = dw_r2_shftr_I[0]
        rx_symQ_dw_r2 = dw_r2_shftr_Q[0]
    
        if( i%OS_DSP ==0 ): # Downsampling to OS_DSP*BR rate
            j = int(i/OS_DSP)
            
            #### DSP
            # FSE output calculation
            rx_symI_fse, rx_symQ_fse  = fse.filt(rx_symI_dw_r2,rx_symQ_dw_r2)
            
            #### Downsamplers (rate 2)
            dw_r1_shftr_I    = np.roll(dw_r1_shftr_I,1)
            dw_r1_shftr_Q    = np.roll(dw_r1_shftr_Q,1)
            dw_r1_shftr_I[0] = rx_symI_fse
            dw_r1_shftr_Q[0] = rx_symQ_fse
            
            rx_symI_dw_r1 = dw_r1_shftr_I[0]
            rx_symQ_dw_r1 = dw_r1_shftr_Q[0]
            
            if((j+1)%OS_DSP)==0: # Downsampling to BR rate (os=1)
                k = int(j/OS_DSP)
                
                # FCR output: multiplication by e^{-jnco_out}
                rx_symI_fcr, rx_symQ_fcr =  fcr.derot(rx_symI_dw_r1, rx_symQ_dw_r1)
              
                # Slicer
                rx_symI_slcr = fn.slicer_pam(rx_symI_fcr)
                rx_symQ_slcr = fn.slicer_pam(rx_symQ_fcr)
                
                # Error for LMS
                coeff_err_I.value =(rx_symI_fcr-rx_symI_slcr)
                coeff_err_Q.value =(rx_symQ_fcr-rx_symQ_slcr)
                coeff_err_I.value, coeff_err_Q.value =  fcr.rot(coeff_err_I.fValue, coeff_err_Q.fValue)
                
                # LMS
                coeffI, coeffQ = lms.update(coeff_err_I.fValue, coeff_err_Q.fValue,
                                             fse.get_buffI()  , fse.get_buffQ()   )
                fse.set_taps(coeffI, coeffQ)
                
                # PI loop filter
                fcr.pll_loop(k, rx_symI_fcr, rx_symQ_fcr, rx_symI_slcr, rx_symQ_slcr)
            ##### DSP end
                
                
                # Demapper
                rx_bitI_demap = 0 if(rx_symI_slcr==1) else 1
                rx_bitQ_demap = 0 if(rx_symQ_slcr==1) else 1
             
                ######################## BIT-ERROR RATE ########################
                if( k<START_SYN ): ### Wait for converge. before start synchron.
                    ber_IjQ.reset_values()
                    
                elif( k>=START_SYN and k<START_CNT ): ########## Synchronization
                    latency, rot_ang_detec = ber_IjQ.synchronize(k, rx_bitI_demap, rx_bitQ_demap) 
                    
                else: ###################### Perform error counting (k<START_CNT)
                    rate_I, rate_Q = ber_IjQ.count_errors(rx_bitI_demap, rx_bitQ_demap) 
                    
    
    
    bersI_contadas[SNR_db] = rate_I
    bersQ_contadas[SNR_db] = rate_Q
    th_ber[SNR_db] = fn.theoric_ber(M, SNR_db)

    print("SNR=", SNR_db, " | f_off=",f_offset)
    print("BER_I: {:.3e}".format(rate_I))
    print("BER_Q: {:.3e}".format(rate_Q))
    print("theo_ber: {:.3e}\n".format(th_ber[SNR_db]) )

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
os.makedirs("plots", exist_ok=True)


plt.figure(figsize=[7,7])
plt.title('BER vs SNR | (fixed sim.)', fontsize=18)
plt.semilogy(x_axis_full, th_ber_full, 'r', marker='x', markeredgewidth=2.5, markersize=7, linewidth=2.0)
plt.semilogy(x_axis_full, (bersQ_full+bersQ_full)/2, 'b--', marker='^', markerfacecolor='none', markersize=7,
             markeredgewidth=2.5, linewidth=2.0)
plt.xlabel('SNR [dB]', fontsize=15)
plt.ylabel('BER', fontsize=15)
plt.grid(True)
#plt.ylim([1e-5, 0.7e-1])
#plt.xlim([6.8, 12.2])
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)
#plt.gca().set_aspect('equal', adjustable='box')
plt.axis('equal')
plt.legend(['BER theo','BER fixed'], fontsize=12)
plt.tight_layout()
plt.savefig(f"plots/ber_vs_snr_from_fixed.png")
plt.close()


