`timescale 1ns/1ps

`define SEED_I        9'h1AA
`define SEED_Q        9'h1FE
`define NBT_OUT       8
`define NBF_OUT       6
`define NBT_COEF_TX   8
`define NBF_COEF_TX   6
`define NBTOT_DAT     8
`define NBAUD         5+1
`define OVERSAMP      4
`define OVERSAMP_DSP  2


module tmp_top_tx
#(
  parameter SEED_I      = `SEED_I     ,
  parameter SEED_Q      = `SEED_Q     ,
  parameter NBT_OUT     = `NBT_OUT    ,
  parameter NBF_OUT     = `NBF_OUT    ,
  parameter NBT_COEF_TX = `NBT_COEF_TX,
  parameter NBF_COEF_TX = `NBF_COEF_TX,
  parameter NBTOT_DAT   = `NBTOT_DAT  ,
  parameter NBAUD       = `NBAUD      ,
  parameter OVERSAMP    = `OVERSAMP   
 )
 (
    //output        [          3:0] o_normal_led               ,
    // temporales
    output signed [NBT_OUT-1:0] out_from_tx_filtI_to_noiseI,
    output signed [NBT_OUT-1:0] out_from_tx_filtQ_to_noiseQ,
    
    //input  [                 3:0]  i_sw        ,
    input                          i_reset     ,
    input                          clk
 );
    
    
    // SEÑALES Y REGISTROS
    wire       w_reset                        ;
    wire [1:0] control_for_T_over_4_rate      ;
    wire       control_for_T_rate             ;
    wire       new_bit_from_prbsI_tx_to_filter;
    wire       new_bit_from_prbsQ_tx_to_filter;
    //wire signed [NBT_OUT-1:0] out_from_tx_filtI_to_noiseI;
    //wire signed [NBT_OUT-1:0] out_from_tx_filtQ_to_noiseQ;
    
    
    // SELECCIONA ENTRE MANEJO FÍSICO DE LA FPGA O MEDIANTE VIO
    assign w_reset  = ~i_reset;
    
    
   
    // INTANCIACIÓN DEL CONTROL
    control
        u_control
            (
                .o_count    (control_for_T_over_4_rate),
                .o_count_max(       control_for_T_rate),
                .i_reset    (                  w_reset),
                .clk        (                      clk)
            );
    
    // INSTANCIACIÓN DE LAS PRBS DEL Tx
    prbs9
       #(
            .SEED (SEED_I)
        )
        u_prbs9I_tx
            (
                .o_new_bit(new_bit_from_prbsI_tx_to_filter),
                .i_ctrl   (             control_for_T_rate),
                .i_reset  (                        w_reset),  
                .clk      (                            clk)            
            );
    
    prbs9
       #(
            .SEED (SEED_Q)
        )
        u_prbs9Q_tx
            (
                .o_new_bit(new_bit_from_prbsQ_tx_to_filter),
                .i_ctrl   (             control_for_T_rate),
                .i_reset  (                        w_reset),  
                .clk      (                            clk)            
            );
    
    // INSTANCIACIÓN DE LOS FILTROS PARA I y Q
    polyph_filter
       #(
            .NBT_OUT     (    NBT_OUT),
            .NBF_OUT     (    NBF_OUT),
            .NBT_COEF_TX (NBT_COEF_TX),
            .NBF_COEF_TX (NBF_COEF_TX),
            .NBAUD       (      NBAUD),
            .OS          (   OVERSAMP)
        )
        u_filter_I
            (
                .o_os_data           (    out_from_tx_filtI_to_noiseI),
                .i_is_data           (new_bit_from_prbsI_tx_to_filter),
                .i_phase_num_of_coeff(      control_for_T_over_4_rate),
                .i_ctrl              (             control_for_T_rate),
                .i_reset             (                        w_reset),            
                .clk                 (                            clk)
            );
    
    
    polyph_filter
       #(
            .NBT_OUT     (    NBT_OUT),
            .NBF_OUT     (    NBF_OUT),
            .NBT_COEF_TX (NBT_COEF_TX),
            .NBF_COEF_TX (NBF_COEF_TX),
            .NBAUD       (      NBAUD),
            .OS          (   OVERSAMP)
        )
        u_filter_Q
            (
                .o_os_data           (    out_from_tx_filtQ_to_noiseQ),
                .i_is_data           (new_bit_from_prbsQ_tx_to_filter),
                .i_phase_num_of_coeff(      control_for_T_over_4_rate),
                .i_ctrl              (             control_for_T_rate),
                .i_reset             (                        w_reset),            
                .clk                 (                            clk)
            );
    
    
   
   
   
  endmodule

