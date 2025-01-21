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
NSYMB = 31# 1e6
BR    = 25e6    # Baud
OS    = 4       # oversampling
BETA  = 0.5     # roll-off
NBAUD = 5
M     = 4       # modulation order

#### Channel
SNR_db   = 7
f_offset = 10e3 # Hz
NSYMB_CONVERGENCE = 20000 # FSE and FCR convergence (a half for each)

#### Receiver
OS_DSP    = 2
NTAPS_FSE = 33
lms_step  = 0.5e-3
lms_leak  = 0
Kp        = 1e-3
Ki        = Kp/1000

#### BER counter
START_SYN = 450191
START_CNT = START_SYN + 4*511*511

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




for i in range(NSYMB*OS):

    if( i%OS ==0 ): # Downsampling to BR rate (os=1)
        k = int(i/OS)
        #### Bits generation
        tx_bitI_prbs = prbs9I.get_new_symbol()
        tx_bitQ_prbs = prbs9Q.get_new_symbol()
        #tx_bitI_prbs_log[k] = tx_bitI_prbs
        #tx_bitQ_prbs_log[k] = tx_bitQ_prbs
        
        #### Mapper
        tx_symI_map = 1 if(tx_bitI_prbs == 0) else -1
        tx_symQ_map = 1 if(tx_bitQ_prbs == 0) else -1
        #tx_symI_map_log[k]=tx_symI_map
        #tx_symQ_map_log[k]=tx_symQ_map

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
np.savetxt('rx_symI_agc.txt', rx_symI_agc_log, delimiter=',')
np.savetxt('rx_symQ_agc.txt', rx_symQ_agc_log, delimiter=',')
print("listo")
input()

#-------------------------------------------
#### PARA COMPARARRRRR

#### Bits generation
tx_bitI_prbs = np.zeros(NSYMB)
tx_bitQ_prbs = np.zeros(NSYMB)
prbs9I_aux = prbs9([0, 1, 0, 1, 0, 1, 0, 1, 1]) # Seed: 0x1AA
prbs9Q_aux = prbs9([0, 1, 1, 1, 1, 1, 1, 1, 1]) # Seed: 0x1FE
for i in range(NSYMB):
    tx_bitI_prbs[i] = prbs9I_aux.get_new_symbol()
    tx_bitQ_prbs[i] = prbs9Q_aux.get_new_symbol()

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

print(tx_symI_rrc)

if( np.array_equal(tx_symI_rrc_log, tx_symI_rrc) ):
    print("Son iguales :)")

for i in range(len(tx_symI_rrc_log)):
    if (tx_symI_rrc_log[i] != tx_symI_rrc[i]):
        print(i,tx_symI_rrc_log[i], tx_symI_rrc_log[i] )
input()

#-------------------------------------------





