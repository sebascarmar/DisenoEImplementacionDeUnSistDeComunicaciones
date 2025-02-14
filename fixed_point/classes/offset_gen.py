import numpy as np

class offset_gen:
# Given a clock frequency of fs=100 MHz:
#           2^(step-1)*[fs/(2048*4)]
#   -for step=1   =>  f_offset = 12.2 kHz
#   -for step=2   =>  f_offset = 24.4 kHz
#   -for step=4   =>  f_offset = 48.8 kHz

    def __init__(self, f_offset):
        
        self.nsamp      = 2049
        wt              = np.linspace(0, np.pi/2, self.nsamp)  
        self.sin_val    = np.sin(wt)
        
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
        
        self.idx  = 4*(self.nsamp-self.step)


    def __sin(self):
        
        # Get the value from the table depending on the corresponding quarter 
        if(self.idx<=(self.nsamp-1)):
            sin_out = self.sin_val[self.idx]
        elif(self.idx<=2*(self.nsamp-1)):
            sin_out = self.sin_val[2*(self.nsamp-1)-self.idx]
        elif(self.idx<=3*(self.nsamp-1)):
            sin_out = -self.sin_val[self.idx-2*(self.nsamp-1)]
        else:
            sin_out = -self.sin_val[4*(self.nsamp-1)-self.idx]
        
        return sin_out


    def __cos(self):
        
        # Get the value from the table depending on the corresponding quarter 
        if(self.idx<=(self.nsamp-1)):
            cos_out = self.sin_val[(self.nsamp-1)-self.idx]
        elif(self.idx<=2*(self.nsamp-1)):
            cos_out = -self.sin_val[self.idx-(self.nsamp-1)]
        elif(self.idx<=3*(self.nsamp-1)):
            cos_out = -self.sin_val[3*(self.nsamp-1)-self.idx]
        else:
            cos_out = self.sin_val[self.idx-3*(self.nsamp-1)]
        
        return cos_out


    def get_offset(self, symbI_in, symbQ_in):
        
        # Increment the counter used to index into the sine values table
        self.idx = (self.idx+self.step) & (4*(self.nsamp-1)-1)
        
        # Apply rotation to the symbol, with real and imaginary parts handled separately
        symI_rot = symbI_in*self.__cos() - symbQ_in*self.__sin()
        symQ_rot = symbI_in*self.__sin() + symbQ_in*self.__cos()
        
        return symI_rot, symQ_rot


    def get_no_offset(self, symbI_in, symbQ_in):
        
        symI_norot = symbI_in*1 - symbQ_in*0
        symQ_norot = symbI_in*0 + symbQ_in*1
        
        return symI_norot, symQ_norot
