//=============================================================================
// Autor: Daniel Juarez 
// AÑO: 03-2025
// Nombre: Contador de BER, para simbolos con detector de fase rotada 
//=============================================================================

module berIQ
#(
    parameter CNT_BER   = 64                               , // Contador de errores
    parameter CNT_ERR   = 64                               , // Contador total de bits evaluados
    parameter PRBS_CYCL = 16                               , // Ciclos de PRBS
    parameter COMB_PRBS = 511                              , // Tamaño del shift register para PRBS
    parameter START_SYN = 249879                           , // Inicio de sincronizacion
    parameter START_CNT = START_SYN + (COMB_PRBS*PRBS_CYCL)
)
(
    input                     i_clock         , // clock del sistema 
    input                     i_reset         , // reset del sistema 
    input   [32:0]            i_count_sym     , // Contador de símbolos (para sincronizacion)
    input                     i_prbs_Q        , // Bit PRBS generado para Q (externo o de otro módulo)
    input                     i_prbs_I        , // Bit PRBS generado para I
    input                     i_rx_bit_Q_demap, // Bit recibido en Q (se usa LSB)
    input                     i_rx_bit_I_demap, // Bit recibido en I (se usa LSB)
    output  reg [CNT_BER-1:0] o_cnt_ber_Q     , // Contador de errores para canal Q
    output  reg [CNT_BER-1:0] o_cnt_ber_I     , // Contador de errores para canal I
    output  reg [CNT_ERR-1:0] o_cnt_err_ber_Q , // Contador total de bits evaluados en Q
    output  reg [CNT_ERR-1:0] o_cnt_err_ber_I , // Contador total de bits evaluados en I     
    output  reg [1:0        ] o_rot_ang_detec   // Fase detectada: 2'b00 -> 0, 2'b01 -> 90, 2'b10 -> 180, 2'b11 -> 270
);


// ========================================
// Registros
// ========================================
reg [COMB_PRBS-1:0] shftr_berI;  // Shif reg canal I
reg [COMB_PRBS-1:0] shftr_berQ;  // Shif reg canal Q

// Contadores de errores para cada rotación (acumulados durante el período de PRBS)
reg [CNT_BER-1:0] err_sym_0;
reg [CNT_BER-1:0] err_sym_90;
reg [CNT_BER-1:0] err_sym_180;
reg [CNT_BER-1:0] err_sym_270;
// Registro para el err minimo
reg [CNT_BER-1:0] min_error;     

reg [8:0] BER_IDX; // ptr para indicar punto de comparacion (desde 0 -> COMB_PRBS-1)
reg [8:0] latency; // Valor del indice del minimo error
// Para almacenar los bits rotados 
reg rx_bitI_rot;
reg rx_bitQ_rot;
// Registro para la rotación detectada: 2'b00 -> 0, 
//                                      2'b01 -> 90, 
//                                      2'b10 -> 180,
//                                      2'b11 -> 270
reg [1:0] rot_ang_detec;
// Contadores de errores en la etapa de 
reg [CNT_BER-1:0] bit_err_I;
reg [CNT_BER-1:0] bit_err_Q;
reg [CNT_ERR-1:0] bit_tot_I;
reg [CNT_ERR-1:0] bit_tot_Q;

// ========================================
// wires internos 
// ========================================
// Se utilizan únicamente los LSB de los datos demapeados
wire rx_bit_I = i_rx_bit_I_demap;
wire rx_bit_Q = i_rx_bit_Q_demap;

// Bit de demaper invertidos 
wire inv_rx_bit_I = ~rx_bit_I;
wire inv_rx_bit_Q = ~rx_bit_Q;


