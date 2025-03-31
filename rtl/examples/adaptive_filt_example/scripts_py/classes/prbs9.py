import numpy as np

class prbs9:

    def __init__(self, seed):
        
        if(seed.bit_length()>9):
            print("PRBS9 CLASS: the lenght of the seed exceeds 9 bits.")
            exit(1)
        if(seed==0):
            print("PRBS9 CLASS: the seed cannot be zero.")
            exit(1)
        
        self.reg = np.zeros(9, dtype=int)
        for i in range(9):
            if( (seed>>i)&0b1 ):
                self.reg[i]=1
            else:
                self.reg[i]=0

    def get_new_bit(self):
        new_out = self.reg[8] 
        # Calculate the new input bit for the register
        new_in  = self.reg[4]^self.reg[8]
        # Shift the register and storage the new bit in the LSB position
        self.reg = np.roll(self.reg,1)
        self.reg[0] = new_in
        
        return new_out
