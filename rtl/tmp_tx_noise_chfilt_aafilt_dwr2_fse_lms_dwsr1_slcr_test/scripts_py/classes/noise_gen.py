import numpy as np
from tool._fixedInt import *

class noise_gen:

    def __init__(self, OS, SNR_dB):
        # Parameters to model noise
        self.SNR_slicer = 10**(SNR_dB/10)
        self.SNR_ch     = self.SNR_slicer/OS
        self.fifo       = np.zeros(1000)
        self.media      = 0
        self.sigma      = 1
        
        # Variable to quantize noise to be added
        self.noise_quan = DeFixedInt(8, 7, 'S', 'trunc', 'saturate')
        self.noise_quan.value = 0.0
        
        # Variable to quantize the output value
        self.sym_plus_noise = DeFixedInt(8, 7, 'S', 'trunc', 'saturate')
        self.sym_plus_noise.value = 0.0


    def add_noise(self, symb_in):
        # Rotate and update FIFO register
        self.fifo    = np.roll(self.fifo, 1)
        self.fifo[0] = symb_in
        
        # Calculate noise (Gaussian) to be added, based on FIFO variance and SNR
        noise_var    = np.var(self.fifo)/self.SNR_ch
        noise        = np.sqrt(noise_var)*np.random.normal(self.media, self.sigma)
        
        # Quantize the noise value
        self.noise_quan.value = noise
        
        # Add quantized noise to input symbol
        self.sym_plus_noise.value = symb_in + self.noise_quan.fValue
        
        return self.sym_plus_noise.fValue

