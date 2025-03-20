`timescale 1ns/1ps

module tb_berIQ;

    parameter CNT_BER   = 64                                 ;
    parameter CNT_ERR   = 64                                 ;
    parameter PRBS_CYCL = 511                                ;
    parameter COMB_PRBS = 511                                ;
    parameter START_SYN = 249879                             ;
    parameter START_CNT = START_SYN + (COMB_PRBS * PRBS_CYCL);



    // inputs
    reg                i_clock         ;
    reg                i_reset         ;
    reg  [32:0       ] i_count_sym     ;
    reg                i_prbs_Q        ;
    reg                i_prbs_I        ;
    reg                i_rx_bit_Q_demap;
    reg                i_rx_bit_I_demap;
    // outputs
    wire [CNT_BER-1:0] o_cnt_ber_Q     ;
    wire [CNT_BER-1:0] o_cnt_ber_I     ;
    wire [CNT_ERR-1:0] o_cnt_err_ber_Q ;
    wire [CNT_ERR-1:0] o_cnt_err_ber_I ;
    wire [1:0        ] o_rot_ang_detec ;


    // parametros para simulacion 
    parameter N_SIMU = 1000000;
    parameter FILE_PRBS_I         = "/home/danielito/Escritorio/Logueos/tx_bitI_prbs.txt";
    parameter FILE_PRBS_Q         = "/home/danielito/Escritorio/Logueos/tx_bitQ_prbs.txt";
    parameter FILE_RX_BIT_I_DEMAP = "/home/danielito/Escritorio/Logueos/rx_bitI_demap.txt";
    parameter FILE_RX_BIT_Q_DEMAP = "/home/danielito/Escritorio/Logueos/rx_bitQ_demap.txt";

    // Variables para la simulación
    // integer flog_prbs_I, flog_prbs_Q;
    // integer flog_rx_bit_I_demap, flog_rx_bit_Q_demap;
    integer i;

    // Registros para la simulación
    reg [0:0] prbs_I         [0:N_SIMU-1];
    reg [0:0] prbs_Q         [0:N_SIMU-1];
    reg [0:0] rx_bit_I_demap [0:N_SIMU-1];
    reg [0:0] rx_bit_Q_demap [0:N_SIMU-1];

    // Carga de los valores de los archivos en la ram
    initial begin  
        $readmemb(FILE_PRBS_I        , prbs_I, 0, N_SIMU-1        );
        $readmemb(FILE_PRBS_Q        , prbs_Q, 0, N_SIMU-1        );
        $readmemb(FILE_RX_BIT_I_DEMAP, rx_bit_I_demap, 0, N_SIMU-1);
        $readmemb(FILE_RX_BIT_Q_DEMAP, rx_bit_Q_demap, 0, N_SIMU-1);
    end 

    // Instancia del modulo 
    berIQ 
    #(
        .CNT_BER   (CNT_BER  ),
        .CNT_ERR   (CNT_ERR  ),
        .PRBS_CYCL (PRBS_CYCL),
        .COMB_PRBS (COMB_PRBS),
        .START_SYN (START_SYN),
        .START_CNT (START_CNT)
    ) 
    u_berIQ (
        .i_clock         (i_clock         ),
        .i_reset         (i_reset         ),
        .i_count_sym     (i_count_sym     ),
        .i_prbs_Q        (i_prbs_Q        ),
        .i_prbs_I        (i_prbs_I        ),
        .i_rx_bit_Q_demap(i_rx_bit_Q_demap),
        .i_rx_bit_I_demap(i_rx_bit_I_demap),
        .o_cnt_ber_Q     (o_cnt_ber_Q     ),
        .o_cnt_ber_I     (o_cnt_ber_I     ),
        .o_cnt_err_ber_Q (o_cnt_err_ber_Q ),
        .o_cnt_err_ber_I (o_cnt_err_ber_I ),
        .o_rot_ang_detec (o_rot_ang_detec )
    );

    always #5 i_clock = ~i_clock;


    initial begin
    // Inicialización de señales
        i_clock           = 0;
        i_reset           = 1;
        i_count_sym       = 0;
        i_prbs_Q          = 0;
        i_prbs_I          = 0;
        i_rx_bit_Q_demap  = 0;
        i_rx_bit_I_demap  = 0;
        // Mantener reset activo durante 20 ns
        #20;
        i_reset = 0;
        // Generar estímulos durante la simulación
        for(i=0; i<N_SIMU; i=i+1) begin
            i_count_sym = i_count_sym + 1'b1; //incrementa el contador 
            // Carga de los valores 
            i_prbs_Q         = prbs_I[i]        ;
            i_prbs_I         = prbs_Q[i]        ;
            i_rx_bit_Q_demap = rx_bit_I_demap[i];
            i_rx_bit_I_demap = rx_bit_Q_demap[i];
            #10;
        end
        $finish;
    end
endmodule