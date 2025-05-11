import numpy as np
import matplotlib.pyplot as plt


snr    = np.array([7.184    , 8.168    , 9.279    , 10.107   , 11.022   , 12.045])
bersI  = np.array([1.525e-02, 7.324e-03, 2.801e-03, 1.206e-03, 3.754e-04, 6.990e-05])
bersQ  = np.array([1.549e-02, 7.412e-03, 2.829e-03, 1.250e-03, 3.987e-04, 9.061e-05])
th_ber = np.array([1.111e-02, 5.217e-03, 1.805e-03, 6.840e-04, 1.875e-04, 3.145e-05])


# Plot
plt.figure(figsize=[10,10])
plt.title('BER vs SNR | (data from testbench)')
plt.semilogy(snr, th_ber, 'r', linewidth=2.0)
plt.semilogy(snr, bersI, 'b', linewidth=2.0)
plt.semilogy(snr, bersQ, 'g', linewidth=2.0)
plt.xlabel('SNR [dB]')
plt.ylabel('BER')
plt.grid(True)
#plt.ylim([1e-5, 0.7e-1])
plt.xlim([6.8, 12.2])
#plt.gca().set_aspect('equal', adjustable='box')
plt.axis('equal')
plt.legend(['SNR theo','SNR I','SNR Q'])
plt.show()

