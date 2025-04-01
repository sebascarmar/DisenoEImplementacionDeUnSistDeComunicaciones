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

#### General
NSYMB = 1000000
BR    = 25e6    # Baud
OS    = 4       # oversampling
BETA  = 0.5     # roll-off
NBAUD = 5
M     = 4       # modulation order
SEED_I =  0x1AA
SEED_Q =  0x1FE

#### Channel
SNR_db   = 7
NSYMB_CONVERGENCE = 20000 # FSE and FCR convergence (a half for each)
f_offset = 0.0 # Hz (0.0, 12e3, 24e3 o 48e3)
fc_ch_filter      = 0.48*BR # Cut-off frecuency of channel filter [Hz]

#### Receiver
fc_aa_filter = 0.5*BR # Cut-off frecuency of anti-alias filter [Hz]
OS_DSP       = 2
NTAPS_FSE    = 11
lms_step     = 0.0
lms_leak     = 1e-3
Kp           = 0 if(f_offset==0) else 1e-3
Ki           = Kp/1000

#### BER counter
START_SYN = 352590
prbs9_cycles = 20  # right value: 511
START_CNT = START_SYN + 511*prbs9_cycles

seedddd=5
np.random.seed(seedddd)  # set the seed: 11,12,14,16,17 - 1,3,4,6,7,8 - 0,2,5,9,13 - 10,15
                         # set the seed: 3,4 - 2 - 0,1 - 5
print("seeeeed:", seedddd)

#### Fixed Point formats
# Tx & Channel
NTOT =  8; NFRA =  7
# FSE & LMS
NTOT_TAP = 28; NFRA_TAP = 25
NTOT_SHI =  8; NFRA_SHI =  7
NTOT_OUT = 12; NFRA_OUT =  9
NTOT_STEP = 12; NFRA_STEP = 11
NTOT_LEAK = 11; NFRA_LEAK = 10
NTOT_ERR  = 12; NFRA_ERR  =  9
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
(t, txf_coeff, dot) = fn.r_rcosine(fc=BR/2, fs=OS*BR, rolloff=BETA, nbauds=NBAUD, norm=True)
tx_filter_I = poly_filter(txf_coeff, NBAUD, OS, NSYMB, NTOT, NFRA)
tx_filter_Q = poly_filter(txf_coeff, NBAUD, OS, NSYMB, NTOT, NFRA)
TX_SYMI_TXFILT_LOG = np.zeros(OS*NSYMB)
TX_SYMQ_TXFILT_LOG = np.zeros(OS*NSYMB)

################################ CHANNEL ###############################
#### AWGN
awgn_gen_I = noise_gen(OS, SNR_db)
awgn_gen_Q = noise_gen(OS, SNR_db)
CH_SYMI_NOISY_LOG = np.zeros(OS*NSYMB)
CH_SYMQ_NOISY_LOG = np.zeros(OS*NSYMB)

#### Frequency Offset
offset_freq = offset_gen(f_offset, NTOT, NFRA)
CH_SYMI_ROT_LOG = np.zeros(OS*NSYMB)
CH_SYMQ_ROT_LOG = np.zeros(OS*NSYMB)

#### Channel filter
(t2, ch_filt_coeff, dot2) = fn.r_rcosine(fc=fc_ch_filter, fs=OS*BR, rolloff=BETA, nbauds=4, norm=True)
chann_filt_I = fir_filter(ch_filt_coeff, NTOT, NFRA)
chann_filt_Q = fir_filter(ch_filt_coeff, NTOT, NFRA)
CH_SYMI_CHFILT_LOG = np.zeros(OS*NSYMB)
CH_SYMQ_CHFILT_LOG = np.zeros(OS*NSYMB)

############################### RECEIVER ###############################
#### Anti-alias filter
(t3, aaf_coeff, dot3) = fn.r_rcosine(fc=fc_aa_filter, fs=OS*BR, rolloff=BETA, nbauds=4, norm=True)
aaf_filt_I = fir_filter(aaf_coeff, NTOT, NFRA)
aaf_filt_Q = fir_filter(aaf_coeff, NTOT, NFRA)
RX_SYMI_AAF_LOG = np.zeros(OS*NSYMB)
RX_SYMQ_AAF_LOG = np.zeros(OS*NSYMB)

