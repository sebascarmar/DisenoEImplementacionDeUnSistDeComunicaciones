import numpy as np

class noise_gen:

    def __init__(self, OS, SNR_dB):
        self.SNR_slicer = 10**(SNR_dB/10)
        self.SNR_ch     = self.SNR_slicer/OS
        self.fifo       = np.zeros(1000)
        self.media      = 0
        self.sigma      = 1


    def add_noise(self, symb_in):
        
        self.fifo    = np.roll(self.fifo, 1)
        self.fifo[0] = symb_in
        
        noise_var    = np.var(self.fifo)/self.SNR_ch
        noise        = np.sqrt(noise_var)*np.random.normal(self.media, self.sigma)
        
        return symb_in + noise

