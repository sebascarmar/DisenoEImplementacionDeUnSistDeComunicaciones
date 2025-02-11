import numpy as np

class fcr_class:

    def __init__(self, Kp, Ki, NSYM_FCR_ON):
        self.NSYM_FCR_ON = NSYM_FCR_ON
        self.Kp = Kp
        self.Ki = Ki
        self.angle_err   = 0.0
        self.proport_err = 0.0
        self.integral_err= 0.0
        self.nco_out = 0.0
        self.symI_out = 0.0
        self.symQ_out = 0.0
        self.errI_unrot = 0.0
        self.errQ_unrot = 0.0
        
        # Generate 2048 evenly spaced values from 0 to 60 and compute their arctan
        self.range_atan = 60
        self.nsamp_atan = 2048
        x_values = np.linspace(0, self.range_atan-1, self.nsamp_atan)
        self.arctan = np.arctan(x_values)
        
        # Generate a quarter-cycle sine table with 1025 samples points
        self.nsamp_sin = 1025
        wt             = np.linspace(0, np.pi/2, self.nsamp_sin)
        self.sin_val   = np.sin(wt)


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
      
        # Index search: map QoverI to an index in the arctan table
        idx = round(np.abs(QoverI) * (self.nsamp_atan-1) / (self.range_atan-1))
        
        # Get the argument value from the table
        if( idx>(self.nsamp_atan-1) ):
            tita = np.pi/2 if(QoverI>=0) else -np.pi/2
        else:
            tita  = self.arctan[idx] if(QoverI>=0) else -self.arctan[idx]
        
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
        idx = round(tita_aux*(self.nsamp_sin-1)/(np.pi/2)) & (4*(self.nsamp_sin-1)-1)
        
        # Get the value from the table depending on the corresponding quarter 
        if( idx<=(self.nsamp_sin-1) ):
            sin_out =  self.sin_val[idx]
        elif( idx<=2*(self.nsamp_sin-1) ):
            sin_out =  self.sin_val[2*(self.nsamp_sin-1) - idx]
        elif( idx<=3*(self.nsamp_sin-1) ):
            sin_out = -self.sin_val[idx - 2*(self.nsamp_sin-1)]
        else:
            sin_out = -self.sin_val[4*(self.nsamp_sin-1) - idx]
        
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
        idx = round(tita_aux*(self.nsamp_sin-1)/(np.pi/2)) & (4*(self.nsamp_sin-1)-1)
        
        # Get the value from the table depending on the corresponding quarter 
        if( idx<=(self.nsamp_sin-1) ):
            cos_out =  self.sin_val[(self.nsamp_sin-1) - idx]
        elif( idx<=2*(self.nsamp_sin-1) ):
            cos_out = -self.sin_val[idx - (self.nsamp_sin-1)]
        elif( idx<=3*(self.nsamp_sin-1) ):
            cos_out = -self.sin_val[3*(self.nsamp_sin-1) - idx]
        else:
            cos_out =  self.sin_val[idx - 3*(self.nsamp_sin-1)]
        
        # Return value
        return cos_out


    def derot(self, symI, symQ):
        # multiplication by e^{-jnco_out}
        self.symI_out = (symI*self.__cos(-self.nco_out) -
                         symQ*self.__sin(-self.nco_out))
        self.symQ_out = (symI*self.__sin(-self.nco_out) +
                         symQ*self.__cos(-self.nco_out))
        
        return self.symI_out, self.symQ_out


    def rot(self, errI, errQ):
        # multiplication by e^{+jnco_out}
        self.errI_unrot = (errI*self.__cos(self.nco_out) -
                           errQ*self.__sin(self.nco_out))
        self.errQ_unrot = (errI*self.__sin(self.nco_out) +
                           errQ*self.__cos(self.nco_out))
        
        return self.errI_unrot, self.errQ_unrot


    def pll_loop(self, cyc_cnt, symI_fcr, symQ_fcr, symI_slcr, symQ_slcr):
        # Phase error
        tita_fcr  = self.__arctg(symI_fcr, symQ_fcr)
        tita_slcr = self.__arctg(symI_slcr, symQ_slcr)
        self.angle_err = (tita_fcr - tita_slcr)
      
        
        if( cyc_cnt>self.NSYM_FCR_ON ):
            # Loop Filter
            self.proport_err  = self.Kp * self.angle_err
            self.integral_err = (self.Ki * self.angle_err) + self.integral_err
            # NCO out
            self.nco_out = (self.proport_err+self.integral_err)+self.nco_out
        else:
            # Loop Filter
            self.proport_err  = 0.0
            self.integral_err = 0.0
            # NCO out
            self.nco_out = 0.0


    def get_nco_out(self):
        return self.nco_out


    def get_integ_err(self):
        return self.integral_err

