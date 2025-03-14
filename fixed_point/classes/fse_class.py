import numpy as np
from tool._fixedInt import *


class fse_class:

    def __init__(self, NTAPS, NTot, NFra):
        NTot_shifter = 8
        NFra_shifter = 7
        NTot_out = 12 #OK
        NFra_out = 9#OK
        
        # Shifters (I&Q) for incoming symbols
        shftrI = np.zeros(NTAPS) 
        shftrQ = np.zeros(NTAPS)
        self.shftrI = arrayFixedInt(NTot_shifter, NFra_shifter, shftrI, 'S', 'trunc', 'saturate')
        self.shftrQ = arrayFixedInt(NTot_shifter, NFra_shifter, shftrQ, 'S', 'trunc', 'saturate')
        
        # Registers (I&Q) for filter coefficients
        tapsI  = np.zeros(NTAPS); tapsI[int(NTAPS/2)] = 1.0
        tapsQ  = np.zeros(NTAPS)
        self.tapsI  = arrayFixedInt(NTot, NFra, tapsI, 'S', 'trunc', 'saturate')
        self.tapsQ  = arrayFixedInt(NTot, NFra, tapsQ, 'S', 'trunc', 'saturate')
        
        ### Partial convolution products
        partial_prod       = np.zeros(NTAPS)
        self.partial_prod  = arrayFixedInt(NTot+NTot_shifter, NFra+NFra_shifter, partial_prod, 'S', 'trunc', 'saturate')
        
        ### Addition of all partial products: we need +6 becasue of 33 partial products
        self.dot_prod_out       = DeFixedInt((NTot+NTot_shifter)+6, NFra+NFra_shifter, 'S', 'trunc', 'saturate')
        self.dot_prod_out.value = 0.0
        
        ### Filter output
        self.filtI_out       = DeFixedInt((NTot+NTot_shifter)+7, NFra+NFra_shifter, 'S', 'trunc', 'saturate') 
        self.filtQ_out       = DeFixedInt((NTot+NTot_shifter)+7, NFra+NFra_shifter, 'S', 'trunc', 'saturate')
        self.filtI_out.value = 0.0
        self.filtQ_out.value = 0.0
     
        ### Saturate and truncation of the filter output
        self.symI_out       = DeFixedInt(NTot_out, NFra_out, 'S', 'trunc', 'saturate')
        self.symQ_out       = DeFixedInt(NTot_out, NFra_out, 'S', 'trunc', 'saturate')
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
        # First, we need to align the input symbols, because they are in S(8,7) format.
        #We avoid doing it here to improve simulation performance, taking into
        #account that the input symbol is already quatized to S(8,7).
        
        # Shift and insert a new symbol (like a FIFO) every OS cycles
        self.shftrI          = np.roll(self.shftrI,1)
        self.shftrI[0].value = new_symI
        self.shftrQ          = np.roll(self.shftrQ,1)
        self.shftrQ[0].value = new_symQ
        
        # Compute dot products between shifters and taps for both lanes
        dotII = self.dot_prod(self.shftrI, self.tapsI)
        dotQQ = self.dot_prod(self.shftrQ, self.tapsQ)
        dotIQ = self.dot_prod(self.shftrI, self.tapsQ)
        dotQI = self.dot_prod(self.shftrQ, self.tapsI)
        
        self.filtI_out.value = dotII - dotQQ
        self.filtQ_out.value = dotIQ + dotQI
        
        # Saturate and truncate the final result
        self.symI_out.value = self.filtI_out.fValue
        self.symQ_out.value = self.filtQ_out.fValue
        
        
        return self.symI_out.fValue, self.symQ_out.fValue


    def set_taps(self, new_taps_I, new_taps_Q):
        for i in range(len(self.tapsI)):
            self.tapsI[i].value = new_taps_I[i]
            self.tapsQ[i].value = new_taps_Q[i]


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
        out = np.zeros(len(self.shftrI))
        for i in range(len(out)):
            out[i] = self.shftrI[i].fValue
        
        return out


    def get_buffQ(self):
        out = np.zeros(len(self.shftrQ))
        for i in range(len(out)):
            out[i] = self.shftrQ[i].fValue
        
        return out



