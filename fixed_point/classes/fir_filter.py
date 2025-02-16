import numpy as np
from tool._fixedInt import *
import copy

class fir_filter:

    def __init__(self, filt_coeff, NTot, NFra):
        ### Perform quantization of filter coefficients
        self.coeffs = arrayFixedInt(NTot, NFra, filt_coeff, 'S', 'trunc', 'saturate')
        ### Shift register for input symbols
        shifter_filt      = np.zeros(len(filt_coeff))
        self.shifter_filt = arrayFixedInt(NTot, NFra, shifter_filt, 'S', 'trunc', 'saturate')
        ### Partial products of the convolution
        partial_prod      = np.zeros(len(filt_coeff))
        self.partial_prod = arrayFixedInt(2*NTot, 2*NFra, partial_prod, 'S', 'trunc', 'saturate')
        ### Filter out
        self.filt_out       = DeFixedInt(2*NTot+5, 2*NFra, 'S', 'trunc', 'saturate')
        self.filt_out.value = 0.0
        ### Saturate and truncation of filter out
        self.sym_out       = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.sym_out.value = 0.0
        
        if( (len(filt_coeff))%2 != 1 ):
            print("FIR_FILTER CLASS: the number of coeffs. is not odd")
        

    def convol(self, new_symb):
        # Shift and get a new symbol (like a FIFO) each OS cycles
        self.shifter_filt    = np.roll(self.shifter_filt,1)
        self.shifter_filt[0].value = new_symb
        
        # Multiplication of filter coeffs. and symbols
        for j in range(len(self.shifter_filt)):
            self.partial_prod[j].value = self.coeffs[j].fValue * self.shifter_filt[j].fValue
            
        # Sum all the partial products
        self.filt_out.value = 0.0
        for k in range(len(self.partial_prod)):
            self.filt_out.value = self.filt_out.fValue + self.partial_prod[k].fValue
            
        # Saturate and truncate the final value
        self.sym_out.value = self.filt_out.fValue
        
        
        return self.sym_out.fValue


    def get_quantized_coeffs(self):
        out = np.zeros(len(self.coeffs))
        for i in range(len(out)):
            out[i] = self.coeffs[i].fValue
        
        return out