#### Downsampler (rate 2)
dw_r2_shftr_I = np.zeros(OS_DSP)
dw_r2_shftr_Q = np.zeros(OS_DSP)
RX_SYMI_DW_RATE2_LOG = np.zeros(NSYMB*OS_DSP)
RX_SYMQ_DW_RATE2_LOG = np.zeros(NSYMB*OS_DSP)

#### DSP
# FSE variables
fse = fse_class(NTAPS_FSE, NTOT_TAP, NFRA_TAP, NTOT_SHI, NFRA_SHI, NTOT_OUT, NFRA_OUT)

rx_symI_fse = 0.0
rx_symQ_fse = 0.0
RX_SYMI_FSE_LOG = np.zeros(NSYMB*OS_DSP)
RX_SYMQ_FSE_LOG = np.zeros(NSYMB*OS_DSP)

log_step     = 500
FSE_I_COEFFS_LOG = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))
FSE_Q_COEFFS_LOG = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))

fseI_taps_from_ver = np.loadtxt("file_fse_taps_I.txt", dtype=np.intp)
fseQ_taps_from_ver = np.loadtxt("file_fse_taps_Q.txt", dtype=np.intp)
frac_bits = NFRA_TAP
fseI_taps = fseI_taps_from_ver/(2**frac_bits)
fseQ_taps = fseQ_taps_from_ver/(2**frac_bits)
print(len(fseI_taps)/500)
#input()
for i in range(NTAPS_FSE):
    for j in range(int(int(NSYMB/log_step))):
        FSE_I_COEFFS_LOG[i][j] = fseI_taps[i + j*NTAPS_FSE]
        FSE_Q_COEFFS_LOG[i][j] = fseQ_taps[i + j*NTAPS_FSE]


# LMS variables
lms = lms_class(lms_step, lms_leak,  NTOT_STEP, NFRA_STEP, NTOT_LEAK, NFRA_LEAK,
                 NTOT_TAP, NFRA_TAP, NTOT_SHI, NFRA_SHI, NTOT_ERR, NFRA_ERR)
coeff_err_I       = DeFixedInt(NTOT_ERR, NFRA_ERR, 'S', 'trunc', 'saturate')
coeff_err_Q       = DeFixedInt(NTOT_ERR, NFRA_ERR, 'S', 'trunc', 'saturate')
coeff_err_I.value = 0.0
coeff_err_Q.value = 0.0

# Downsampler (rate 1)
dw_r1_shftr_I     = np.zeros(1+OS_DSP)
dw_r1_shftr_Q     = np.zeros(1+OS_DSP)
RX_SYMI_DW_RATE1_LOG = np.zeros(NSYMB)
RX_SYMQ_DW_RATE1_LOG = np.zeros(NSYMB)

# FCR variables
fcr = fcr_class(Kp, Ki, NSYMB_CONVERGENCE/2, NTOT_KP, NFRA_KP, NTOT_KI, NFRA_KI, NTOT_ANG_ER, NFRA_ANG_ER,
                NTOT_PRO_ER , NFRA_PRO_ER , NTOT_INT_ER , NFRA_INT_ER , NTOT_NCO_O, NFRA_NCO_O,
                NTOT_OUT_FCR, NFRA_OUT_FCR, NTOT_ER_UROT, NFRA_ER_UROT, NTOT_TAB  , NFRA_TAB  )
rx_symI_fcr = 0.0
rx_symQ_fcr = 0.0
RX_SYMI_FCR_LOG = np.zeros(NSYMB)
RX_SYMQ_FCR_LOG = np.zeros(NSYMB)
NCO_OUT_LOG     = np.zeros(NSYMB)
INT_ERR_LOG     = np.zeros(NSYMB)

# Slicer variables
rx_symI_slcr = 1.0
rx_symQ_slcr = 1.0
RX_SYMI_SLCR_LOG = np.zeros(NSYMB)
RX_SYMQ_SLCR_LOG = np.zeros(NSYMB)

#### Demapper
RX_BITI_DEMAP_LOG= np.zeros(NSYMB)
RX_BITQ_DEMAP_LOG= np.zeros(NSYMB)

