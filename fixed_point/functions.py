import numpy as np
import math

### Calculate RRC filter coefficients
def r_rcosine(fc, fs, rolloff, nbauds, norm):

    rolloff = rolloff + 0.0001
    BR = fc*2         # Baud Rate
    Tbaud = 1 / BR    # Time interval between two consecutive symbols
    Ts = 1 / fs       # Time between 2 consecutive samples at Tx output
    os = int(Tbaud/Ts)# Oversampling

    # Force an odd number of coefficients
    if (os*nbauds)%2 == 0:
        t_vect = np.arange(-0.5*nbauds*Tbaud, 0.5*nbauds*Tbaud+Ts/100, Ts)
    else:
        t_vect = np.arange(-0.5*nbauds*Tbaud, 0.5*nbauds*Tbaud, Ts)

    t_vect_n = t_vect / Tbaud # normaliza

    y_vect = []
    
    # Low-Pass Filter
    for t in t_vect_n:
        if (t == 0):
            y_vect.append((1+rolloff*(4/np.pi-1)))
        else:
            y_vect.append((4*rolloff*t*np.cos(((1+rolloff)*np.pi*t))+
                                       np.sin((1-rolloff)*np.pi*t))/
                          (np.pi*t*(1-(16*rolloff*rolloff*t*t))))

    y_vect = np.array(y_vect)
    if norm:
        y_vect = y_vect/np.sum(y_vect)   # normalize, 0db

    dot = (np.sum(y_vect ** 2))

    return t_vect_n, y_vect, dot


### Slicer used for each lane sepaFuerza un número impar de coeficientes separately
def slicer_pam(x):
    if(x>=0):
        a = 1;
    else:
        a =-1;

    return a


### Calculate the theoric values of BER in function of SNR
def theoric_ber(M, SNRdB):
    SNR_slicer  = 10**(SNRdB/10)
    EbNo = SNR_slicer/np.log2(M)
    k    = np.log2(M)
    x    = np.sqrt(3*k*EbNo/(M-1))
    ber  = (4/k)*(1-1/np.sqrt(M))*(1/2)*math.erfc(x/np.sqrt(2))

    return ber

