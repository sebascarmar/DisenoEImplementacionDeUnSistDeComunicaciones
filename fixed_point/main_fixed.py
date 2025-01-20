import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.io import savemat
import math
import functions as fn
from classes.prbs9 import prbs9
from classes.poly_filter import poly_filter
from classes.noise_gen import noise_gen


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

for i in range(NSYMB*OS):

    if( i%OS ==0 ): # Downsampling to BR rate (os=1)
        k = int(i/OS)
        #### Bits generation
        tx_bitI_prbs = prbs9I.get_new_symbol()
        tx_bitQ_prbs = prbs9Q.get_new_symbol()
        print(k,tx_bitI_prbs)
        tx_bitI_prbs_log[k] = tx_bitI_prbs
        tx_bitQ_prbs_log[k] = tx_bitQ_prbs
        
        #### Mapper
        tx_symI_map = 1 if(tx_bitI_prbs == 0) else -1
        tx_symQ_map = 1 if(tx_bitQ_prbs == 0) else -1
        tx_symI_map_log[k]=tx_symI_map
        tx_symQ_map_log[k]=tx_symQ_map

    #### Up-sampler & Tx Filter
    tx_symI_rrc = tx_filter_I.convol(i, tx_symI_map) 
    tx_symQ_rrc = tx_filter_Q.convol(i, tx_symI_map) 

    tx_symI_rrc_log[i] = tx_symI_rrc
    tx_symQ_rrc_log[i] = tx_symQ_rrc


    #### Noise
    ch_symI_noisy = awgn_gen_I.add_noise(tx_symI_rrc)
    ch_symQ_noisy = awgn_gen_Q.add_noise(tx_symQ_rrc)
    #ch_symI_noisy_log[i] = ch_symI_noisy
    #ch_symQ_noisy_log[i] = ch_symQ_noisy


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