############################ BIT-ERROR RATE ############################
ber_IjQ = ber(SEED_I, SEED_Q, START_SYN, START_CNT)

#tx_bitI_prbs_v = np.loadtxt("file_tx_bitI_prbs.txt", dtype=np.intp)
#tx_bitQ_prbs_v = np.loadtxt("file_tx_bitQ_prbs.txt", dtype=np.intp)

#---------------------------------------------------------------------------------------------
# INYECCION DE DATOS GENERADOS EN EL TX DE VERILOG
#levanta archivos en formato entero equivalente
rx_symI_dw_r1_from_ver = np.loadtxt("file_rx_symI_dwr4.txt", dtype=np.intp)
rx_symQ_dw_r1_from_ver = np.loadtxt("file_rx_symQ_dwr4.txt", dtype=np.intp)
#convierte al valor correspondiente al formato de punto fijo S(8.7)
frac_bits = 9
rx_symI_dw_r1_v = rx_symI_dw_r1_from_ver / (2**frac_bits)
rx_symQ_dw_r1_v = rx_symQ_dw_r1_from_ver / (2**frac_bits)
print("Fragmento de salidas del dwsamp tasa1 I y Q")
print(rx_symI_dw_r1_v[0:50])
print(rx_symQ_dw_r1_v[0:50])


#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#levanta archivos en formato entero equivalente
rx_symI_slcr_from_ver = np.loadtxt("file_rx_symI_slcr.txt", dtype=np.intp)
rx_symQ_slcr_from_ver = np.loadtxt("file_rx_symQ_slcr.txt", dtype=np.intp)
#convierte al valor correspondiente al formato de punto fijo S(8.7)
frac_bits = 9
rx_symI_slcr_v = rx_symI_slcr_from_ver / (2**frac_bits)
rx_symQ_slcr_v = rx_symQ_slcr_from_ver / (2**frac_bits)
print("Fragmento de salidas del slicer I y Q")
print(rx_symI_slcr_v[0:50])
print(rx_symQ_slcr_v[0:50])

#---------------------------------------------------------------------------------------------
# INYECCION DE DATOS GENERADOS EN EL TX DE VERILOG
#levanta archivos en formato entero equivalente
rx_err_lms_I_from_ver = np.loadtxt("file_rx_error_I.txt", dtype=np.intp)
rx_err_lms_Q_from_ver = np.loadtxt("file_rx_error_Q.txt", dtype=np.intp)
#convierte al valor correspondiente al formato de punto fijo S(8.7)
frac_bits = 9
rx_err_lms_I_v = rx_err_lms_I_from_ver / (2**frac_bits)
rx_err_lms_Q_v = rx_err_lms_Q_from_ver / (2**frac_bits)
print("Fragmento de salidas del error I y Q")
print(rx_err_lms_I_v[0:50])
print(rx_err_lms_Q_v[0:50])
print("Fin de la toma de datos inyectados")

#---------------------------------------------------------------------------------------------

################################## LOOP ################################
for i in range(NSYMB*OS):
#    print(i)
    ############################## TRANSMITTER  #############################
    if( i%OS ==0 ): # Downsampling to BR rate (os=1)
        n = int(i/OS)
        #### Bits generation
#        tx_bitI_prbs = tx_bitI_prbs_v[n]
#        tx_bitQ_prbs = tx_bitQ_prbs_v[n]
#        TX_BITI_PRBS_LOG[n] = tx_bitI_prbs
#        TX_BITQ_PRBS_LOG[n] = tx_bitQ_prbs
        
#        #### Mapper
#        tx_symI_map = 1 if(tx_bitI_prbs == 0) else -1
#        tx_symQ_map = 1 if(tx_bitQ_prbs == 0) else -1
#        TX_SYMI_MAP_LOG[n]=tx_symI_map
#        TX_SYMQ_MAP_LOG[n]=tx_symQ_map

