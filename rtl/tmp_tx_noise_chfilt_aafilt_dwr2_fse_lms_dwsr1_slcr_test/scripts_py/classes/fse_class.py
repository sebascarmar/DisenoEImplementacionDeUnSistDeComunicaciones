import numpy as np
from tool._fixedInt import *


class fse_class:

    def __init__(self, NTAPS, NTOT_TAP, NFRA_TAP, NTOT_SHI, NFRA_SHI, NTOT_OUT, NFRA_OUT):
        
        # Shifters (I&Q) for incoming symbols
        shftrI = np.zeros(1+NTAPS) 
        shftrQ = np.zeros(1+NTAPS)
        self.shftrI = arrayFixedInt(NTOT_SHI, NFRA_SHI, shftrI, 'S', 'trunc', 'saturate')
        self.shftrQ = arrayFixedInt(NTOT_SHI, NFRA_SHI, shftrQ, 'S', 'trunc', 'saturate')
        
        # Registers (I&Q) for filter coefficients
        tapsI  = np.zeros(NTAPS); tapsI[int(NTAPS/2)] = 1.0
        tapsQ  = np.zeros(NTAPS)
        self.tapsI_retardo_inicial  = arrayFixedInt(NTOT_TAP, NFRA_TAP, tapsI, 'S', 'trunc', 'saturate')
        self.tapsQ_retardo_inicial  = arrayFixedInt(NTOT_TAP, NFRA_TAP, tapsQ, 'S', 'trunc', 'saturate')
        self.tapsI  = arrayFixedInt(NTOT_TAP, NFRA_TAP, tapsI, 'S', 'trunc', 'saturate')
        self.tapsQ  = arrayFixedInt(NTOT_TAP, NFRA_TAP, tapsQ, 'S', 'trunc', 'saturate')
        
        ### Partial convolution products
        partial_prod       = np.zeros(NTAPS)
        self.partial_prod  = arrayFixedInt(NTOT_TAP+NTOT_SHI, NFRA_TAP+NFRA_SHI, partial_prod, 'S', 'trunc', 'saturate')
        
        ### Addition of all partial products: +6 required due to 33 taps -> ceil(log2(taps))
        self.dot_prod_out       = DeFixedInt((NTOT_TAP+NTOT_SHI)+6, NFRA_TAP+NFRA_SHI, 'S', 'trunc', 'saturate')
        self.dot_prod_out.value = 0.0
        
        ### Filter output  -> ceil(log2(taps))+1
        self.filtI_out       = DeFixedInt((NTOT_TAP+NTOT_SHI)+7, NFRA_TAP+NFRA_SHI, 'S', 'trunc', 'saturate') 
        self.filtQ_out       = DeFixedInt((NTOT_TAP+NTOT_SHI)+7, NFRA_TAP+NFRA_SHI, 'S', 'trunc', 'saturate')
        self.filtI_out.value = 0.0
        self.filtQ_out.value = 0.0
     
        ### Saturate and truncation of the filter output
        self.symI_out       = DeFixedInt(NTOT_OUT, NFRA_OUT, 'S', 'trunc', 'saturate')
        self.symQ_out       = DeFixedInt(NTOT_OUT, NFRA_OUT, 'S', 'trunc', 'saturate')
        self.symI_out.value = 0.0
        self.symQ_out.value = 0.0
        
        if( NTAPS%2 != 1 ):
            print("FSE_CLASS: the number of coeffs. is not odd")


    def dot_prod(self,buff1,buff2):
        # Multiply filter coefficients and symbols
        for j in range(len(buff1)):
            self.partial_prod[j].value = buff1[j].fValue * buff2[j].fValue
        
        # Accumulate all the partial products
        self.dot_prod_out.value = 0.0
        for k in range(len(self.partial_prod)):
            self.dot_prod_out.value = self.dot_prod_out.fValue + self.partial_prod[k].fValue
        
        return self.dot_prod_out.fValue


    def filt(self, new_symI, new_symQ):
        
        # Shift and insert a new symbol (like a FIFO) every OS_DSP cycles
        self.shftrI          = np.roll(self.shftrI,1)
        self.shftrI[0].value = new_symI
        self.shftrQ          = np.roll(self.shftrQ,1)
        self.shftrQ[0].value = new_symQ
        
        # Compute dot products between shifters and taps for both lanes
        dotII = self.dot_prod(self.shftrI[1:], self.tapsI)
        dotQQ = self.dot_prod(self.shftrQ[1:], self.tapsQ)
        dotIQ = self.dot_prod(self.shftrI[1:], self.tapsQ)
        dotQI = self.dot_prod(self.shftrQ[1:], self.tapsI)
        
        self.filtI_out.value = dotII - dotQQ
        self.filtQ_out.value = dotIQ + dotQI
        
        # Saturate and truncate the final result
        self.symI_out.value = self.filtI_out.fValue
        self.symQ_out.value = self.filtQ_out.fValue
        
        
        return self.symI_out.fValue, self.symQ_out.fValue


    def set_taps(self, new_taps_I, new_taps_Q):
        for i in range(len(self.tapsI)):
            self.tapsI[i].value = self.tapsI_retardo_inicial[i].fValue 
            self.tapsQ[i].value = self.tapsQ_retardo_inicial[i].fValue 
            self.tapsI_retardo_inicial[i].value = new_taps_I[i]
            self.tapsQ_retardo_inicial[i].value = new_taps_Q[i]


    def get_coeffI(self):
        out = np.zeros(len(self.tapsI))
        for i in range(len(out)):
            out[i] = self.tapsI[i].fValue
        
        return out


    def get_coeffQ(self):
        out = np.zeros(len(self.tapsQ))
        for i in range(len(out)):
            out[i] = self.tapsQ[i].fValue
        
        return out


    def get_buffI(self):
        out = np.zeros(len(self.shftrI[1:]))
        for i in range(len(out)):
            out[i] = self.shftrI[i+1].fValue
        
        return out


    def get_buffQ(self):
        out = np.zeros(len(self.shftrQ[1:]))
        for i in range(len(out)):
            out[i] = self.shftrQ[i+1].fValue
        
        return out

