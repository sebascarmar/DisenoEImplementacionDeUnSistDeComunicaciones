import numpy as np
from tool._fixedInt import *


class offset_gen:
# Given a clock frequency of fs=100 MHz:
#           2^(step-1)*[fs/(2048*4)]
#   -for step=1   =>  f_offset = 12.2 kHz
#   -for step=2   =>  f_offset = 24.4 kHz
#   -for step=4   =>  f_offset = 48.8 kHz

    def __init__(self, f_offset, NTot, NFra):
        # Create the quarter-sine table and quantize the values
        self.nsamp   = 2049
        wt           = np.linspace(0, np.pi/2, self.nsamp)  
        sin_val      = np.sin(wt)
        self.sin_val = arrayFixedInt(NTot, NFra, sin_val, 'S', 'trunc', 'saturate')
        
        # Set the step size to access the table
        if( f_offset == 0 ):
            self.step = 0
        elif( f_offset == 12e3 ):
            self.step = 1
        elif( f_offset == 24e3 ):
            self.step = 2
        elif( f_offset == 48e3 ):
            self.step = 4
        else:
            print("OFFSET_GEN CLASS: invalid valur of f_offset")
            exit(1)
        
        # Variables to quantize the input values
        self.symI_quant = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.symQ_quant = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.symI_quant.value = 0.0
        self.symQ_quant.value = 0.0
        
        # Set the counter with 4*(nsamp-1) combinations (based on the table samples)
        quarter_cntr_bits = np.log2(self.nsamp-1)
        self.idx          = DeFixedInt(2+int(quarter_cntr_bits), 0, 'U', 'trunc', 'wrap')
        self.idx.value    = 4*(self.nsamp-self.step)-1
        
        # Intermediate variables quantized for symbol rotation:
        #multiplication
        self.prodA = DeFixedInt(2*NTot, 2*NFra, 'S', 'trunc', 'saturate')
        self.prodB = DeFixedInt(2*NTot, 2*NFra, 'S', 'trunc', 'saturate')
        self.prodC = DeFixedInt(2*NTot, 2*NFra, 'S', 'trunc', 'saturate')
        self.prodD = DeFixedInt(2*NTot, 2*NFra, 'S', 'trunc', 'saturate')
        self.prodA.value = 0.0
        self.prodB.value = 0.0
        self.prodC.value = 0.0
        self.prodD.value = 0.0
        #addtion
        self.symI_rot= DeFixedInt(2*NTot+1, 2*NFra, 'S', 'trunc', 'saturate')
        self.symQ_rot= DeFixedInt(2*NTot+1, 2*NFra, 'S', 'trunc', 'saturate')
        self.symI_rot.value = 0.0
        self.symQ_rot.value = 0.0
        
        # Variables to quantize the output values
        self.symI_rot_quan       = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.symI_rot_quan.value = 0.0
        self.symQ_rot_quan       = DeFixedInt(NTot, NFra, 'S', 'trunc', 'saturate')
        self.symQ_rot_quan.value = 0.0
        
        


    def __sin(self):
        idx   = self.idx.intvalue
        nsamp = self.nsamp
        
        # Get the value from the table depending on the corresponding quarter 
        if( idx<=(nsamp-1) ):
            sin_out =  self.sin_val[            idx].fValue
        elif( idx<=2*(nsamp-1) ):
            sin_out =  self.sin_val[2*(nsamp-1)-idx].fValue
        elif( idx<=3*(nsamp-1) ):
            sin_out = -self.sin_val[idx-2*(nsamp-1)].fValue
        else:
            sin_out = -self.sin_val[4*(nsamp-1)-idx].fValue
        
        return sin_out


    def __cos(self):
        idx   = self.idx.intvalue
        nsamp = self.nsamp
        
        # Get the value from the table depending on the corresponding quarter 
        if( idx<=(nsamp-1) ):
            cos_out =  self.sin_val[  (nsamp-1)-idx].fValue
        elif( idx<=2*(nsamp-1) ):
            cos_out = -self.sin_val[  idx-(nsamp-1)].fValue
        elif( idx<=3*(nsamp-1) ):
            cos_out = -self.sin_val[3*(nsamp-1)-idx].fValue
        else:
            cos_out =  self.sin_val[idx-3*(nsamp-1)].fValue
        
        return cos_out


    def get_offset(self, symbI_in, symbQ_in):
        # Apply quantization 
        self.symI_quant.value = symbI_in
        self.symQ_quant.value = symbQ_in
        
        # Increment the counter used to index into the sine values table.
        #Overflow is used to stay within its bit-limited range.
        self.idx.value = self.idx.intvalue + 1
        
        # Apply rotation to the symbol, with real and imaginary parts handled separately
        #Real part: I_rot = I*cos()-Q*sin()
        self.prodA.value = self.symI_quant.fValue * self.__cos() 
        self.prodB.value = self.symQ_quant.fValue * self.__sin()
        self.symI_rot.value = self.prodA.fValue - self.prodB.fValue
        #Imaginary part: Q_rot = I*sin()+Q*cos()
        self.prodC.value = self.symI_quant.fValue * self.__sin() 
        self.prodD.value = self.symQ_quant.fValue * self.__cos()
        self.symQ_rot.value = self.prodC.fValue + self.prodD.fValue
        # Perform quantization 
        self.symI_rot_quan.value = self.symI_rot.fValue
        self.symQ_rot_quan.value = self.symQ_rot.fValue
        
     
        return self.symI_rot_quan.fValue, self.symQ_rot_quan.fValue


    def get_no_offset(self, symbI_in, symbQ_in):
        # Apply quantization 
        self.symI_quant.value = symbI_in
        self.symQ_quant.value = symbQ_in
        
        return self.symI_quant.fValue, self.symQ_quant.fValue

