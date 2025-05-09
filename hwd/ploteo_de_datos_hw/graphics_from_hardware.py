import numpy as np
import matplotlib.pyplot as plt
import math
from scipy import signal
import os

### Calculate the theoric values of BER in function of SNR
def theoric_ber(SNRdB):
    M = 4
    SNR_slicer  = 10**(SNRdB/10)
    EbNo = SNR_slicer/np.log2(M)
    k    = np.log2(M)
    x    = np.sqrt(3*k*EbNo/(M-1))
    ber  = (4/k)*(1-1/np.sqrt(M))*(1/2)*math.erfc(x/np.sqrt(2))

    return ber



def ber_with_data_from_hw():
    # Datos proporcionados
    data_ber_I = [
        15410734072,  # SNR 7
        15154096919,  # SNR 8
        15058556948,  # SNR 9
        15066086070,  # SNR 10
        15057614520,  # SNR 11
        15029990543   # SNR 12
    ]

    data_err_I = [
        233939948,  # SNR 7
        110208793,  # SNR 8
        41115022,   # SNR 9
        17406034,   # SNR 10
        5727043,    # SNR 11
        1310255     # SNR 12
    ]

    data_ber_Q = [
        15410734072,  # SNR 7
        15154096919,  # SNR 8
        15058556948,  # SNR 9
        15066086070,  # SNR 10
        15057614520,  # SNR 11
        15029990543   # SNR 12
    ]

    data_err_Q = [
        237602878,  # SNR 7
        112501296,  # SNR 8
        42274846,   # SNR 9
        17988166,   # SNR 10
        5938746,    # SNR 11
        1351223     # SNR 12
    ]

    # Calcular BER para I y Q
    BERI = [err / ber for err, ber in zip(data_err_I, data_ber_I)]
    BERQ = [err / ber for err, ber in zip(data_err_Q, data_ber_Q)]

    return BERI, BERQ

####################################################################################
#                                      MAIN                                        #
####################################################################################

# Parámetros
NBF_AAFILT_OUT = 7   
NBF_FSE_OUT    = 9
NTAPS_FSE      = 9
NBF_FSE_TAPS   = 7
NSYMB          = 32760
th_ber = []  

