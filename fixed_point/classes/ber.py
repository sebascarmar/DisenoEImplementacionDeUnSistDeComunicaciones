import numpy as np

# Add class/ absolute path to sys.path to allow module imports
import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from classes.prbs9 import prbs9



### It's used for rotate the input constelation post slicer
def inv(bit):
    # Invert the input bit
    return 0 if (bit==1) else 1


class ber:

    def __init__(self, SEED_I, SEED_Q, START_SYN, START_CNT):
        
        #### Flags
        self.START_SYN = START_SYN
        self.START_CNT = START_CNT
        self.COMB_PRBS = 511
        #### Bits generation
        self.prbs9I_rx = prbs9(SEED_I) # Seed: 0x1AA
        self.prbs9Q_rx = prbs9(SEED_Q) # Seed: 0x1FE
        # PRBS regster and data
        self.shftr_berI = np.zeros(self.COMB_PRBS, dtype=int)
        self.shftr_berQ = np.zeros(self.COMB_PRBS, dtype=int)
        # Synchro variables
        self.min_error   = len(self.shftr_berQ)
        self.err_sym_0   = 0
        self.err_sym_90  = 0
        self.err_sym_180 = 0
        self.err_sym_270 = 0
        self.BER_IDX       = 0
        self.latency       = 0
        self.rot_ang_detec = 0
        #### Counting errors after synchronization
        self.bit_err_I = 0
        self.bit_tot_I = 0
        self.bit_err_Q = 0
        self.bit_tot_Q = 0


    def reset_values(self):
        # PRBS regster and data
        self.shftr_berI = self.shftr_berI
        self.shftr_berQ = self.shftr_berQ
        # Synchro variables
        self.min_error   = len(self.shftr_berQ)
        self.err_sym_0   = 0
        self.err_sym_90  = 0
        self.err_sym_180 = 0
        self.err_sym_270 = 0
        self.BER_IDX       = 0
        self.latency       = 0
        self.rot_ang_detec = 0
        #### Counting errors after synchronization
        self.bit_err_I = 0
        self.bit_tot_I = 0
        self.bit_err_Q = 0
        self.bit_tot_Q = 0


    def synchronize(self, cyc_cnt, rx_bitI_demap, rx_bitQ_demap):
        
        # Store data for the minimum case and reset accumulators for each sequence of the PRBS9
        if( cyc_cnt%self.COMB_PRBS == 0 and cyc_cnt>self.START_SYN ):
            if( self.err_sym_0<self.min_error   and self.err_sym_0<self.err_sym_90 and
                self.err_sym_0<self.err_sym_180 and self.err_sym_0<self.err_sym_270):
                self.min_error     = self.err_sym_0
                self.err_sym_0     = 0
                self.latency       = self.BER_IDX
                self.rot_ang_detec = 0
            elif( self.err_sym_90<self.min_error and self.err_sym_90<self.err_sym_180 and
                  self.err_sym_90<self.err_sym_270 ):
                self.min_error     = self.err_sym_90
                self.err_sym_90    = 0
                self.latency       = self.BER_IDX
                self.rot_ang_detec = 90
            elif( self.err_sym_180<self.min_error and self.err_sym_180<self.err_sym_270 ):
                self.min_error     = self.err_sym_180
                self.err_sym_180   = 0
                self.latency       = self.BER_IDX
                self.rot_ang_detec = 180
            elif( self.err_sym_270<self.min_error ):
                self.min_error     = self.err_sym_270
                self.err_sym_270   = 0
                self.latency       = self.BER_IDX
                self.rot_ang_detec = 270
            else:
                self.err_sym_0   = 0
                self.err_sym_90  = 0
                self.err_sym_180 = 0
                self.err_sym_270 = 0
                self.min_error     = self.min_error    
                self.latency       = self.latency  
                self.rot_ang_detec = self.rot_ang_detec
            
            # Update the pointer to the BER shifter 
            self.BER_IDX += 1
         
        # Keep the values during each sequence of the PRBS9
        else:
            self.err_sym_0   = self.err_sym_0  
            self.err_sym_90  = self.err_sym_90 
            self.err_sym_180 = self.err_sym_180
            self.err_sym_270 = self.err_sym_270
            self.min_error     = self.min_error    
            self.latency       = self.latency  
            self.rot_ang_detec = self.rot_ang_detec
            self.BER_IDX = self.BER_IDX
        
        # Shift and update register used for PRBS 
        self.shftr_berI = np.roll(self.shftr_berI,1)
        self.shftr_berQ = np.roll(self.shftr_berQ,1)
        self.shftr_berI[0] = self.prbs9I_rx.get_new_bit()
        self.shftr_berQ[0] = self.prbs9Q_rx.get_new_bit()
        
        # Compare PRBS with received data rotated by 0º (BER_IDX refers to a fixed position)
        self.err_sym_0   += (self.shftr_berI[self.BER_IDX]^rx_bitI_demap) | (self.shftr_berQ[self.BER_IDX]^rx_bitQ_demap)
        # Compare PRBS with received data rotated by 90º (BER_IDX refers to a fixed position)
        self.err_sym_90  += (self.shftr_berI[self.BER_IDX]^inv(rx_bitQ_demap)) | (self.shftr_berQ[self.BER_IDX]^rx_bitI_demap)
        # Compare PRBS with received data rotated by 180º (BER_IDX refers to a fixed position)
        self.err_sym_180 += (self.shftr_berI[self.BER_IDX]^inv(rx_bitI_demap)) | (self.shftr_berQ[self.BER_IDX]^inv(rx_bitQ_demap))
        # Compare PRBS with received data rotated by 270º (BER_IDX refers to a fixed position)
        self.err_sym_270 += (self.shftr_berI[self.BER_IDX]^rx_bitQ_demap) | (self.shftr_berQ[self.BER_IDX]^inv(rx_bitI_demap))
        
        
        return self.latency, self.rot_ang_detec


    def count_errors(self, rx_bitI_demap, rx_bitQ_demap):
        # Apply the detected rotation
        if( self.rot_ang_detec == 0 ):
            rx_bitI_rot =     rx_bitI_demap
            rx_bitQ_rot =     rx_bitQ_demap
        elif( self.rot_ang_detec == 90 ):
            rx_bitI_rot = inv(rx_bitQ_demap)
            rx_bitQ_rot =     rx_bitI_demap
        elif( self.rot_ang_detec == 180 ):
            rx_bitI_rot = inv(rx_bitI_demap)
            rx_bitQ_rot = inv(rx_bitQ_demap)
        else: # rot_ang_detec=270
            rx_bitI_rot =     rx_bitQ_demap
            rx_bitQ_rot = inv(rx_bitI_demap)
        
        # Shift and update register used for PRBS 
        self.shftr_berI = np.roll(self.shftr_berI,1)
        self.shftr_berQ = np.roll(self.shftr_berQ,1)
        self.shftr_berI[0] = self.prbs9I_rx.get_new_bit()
        self.shftr_berQ[0] = self.prbs9Q_rx.get_new_bit()
        
        # Lane I
        self.bit_err_I += self.shftr_berI[self.latency] ^ rx_bitI_rot
        self.bit_tot_I += 1
        
        # Lane Q
        self.bit_err_Q += self.shftr_berQ[self.latency] ^ rx_bitQ_rot
        self.bit_tot_Q += 1
        
        return self.bit_err_I/self.bit_tot_I, self.bit_err_Q/self.bit_tot_Q


