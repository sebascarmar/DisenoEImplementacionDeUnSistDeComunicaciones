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
        # Phase error
        self.angle_err = ( np.angle(symI_fcr+1j*symQ_fcr) -
                           np.angle(symI_slcr+1j*symQ_slcr) )
     
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

