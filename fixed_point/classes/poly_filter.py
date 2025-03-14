import numpy as np
from tool._fixedInt import *

class poly_filter:
    
    def __init__(self, filt_coeff, NBAUD, OS, NSYMB, NTOT, NFRA):
        
        ### Perform quantization of filter coefficients
        self.coeffs = arrayFixedInt(NTOT, NFRA, filt_coeff, 'S', 'trunc', 'saturate')
        ### Oversampling: number of phases
        self.OS           = OS
        ### Shift register for input symbols
        self.shifter_filt = np.full(NBAUD+1,0)
        ### Coeffs. of each phase
        self.poly_filter  = []
        zero = DeFixedInt(NTOT, NFRA, 'S', 'trunc', 'saturate')
        zero.value = 0.0
        for phase in range(OS):  # OS phases
            self.poly_filter.append([])
            for j in range(NBAUD+1):
                if( phase==0 ):
                    self.poly_filter[phase].append( self.coeffs[phase + j*OS] )
                else:
                    if(j<NBAUD):
                        self.poly_filter[phase].append( self.coeffs[phase + j*OS] )
                    else:
                        self.poly_filter[phase].append( zero )
        ### Partial products of the convolution
        partial_prod_aux  = np.zeros(NBAUD+1)
        self.partial_prod = arrayFixedInt(NTOT, NFRA, partial_prod_aux, 'S', 'trunc', 'saturate')
        ### Filter out
        self.filt_out       = DeFixedInt(NTOT+3, NFRA, 'S', 'trunc', 'saturate')
        self.filt_out.value = 0.0
        ### Saturate and truncation of filter out
        self.sym_out       = DeFixedInt(NTOT, NFRA, 'S', 'trunc', 'saturate')
        self.sym_out.value = 0.0
        ### Counter. Ensures that the phase 0 of the filter (coefficients)  
        ###aligns with the first symbol fed into the filter (loop i=1, or second clock cycle)
        self.phase_cntr = self.OS-1


    def convol(self, i, new_symb):
        # Select the right phase of the filter
        if( self.phase_cntr>=self.OS-1 ):
            self.phase_cntr = 0
        else:
            self.phase_cntr += 1
        
        # Shift and get a new symbol (like a FIFO) each OS cycles
        if( i%self.OS == 0 ):
            self.shifter_filt    = np.roll(self.shifter_filt,1)
            self.shifter_filt[0] = new_symb
            
        # Multiplication of filter coeffs. and symbols
        for j in range(len(self.shifter_filt)):
            if( self.shifter_filt[j]==-1.0 ):
                self.partial_prod[j].value = -1.0 * self.poly_filter[self.phase_cntr][j].fValue
            elif( self.shifter_filt[j]==0.0 ):
                self.partial_prod[j].value = 0.0 
            else:
                self.partial_prod[j].value =        self.poly_filter[self.phase_cntr][j].fValue
        
        # Sum all the partial products
        self.filt_out.value = 0.0
        for k in range(0,len(self.partial_prod),2):
            self.filt_out.value = self.filt_out.fValue + self.partial_prod[k].fValue + self.partial_prod[k+1].fValue
        
        # Saturate and truncate the final value
        self.sym_out.value = self.filt_out.fValue
        
        
        return self.sym_out.fValue


    def get_quantized_coeffs(self):
        out = np.zeros(len(self.coeffs))
        for i in range(len(out)):
            out[i] = self.coeffs[i].fValue
        
        return out

