import numpy as np

class fse_class:

    def __init__(self, NTAPS):
        self.shftr_filt_I = np.zeros(NTAPS) 
        self.shftr_filt_Q = np.zeros(NTAPS)
        self.coeff_filt_I = np.zeros(NTAPS); self.coeff_filt_I[int(NTAPS/2)] = 1
        self.coeff_filt_Q = np.zeros(NTAPS)
        
        # It's going to be useful for truncation and saturation
        self.partial_prod = np.zeros(NTAPS)
        self.dot_prod_out = 0.0
        self.dotII = 0.0 
        self.dotQQ = 0.0 
        self.dotIQ = 0.0 
        self.dotQI = 0.0 
        self.symI_out = 0.0
        self.symQ_out = 0.0
        
        
        if( NTAPS%2 != 1 ):
            print("FSE_CLASS: the number of coeffs. is not odd")


    def dot_prod(self,buff1,buff2):
        # Multiplication of filter coeffs. and symbols
        for j in range(len(buff1)):
            self.partial_prod[j] = buff1[j]*buff2[j]
        
        # Reset the variable
        self.dot_prod_out = 0.0
        # Sum all the partial products
        for j in range(0,len(self.partial_prod)-1,2):
            self.dot_prod_out += self.partial_prod[j]+self.partial_prod[j+1]
        self.dot_prod_out += self.partial_prod[len(self.partial_prod)-1]
        
        return self.dot_prod_out


    def filt(self, new_symI, new_symQ):
        # Shift and get a new symbol (like a FIFO) each OS cycles
        self.shftr_filt_I[1:]= self.shftr_filt_I[:-1]
        self.shftr_filt_I[0] = new_symI
        self.shftr_filt_Q[1:]= self.shftr_filt_Q[:-1]
        self.shftr_filt_Q[0] = new_symQ
        
        self.dotII = self.dot_prod(self.shftr_filt_I, self.coeff_filt_I)
        self.dotQQ = self.dot_prod(self.shftr_filt_Q, self.coeff_filt_Q)
        self.dotIQ = self.dot_prod(self.shftr_filt_I, self.coeff_filt_Q)
        self.dotQI = self.dot_prod(self.shftr_filt_Q, self.coeff_filt_I)
        
        self.symI_out = self.dotII - self.dotQQ
        self.symQ_out = self.dotIQ + self.dotQI
        
        return self.symI_out, self.symQ_out


    def set_taps(self, new_taps_I, new_taps_Q):
        self.coeff_filt_I = new_taps_I
        self.coeff_filt_Q = new_taps_Q


    def get_coeffI(self):
        return self.coeff_filt_I


    def get_coeffQ(self):
        return self.coeff_filt_Q


    def get_buffI(self):
        return self.shftr_filt_I


    def get_buffQ(self):
        return self.shftr_filt_Q



## Example integration
#fse = FSE(num_taps=5, step_size=0.01)
#lms = LMS(step_size=0.001)
#
## Simulated input signals
#fractional_samples = [0.1, -0.2, 0.3, -0.1, 0.2, -0.4]
#desired_output = [1, 0, -1, 0]  # Symbol-rate desired outputs
#
#for i in range(len(desired_output)):
#    # FSE processes at rate 2
#    for _ in range(2):  # Two samples per symbol
#        sample = fractional_samples.pop(0)
#        output = fse.filter(sample)
#    
#    # Calculate error at rate 1
#    error = desired_output[i] - output
#    
#    # LMS updates coefficients at rate 1
#    new_taps = lms.update(fse.get_taps(), fse.buffer, error)
#    fse.set_taps(new_taps)
