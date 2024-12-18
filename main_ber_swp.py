
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.io import savemat
import math

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


def theoric_ber(M, EbNodB):
    EbNo = 10**(EbNodB/10)
    k    = np.log2(M)
    x    = np.sqrt(3*k*EbNo/(M-1))
    ber  = (4/k)*(1-1/np.sqrt(M))*(1/2)*math.erfc(x/np.sqrt(2))

    return ber


####################################################################################
#                                      MAIN                                        #
####################################################################################

#------------------ Parámetros
# Generales
NSYMB = 1000000 # 1e6
BR    = 25e6    # Baud
OS    = 4       # oversampling
BETA  = 0.5     # roll-off
NBAUD = 16
M     = 4       # orden de modulación

# Canal
sweep_times = 12 
f_offset    = 10e3 # Hz
NSYMB_CONVERGENCE = 100000 # Convergencia de FSE y FCR (mitad y mitad)

# Receptor
OS_DSP    = 2
NTAPS_FSE = 33
lms_step  = 1e-3
lms_leak  = 0
Kp        = 1e-3
Ki        = Kp/1000

# Contador de BER
START_CNT = 400000

#np.random.seed(1)  # Establece la semilla




bersI_contadas = np.zeros(sweep_times)
bersQ_contadas = np.zeros(sweep_times)
th_ber         = np.zeros(sweep_times)
for EbNo_db in range(sweep_times):
    #######  TRANSMISOR
    # Symbols generator
    tx_symI_rand = 2*(np.random.uniform(-1,1,NSYMB)>0.0)-1
    tx_symQ_rand = 2*(np.random.uniform(-1,1,NSYMB)>0.0)-1
    
    # Up-sampler
    tx_symI_up = np.zeros(OS*NSYMB); tx_symI_up[0:len(tx_symI_up):int(OS)]=tx_symI_rand*OS
    tx_symQ_up = np.zeros(OS*NSYMB); tx_symQ_up[0:len(tx_symQ_up):int(OS)]=tx_symQ_rand*OS
    
    # RRC Filter
    (t, rrc, dot) = r_rcosine(fc=BR/2, fs=OS*BR, rolloff=BETA, nbauds=NBAUD, norm=True)
    
    tx_symI_rrc = signal.lfilter(rrc, [1], tx_symI_up)
    tx_symQ_rrc = signal.lfilter(rrc, [1], tx_symQ_up)
    
    
    
    ######## CANAL
    # AWG
    EbNo       = 10**(EbNo_db/10)
    SNR_slicer = EbNo*np.log2(M)
    SNR_ch     = SNR_slicer/OS
    noise_var = np.var(tx_symI_rrc+1j*tx_symQ_rrc)/SNR_ch
    noise_I = np.sqrt(noise_var/2)*np.random.normal(loc=0, scale=1, size=tx_symI_rrc.shape)
    noise_Q = np.sqrt(noise_var/2)*np.random.normal(loc=0, scale=1, size=tx_symQ_rrc.shape)
    
    ch_symI_noisy = tx_symI_rrc + noise_I
    ch_symQ_noisy = tx_symQ_rrc + noise_Q
    
    
    # Offset de frecuencia
    Ts = 1/(OS*BR)
    time_vector    = np.arange(NSYMB_CONVERGENCE*OS*Ts, NSYMB*OS*Ts, Ts)
    titas          = np.array(2*np.pi*f_offset * time_vector, dtype=np.float32)
    ch_symIjQ_rot  = ch_symI_noisy + 1j*ch_symQ_noisy
    ch_symI_rot = np.array(ch_symI_noisy, dtype=np.float32)
    ch_symQ_rot = np.array(ch_symQ_noisy, dtype=np.float32)
    
    ch_symI_rot[NSYMB_CONVERGENCE*OS: ] = (ch_symI_noisy[NSYMB_CONVERGENCE*OS: ]*np.cos(titas)-
                                             ch_symQ_noisy[NSYMB_CONVERGENCE*OS: ]*np.sin(titas))
    ch_symQ_rot[NSYMB_CONVERGENCE*OS: ] = (ch_symI_noisy[NSYMB_CONVERGENCE*OS: ]*np.sin(titas)+
                                             ch_symQ_noisy[NSYMB_CONVERGENCE*OS: ]*np.cos(titas))
    
    
    # Filtro de canal
    ch_filt_coeff = signal.firwin(numtaps=100, cutoff=0.5*BR ,window='hamming', fs=4*BR)
    ch_symI_ch_filt = signal.lfilter(ch_filt_coeff, [1], ch_symI_rot)
    ch_symQ_ch_filt = signal.lfilter(ch_filt_coeff, [1], ch_symQ_rot)
    
    
    ######## RECEPTOR
    aaf_coeff = signal.firwin(numtaps=100, cutoff=0.9*(BR) ,window='hamming', fs=4*BR)
    rx_symI_aaf = signal.lfilter(aaf_coeff, [1], ch_symI_ch_filt)
    rx_symQ_aaf = signal.lfilter(aaf_coeff, [1], ch_symQ_ch_filt)
    
    # Downsampler
    rx_symI_dw = rx_symI_aaf[0:len(rx_symI_aaf):int(OS_DSP)]
    rx_symQ_dw = rx_symQ_aaf[0:len(rx_symQ_aaf):int(OS_DSP)]
    
    # AGC
