import numpy as np

class poly_filter:
    
    def __init__(self, filt_coeff, NBAUD, OS, NSYMB):
        
        ### Oversampling: number of phases
        self.OS           = OS
        ### Shift register for input symbols
        self.shifter_filt = np.full(NBAUD+1,0)
        ### Coeffs. of each phase
        self.poly_filter  = []
        for phase in range(OS):  # OS phases
            self.poly_filter.append([])
            for j in range(NBAUD+1):
                if( phase==0 ):
                    self.poly_filter[phase].append( filt_coeff[phase + j*OS] )
                else:
                    if(j<NBAUD):
                        self.poly_filter[phase].append( filt_coeff[phase + j*OS] )
                    else:
                        self.poly_filter[phase].append(0.0)
        ### Partial products of the convolution
        self.partial_prod = np.zeros(NBAUD+1)
        ### Filter out
        self.sym_out   = 0.0
        ### Contador. Permite que coincida la fase0 del filtro (coeficientes) con el primer
        ###símbolo ingresado al filtro (bucle i=1, o segundo clock)
        self.phase_cntr = self.OS-1


    def convol(self, i, new_symb):
        # It's going to be useful for truncation and saturation
        self.sym_out = 0.0
        
        # Select the right phase of the filter
        if( self.phase_cntr>=self.OS-1 ):
            self.phase_cntr = 0
        else:
            self.phase_cntr += 1
        
        # Shift and get a new symbol (like a FIFO) each OS cycles
        if( i%self.OS == 0 ):
            self.shifter_filt    = np.roll(self.shifter_filt,1)
            self.shifter_filt[0] = new_symb
            
        # Multiplication of filter coeffs. and symbols
        for j in range(len(self.shifter_filt)):
            self.partial_prod[j] = self.poly_filter[self.phase_cntr][j]*self.shifter_filt[j]
            #print(self.partial_prod[j],pol_filter[phase_cntr][j],shifter_filt[j])
        
        # Sum all the partial products
        for k in range(0,len(self.partial_prod),2):
            self.sym_out += self.partial_prod[k]+self.partial_prod[k+1]
        
        return self.sym_out



#   def __init__(self, filt_coeff, NBAUD, OS, NSYMB):
#        ### Conjunto de coeficientes correspondientes a cada fase del filtro 
#        self.ph0_coeff = np.zeros(len(self.shifter_filt))
#        self.ph1_coeff = np.zeros(len(self.shifter_filt))
#        self.ph2_coeff = np.zeros(len(self.shifter_filt))
#        self.ph3_coeff = np.zeros(len(self.shifter_filt))
#        for i in range(1,NBAUD*OS+OS,OS):
#            if( i<NBAUD*OS ):
#                self.ph0_coeff[int(i/OS)] = filt_coeff[i-1]
#                self.ph1_coeff[int(i/OS)] = filt_coeff[i+0]
#                self.ph2_coeff[int(i/OS)] = filt_coeff[i+1]
#                self.ph3_coeff[int(i/OS)] = filt_coeff[i+2]
#            else:
#                self.ph0_coeff[int(i/OS)] = filt_coeff[i-1]
#
#        ### Productos parciales
#        self.prod_parcial = np.zeros(6)
#        ### Sumas parciales y final
#        self.sum_lvl1_a = 0.0
#        self.sum_lvl1_b = 0.0
#        self.sum_lvl1_c = 0.0
#        self.sum_lvl2_a = 0.0
#        self.sum_lvl2_b = 0.0
#        self.sum_lvl3   = 0.0
#        ### Saturación y truncado
#        self.sym_out   = 0.0
#        ### Contador. Permite que coincida la fase0 del filtro (coeficientes) con el primer
#        ###símbolo ingresado al filtro (bucle i=1, o segundo clock)
#        self.phase_counter = OS-1
