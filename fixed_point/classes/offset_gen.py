import numpy as np

class offset_gen:

    def __init__(self, fs, f_offset):
        if( f_offset > 0.0 ):
            time_vec = np.arange(0, 1/f_offset, 1/fs)
            titas    = np.array(2*np.pi*f_offset * time_vec, dtype=np.float32)
            
            self.sin = np.sin(titas)
            self.cos = np.cos(titas)
            self.idx = len(self.sin)-1
         
            if (fs%f_offset != 0) or ((fs/f_offset)%2 != 0):
                print("OFFSET_GEN CLASS: f_offset value is not an even multiple of fs")
         
        elif( f_offset == 0.0 ):
            self.sin = np.full(1000, 1.0)
            self.cos = np.full(1000, 0.0)
            self.idx = len(self.sin)-1
            
        else:  # f_offset<0
            print("OFFSET_GEN CLASS: f_offset value is negative")
            exit(1)

    def get_offset(self, symbI_in, symbQ_in):
        
        if( self.idx==(len(self.sin)-1) ):
            self.idx = 0
        else:
            self.idx += 1
        
        symI_rot = symbI_in*self.cos[self.idx] - symbQ_in*self.sin[self.idx]
        symQ_rot = symbI_in*self.sin[self.idx] + symbQ_in*self.cos[self.idx]
        
        return symI_rot, symQ_rot


    def get_no_offset(self, symbI_in, symbQ_in):
        
        symI_rot = symbI_in*self.cos[0] - symbQ_in*self.sin[0]
        symQ_rot = symbI_in*self.sin[0] + symbQ_in*self.cos[0]
        
        return symI_rot, symQ_rot
