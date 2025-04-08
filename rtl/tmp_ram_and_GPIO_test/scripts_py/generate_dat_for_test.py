import numpy as np
import matplotlib.pyplot as plt
import subprocess
import os 
from tool._fixedInt      import *

# Path data in float
path_data_fse_I    = "/home/danielito/Escritorio/Logueo/data_fse_I.txt"	      ;	
path_data_fse_Q    = "/home/danielito/Escritorio/Logueo/data_fse_Q.txt"	      ;	
path_data_slcr_I   = "/home/danielito/Escritorio/Logueo/data_input_slcr_I.txt";	
path_data_slcr_Q   = "/home/danielito/Escritorio/Logueo/data_input_slcr_Q.txt";	
path_data_coeffs_I = "/home/danielito/Escritorio/Logueo/data_coeff_I.txt"	  ;	
path_data_coeffs_Q = "/home/danielito/Escritorio/Logueo/data_coeff_Q.txt"	  ;	
path_data_err_I    = "/home/danielito/Escritorio/Logueo/data_err_I.txt"       ;	
path_data_err_Q    = "/home/danielito/Escritorio/Logueo/data_err_Q.txt"       ;	


# path data for rtl 
path_logs = "/home/danielito/Escritorio/CorreccionDeEfectosDeCanal/rtl/build/Ram_and_GPIO/Modulos/Data_for_Test/"
flog_data_fse_I    = open( path_logs + "data_fse_I.dat" , "wt") 
flog_data_fse_Q    = open( path_logs + "data_fse_Q.dat" , "wt") 
flog_data_slcr_I   = open( path_logs + "data_slcr_I.dat" , "wt") 
flog_data_slcr_Q   = open( path_logs + "data_slcr_Q.dat" , "wt") 
flog_data_coeffs_I = open( path_logs + "data_coeffs_I.dat" , "wt") 
flog_data_coeffs_Q = open( path_logs + "data_coeffs_Q.dat" , "wt") 
flog_data_err_I    = open( path_logs + "data_err_I.dat" , "wt") 
flog_data_err_Q    = open( path_logs + "data_err_Q.dat" , "wt") 

# Load the data
try:
    data_fse_I    = np.loadtxt(path_data_fse_I    , dtype=np.float32).tolist() 
    data_fse_Q    = np.loadtxt(path_data_fse_Q    , dtype=np.float32).tolist()
    data_slcr_I   = np.loadtxt(path_data_slcr_I   , dtype=np.float32).tolist() 
    data_slcr_Q   = np.loadtxt(path_data_slcr_Q   , dtype=np.float32).tolist() 
    data_coeffs_I = np.loadtxt(path_data_coeffs_I , dtype=np.float32).tolist() 
    data_coeffs_Q = np.loadtxt(path_data_coeffs_Q , dtype=np.float32).tolist() 
    data_err_I    = np.loadtxt(path_data_err_I    , dtype=np.float32).tolist() 
    data_err_Q    = np.loadtxt(path_data_err_Q    , dtype=np.float32).tolist() 

except Exception as e:
    print(f"Error loading files: {e}")
    exit()


# Fixed data for log
data_fse_I    = arrayFixedInt(8, 7,   data_fse_I    , 'S', 'trunc', 'saturate') 
data_fse_Q    = arrayFixedInt(8, 7,   data_fse_Q    , 'S', 'trunc', 'saturate') 
data_slcr_I   = arrayFixedInt(12, 9,  data_slcr_I   , 'S', 'trunc', 'saturate') 
data_slcr_Q   = arrayFixedInt(12, 9,  data_slcr_Q   , 'S', 'trunc', 'saturate') 
data_err_I    = arrayFixedInt(12, 9,  data_err_I    , 'S', 'trunc', 'saturate') 
data_err_Q    = arrayFixedInt(12, 9,  data_err_Q    , 'S', 'trunc', 'saturate') 
data_coeffs_I = arrayFixedInt(8, 5,   data_coeffs_I , 'S', 'trunc', 'saturate') 
data_coeffs_Q = arrayFixedInt(8, 5,   data_coeffs_Q , 'S', 'trunc', 'saturate') 

N_LOG_DATA = 33
# Login binary data
for idx in range (N_LOG_DATA):
    flog_data_fse_I.write(str(bin(data_fse_I[idx].intvalue))[2:]+"\n")
    flog_data_fse_Q.write(str(bin(data_fse_Q[idx].intvalue))[2:]+"\n") 

for idx in range (N_LOG_DATA):
    flog_data_slcr_I.write(str(bin(data_slcr_I[idx].intvalue))[2:]+"\n")
    flog_data_slcr_Q.write(str(bin(data_slcr_Q[idx].intvalue))[2:]+"\n") 

for idx in range (N_LOG_DATA):
    flog_data_err_I.write(str(bin(data_err_I[idx].intvalue))[2:]+"\n")
    flog_data_err_Q.write(str(bin(data_err_Q[idx].intvalue))[2:]+"\n") 

for idx in range (N_LOG_DATA):
    flog_data_coeffs_I.write(str(bin(data_coeffs_I[idx].intvalue))[2:]+"\n")
    flog_data_coeffs_Q.write(str(bin(data_coeffs_Q[idx].intvalue))[2:]+"\n") 

flog_data_fse_I.close()
flog_data_fse_Q.close()
flog_data_slcr_I.close()
flog_data_slcr_Q.close()
flog_data_coeffs_I.close()
flog_data_coeffs_Q.close()
flog_data_err_I.close()
flog_data_err_Q.close()


