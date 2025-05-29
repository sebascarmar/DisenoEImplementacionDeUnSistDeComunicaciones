import numpy as np
from tool._fixedInt import *

class noise_gen:

    def __init__(self, OS, SNR_dB):
        # Parameters to model noise
        self.SNR_slicer = 10**(SNR_dB/10)
        self.SNR_ch     = self.SNR_slicer/OS
        self.fifo_I     = np.zeros(10000)
        self.fifo_Q     = np.zeros(10000)
        self.media_gen  = 0
        self.sigma_gen  = 1
        self.noise_sigma  = DeFixedInt(8, 7, 'S', 'trunc', 'saturate')
        self.noise_sigma.value = 0.0
        self.randn      = DeFixedInt(16, 11, 'S', 'trunc', 'saturate')
        self.randn.value = 0.0
        
        # Variable to quantize noise to be added
        self.noise_quan = DeFixedInt(8, 7, 'S', 'trunc', 'saturate')
        self.noise_quan.value = 0.0
        
        # Variable to quantize the output value
        self.sym_plus_noise = DeFixedInt(8, 7, 'S', 'trunc', 'saturate')
        self.sym_plus_noise.value = 0.0


    def add_noise_I(self, symb_in):
        # Rotate and update FIFO register
        self.fifo_I    = np.roll(self.fifo_I, 1)
        self.fifo_I[0] = symb_in
        
        # Calculate noise (Gaussian) to be added, based on FIFO variance and SNR
        noise_var_per_lane     = np.var(self.fifo_I)/self.SNR_ch
        self.noise_sigma.value = np.sqrt(noise_var_per_lane)
        self.randn.value       = np.random.normal(self.media_gen, self.sigma_gen)
        noise_to_be_added      = self.noise_sigma.fValue*self.randn.fValue
        
        # Quantize the noise value
        self.noise_quan.value = noise_to_be_added
        
        # Add quantized noise to input symbol
        self.sym_plus_noise.value = symb_in + self.noise_quan.fValue
        
        return self.sym_plus_noise.fValue


    def add_noise_Q(self, symb_in):
        # Rotate and update FIFO register
        self.fifo_Q    = np.roll(self.fifo_Q, 1)
        self.fifo_Q[0] = symb_in
        
        # Calculate noise (Gaussian) to be added, based on FIFO variance and SNR
        noise_var_per_lane     = np.var(self.fifo_Q)/self.SNR_ch
        self.noise_sigma.value = np.sqrt(noise_var_per_lane)
        self.randn.value       = np.random.normal(self.media_gen, self.sigma_gen)
        noise_to_be_added      = self.noise_sigma.fValue*self.randn.fValue
        
        # Quantize the noise value
        self.noise_quan.value = noise_to_be_added
        
        # Add quantized noise to input symbol
        self.sym_plus_noise.value = symb_in + self.noise_quan.fValue
        
        return self.sym_plus_noise.fValue