# Recorrer carpetas snr7 a snr12
for snr in range(7, 13):
    folder = f"snr{snr}"

    # Crear carpeta para guardar gráficos
    if not os.path.exists("plots"):
        os.makedirs("plots")
    ##############
    folder_save = f"plots"
    print(f"leyendo folder: {folder}")

    # Leer los archivos
    try:
        rx_symI_dw_r2_from_ver = np.loadtxt(os.path.join(folder, f"file_rx_symI_dwr2_snr_{snr}.txt"))
        rx_symQ_dw_r2_from_ver = np.loadtxt(os.path.join(folder, f"file_rx_symQ_dwr2_snr_{snr}.txt"))

        rx_symI_dw_r2 = rx_symI_dw_r2_from_ver / (2**NBF_AAFILT_OUT)
        rx_symQ_dw_r2 = rx_symQ_dw_r2_from_ver / (2**NBF_AAFILT_OUT)

        fseI_taps_from_ver = np.loadtxt(os.path.join(folder, f"file_fse_taps_I_snr_{snr}.txt"))
        fseQ_taps_from_ver = np.loadtxt(os.path.join(folder, f"file_fse_taps_Q_snr_{snr}.txt"))

        fseI_taps = fseI_taps_from_ver / (2**NBF_FSE_TAPS)
        fseQ_taps = fseQ_taps_from_ver / (2**NBF_FSE_TAPS)

        fse_coeff_I = np.zeros((NTAPS_FSE, int(NSYMB/NTAPS_FSE)))
        fse_coeff_Q = np.zeros((NTAPS_FSE, int(NSYMB/NTAPS_FSE)))
        for i in range(NTAPS_FSE):
            for j in range(int(NSYMB/NTAPS_FSE)):
                fse_coeff_I[i][j] = fseI_taps[i + j*NTAPS_FSE]
                fse_coeff_Q[i][j] = fseQ_taps[i + j*NTAPS_FSE]

        rx_symI_dw_r1_from_ver = np.loadtxt(os.path.join(folder, f"file_rx_symI_dwr1_snr_{snr}.txt"))
        rx_symQ_dw_r1_from_ver = np.loadtxt(os.path.join(folder, f"file_rx_symQ_dwr1_snr_{snr}.txt"))

        rx_symI_dw_r1 = rx_symI_dw_r1_from_ver / (2**NBF_FSE_OUT)
        rx_symQ_dw_r1 = rx_symQ_dw_r1_from_ver / (2**NBF_FSE_OUT)

        ##################################
        # Generar y guardar los gráficos #
        ##################################

        # Plot 1: Constelaciones
        plt.figure(figsize=[8,4])
        plt.suptitle(f'Constellation Diagrams SNR={snr}')
        plt.subplot(1,2,1)
        plt.plot(rx_symI_dw_r2, rx_symQ_dw_r2, color='chocolate', marker='.', linestyle='', label='dowsamp. (rate 2)')
        plt.xlim((-3, 3))
        plt.ylim((-3, 3))
        plt.gca().set_aspect('equal', adjustable='box')
        plt.grid(True)
        plt.xlabel('Real (I)')
        plt.ylabel('Imag (Q)')
        plt.legend()
        plt.subplot(1,2,2)
        plt.plot(rx_symI_dw_r1, rx_symQ_dw_r1, color='seagreen', marker='.', linestyle='', label='dowsamp. (rate 1)')
        plt.xlim((-3, 3))
        plt.ylim((-3, 3))
        plt.gca().set_aspect('equal', adjustable='box')
        plt.grid(True)
        plt.xlabel('Real (I)')
        plt.legend()
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"constellation_snr{snr}.png"))
        plt.close()

        # Plot 2: símbolos reales vs tiempo
        plt.figure(figsize=[10,6])
        plt.suptitle(f'Equalizer input and output SNR={snr}')
        plt.subplot(2,1,1)
        plt.plot(rx_symI_dw_r2, color='chocolate', marker='.', linestyle='', label="Dws - rate 2")
        plt.ylim((-3, 3))
        plt.ylabel('Real (I)')
        plt.grid(True)
        plt.legend()
        plt.subplot(2,1,2)
        plt.plot(rx_symI_dw_r1, color='seagreen', marker='.', linestyle='', label="Dws - rate 1")
        plt.ylim((-3, 3))
        plt.xlabel('Time [n]')
        plt.ylabel('Real (I)')
        plt.grid(True)
        plt.legend()
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"symbols_time_snr{snr}.png"))
        plt.close()


        ##################### Adapatvie Filter graphics ####################

        # Get frequencies and magnitudes
        last_fse_taps = fse_coeff_I[:NTAPS_FSE, (int(NSYMB/NTAPS_FSE))-1]

        f_fse, h_fse = signal.freqz(last_fse_taps, worN=800, fs=50e6)
        # Find the -3 dB point
        fc_idx = np.where(20*np.log10(np.abs(h_fse)) <= (20*np.log10(np.abs(h_fse[50])) - 3.01))[0][0]
        actual_fc_fse = f_fse[fc_idx]

        ## Frequency response of the channel filter
        plt.figure(figsize=(8, 5))
        plt.plot(f_fse, 20*np.log10(np.abs(h_fse)), color='saddlebrown')
        plt.axhline(y=20*np.log10(np.abs(h_fse[50]))-3.01,
                    color='black',linestyle='dashed',linewidth=2.0,
                    label=f"{20*np.log10(np.abs(h_fse[50]))-3.01:.2f}dB")
        plt.axvline(x=actual_fc_fse,color='gray',linewidth=2.0,
                    label=f"{actual_fc_fse / 1e6:.2f}MHz")
        plt.axvline(x=12.5e6,color='coral',linewidth=2.0,
                    label=f"{12.5e6 / 1e6:.2f}MHz")
        plt.title(f'Bode - FSE I - SNR={snr}')
        plt.xlabel("Frequency [Hz]")
        plt.ylabel("Magnitud [dB]")
        plt.legend(loc="lower left")
        plt.ylim(-6.0,16.0)
        plt.grid(True)
        plt.legend()
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"bode_fse_I_snr{snr}.png"))   
        plt.close()

        ## Time axis (centered around zero)
        t = np.linspace(-0.5*(1/(50e6))*(len(last_fse_taps)-1),
                        0.5*(1/(50e6))*(len(last_fse_taps)-1),
                        len(last_fse_taps))
        # Impulse response of the transmitter filter
        plt.figure(figsize=[7,4])
        plt.plot(t, last_fse_taps, color='saddlebrown', marker='o',
                linestyle='-', linewidth=2.0)
        plt.axvline(0, color='k', linestyle='--', linewidth=1.5) 
        plt.title(f'FSE I Coefficients Impulse - SNR={snr}')
        plt.xlabel('Sample [s]')
        plt.ylabel('Magnitud')
        plt.ylim(-1.5,3.0)
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"fse_coeff_impulse_snr{snr}.png"))
        plt.close()

        # Plot 3: Coeficientes FSE I
        plt.figure(figsize=[10,6])
        plt.plot(fse_coeff_I.T)
        plt.title(f'FSE coefficients (I lane) - SNR={snr}')
        plt.xlabel('Time [n]')
        plt.ylim(-1.5, 3.0)
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"fse_coeff_I_snr{snr}.png"))
        plt.close()

        # Plot 4: Coeficientes FSE Q
        plt.figure(figsize=[10,6])
        plt.plot(fse_coeff_Q.T)
        plt.title(f'FSE coefficients (Q lane) - SNR={snr}')
        plt.xlabel('Time [n]')
        plt.ylim(-1.5, 3.0)
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(folder_save, f"fse_coeff_Q_snr{snr}.png"))
        plt.close()

    except FileNotFoundError as e:
        print(f"Error: No se encontró el archivo: {e.filename}")
    except Exception as e:
        print(f"Ocurrió un error procesando SNR={snr}: {e}")




snr = np.array   ([7.184, 8.168, 9.279, 10.107, 11.022, 12.045])
bersI, bersQ = ber_with_data_from_hw()
### calcular BER teórico con los valores de lista snr
for i in range(len(snr)):
    th_ber.append(theoric_ber(snr[i]))

print("snr: ", snr)
print("BER I lane: ", bersI)
print("BER Q lane: ", bersQ)
print("BER teórico: ", th_ber)

# Plot
plt.figure(figsize=[10,6])
plt.title('BER vs SNR - (Results from Hw custom)')
plt.semilogy(snr, th_ber, 'r', linewidth=2.0)
plt.semilogy(snr, bersI, 'b', linewidth=2.0)
plt.semilogy(snr, bersQ, 'g', linewidth=2.0)
plt.xlabel('SNR(dB)')
plt.ylabel('BER')
plt.grid(True)
plt.ylim([1e-5, 0.7e-1])
plt.xlim([6.9, 12.1])
plt.legend(['SNR theo','SNR I','SNR Q'])
plt.tight_layout()
plt.savefig(os.path.join(folder_save, f"ber_vs_snr_hw.png"))
plt.close()

