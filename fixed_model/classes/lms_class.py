import numpy as np
from tool._fixedInt import *


class lms_class:

    def __init__(self, step, leak, NTAPS, NTOT_STEP, NFRA_STEP, NTOT_LEAK, NFRA_LEAK,
                 NTOT_TAP, NFRA_TAP, NTOT_SHI, NFRA_SHI, NTOT_ERR, NFRA_ERR):
        
        ### Variables for the step and leakage of the adaptive filter
        self.step       = DeFixedInt(NTOT_STEP, NFRA_STEP, 'S', 'trunc', 'saturate')
        self.step.value = step
        self.leak       = DeFixedInt(NTOT_LEAK, NFRA_LEAK, 'S', 'trunc', 'saturate')
        self.leak.value = leak
        
        ### Variables for the internal operation of the LMS algorithm
        ##I taps
        self.term1_I       = DeFixedInt(NTOT_TAP+(NTOT_STEP+NTOT_LEAK), NFRA_TAP+(NFRA_STEP+NFRA_LEAK),
                                       'S', 'trunc', 'saturate')
        self.term2_I = DeFixedInt(NTOT_STEP+(NTOT_ERR+NTOT_SHI+1), NFRA_STEP+(NFRA_ERR+NFRA_SHI),
                                   'S', 'trunc', 'saturate')
        self.term1_I.value = 0.0
        self.term2_I.value = 0.0
        # These options depend on higher-precision quantizations
        self.add_I       = DeFixedInt(NTOT_STEP+(NTOT_ERR+NTOT_SHI+1)+1, NFRA_STEP+(NFRA_ERR+NFRA_SHI),
                                   'S', 'trunc', 'saturate')
        #self.add_I       = DeFixedInt(NTOT_TAP+(NTOT_STEP+NTOT_LEAK)+1, NFRA_TAP+(NFRA_STEP+NFRA_LEAK),
        #                               'S', 'trunc', 'saturate')
        self.add_I.value = 0.0 
        
        ##Q taps
        self.term1_Q       = DeFixedInt(NTOT_TAP+(NTOT_STEP+NTOT_LEAK), NFRA_TAP+(NFRA_STEP+NFRA_LEAK),
                                       'S', 'trunc', 'saturate')
        self.term2_Q = DeFixedInt(NTOT_STEP+(NTOT_ERR+NTOT_SHI+1), NFRA_STEP+(NFRA_ERR+NFRA_SHI),
                                   'S', 'trunc', 'saturate')
        self.term1_Q.value = 0.0
        self.term2_Q.value = 0.0
        
        # Estas dos opciones dependen de las cuantizaciones de mayor bits
        self.add_Q       = DeFixedInt(NTOT_STEP+(NTOT_ERR+NTOT_SHI+1)+1, NFRA_STEP+(NFRA_ERR+NFRA_SHI),
                                   'S', 'trunc', 'saturate')
        #self.add_Q       = DeFixedInt(NTOT_TAP+(NTOT_STEP+NTOT_LEAK)+1, NFRA_TAP+(NFRA_STEP+NFRA_LEAK),
        #                               'S', 'trunc', 'saturate')
        self.add_Q.value = 0.0 
        
        ### Saturate and truncation of new taps
        self.tapI_quan       = DeFixedInt(NTOT_TAP, NFRA_TAP, 'S', 'trunc', 'saturate')
        self.tapQ_quan       = DeFixedInt(NTOT_TAP, NFRA_TAP, 'S', 'trunc', 'saturate')
        self.tapI_quan.value = 0.0
        self.tapQ_quan.value = 0.0
        ## HACER ARRAY
        fseI_coeff  = np.zeros(NTAPS); fseI_coeff[int(NTAPS/2)] = 1
        fseQ_coeff  = np.zeros(NTAPS); fseQ_coeff[int(NTAPS/2)] = 0
        self.tapsI  = arrayFixedInt(NTOT_TAP, NFRA_TAP, fseI_coeff, 'S', 'trunc', 'saturate')
        self.tapsQ  = arrayFixedInt(NTOT_TAP, NFRA_TAP, fseQ_coeff, 'S', 'trunc', 'saturate')

    
    #def update(self, errI, errQ, tapsI, shftrI, tapsQ, shftrQ):
    def update(self, errI, errQ, shftrI, shftrQ):
        
        # Equations for calculating new taps:
        #new_tapsI = tapsI*(1-step*leak) - step*(errI*shftrI + errQ*shftrQ)
        #new_tapsQ = tapsQ*(1-step*leak) + step*(errI*shftrQ - errQ*shftrI)
        
        new_tapsI = np.zeros(len(self.tapsI))
        new_tapsQ = np.zeros(len(self.tapsQ))
        for i in range(len(self.tapsI)):
            # Compute new I taps
            self.term1_I.value = self.tapsI[i].fValue * (1 - self.step.fValue*self.leak.fValue)
            self.term2_I.value = self.step.fValue * (errI*shftrI[i] + errQ*shftrQ[i])
            self.add_I.value   = self.term1_I.fValue - self.term2_I.fValue
            # Apply quantization to the new tap
            #self.tapI_quan.value = self.add_I.fValue
            self.tapsI[i].value = self.add_I.fValue
            
            new_tapsI[i] = self.tapsI[i].fValue
            
            # Compute new Q taps
            self.term1_Q.value = self.tapsQ[i].fValue * (1 - self.step.fValue*self.leak.fValue)
            self.term2_Q.value = self.step.fValue * (errI*shftrQ[i] - errQ*shftrI[i])
            self.add_Q.value   = self.term1_Q.fValue + self.term2_Q.fValue
            # Apply quantization to the new tap
            #self.tapQ_quan.value = self.add_Q.fValue
            self.tapsQ[i].value = self.add_Q.fValue
            
            new_tapsQ[i] = self.tapsQ[i].fValue
            
            
        return new_tapsI, new_tapsQ