#    #### Up-sampler & Tx Filter
#    tx_symI_txf = tx_filter_I.convol(i, tx_symI_map) 
#    tx_symQ_txf = tx_filter_Q.convol(i, tx_symQ_map) 
#    TX_SYMI_TXFILT_LOG[i] = tx_symI_txf
#    TX_SYMQ_TXFILT_LOG[i] = tx_symQ_txf
#
#    ################################ CHANNEL ###############################
#    #### Noise
#    ch_symI_noisy = awgn_gen_I.add_noise(tx_symI_txf)
#    ch_symQ_noisy = awgn_gen_Q.add_noise(tx_symQ_txf)
#    CH_SYMI_NOISY_LOG[i] = ch_symI_noisy
#    CH_SYMQ_NOISY_LOG[i] = ch_symQ_noisy
#
#    #### Frequency Offset
#    if( i>(NSYMB_CONVERGENCE*OS-1) ):
#        if( f_offset>0.0 ):
#            ch_symI_rot, ch_symQ_rot = offset_freq.get_offset(ch_symI_noisy, ch_symQ_noisy)
#        else:
#            ch_symI_rot, ch_symQ_rot = offset_freq.get_no_offset(ch_symI_noisy, ch_symQ_noisy)
#    else:
#        ch_symI_rot, ch_symQ_rot = offset_freq.get_no_offset(ch_symI_noisy, ch_symQ_noisy)
#    CH_SYMI_ROT_LOG[i] = ch_symI_rot
#    CH_SYMQ_ROT_LOG[i] = ch_symQ_rot
#
#    #### Channel filter (ISI)
#    ch_symI_chfilt = chann_filt_I.convol(ch_symI_rot)
#    ch_symQ_chfilt = chann_filt_Q.convol(ch_symQ_rot)
#    CH_SYMI_CHFILT_LOG[i] = ch_symI_chfilt
#    CH_SYMQ_CHFILT_LOG[i] = ch_symQ_chfilt
#
#    ############################### RECEIVER ###############################
#    #### Anti-alias filter
#    rx_symI_aaf = aaf_filt_I.convol(ch_symI_chfilt)
#    rx_symQ_aaf = aaf_filt_Q.convol(ch_symQ_chfilt)
#    RX_SYMI_AAF_LOG[i] = rx_symI_aaf
#    RX_SYMQ_AAF_LOG[i] = rx_symQ_aaf

    #### Downsamplers (rate 2)
#    dw_r2_shftr_I    = np.roll(dw_r2_shftr_I,1)
#    dw_r2_shftr_Q    = np.roll(dw_r2_shftr_Q,1)
#    dw_r2_shftr_I[0] = rx_symI_aaf
#    dw_r2_shftr_Q[0] = rx_symQ_aaf
#
#    rx_symI_dw_r2 = dw_r2_shftr_I[0]
#    rx_symQ_dw_r2 = dw_r2_shftr_Q[0]


    if( i%OS_DSP ==0 ): # Downsampling to OS_DSP*BR rate
        j = int(i/OS_DSP)
#        rx_symI_dw_r2 = rx_symI_dw_r2_v[j]
#        rx_symQ_dw_r2 = rx_symQ_dw_r2_v[j]
#        RX_SYMI_DW_RATE2_LOG[j] = rx_symI_dw_r2
#        RX_SYMQ_DW_RATE2_LOG[j] = rx_symQ_dw_r2
#        
#        #### DSP
#        # FSE output calculation
#        rx_symI_fse, rx_symQ_fse  = fse.filt(rx_symI_dw_r2,rx_symQ_dw_r2)
#        RX_SYMI_FSE_LOG[j] = rx_symI_fse 
#        RX_SYMQ_FSE_LOG[j] = rx_symQ_fse 
#        
#        #### Downsamplers (rate 2)
#        dw_r1_shftr_I    = np.roll(dw_r1_shftr_I,1)
#        dw_r1_shftr_Q    = np.roll(dw_r1_shftr_Q,1)
#        dw_r1_shftr_I[0] = rx_symI_fse
#        dw_r1_shftr_Q[0] = rx_symQ_fse
#        
#        rx_symI_dw_r1 = dw_r1_shftr_I[1]
#        rx_symQ_dw_r1 = dw_r1_shftr_Q[1]
        
        if((j+1)%OS_DSP)==0: # Downsampling to BR rate (os=1)
            k = int(j/OS_DSP)
            rx_symI_dw_r1 = rx_symI_dw_r1_v[k]
            rx_symQ_dw_r1 = rx_symQ_dw_r1_v[k]
            RX_SYMI_DW_RATE1_LOG[k] = rx_symI_dw_r1
            RX_SYMQ_DW_RATE1_LOG[k] = rx_symQ_dw_r1
            
            # FCR output: multiplication by e^{-jnco_out}
            rx_symI_fcr, rx_symQ_fcr =  fcr.derot(rx_symI_dw_r1, rx_symQ_dw_r1)
            RX_SYMI_FCR_LOG[k] = rx_symI_fcr 
            RX_SYMQ_FCR_LOG[k] = rx_symQ_fcr 
          
            # Slicer
            #rx_symI_slcr = fn.slicer_pam(rx_symI_fcr)
            #rx_symQ_slcr = fn.slicer_pam(rx_symQ_fcr)
            rx_symI_slcr = rx_symI_slcr_v[k]
            rx_symQ_slcr = rx_symQ_slcr_v[k]
            RX_SYMI_SLCR_LOG[k] = rx_symI_slcr
            RX_SYMQ_SLCR_LOG[k] = rx_symQ_slcr
            