// ==========================
// always principal 
// ==========================
always @(posedge i_clock) begin
    // Reset de todos los registros 
    if (i_reset) begin
        shftr_berI      <= 0                ;
        shftr_berQ      <= 0                ;
        BER_IDX         <= 0                ;
        err_sym_0       <= 0                ;
        err_sym_90      <= 0                ;
        err_sym_180     <= 0                ;
        err_sym_270     <= 0                ;
        min_error       <= {COMB_PRBS{1'b1}}; // Inicializa en el extremo 511
        latency         <= 0                ;
        rot_ang_detec   <= 2'b00            ;
        bit_err_I       <= 0                ;
        bit_err_Q       <= 0                ;
        bit_tot_I       <= 0                ;
        bit_tot_Q       <= 0                ;
        o_cnt_ber_I     <= 0                ;
        o_cnt_ber_Q     <= 0                ;
        o_cnt_err_ber_I <= 0                ;
        o_cnt_err_ber_Q <= 0                ;
        o_rot_ang_detec <= 2'b00            ;
    end else begin

    // Se actualiza los registros PRBS (shift register)
    shftr_berI <= {i_prbs_I, shftr_berI[COMB_PRBS-1:1]};
    shftr_berQ <= {i_prbs_Q, shftr_berQ[COMB_PRBS-1:1]};

    // Sincronizacion: i_count_sym sea multiplo de COMB_PRBS y mayor que COMB_PRBS 
    // Lo que se busca es en que multiplo de 90 esta rotada la constelacion y el menor error.
    if ((i_count_sym % COMB_PRBS == 0) && (i_count_sym > START_SYN)) begin
        if ((err_sym_0 <= err_sym_90) && (err_sym_0 <= err_sym_180) && (err_sym_0 <= err_sym_270)) begin
        min_error     <= err_sym_0; // Se asigna el min error                       
        latency       <= BER_IDX;   // se asigna el indice de latencia              
        rot_ang_detec <= 2'b00;     // Se indica la rot de la constelacion 0 grados 
        err_sym_0     <= 0;         // Se resetea el valor para una prox cuenta     
        end else if ((err_sym_90 < err_sym_0) && (err_sym_90 <= err_sym_180) && (err_sym_90 <= err_sym_270)) begin
        min_error     <= err_sym_90; // Se asigna el min error                       
        latency       <= BER_IDX;    // se asigna el indice de latencia                     
        rot_ang_detec <= 2'b01;      // Se indica la rot de la constelacion 90 grados 
        err_sym_90    <= 0;          // Se resetea el valor para una prox cuenta     
        end else if ((err_sym_180 < err_sym_0) && (err_sym_180 < err_sym_90) && (err_sym_180 <= err_sym_270)) begin
        min_error     <= err_sym_180;
        latency       <= BER_IDX;
        rot_ang_detec <= 2'b10; // Se indica la rot de la constelacion 180 grados
        err_sym_180   <= 0;
        end else if ((err_sym_270 < err_sym_0) && (err_sym_270 < err_sym_90) && (err_sym_270 < err_sym_180)) begin
        min_error     <= err_sym_270;
        latency       <= BER_IDX;
        rot_ang_detec <= 2'b11; // Se indica la rot de la constelacion 270 grados 
        err_sym_270   <= 0;
        end 
        BER_IDX <= BER_IDX + 1; // se actualiza el indice para la siguiente comparacion 
    end else begin

        BER_IDX <= BER_IDX; // Sino se mantiene el indice 
    end

    // -------------------------------------------------------------
    // Se compara los bits PRBS (posicion BER_IDX) con los bits (demapeados)
    // para los 4 casos:
    // * 0   : Se comapra directo 
    // * 90  : Se invierte los bits del canal Q
    // * 180 : Se invierten los dos canales
    // * 270 : Se invierte los bits del canal I
    // -------------------------------------------------------------
    err_sym_0   <= err_sym_0   + ((shftr_berI[BER_IDX] ^ rx_bit_I    ) | (shftr_berQ[BER_IDX] ^ rx_bit_Q    ));
    err_sym_90  <= err_sym_90  + ((shftr_berI[BER_IDX] ^ inv_rx_bit_Q) | (shftr_berQ[BER_IDX] ^ rx_bit_I    ));
    err_sym_180 <= err_sym_180 + ((shftr_berI[BER_IDX] ^ inv_rx_bit_I) | (shftr_berQ[BER_IDX] ^ inv_rx_bit_Q));
    err_sym_270 <= err_sym_270 + ((shftr_berI[BER_IDX] ^ rx_bit_Q    ) | (shftr_berQ[BER_IDX] ^ inv_rx_bit_I));

    // Conteo de los errores despues de sincronizar y correccion de los bits 
    // segun la rotacion detectada 
    case (rot_ang_detec)
        2'b00: begin
        rx_bitI_rot = rx_bit_I;
        rx_bitQ_rot = rx_bit_Q;
        end
        2'b01: begin
        rx_bitI_rot = inv_rx_bit_Q;
        rx_bitQ_rot = rx_bit_I;
        end
        2'b10: begin
        rx_bitI_rot = inv_rx_bit_I;
        rx_bitQ_rot = inv_rx_bit_Q;
        end
        2'b11: begin
        rx_bitI_rot = rx_bit_Q;
        rx_bitQ_rot = inv_rx_bit_I;
        end
        default: begin
        rx_bitI_rot = rx_bit_I;
        rx_bitQ_rot = rx_bit_Q;
        end
    endcase

    // // Se vuelve a actualizar el shift register con el nuevo bit PRBS 
    // shftr_berI <= {i_prbs_I, shftr_berI[COMB_PRBS-1:1]};
    // shftr_berQ <= {i_prbs_Q, shftr_berQ[COMB_PRBS-1:1]};
    // Conteo de errores utilizando el bit en la posición latency
    bit_err_I <= bit_err_I + (shftr_berI[latency] ^ rx_bitI_rot);
    bit_err_Q <= bit_err_Q + (shftr_berQ[latency] ^ rx_bitQ_rot);
    bit_tot_I <= bit_tot_I + 1'b1                               ;
    bit_tot_Q <= bit_tot_Q + 1'b1                               ;
    // Asignacion de las salidas
    o_cnt_ber_I     <= bit_err_I    ;
    o_cnt_ber_Q     <= bit_err_Q    ;
    o_cnt_err_ber_I <= bit_tot_I    ;
    o_cnt_err_ber_Q <= bit_tot_Q    ;
    o_rot_ang_detec <= rot_ang_detec;

    end // end if reset
end // always

endmodule