import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator
import os 

### Los graficos a realizar son... 
# BER th + Ber float + Ber fix (con isis y sin) 
# BER th + Ber fix + Ber hwd (con isi y sin)

# Create folder
if not os.path.exists("plots/ber_compare"):
    os.makedirs("plots/ber_compare")

### Variables
folder_save = f"plots/ber_compare"

########################################################################################
########################################################################################

snr                       = np.array([   7.0  ,     8.0  ,     9.0  ,    10.0  ])
snr_hwd                   = np.array([   7.184,     8.168,     9.279,    10.107])

ber_the                   = np.array([1.259e-02, 6.004e-03, 2.43e-03, 7.827e-04])

#---------------------------------------------------------------------------------------

ber_I_noise_float         = np.array([1.363e-02, 6.595e-03, 2.755e-03, 1.002e-03]) # 1M of symbs
ber_Q_noise_float         = np.array([1.369e-02, 6.733e-03, 2.723e-03, 9.710e-04]) # 1M of symbs

ber_I_noise_fixed         = np.array([1.432e-02, 6.595e-03, 2.975e-03, 1.093e-03]) # 1M of symbs
ber_Q_noise_fixed         = np.array([1.417e-02, 6.733e-03, 2.963e-03, 1.011e-03]) # 1M of symbs

ber_I_noise_hwd           = np.array([1.454e-02, 6.888e-03, 2.543e-03, 1.061e-03]) # 5 min to take it
ber_Q_noise_hwd           = np.array([1.474e-02, 7.015e-03, 2.606e-03, 1.091e-03]) # 5 min to take it

#---------------------------------------------------------------------------------------


ber_I_noise_isi_float_12M = np.array([1.363e-02, 6.692e-03, 2.759e-03, 9.441e-04]) # 1M of symbs
ber_Q_noise_isi_float_12M = np.array([1.357e-02, 6.593e-03, 2.901e-03, 9.873e-04]) # 1M of symbs

ber_I_noise_isi_fixed_12M = np.array([1.529e-2,  7.795e-03, 3.338e-03, 1.273e-03]) # 1M of symbs
ber_Q_noise_isi_fixed_12M = np.array([1.516e-02, 7.598e-03, 3.349e-03, 1.165e-03]) # 1M of symbs

ber_I_noise_isi_hwd_12M   = np.array([1.518e-02, 7.273e-03, 2.730e-03, 1.155e-03]) # 5 min to take it
ber_Q_noise_isi_hwd_12M   = np.array([1.542e-02, 7.423e-03, 2.807e-03, 1.194e-03]) # 5 min to take it

#---------------------------------------------------------------------------------------

ber_I_noise_isi_hwd_10M   = np.array([1.666e-02, 8.224e-03, 3.226e-03, 1.428e-03]) # 5 min to take it
ber_Q_noise_isi_hwd_10M   = np.array([1.692e-02, 8.399e-03, 3.324e-03, 1.483e-03]) # 5 min to take it

########################################################################################
########################################################################################


snr_th_full                  = np.array([   7.0,     8.0,     9.0,    10.0,
                                           11.0,    12.0,    13.0,    14.0,
                                           15.0,    16.0,    17.0  
                                        ])

snr_hwd_full                 = np.array([   7.184,     8.168,     9.279,    10.107,
                                           11.022,    12.045,    13.205,    14.544,
                                           15.299,    16.127,    17.042  
                                        ])


