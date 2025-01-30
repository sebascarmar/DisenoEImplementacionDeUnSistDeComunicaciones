import numpy as np

class fcr_class:

    def __init__(self, Kp, Ki, NSYM_FCR_ON):
        self.NSYM_FCR_ON = NSYM_FCR_ON
        self.Kp = Kp
        self.Ki = Ki
        self.angle_err   = 0.0
        self.angle_err_aux    = []
        self.proport_err = 0.0
        self.integral_err= 0.0
        self.nco_out = 0.0
        self.symI_out = 0.0
        self.symQ_out = 0.0
        self.errI_unrot = 0.0
        self.errQ_unrot = 0.0
        
        # Generate 1024 evenly spaced values from 0 to 500 and compute their arctan
        self.range_atan = 500
        self.n_samp     = 4096
        x_values = np.linspace(0, self.range_atan-1, self.n_samp)
        self.arctan = np.arctan(x_values)
        self.LOG_RANGE_DIV = []


    
    def derot(self, symI, symQ):
        # multiplication by e^{-jnco_out}
        self.symI_out = (symI*np.cos(-self.nco_out) -
                         symQ*np.sin(-self.nco_out))
        self.symQ_out = (symI*np.sin(-self.nco_out) +
                         symQ*np.cos(-self.nco_out))
        
        return self.symI_out, self.symQ_out


    def rot(self, errI, errQ):
        # multiplication by e^{+jnco_out}
        self.errI_unrot = (errI*np.cos(self.nco_out) -
                           errQ*np.sin(self.nco_out))
        self.errQ_unrot = (errI*np.sin(self.nco_out) +
                           errQ*np.cos(self.nco_out))
        
        return self.errI_unrot, self.errQ_unrot


    def pll_loop(self, cyc_cnt, symI_fcr, symQ_fcr, symI_slcr, symQ_slcr):
        # Calculate arguments
        if(symI_fcr!=0):
            QoverI_fcr = symQ_fcr/symI_fcr       
        elif(symQ_fcr==0):
            QoverI_fcr = 0 # The complex number 0+j0 has an argument of 0º
        elif(symQ_fcr>0):
            QoverI_fcr = self.range_atan-1 
        else:
            QoverI_fcr = -self.range_atan-1 
        QoverI_slcr = symQ_slcr/symI_slcr
        self.LOG_RANGE_DIV.append(QoverI_fcr)
        # Index search
        idx_fcr = round(np.abs(QoverI_fcr) * (self.n_samp-1) / (self.range_atan-1))
        idx_slcr = round(np.abs(QoverI_slcr) * (self.n_samp-1) / (self.range_atan-1))
        # Get the argument value from the table
        if(idx_fcr>1023):
            tita_fcr = np.pi/2 if(QoverI_fcr>=0) else -np.pi/2
        else:
            tita_fcr  = self.arctan[idx_fcr] if(QoverI_fcr>=0) else -self.arctan[idx_fcr]
        if(idx_slcr>1023):
            tita_slcr = np.pi/2 if(QoverI_slcr>=0) else -np.pi/2
        else:
            tita_slcr  = self.arctan[idx_slcr] if(QoverI_slcr>=0) else -self.arctan[idx_slcr]
        # Phase error
        self.angle_err = ( np.angle(symI_fcr+1j*symQ_fcr) -
                           np.angle(symI_slcr+1j*symQ_slcr) )
        self.angle_err_aux.append((tita_fcr - tita_slcr) - self.angle_err)
        self.angle_err = (tita_fcr - tita_slcr)
      
        
        if( cyc_cnt>self.NSYM_FCR_ON ):
            self.proport_err  = self.Kp * self.angle_err
            self.integral_err = (self.Ki * self.angle_err) + self.integral_err
            self.nco_out = (self.proport_err+self.integral_err)+self.nco_out
        else:
            self.proport_err  = 0.0
            self.integral_err = 0.0
            self.nco_out = 0.0


    def get_nco_out(self):
        return self.nco_out


    def get_integ_err(self):
        return self.integral_err


    def get_log_range_div(self):
        return self.LOG_RANGE_DIV


    def get_log_angle_diff(self):
        return self.angle_err_aux
