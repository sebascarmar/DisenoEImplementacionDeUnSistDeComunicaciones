
#!/bin/bash

# Para que este scip de bash funcione se debe generar una clave ssh publica y copiarla al servidor 
#
# 1) coloca en la consola ssh-keygen -t rsa -b 4096 -C "user@fulgorip1.hopto.org"
# 2) luego se pedira Enter file in which to save the key (/home/tu_usuario/.ssh/id_rsa): 
# 3) la contraseña es opcional, sino no coloques nada preciona enter 3 veces para que nunca pida contraseña y se genere el SHA 
# 4) Copia la clave publica al servidor ssh-copy-id -p 4466 user@fulgorip1.hopto.org
# 5) Prueba conexion ssh -p 4466 user@fulgorip1.hopto.org
#
# NOTA: Se debe instalar scp sudo apt install openssh-client

# Dowload data in sweep_snr
for x in {7..17}; do
    echo "Download sweep_with_snr_$x.txt..."
    scp -P 4466 user@fulgorip1.hopto.org:/home/user/work_dda/djuarez/scripts/tesis/snr_sweep/sweep_with_snr_${x}.txt ~/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/hwd/plots_script/logs/snr_sweep
done



# Download data stored 
for x in {7..17}; do
    echo "Download sweep_with_snr_$x.txt..."
    scp -P 4466 user@fulgorip1.hopto.org:/home/user/work_dda/djuarez/scripts/tesis/dsp_data/file_rx_symI_dwr2_snr_${x}.txt ~/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/hwd/plots_script/logs/dsp_data/  
    scp -P 4466 user@fulgorip1.hopto.org:/home/user/work_dda/djuarez/scripts/tesis/dsp_data/file_rx_symQ_dwr2_snr_${x}.txt ~/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/hwd/plots_script/logs/dsp_data/  
    scp -P 4466 user@fulgorip1.hopto.org:/home/user/work_dda/djuarez/scripts/tesis/dsp_data/file_rx_symI_dwr1_snr_${x}.txt ~/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/hwd/plots_script/logs/dsp_data/  
    scp -P 4466 user@fulgorip1.hopto.org:/home/user/work_dda/djuarez/scripts/tesis/dsp_data/file_rx_symQ_dwr1_snr_${x}.txt ~/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/hwd/plots_script/logs/dsp_data/  
    scp -P 4466 user@fulgorip1.hopto.org:/home/user/work_dda/djuarez/scripts/tesis/dsp_data/file_fse_taps_I_snr_${x}.txt ~/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/hwd/plots_script/logs/dsp_data/ 
    scp -P 4466 user@fulgorip1.hopto.org:/home/user/work_dda/djuarez/scripts/tesis/dsp_data/file_fse_taps_Q_snr_${x}.txt ~/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/hwd/plots_script/logs/dsp_data/   
done


