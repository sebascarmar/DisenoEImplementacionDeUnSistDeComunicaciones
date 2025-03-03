import numpy as np
from tool._fixedInt import *


class fcr_class:

    def __init__(self, Kp, Ki, NSYM_FCR_ON):
        NTot = 8
        NFra = 7

        self.NSYM_FCR_ON = NSYM_FCR_ON
        
        self.Kp       = DeFixedInt(11, 10, 'S', 'trunc', 'saturate')
        self.Kp.value = Kp
        self.Ki       = DeFixedInt(21, 20, 'S', 'trunc', 'saturate')
        self.Ki.value = Ki
        
        self.angle_err       = DeFixedInt(8, 7, 'S', 'trunc', 'saturate') # Puede ser S(7,6)
        self.angle_err.value = 0.0
        self.proport_err       = DeFixedInt(13, 12, 'S', 'trunc', 'saturate') #14ok; 13ok ; 12ok ; 11no ; 10no
        self.proport_err.value = 0.0
        self.integral_err       = DeFixedInt(27, 26, 'S', 'trunc', 'saturate') #28ok ; 27ok ; 26ok ; 25no
        self.integral_err.value = 0.0
        self.nco_out       = DeFixedInt(29, 26, 'U', 'trunc', 'wrap')  # Wrap no es usado, pero es menos hardware que sat. 25?
        self.nco_out.value = 0.0
        
        # Va a depender de la cuantización del error en LMS/FSE
        self.symI_out       = DeFixedInt(32, 29, 'S', 'trunc', 'saturate')
        self.symQ_out       = DeFixedInt(32, 29, 'S', 'trunc', 'saturate')
        self.symI_out.value = 0.0
        self.symQ_out.value = 0.0
        # Va a depender de la cuantización del error en LMS/FSE
        self.errI_unrot       = DeFixedInt(32, 29, 'S', 'trunc', 'saturate')
        self.errQ_unrot       = DeFixedInt(32, 29, 'S', 'trunc', 'saturate')
        self.errI_unrot.value = 0.0
        self.errQ_unrot.value = 0.0
        
        # Generate 2048 evenly spaced values from 0 to 60 and compute their arctan
        self.range_atan = 60
        self.nsamp_atan = 2048
        x_values        = np.linspace(0, self.range_atan-1, self.nsamp_atan)
        arctan          = np.arctan(x_values)
        self.arctan     = arrayFixedInt(NTot, NFra-1, arctan, 'S', 'trunc', 'saturate')

        self.idx_atg       = DeFixedInt(11+1, 0, 'U', 'round', 'saturate')
        self.idx_atg.value = 0.0
        self.cte_atg       = DeFixedInt(6, 0, 'U', 'trunc', 'saturate') # Chequear con prueba larga
        self.cte_atg.value = (self.nsamp_atan-1) / (self.range_atan-1)

        
        # Generate a quarter-cycle sine table with 1025 samples points
        self.nsamp_sin = 1025
        wt             = np.linspace(0, np.pi/2, self.nsamp_sin)
        sin_val        = np.sin(wt)
        self.sin_val   = arrayFixedInt(NTot, NFra, sin_val, 'S', 'trunc', 'saturate')

        self.idx_SyC       = DeFixedInt(12, 0, 'U', 'round', 'wrap')
        self.idx_SyC.value = 0.0
        self.cte_SyC       = DeFixedInt(12, 2, 'U', 'trunc', 'saturate')
        self.cte_SyC.value = (self.nsamp_sin-1)/(np.pi/2)


    def __arctg(self, I, Q):
        # Calculate the ratio of Q to I
        if(I!=0):
            QoverI = Q/I                # Normal case
        elif(Q==0):
            QoverI = 0                  # For Q=0 and I=0, the arg. is 0º
        elif(Q>0):
            QoverI = self.range_atan-1  # For +Q and I=0, the arg. is 90º
        else:
            QoverI = -self.range_atan+1 # For -Q and I=0, the arg. is -90º
      
        if(QoverI<0):
            QoverI = -QoverI
            is_neg = True
        else:
            QoverI = QoverI
            is_neg = False
        
        # Index search: map QoverI to an index in the arctan table
        self.idx_atg.value = QoverI * self.cte_atg.fValue
        
        # Get the argument value from the table
        if( self.idx_atg.intvalue>(self.nsamp_atan-1) ):
            tita = -np.pi/2 if(is_neg==True) else np.pi/2
        else:
            if(is_neg==True):
                tita = -self.arctan[self.idx_atg.intvalue].fValue
            else:
                tita =  self.arctan[self.idx_atg.intvalue].fValue
        
        return tita


    def __sin(self, tita):
        # Get absolute value of the angle and set the flag if it's negative
        if(tita<0):
            tita_aux = -tita
            is_neg = True
        else:
            tita_aux = tita
            is_neg = False
        
        # Compute the index for table lookup: rule of 3, round to the nearest
        #integer and ensure overflow handling
        self.idx_SyC.value = tita_aux * self.cte_SyC.fValue
        idx = self.idx_SyC.intvalue
        
        # Get the value from the table depending on the corresponding quarter 
        if( idx<=(self.nsamp_sin-1) ):
            sin_out =  self.sin_val[idx].fValue
        elif( idx<=2*(self.nsamp_sin-1) ):
            sin_out =  self.sin_val[2*(self.nsamp_sin-1) - idx].fValue
        elif( idx<=3*(self.nsamp_sin-1) ):
            sin_out = -self.sin_val[idx - 2*(self.nsamp_sin-1)].fValue
        else:
            sin_out = -self.sin_val[4*(self.nsamp_sin-1) - idx].fValue
        
        # Use the odd symmetry of the sine function
        if( is_neg ): 
            sin_out = -sin_out
        else:
            sin_out =  sin_out
        
        # Return value
        return sin_out


    def __cos(self, tita):
        # Get absolute value of the angle (cosine function has an even symmetry)
        if(tita<0):
            tita_aux = -tita
        else:
            tita_aux = tita
        
        # Compute the index for table lookup: rule of 3, round to the nearest
        #integer and ensure overflow handling
        self.idx_SyC.value = tita_aux * self.cte_SyC.fValue
        idx = self.idx_SyC.intvalue
        
        # Get the value from the table depending on the corresponding quarter 
        if( idx<=(self.nsamp_sin-1) ):
            cos_out =  self.sin_val[(self.nsamp_sin-1) - idx].fValue
        elif( idx<=2*(self.nsamp_sin-1) ):
            cos_out = -self.sin_val[idx - (self.nsamp_sin-1)].fValue
        elif( idx<=3*(self.nsamp_sin-1) ):
            cos_out = -self.sin_val[3*(self.nsamp_sin-1) - idx].fValue
        else:
            cos_out =  self.sin_val[idx - 3*(self.nsamp_sin-1)].fValue
        
        # Return value
        return cos_out


    def derot(self, symI, symQ):
        # multiplication by e^{-jnco_out}
        self.symI_out.value = (symI*self.__cos(-self.nco_out.fValue) -
                               symQ*self.__sin(-self.nco_out.fValue))
        self.symQ_out.value = (symI*self.__sin(-self.nco_out.fValue) +
                               symQ*self.__cos(-self.nco_out.fValue))
        
        return self.symI_out.fValue, self.symQ_out.fValue


    def rot(self, errI, errQ):
        # multiplication by e^{+jnco_out}
        self.errI_unrot.value = (errI*self.__cos(self.nco_out.fValue) -
                           errQ*self.__sin(self.nco_out.fValue))
        self.errQ_unrot.value = (errI*self.__sin(self.nco_out.fValue) +
                           errQ*self.__cos(self.nco_out.fValue))
        
        return self.errI_unrot.fValue, self.errQ_unrot.fValue


    def pll_loop(self, cyc_cnt, symI_fcr, symQ_fcr, symI_slcr, symQ_slcr):
        # Phase error
        tita_fcr  = self.__arctg(symI_fcr, symQ_fcr)
        tita_slcr = self.__arctg(symI_slcr, symQ_slcr)
        self.angle_err.value = (tita_fcr - tita_slcr)
      
        
        if( cyc_cnt>self.NSYM_FCR_ON ):
            # Loop Filter
            self.proport_err.value  = self.Kp.fValue * self.angle_err.fValue
            self.integral_err.value = (self.Ki.fValue * self.angle_err.fValue) + self.integral_err.fValue
            # NCO out
            nco_out_aux = (self.proport_err.fValue+self.integral_err.fValue)+self.nco_out.fValue
            if(nco_out_aux < 0):
                self.nco_out.value = 0.0
            elif(nco_out_aux >= 6.283185303211212):
                self.nco_out.value = 0.0
            else:
                self.nco_out.value = nco_out_aux
            
        else:
            # Loop Filter
            self.proport_err.value  = 0.0
            self.integral_err.value = 0.0
            # NCO out
            self.nco_out.value = 0.0


    def get_nco_out(self):
        return self.nco_out.fValue


    def get_integ_err(self):
        return self.integral_err.fValue