ber_th_full                  = np.array([1.259e-02, 6.004e-03, 2.43e-03, 7.827e-04,
                                         1.939855e-04, 3.430262e-05, 3.969248e-06, 2.695148e-07, 
                                         9.361040e-09, 1.399028e-10, 7.235976e-13
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
plt.title('BER vs SNR | Noise', fontsize=18)
plt.semilogy(snr, ber_the, 'r',marker='x', markersize=7, markeredgewidth=2.5, linewidth=2.0)

plt.semilogy(snr, (ber_I_noise_float+ber_Q_noise_float)/2,
             'g--', marker='o', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd, (ber_I_noise_fixed+ber_Q_noise_fixed)/2, 
             color='blue', linestyle='--', marker='^', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
#   plt.semilogy(snr_hwd, (ber_I_noise_hwd+ber_Q_noise_hwd)/2, 
#                color='darkviolet', linestyle='--', marker='D', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.xlabel('SNR [dB]', fontsize=15)
plt.ylabel('BER', fontsize=15)
plt.grid(True, which='both')
plt.xlim([6.8, 10.5])
plt.ylim([6e-4, 2e-2])
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)
# plt.legend(['BER theo', 'BER float (BWch=impulse)', 'BER fixed (BWch=impulse)', 'BER hwd (BWch=impulse)'], fontsize=12)
plt.legend(['BER theo', 'BER float (BWch=impulse)', 'BER fixed (BWch=impulse)'], fontsize=12)
plt.tight_layout()
#plt.show()
plt.savefig(os.path.join(folder_save, f"ber_vs_snr_noise_float_fix.png"))
plt.close()

# Plot
plt.figure(figsize=[7,7])
plt.title('BER vs SNR | Noise+ISI', fontsize=18)
plt.semilogy(snr, ber_the, 'r',marker='x', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr, (ber_I_noise_isi_float_12M+ber_Q_noise_isi_float_12M)/2,
             'g--', marker='o', markerfacecolor='none', markersize=7,markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd, (ber_I_noise_isi_fixed_12M+ber_Q_noise_isi_fixed_12M)/2,
             color='blue', linestyle='--', marker='^', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
#   plt.semilogy(snr_hwd, (ber_I_noise_isi_hwd_12M+ber_Q_noise_isi_hwd_12M)/2, 
#                color='darkviolet', linestyle='--', marker='D', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.xlabel('SNR [dB]', fontsize=15)
plt.ylabel('BER',fontsize=15)
plt.grid(True, which='both')
plt.xlim([6.8, 10.5])
plt.ylim([6e-4, 2e-2])
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)
#plt.legend(['BER theo','BER float (BWch=12MHz)','BER fixed (ch BW: 12MHz)', 'BER hwd (BWch=12MHz)'], fontsize=12)
plt.legend(['BER theo','BER float (BWch=12MHz)','BER fixed (BWch=12MHz)'], fontsize=12)
plt.tight_layout()
#plt.show()
plt.savefig(os.path.join(folder_save, f"ber_vs_snr_noise_and_isi_float_fix.png"))
plt.close()



# Plot
plt.figure(figsize=[7, 7])  
plt.title('BER vs SNR | Noise', fontsize=18)
plt.semilogy(snr, ber_the, 'r',marker='x', markersize=7, markeredgewidth=2.5, linewidth=2.0)

#plt.semilogy(snr, (ber_I_noise_float+ber_Q_noise_float)/2,
#             'g--', marker='o', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd, (ber_I_noise_fixed+ber_Q_noise_fixed)/2, 
             color='blue', linestyle='--', marker='^', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd, (ber_I_noise_hwd+ber_Q_noise_hwd)/2, 
             color='darkviolet', linestyle='--', marker='D', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.xlabel('SNR [dB]', fontsize=15)
plt.ylabel('BER', fontsize=15)
plt.grid(True, which='both')
plt.xlim([6.8, 10.5])
plt.ylim([6e-4, 2e-2])
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)
# plt.legend(['BER theo', 'BER float (BWch=impulse)', 'BER fixed (BWch=impulse)', 'BER hwd (BWch=impulse)'], fontsize=12)
plt.legend(['BER theo', 'BER fixed (BWch=impulse)', 'BER hwd (BWch=impulse)'], fontsize=12)
plt.tight_layout()
#plt.show()
plt.savefig(os.path.join(folder_save, f"ber_vs_snr_noise_fix_hwd.png"))
plt.close()

# Plot
plt.figure(figsize=[7,7])
plt.title('BER vs SNR | Noise+ISI', fontsize=18)
plt.semilogy(snr, ber_the, 'r',marker='x', markersize=7, markeredgewidth=2.5, linewidth=2.0)
#   plt.semilogy(snr, (ber_I_noise_isi_float_12M+ber_Q_noise_isi_float_12M)/2,
#                'g--', marker='o', markerfacecolor='none', markersize=7,markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd, (ber_I_noise_isi_fixed_12M+ber_Q_noise_isi_fixed_12M)/2,
             color='blue', linestyle='--', marker='^', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd, (ber_I_noise_isi_hwd_12M+ber_Q_noise_isi_hwd_12M)/2, 
             color='darkviolet', linestyle='--', marker='D', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.xlabel('SNR [dB]', fontsize=15)
plt.ylabel('BER',fontsize=15)
plt.grid(True, which='both')
plt.xlim([6.8, 10.5])
plt.ylim([6e-4, 2e-2])
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)
#plt.legend(['BER theo','BER float (BWch=12MHz)','BER fixed (ch BW: 12MHz)', 'BER hwd (BWch=12MHz)'], fontsize=12)
plt.legend(['BER theo', 'BER fixed (BWch=12MHz)', 'BER hwd (BWch=12MHz)'], fontsize=12)
plt.tight_layout()
#plt.show()
plt.savefig(os.path.join(folder_save, f"ber_vs_snr_noise_and_isi_fix_hwd.png"))
plt.close()


