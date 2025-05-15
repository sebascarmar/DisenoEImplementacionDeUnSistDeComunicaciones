import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator




########################################################################################
########################################################################################

snr                       = np.array([    7.184,     8.168,     9.279,    10.107])

ber_the                   = np.array([1.111e-02, 5.217e-03, 1.805e-03, 6.840e-04])

#---------------------------------------------------------------------------------------

ber_I_noise_float         = np.array([1.125e-02, 5.373e-03, 1.985e-03, 7.108e-04]) # 1M of symbs
ber_Q_noise_float         = np.array([1.130e-02, 5.279e-03, 1.822e-03, 7.094e-04]) # 1M of symbs

ber_I_noise_hwd           = np.array([1.454e-02, 6.888e-03, 2.543e-03, 1.061e-03]) # 5 min to take it
ber_Q_noise_hwd           = np.array([1.474e-02, 7.015e-03, 2.606e-03, 1.091e-03]) # 5 min to take it

#---------------------------------------------------------------------------------------

ber_I_noise_isi_float_12M = np.array([1.224e-02, 5.871e-03, 2.023e-03, 8.173e-04]) # 1M of symbs
ber_Q_noise_isi_float_12M = np.array([1.241e-02, 5.845e-03, 2.128e-03, 8.659e-04]) # 1M of symbs

ber_I_noise_isi_hwd_12M   = np.array([1.518e-02, 7.273e-03, 2.730e-03, 1.155e-03]) # 5 min to take it
ber_Q_noise_isi_hwd_12M   = np.array([1.542e-02, 7.423e-03, 2.807e-03, 1.194e-03]) # 5 min to take it

#---------------------------------------------------------------------------------------

ber_I_noise_isi_hwd_10M   = np.array([1.666e-02, 8.224e-03, 3.226e-03, 1.428e-03]) # 5 min to take it
ber_Q_noise_isi_hwd_10M   = np.array([1.692e-02, 8.399e-03, 3.324e-03, 1.483e-03]) # 5 min to take it

########################################################################################
########################################################################################

snr_full                     = np.array([   7.184,     8.168,     9.279,    10.107,
                                           11.022,    12.045,    13.205,    14.544,
                                           15.299,    16.127,    17.042  
                                        ])

ber_the_full                 = np.array([1.111e-02, 5.217e-03, 1.805e-03, 6.840e-04,
                                         1.875e-04, 3.145e-05, 2.400e-06, 4.762e-08,
                                         2.932e-09, 7.634e-11, 5.633e-13 
                                        ])

#---------------------------------------------------------------------------------------

ber_I_noise_hwd_full         = np.array([1.454e-02, 6.888e-03, 2.543e-03, 1.061e-03,
                                         3.447e-04, 7.748e-05, 1.004e-05, 5.478e-07,
                                         7.644e-08, 7.318e-09, 3.326e-10
                                        ]) # 10 min to take it
ber_Q_noise_hwd_full         = np.array([1.474e-02, 7.016e-03, 2.607e-03, 1.091e-03,
                                         3.550e-04, 7.877e-05, 9.684e-06, 4.407e-07,
                                         5.548e-08, 3.460e-09, 2.661e-10
                                        ]) # 10 min to take it

#---------------------------------------------------------------------------------------
    
ber_I_noise_isi_hwd_12M_full = np.array([1.518e-02, 7.273e-03, 2.730e-03, 1.155e-03,
                                         3.802e-04, 8.718e-05, 1.149e-05, 6.351e-07,
                                         8.908e-08, 7.584e-09, 3.326e-10
                                        ]) # 10 min to take it
ber_Q_noise_isi_hwd_12M_full = np.array([1.542e-02, 7.424e-03, 2.807e-03, 1.194e-03,
                                         3.945e-04, 8.989e-05, 1.146e-05, 5.506e-07,
                                         7.032e-08, 4.790e-09, 4.657e-10
                                        ]) # 10 min to take it

#---------------------------------------------------------------------------------------
    
ber_I_noise_isi_hwd_10M_full = np.array([1.666e-02, 8.223e-03, 3.227e-03, 1.428e-03,
                                         5.015e-04, 1.261e-04, 1.921e-05, 1.334e-06,
                                         2.237e-07, 2.362e-08, 1.264e-09
                                        ]) # 10 min to take it
ber_Q_noise_isi_hwd_10M_full = np.array([1.692e-02, 8.400e-03, 3.325e-03, 1.483e-03,
                                         5.269e-04, 1.345e-04, 2.087e-05, 1.474e-06,
                                         2.435e-07, 2.814e-08, 2.395e-09
                                        ]) # 10 min to take it
                                      

########################################################################################
########################################################################################


# Plot
plt.figure(figsize=[7, 7])  
plt.title('BER vs SNR | Noise')
plt.semilogy(snr, ber_the, 'r', linewidth=2.0)
plt.semilogy(snr, (ber_I_noise_float+ber_Q_noise_float)/2,
             'g', linewidth=2.0)
plt.semilogy(snr, (ber_I_noise_hwd+ber_Q_noise_hwd)/2, 
             color='coral', linewidth=2.0)
plt.xlabel('SNR [dB]')
plt.ylabel('BER')
plt.grid(True, which='both')
plt.xlim([6.8, 10.5])
plt.ylim([6e-4, 2e-2])
plt.legend(['BER theo','BER float','BER hwd'])
plt.tight_layout()
#plt.show()


# Plot
plt.figure(figsize=[7,7])
plt.title('BER vs SNR | Noise+ISI')
plt.semilogy(snr, ber_the, 'r', linewidth=2.0)
plt.semilogy(snr, (ber_I_noise_isi_float_12M+ber_Q_noise_isi_float_12M)/2,
             'g',  linewidth=2.0)
plt.semilogy(snr, (ber_I_noise_isi_hwd_12M+ber_Q_noise_isi_hwd_12M)/2,
             color='coral', linewidth=2.0)
plt.xlabel('SNR [dB]')
plt.ylabel('BER')
plt.grid(True, which='both')
plt.xlim([6.8, 10.5])
plt.ylim([6e-4, 2e-2])
plt.legend(['BER theo','BER float','BER hwd'])
plt.tight_layout()
#plt.show()


 
                                     
# Plot
plt.figure(figsize=[7, 7])  
plt.title('BER vs SNR | Data from hardware')
plt.semilogy(snr_full, ber_the_full, color='red', linewidth=2.0)
plt.semilogy(snr_full, (ber_I_noise_hwd_full+ber_Q_noise_hwd_full)/2,
             color='green', linewidth=2.0)
plt.semilogy(snr_full, (ber_I_noise_isi_hwd_12M_full+ber_Q_noise_isi_hwd_12M_full)/2,
             color='blueviolet', linewidth=2.0)
plt.semilogy(snr_full, (ber_I_noise_isi_hwd_10M_full+ber_Q_noise_isi_hwd_10M_full)/2,
             color='coral', linewidth=2.0)

plt.xlabel('SNR [dB]')
plt.ylabel('BER')
plt.xlim([6.5, 17.5])
plt.ylim([3e-13, 2e-2])

ax = plt.gca()
ax.yaxis.set_minor_locator(LogLocator(base=10.0, subs=np.arange(2, 10)*0.1, numticks=100))
ax.grid(True, which='major', linestyle='-', linewidth=0.8)
ax.grid(True, which='minor', linestyle='--', linewidth=0.5)


plt.legend(['BER theo', 'BER (impulse)', 'BER (12MHz)', 'BER (10MHz)'])
plt.tight_layout()
plt.show()                                    