# import numpy as np

# class fse_class:

#     def __init__(self, NTAPS):
#         self.shftr_filt_I = np.zeros(NTAPS) 
#         self.shftr_filt_Q = np.zeros(NTAPS)
#         self.coeff_filt_I = np.zeros(NTAPS); self.coeff_filt_I[int(NTAPS/2)] = 1
#         self.coeff_filt_Q = np.zeros(NTAPS)
        
#         # It's going to be useful for truncation and saturation
#         self.partial_prod = np.zeros(NTAPS)
#         self.dot_prod_out = 0.0
#         self.dotII = 0.0 
#         self.dotQQ = 0.0 
#         self.dotIQ = 0.0 
#         self.dotQI = 0.0 
#         self.symI_out = 0.0
#         self.symQ_out = 0.0
        
        
#         if( NTAPS%2 != 1 ):
#             print("FSE_CLASS: the number of coeffs. is not odd")


#     def dot_prod(self,buff1,buff2):
#         # Multiplication of filter coeffs. and symbols
#         for j in range(len(buff1)):
#             self.partial_prod[j] = buff1[j]*buff2[j]
        
#         # Reset the variable
#         self.dot_prod_out = 0.0
#         # Sum all the partial products
#         for j in range(0,len(self.partial_prod)-1,2):
#             self.dot_prod_out += self.partial_prod[j]+self.partial_prod[j+1]
#         self.dot_prod_out += self.partial_prod[len(self.partial_prod)-1]
        
#         return self.dot_prod_out


#     def filt(self, new_symI, new_symQ):
#         # Shift and get a new symbol (like a FIFO) each OS cycles
#         self.shftr_filt_I[1:]= self.shftr_filt_I[:-1]
#         self.shftr_filt_I[0] = new_symI
#         self.shftr_filt_Q[1:]= self.shftr_filt_Q[:-1]
#         self.shftr_filt_Q[0] = new_symQ
        
#         self.dotII = self.dot_prod(self.shftr_filt_I, self.coeff_filt_I)
#         self.dotQQ = self.dot_prod(self.shftr_filt_Q, self.coeff_filt_Q)
#         self.dotIQ = self.dot_prod(self.shftr_filt_I, self.coeff_filt_Q)
#         self.dotQI = self.dot_prod(self.shftr_filt_Q, self.coeff_filt_I)
        
#         self.symI_out = self.dotII - self.dotQQ
#         self.symQ_out = self.dotIQ + self.dotQI
        
#         return self.symI_out, self.symQ_out


#     def set_taps(self, new_taps_I, new_taps_Q):
#         self.coeff_filt_I = new_taps_I
#         self.coeff_filt_Q = new_taps_Q


#     def get_coeffI(self):
#         return self.coeff_filt_I


#     def get_coeffQ(self):
#         return self.coeff_filt_Q


#     def get_buffI(self):
#         return self.shftr_filt_I


#     def get_buffQ(self):
#         return self.shftr_filt_Q



# ## Example integration
# #fse = FSE(num_taps=5, step_size=0.01)
# #lms = LMS(step_size=0.001)
# #
# ## Simulated input signals
# #fractional_samples = [0.1, -0.2, 0.3, -0.1, 0.2, -0.4]
# #desired_output = [1, 0, -1, 0]  # Symbol-rate desired outputs
# #
# #for i in range(len(desired_output)):
# #    # FSE processes at rate 2
# #    for _ in range(2):  # Two samples per symbol
# #        sample = fractional_samples.pop(0)
# #        output = fse.filter(sample)
# #    
# #    # Calculate error at rate 1
# #    error = desired_output[i] - output
# #    
# #    # LMS updates coefficients at rate 1
# #    new_taps = lms.update(fse.get_taps(), fse.buffer, error)
# #    fse.set_taps(new_taps)