#            # Error for LMS
#            coeff_err_I.value =(rx_symI_fcr-rx_symI_slcr)
#            coeff_err_Q.value =(rx_symQ_fcr-rx_symQ_slcr)
#            coeff_err_I.value, coeff_err_Q.value =  fcr.rot(coeff_err_I.fValue, coeff_err_Q.fValue)
#            
#            # LMS
#            coeffI, coeffQ = lms.update(coeff_err_I.fValue, coeff_err_Q.fValue,
#                                        fse.get_coeffI()  , fse.get_buffI()   ,
#                                        fse.get_coeffQ()  , fse.get_buffQ()   )
#            
#            fse.set_taps(coeffI, coeffQ)
#            if( (((j+1)/OS_DSP)%log_step) == 0 ):
#                FSE_I_COEFFS_LOG[:, int(((j+1)/OS_DSP)/log_step)-1] = fse.get_coeffI()
            
            # PI loop filter
            fcr.pll_loop(k, rx_symI_fcr, rx_symQ_fcr, rx_symI_slcr, rx_symQ_slcr)
            NCO_OUT_LOG[k] = fcr.get_nco_out()
            INT_ERR_LOG[k] = fcr.get_integ_err()
        ##### DSP end
            
            
            # Demapper
            rx_bitI_demap = 0 if(rx_symI_slcr==1) else 1
            rx_bitQ_demap = 0 if(rx_symQ_slcr==1) else 1
            RX_BITI_DEMAP_LOG[k] = rx_bitI_demap
            RX_BITQ_DEMAP_LOG[k] = rx_bitQ_demap
         
            ######################## BIT-ERROR RATE ########################
            if( k<START_SYN ): ### Wait for converge. before start synchron.
                ber_IjQ.reset_values()
                
            elif( k>=START_SYN and k<START_CNT ): ########## Synchronization
                latency, rot_ang_detec = ber_IjQ.synchronize(k, rx_bitI_demap, rx_bitQ_demap) 
                
            else: ###################### Perform error counting (k<START_CNT)
                rate_I, rate_Q = ber_IjQ.count_errors(rx_bitI_demap, rx_bitQ_demap) 
                
#    print(rx_symI_dw_r2,rx_symQ_dw_r2)
#    print("fse_I:", rx_symI_fse)
#    print("dws_I:", rx_symI_dw_r1)
#    print("slc_I:", rx_symI_slcr)
#    print("err_I:", coeff_err_I.fValue)
#    print("fse_Q:", rx_symQ_fse)
#    print("dws_Q:",rx_symQ_dw_r1)
#    print("slc_Q:", rx_symQ_slcr)
#    print("err_Q:", coeff_err_Q.fValue)
#
#    #print("errI",     coeff_err_I.fValue)
#    #print("errQ",     coeff_err_Q.fValue)
#    #print("tapI",     fse.get_coeffI())
#    #print("tapQ",     fse.get_coeffQ())
#    print("shiI",     fse.get_buffI())
#    print("shiQ",     fse.get_buffQ())
#    print()
#    input()
          

