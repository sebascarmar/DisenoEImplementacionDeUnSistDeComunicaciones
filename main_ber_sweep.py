import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.io import savemat
import math
from classes.prbs9 import prbs9


def r_rcosine(fc, fs, rolloff, nbauds, norm):

    rolloff = rolloff + 0.0001
    BR = fc*2       #Baud Rate
    Tbaud = 1 / BR       #Time interval between two consecutive symbols
    Ts = 1 / fs      #Time between 2 consecutive samples at Tx output

    if ((Tbaud/Ts)*nbauds)%2 == 0:
        t_vect = np.arange(-0.5*nbauds*Tbaud, 0.5*nbauds*Tbaud+Ts, Ts)
    else:
        t_vect = np.arange(-0.5*nbauds*Tbaud, 0.5*nbauds*Tbaud, Ts)

    t_vect_n = t_vect / Tbaud # normaliza

    y_vect = []
    #filtro pasabajos
    for t in t_vect_n:
        if (t == 0):
            y_vect.append((1+rolloff*(4/np.pi-1)))
        else:
            y_vect.append((4*rolloff*t*np.cos(((1+rolloff)*np.pi*t))+
                                       np.sin((1-rolloff)*np.pi*t))/
                          (np.pi*t*(1-(16*rolloff*rolloff*t*t))))


    y_vect = np.array(y_vect)
    if norm:
        y_vect = y_vect/np.sum(y_vect)   #normaliza ganancia, 0db

    dot = (np.sum(y_vect ** 2))

    return t_vect_n, y_vect, dot


def slicer_qpsk(x):
    if(x>=0):
        a = 1;
    else:
        a =-1;

    return a


def find_delay(signal1, signal2):
    # Calculate cross-correlation
    correlation = np.correlate(signal1, signal2, mode='full')
    # Find the index of the maximum correlation
    delay = np.argmax(correlation) - (len(signal2) - 1)
    return delay


def theoric_ber(M, SNRdB):
    SNR_slicer  = 10**(SNRdB/10)
    EbNo = SNR_slicer/np.log2(M)
    k    = np.log2(M)
    x    = np.sqrt(3*k*EbNo/(M-1))
    ber  = (4/k)*(1-1/np.sqrt(M))*(1/2)*math.erfc(x/np.sqrt(2))

    return ber

def inv(arreglo):
    # Retorna el arreglo con sus símbolos invertidos
    return np.where(arreglo == 1, -1, 1)


####################################################################################
#                                      MAIN                                        #
####################################################################################

############################### PARAMETERS #############################

#### General
NSYMB = 3000000 # 1e6
BR    = 25e6    # Baud
OS    = 4       # oversampling
BETA  = 0.5     # roll-off
NBAUD = 5
M     = 4       # modulation order

#### Channel
SWEEP_TIMES = 10
f_offset    = 0e3 # Hz
NSYMB_CONVERGENCE = 20000 # FSE and FCR convergence (a half for each)

#### Receiver
OS_DSP    = 2
NTAPS_FSE = 33
lms_step  = 0.1e-3
lms_leak  = 0
Kp        = 1e-3
Ki        = Kp/1000

#### BER counter
START_SYN = 450191
START_CNT = START_SYN + 4*511*511

# np.random.seed(2)  # set the seed


