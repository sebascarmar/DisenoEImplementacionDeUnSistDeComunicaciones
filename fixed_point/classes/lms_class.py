import numpy as np
from tool._fixedInt import *


class lms_class:

    def __init__(self, step, leak, NTot, NFra):
        
        ### Variables for the step and leakage of the adaptive filter
        self.step       = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.step.value = step
        self.leak       = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.leak.value = leak
        
        ### Variables for the internal operation of the LMS algorithm
        self.k       = DeFixedInt(2*NTot+1, 2*NFra, 'S', 'trunc', 'saturate')
        self.k.value = 1 - self.step.fValue*self.leak.fValue  
        
        ##I taps
        self.ItapXk       = DeFixedInt(3*NTot+1, 3*NFra, 'S', 'trunc', 'saturate')
        self.ItapXk.value = 0.0
        
        self.IerXIsh  = DeFixedInt(2*NTot, 2*NFra, 'S', 'trunc', 'saturate')
        self.QerXQsh  = DeFixedInt(2*NTot, 2*NFra, 'S', 'trunc', 'saturate')
        self.add1     = DeFixedInt(2*NTot+1, 2*NFra, 'S', 'trunc', 'saturate')
        self.stpXadd1 = DeFixedInt(3*NTot+1, 3*NFra, 'S', 'trunc', 'saturate')
        self.IerXIsh.value  = 0.0
        self.QerXQsh.value  = 0.0
        self.add1.value     = 0.0
        self.stpXadd1.value = 0.0
        
        self.add2       = DeFixedInt(3*NTot+2, 3*NFra, 'S', 'trunc', 'saturate')
        self.add2.value = 0.0 
        
        ##Q taps
        self.QtapXk       = DeFixedInt(3*NTot+1, 3*NFra, 'S', 'trunc', 'saturate')
        self.QtapXk.value = 0.0
        
        self.IerXQsh  = DeFixedInt(2*NTot, 2*NFra, 'S', 'trunc', 'saturate')
        self.QerXIsh  = DeFixedInt(2*NTot, 2*NFra, 'S', 'trunc', 'saturate')
        self.add3     = DeFixedInt(2*NTot+1, 2*NFra, 'S', 'trunc', 'saturate')
        self.stpXadd3 = DeFixedInt(3*NTot+1, 3*NFra, 'S', 'trunc', 'saturate')
        self.IerXQsh.value  = 0.0
        self.QerXIsh.value  = 0.0
        self.add3.value     = 0.0
        self.stpXadd3.value = 0.0
        
        self.add4       = DeFixedInt(3*NTot+2, 3*NFra, 'S', 'trunc', 'saturate')
        self.add4.value = 0.0 
        
        ### Saturate and truncation of new taps
        self.tapI_quan       = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.tapQ_quan       = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.tapI_quan.value = 0.0
        self.tapQ_quan.value = 0.0

    
    def update(self, errI, errQ, tapsI, shftrI, tapsQ, shftrQ):
        # Incoming taps are in a S(23,20) format
        # We assume the coefficient errors are in S(23,20) format [could change]
        
        # Equations for calculating new taps:
        #new_tapsI = tapsI*(1-step*leak) - step*(errI*shftrI + errQ*shftrQ)
        #new_tapsQ = tapsQ*(1-step*leak) + step*(errI*shftrQ - errQ*shftrI)
        
        new_tapsI = np.zeros(len(tapsI))
        new_tapsQ = np.zeros(len(tapsQ))
        for i in range(len(tapsI)):
            # Compute new I taps
            self.ItapXk.value   = tapsI[i] * self.k.fValue
            self.IerXIsh.value  = errI * shftrI[i]
            self.QerXQsh.value  = errQ * shftrQ[i]
            self.add1.value     = self.IerXIsh.fValue + self.QerXQsh.fValue
            self.stpXadd1.value = self.step.fValue * self.add1.fValue
            self.add2.value     = self.ItapXk.fValue - self.stpXadd1.fValue
            # Apply quantization to the new tap
            self.tapI_quan.value = self.add2.fValue
            
            new_tapsI[i] = self.tapI_quan.fValue
            
            # Compute new Q taps
            self.QtapXk.value   = tapsQ[i] * self.k.fValue
            self.IerXQsh.value  = errI * shftrQ[i]
            self.QerXIsh.value  = errQ * shftrI[i]
            self.add3.value     = self.IerXQsh.fValue - self.QerXIsh.fValue
            self.stpXadd3.value = self.step.fValue * self.add3.fValue
            self.add4.value     = self.QtapXk.fValue + self.stpXadd3.fValue
            # Apply quantization to the new tap
            self.tapQ_quan.value = self.add4.fValue
            
            new_tapsQ[i] = self.tapQ_quan.fValue
            
            
        return new_tapsI, new_tapsQ