th_ber = fn.theoric_ber(M, SNR_db)
print("latency:",latency, "| ang:",rot_ang_detec)
print("SNR=", SNR_db, " | f_off=",f_offset, " | step=", lms_step, " | leak=", lms_leak)
print("Kp=", Kp, " | Ki=", Ki, " | fc_ch=", fc_ch_filter, " | fc_aaf=",fc_aa_filter, )
print("BER_I: ", rate_I)
print("BER_Q: ", rate_Q)
print("theo_ber: ", th_ber)
SIMULATION_DATA = [latency, rot_ang_detec, SNR_db, f_offset, lms_step, lms_leak,
                   Kp, Ki, fc_ch_filter, fc_aa_filter, rate_I, rate_Q, th_ber]

################################## LOGS ################################
logs_absPath = os.path.join(os.path.dirname(__file__), 'logs')
os.makedirs(logs_absPath, exist_ok=True) # Create logs/ if it doesn't exist

np.savetxt(os.path.join(logs_absPath,'simulation_data.txt' ), SIMULATION_DATA      , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'tx_bitI_prbs.txt'    ), TX_BITI_PRBS_LOG     , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'tx_bitQ_prbs.txt'    ), TX_BITQ_PRBS_LOG     , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'tx_symI_map.txt'     ), TX_SYMI_MAP_LOG      , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'tx_symQ_map.txt'     ), TX_SYMQ_MAP_LOG      , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'coeffs_txf.txt'      ), tx_filter_I.get_quantized_coeffs(), delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'tx_symI_txf.txt'     ), TX_SYMI_TXFILT_LOG   , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'tx_symQ_txf.txt'     ), TX_SYMQ_TXFILT_LOG   , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'ch_symI_noisy.txt'   ), CH_SYMI_NOISY_LOG    , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'ch_symQ_noisy.txt'   ), CH_SYMQ_NOISY_LOG    , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'ch_symI_rot.txt'     ), CH_SYMI_ROT_LOG      , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'ch_symQ_rot.txt'     ), CH_SYMQ_ROT_LOG      , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'coeffs_chfilt.txt'   ), chann_filt_I.get_quantized_coeffs(), delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'ch_symI_chfilt.txt'  ), CH_SYMI_CHFILT_LOG   , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'ch_symQ_chfilt.txt'  ), CH_SYMQ_CHFILT_LOG   , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'coeffs_aafilt.txt'   ), aaf_filt_I.get_quantized_coeffs(), delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'rx_symI_aaf.txt'     ), RX_SYMI_AAF_LOG      , delimiter=',')
#np.savetxt(os.path.join(logs_absPath,'rx_symQ_aaf.txt'     ), RX_SYMQ_AAF_LOG      , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symI_dw_rate2.txt'), RX_SYMI_DW_RATE2_LOG , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symQ_dw_rate2.txt'), RX_SYMQ_DW_RATE2_LOG , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'coeffs_fse_I.txt'    ), FSE_I_COEFFS_LOG     , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'coeffs_fse_Q.txt'    ), FSE_Q_COEFFS_LOG     , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symI_fse.txt'     ), RX_SYMI_FSE_LOG      , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symQ_fse.txt'     ), RX_SYMQ_FSE_LOG      , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symI_fcr.txt'     ), RX_SYMI_FCR_LOG      , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symQ_fcr.txt'     ), RX_SYMQ_FCR_LOG      , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'nco_out.txt'         ), NCO_OUT_LOG          , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'int_error.txt'       ), INT_ERR_LOG          , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symI_dw_rate1.txt'), RX_SYMI_DW_RATE1_LOG , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symQ_dw_rate1.txt'), RX_SYMQ_DW_RATE1_LOG , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symI_slcr.txt'    ), RX_SYMI_SLCR_LOG     , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_symQ_slcr.txt'    ), RX_SYMQ_SLCR_LOG     , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_err_lms_I_v.txt'   ), rx_err_lms_I_v    , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_err_lms_Q_v.txt'   ), rx_err_lms_Q_v    , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_bitI_demap.txt'   ), RX_BITI_DEMAP_LOG    , delimiter=',')
np.savetxt(os.path.join(logs_absPath,'rx_bitQ_demap.txt'   ), RX_BITQ_DEMAP_LOG    , delimiter=',')
