import numpy as np

class fir_filter:

    def __init__(self, filt_coeff):
        self.filt_coeff   = filt_coeff
        self.shifter_filt = np.zeros(len(filt_coeff))
        self.partial_prod = np.zeros(len(filt_coeff))
        self.sym_out      = 0.0
        
        if( (len(filt_coeff))%2 != 1 ):
            print("FIR_FILTER CLASS: the number of coeffs. is not odd")
        

    def convol(self, new_symb):
        # It's going to be useful for truncation and saturation
        self.sym_out = 0.0
        
        # Shift and get a new symbol (like a FIFO) each OS cycles
        self.shifter_filt    = np.roll(self.shifter_filt,1)
        self.shifter_filt[0] = new_symb
        
        # Multiplication of filter coeffs. and symbols
        for j in range(len(self.shifter_filt)):
            self.partial_prod[j] = self.filt_coeff[j]*self.shifter_filt[j]
            
        # Sum all the partial products
        for k in range(0,len(self.partial_prod)-1,2):
            self.sym_out += self.partial_prod[k]+self.partial_prod[k+1]
        self.sym_out += self.partial_prod[len(self.partial_prod)-1]
            

        return self.sym_out