bersI_contadas = np.zeros(SWEEP_TIMES+2)
bersQ_contadas = np.zeros(SWEEP_TIMES+2)
th_ber         = np.zeros(SWEEP_TIMES+2)
for SNR_db in range(2, SWEEP_TIMES+2):
    ############################## TRANSCEIVER #############################

    #### Bits generation
    tx_bitI_prbs = np.zeros(NSYMB)
    tx_bitQ_prbs = np.zeros(NSYMB)

    prbs9I = prbs9([0, 1, 0, 1, 0, 1, 0, 1, 1]) # Seed: 0x1AA
    prbs9Q = prbs9([0, 1, 1, 1, 1, 1, 1, 1, 1]) # Seed: 0x1FE

    for i in range(NSYMB):
        tx_bitI_prbs[i] = prbs9I.get_new_symbol()
        tx_bitQ_prbs[i] = prbs9Q.get_new_symbol()

    #### Mapper
    tx_symI_map = 2*(tx_bitI_prbs != 1)-1
    tx_symQ_map = 2*(tx_bitQ_prbs != 1)-1

    #### Up-sampler
    tx_symI_up = np.zeros(OS*NSYMB); tx_symI_up[0:len(tx_symI_up):int(OS)]=tx_symI_map
    tx_symQ_up = np.zeros(OS*NSYMB); tx_symQ_up[0:len(tx_symQ_up):int(OS)]=tx_symQ_map


    #### RRC Filter
    (t, rrc, dot) = r_rcosine(fc=BR/2, fs=OS*BR, rolloff=BETA, nbauds=NBAUD, norm=True)

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
    ch_filt_coeff   = signal.firwin(numtaps=17, cutoff=0.49*BR ,window='hamming', fs=4*BR)
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


        if((i+1)%OS_DSP)==0: # Downsampling to BR rate (os=1)
            k = int(i/OS_DSP)
            # Slicer
            rx_symI_slcr[k] = slicer_qpsk(rx_symI_fcr[i])
            rx_symQ_slcr[k] = slicer_qpsk(rx_symQ_fcr[i])
            
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

    rx_prbs_I = tx_symI_map[START_SYN:START_SYN+511]
    rx_prbs_Q = tx_symQ_map[START_SYN:START_SYN+511]


    err_sym_count = 0
    min_error_aux = len(rx_prbs_I)
    min_error     = len(rx_prbs_I)
    lat_aux       = 0

    latency       = 0
    rot_ang_detec = 0
    for angle in [0, 90, 180, 270]:
        # Rotate rx symbs
        if( angle == 0):
            rx_slcr_I =     rx_symI_slcr[START_SYN+511*511*0:START_SYN+511*511*1]
            rx_slcr_Q =     rx_symQ_slcr[START_SYN+511*511*0:START_SYN+511*511*1]
        elif( angle == 90 ):
            rx_slcr_I = inv(rx_symQ_slcr[START_SYN+511*511*1:START_SYN+511*511*2])
            rx_slcr_Q =     rx_symI_slcr[START_SYN+511*511*1:START_SYN+511*511*2]
        elif( angle == 180 ):
            rx_slcr_I = inv(rx_symI_slcr[START_SYN+511*511*2:START_SYN+511*511*3])
            rx_slcr_Q = inv(rx_symQ_slcr[START_SYN+511*511*2:START_SYN+511*511*3])
        else: # angle==270
            rx_slcr_I =     rx_symQ_slcr[START_SYN+511*511*3:START_SYN+511*511*4]
            rx_slcr_Q = inv(rx_symI_slcr[START_SYN+511*511*3:START_SYN+511*511*4])

        # Symbol error counting for every angle
        min_error_aux = len(rx_prbs_I)
        for BER_IDX in range(len(rx_prbs_I)):

            err_sym_count = 0
            # Count errors for each BER_IDX
            for i in range(len(rx_prbs_I)):
                if( i>0 ):
                    rx_prbs_I = np.roll(rx_prbs_I,-1)
                    rx_prbs_Q = np.roll(rx_prbs_Q,-1)
                new_bit_prbs_I = rx_prbs_I[BER_IDX]
                new_bit_prbs_Q = rx_prbs_Q[BER_IDX]

                if( (new_bit_prbs_I != rx_slcr_I[i+511*BER_IDX]) or (new_bit_prbs_Q != rx_slcr_Q[i+511*BER_IDX]) ):
                    err_sym_count += 1
                else:
                    err_sym_count = err_sym_count

            rx_prbs_I = np.roll(rx_prbs_I,-1)
            rx_prbs_Q = np.roll(rx_prbs_Q,-1)
            
            if( err_sym_count < min_error_aux ):
                min_error_aux = err_sym_count
                lat_aux       = BER_IDX


        print(angle)
        print("Lat:" ,lat_aux, "err:", min_error_aux, "\n")

        
        if( min_error_aux < min_error ):
            min_error     = min_error_aux
            latency       = lat_aux 
            rot_ang_detec = angle


    #### Counting
    print("latency:",latency, "| ang:",rot_ang_detec)
    rx_prbs_I = tx_symI_map
    rx_prbs_Q = tx_symQ_map
    # latency = 365
    # rot_ang_detec = 180

    # Select the detected rotation
    if( rot_ang_detec == 0 ):
        rx_slcr_I =     rx_symI_slcr
        rx_slcr_Q =     rx_symQ_slcr
    elif( rot_ang_detec == 90 ):
        rx_slcr_I = inv(rx_symQ_slcr)
        rx_slcr_Q =     rx_symI_slcr
    elif( rot_ang_detec == 180 ):
        rx_slcr_I = inv(rx_symI_slcr)
        rx_slcr_Q = inv(rx_symQ_slcr)
    else: # rot_ang_detec=270
        rx_slcr_I =     rx_symQ_slcr
        rx_slcr_Q = inv(rx_symI_slcr)

    # BER (Lane I)
    bit_err_I = 0
    bit_tot_I = 0
    for i in range(START_CNT,len(rx_slcr_I)-latency):
        if( rx_prbs_I[latency+i] != rx_slcr_I[i] ):
            bit_err_I +=1
        bit_tot_I += 1

    # BER (Lane Q)
    bit_err_Q = 0
    bit_tot_Q = 0
    for i in range(START_CNT,len(rx_slcr_Q)-latency):
        if( rx_prbs_Q[latency+i] != rx_slcr_Q[i] ):
            bit_err_Q +=1
        bit_tot_Q += 1

    bersI_contadas[SNR_db] = bit_err_I/bit_tot_I
    bersQ_contadas[SNR_db] = bit_err_Q/bit_tot_Q
    th_ber[SNR_db] = theoric_ber(M, SNR_db)

    print("SNR=", SNR_db, " | f_off=",f_offset)
    print("BER_I: ", bit_err_I/bit_tot_I)
    print("BER_Q: ", bit_err_Q/bit_tot_Q)
    print("theo_ber: ", th_ber[SNR_db], "\n")
    


#########################  PRINCIPAL GRAPHICS ##########################
plt.figure(figsize=[14,6])
plt.title('BER vs SNR')
plt.semilogy(range(SWEEP_TIMES+2), th_ber  , 'r', linewidth=2.0)
plt.semilogy(range(SWEEP_TIMES+2), bersI_contadas, 'b', linewidth=2.0)
plt.semilogy(range(SWEEP_TIMES+2), bersI_contadas, 'g', linewidth=2.0)
plt.xlabel('SNR(dB)')
plt.ylabel('BER')
plt.grid(True)
plt.xlim(0,15)
plt.ylim(0.000001,1)
plt.legend(['SNR theo','SNR I','SNR Q'])
plt.show()