#   # Plot
#   plt.figure(figsize=[7,7])
#   plt.title('BER vs SNR | Noise+ISI', fontsize=18)
#   plt.semilogy(snr, ber_the, 'r',marker='x', markersize=7, markeredgewidth=2.5, linewidth=2.0)
#   plt.semilogy(snr, (ber_I_noise_isi_float_12M+ber_Q_noise_isi_float_12M)/2,
#                'g--', marker='o', markerfacecolor='none', markersize=7,markeredgewidth=2.5, linewidth=2.0)
#   plt.semilogy(snr_hwd, (ber_I_noise_isi_fixed_12M+ber_Q_noise_isi_fixed_12M)/2,
#                color='blue', linestyle='--', marker='^', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
#   plt.semilogy(snr_hwd, (ber_I_noise_isi_hwd_12M+ber_Q_noise_isi_hwd_12M)/2, 
#                color='darkviolet', linestyle='--', marker='D', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
#   plt.xlabel('SNR [dB]', fontsize=15)
#   plt.ylabel('BER',fontsize=15)
#   plt.grid(True, which='both')
#   plt.xlim([6.8, 10.5])
#   plt.ylim([6e-4, 2e-2])
#   plt.xticks(fontsize=14)
#   plt.yticks(fontsize=14)
#   plt.legend(['BER theo','BER float (BWch=12MHz)','BER fixed (ch BW: 12MHz)', 'BER hwd (BWch=12MHz)'], fontsize=12)
#   plt.tight_layout()
#   #plt.show()
            

# Plot
plt.figure(figsize=[7, 7])  
plt.suptitle('BER vs SNR  (hwd data)', fontsize=18)
plt.semilogy(snr_th_full, ber_th_full, color='red', marker='x', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd_full, (ber_I_noise_hwd_full+ber_Q_noise_hwd_full)/2,
             color='green', linestyle='--', marker='o', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd_full, (ber_I_noise_isi_hwd_12M_full+ber_Q_noise_isi_hwd_12M_full)/2,
             color='blueviolet', linestyle='--', marker='v', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.semilogy(snr_hwd_full, (ber_I_noise_isi_hwd_10M_full+ber_Q_noise_isi_hwd_10M_full)/2,
             color='coral', linestyle='--', marker='D', markerfacecolor='none', markersize=7, markeredgewidth=2.5, linewidth=2.0)
plt.xlabel('SNR [dB]', fontsize=15)
plt.ylabel('BER', fontsize=15)
plt.xlim([6.5, 17.5])
plt.ylim([3e-13, 2e-2])
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)
ax = plt.gca()
ax.yaxis.set_minor_locator(LogLocator(base=10.0, subs=np.arange(2, 10)*0.1, numticks=100))
ax.grid(True, which='major', linestyle='-', linewidth=0.8)
ax.grid(True, which='minor', linestyle='--', linewidth=0.5)
plt.legend(['BER theo', 'BER (BWch=impulse)', 'BER (BWch=12MHz)', 'BER (BWch=10MHz)'], fontsize=12)
plt.tight_layout()
#plt.show()        
plt.savefig(os.path.join(folder_save, f"ber_vs_snr_noise_and_isi_hwd_data.png"))
plt.close()

print("All plots were saved")