#    target = 1 # Vrms
#    metric = np.std(rx_symI_dw+1j*rx_symQ_dw)
#    agc_gain = target/metric
    agc_gain = 1
    rx_symI_agc =  rx_symI_dw * agc_gain
    rx_symQ_agc =  rx_symQ_dw * agc_gain
    
    
    # Variables para FFE
    fseI_buffer = np.zeros(NTAPS_FSE)
    fseQ_buffer = np.zeros(NTAPS_FSE)
    fseI_coeff  = np.zeros(NTAPS_FSE); fseI_coeff[int(NTAPS_FSE/2)] = 1
    fseQ_coeff  = np.zeros(NTAPS_FSE); fseQ_coeff[int(NTAPS_FSE/2)] = 0
    rx_symI_fse = np.zeros(NSYMB*OS_DSP)
    rx_symQ_fse = np.zeros(NSYMB*OS_DSP)
    
    log_step    = 500
    coeffs_log  = np.zeros((NTAPS_FSE, int(NSYMB/log_step)))
    
    # Variables para FCR
    nco_out     = 0
    int_err     = 0 
    rx_symI_fcr = np.zeros(NSYMB*OS_DSP)
    rx_symQ_fcr = np.zeros(NSYMB*OS_DSP)
    
    # Variables para el slicer
    rx_symI_slcr  = np.zeros(NSYMB)
    rx_symQ_slcr  = np.zeros(NSYMB)
    
    for i in range(NSYMB*OS_DSP):
        # Filter buffer
        fseI_buffer[1:] = fseI_buffer[:-1]
        fseI_buffer[0]  = rx_symI_agc[i]
        fseQ_buffer[1:] = fseQ_buffer[:-1]
        fseQ_buffer[0]  = rx_symQ_agc[i]
     
        # Filter output
        rx_symI_fse[i] = np.dot(fseI_buffer,fseI_coeff)-np.dot(fseQ_buffer,fseQ_coeff)
        rx_symQ_fse[i] = np.dot(fseI_buffer,fseQ_coeff)+np.dot(fseQ_buffer,fseI_coeff)
        
        # FCR output: multiplicación por e^{-jnco_out}
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
            if (((i+1)/OS_DSP)%log_step) == 0:
                coeffs_log[:, int(((i+1)/OS_DSP)/log_step)-1] = fseI_coeff
            
            # Phase error
            angle_err = np.angle(rx_symI_fcr[i]+1j*rx_symQ_fcr[i])-np.angle(rx_symI_slcr[k]+1j*rx_symQ_slcr[k])
            # PI loop filter
            Kp = 1e-3 if(i>(NSYMB_CONVERGENCE/2)) else 0
            Ki = Kp/1000
            prop_err = Kp * angle_err
            int_err  = Ki*angle_err + int_err
            # NCO
            nco_out  = (prop_err+int_err) + nco_out
    # Fin del for del dsp
    
    #####################  Bit-Error Rate
    # Synchro
    #LAT =  -find_delay(tx_symI_rand,rx_symI_slcr)
    LAT=40
    rx_symI_ber_sync = rx_symI_slcr[LAT:]
    rx_symQ_ber_sync = rx_symQ_slcr[LAT:]
    
    # Counter
    phases = np.array([0, np.pi/2, np.pi, (3/2)*np.pi])
    ber_I  = np.zeros(4)
    ber_Q  = np.zeros(4)
    for i in range(len(phases)):
        # Rotation of constellation
        rx_symIjQ_rot_4_ber = (rx_symI_ber_sync+1j*rx_symQ_ber_sync) * np.exp(1j*phases[i])
        rx_symI_rot_4_ber   = 2*(rx_symIjQ_rot_4_ber.real>0.0)-1
        rx_symQ_rot_4_ber   = 2*(rx_symIjQ_rot_4_ber.imag>0.0)-1
       
        # Demapper
        rx_bit_I = np.where(rx_symI_rot_4_ber == 1, 0, 1)
        rx_bit_Q = np.where(rx_symQ_rot_4_ber == 1, 0, 1)
        tx_bit_I = np.where(tx_symI_rand == 1, 0, 1)
        tx_bit_Q = np.where(tx_symQ_rand == 1, 0, 1)
     
        # BER counter
        error_I=0
        total_I=0
        error_Q=0
        total_Q=0
        for k in range(START_CNT,NSYMB-LAT):
            if (rx_bit_I[k] != tx_bit_I[k]):
                error_I = error_I + 1
            total_I = total_I + 1 
            if (rx_bit_Q[k] != tx_bit_Q[k]):
                error_Q = error_Q + 1
            total_Q = total_Q + 1 
        
        ber_I[i] = error_I/total_I
        ber_Q[i] = error_Q/total_Q
    # Fin del for del conteo
    
    
    bersI_contadas[EbNo_db] = np.min(ber_I)
    bersQ_contadas[EbNo_db] = np.min(ber_Q)
    th_ber[EbNo_db] = theoric_ber(M, EbNo_db)
    

    print("EbNo =", EbNo_db, "dB | f_off =",f_offset, "Hz")
    print("BER_I: ", ber_I)
    print("BER_Q: ", ber_Q)
    print("theo_ber: ", th_ber[EbNo_db],"\n")

# Fin del for de barrido de EbNo




plt.figure(figsize=[14,6])
plt.title('BER vs EbNo')
plt.semilogy(range(sweep_times), th_ber  , 'r', linewidth=2.0)
plt.semilogy(range(sweep_times), bersI_contadas, 'b', linewidth=2.0)
plt.semilogy(range(sweep_times), bersI_contadas, 'g', linewidth=2.0)
plt.xlabel('EbNo(dB)')
plt.ylabel('BER')
plt.grid(True)
plt.xlim(0,15)
plt.ylim(0.000001,1)
plt.legend(['BER teo','BER I','BER Q'])
plt.show()
