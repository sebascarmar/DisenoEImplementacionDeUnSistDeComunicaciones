//================================== Test Bench ==================================
// AUTOR: Juarez Daniel 
// AÑO:   2025  
// NOMBRE: Test Bench for the top TX module 
//================================================================================
`timescale 1ns/1ps

module tb_top ();

  // Parameters
  parameter NB_OUTPUT  = 8;  // NB of output
  parameter NBF_OUTPUT = 7;  // NBF of output
  parameter NB_COEFF   = 16; // NB of Coefficients
  parameter NBF_COEFF  = 15; // NBF of Coefficients
  parameter INIT_FILE  = "/home/danielito/Escritorio/run/ModuleFIlterTX/Module/txf_coeff.dat";  // File with the coefficients

  // Registers and wires
  reg                 i_reset;    
  reg                 i_clock;   
  reg           [3:0] i_sw; 

  wire signed [NB_COEFF+2:0]  o_tx_full_symbI;
  wire signed [NB_COEFF+2:0]  o_tx_full_symbQ;
  wire signed [NB_OUTPUT-1:0] o_tx_symbI;
  wire signed [NB_OUTPUT-1:0] o_tx_symbQ;

  integer file_symb_txI     ;
  integer file_symb_txQ     ;
  integer file_symb_full_txI;
  integer file_symb_full_txQ;  
  integer i;
  integer n_logs = 1000000;

  // Instance of the top module
  top_tx
  #(    
      .NB_OUTPUT (NB_OUTPUT ), 
      .NBF_OUTPUT(NBF_OUTPUT), 
      .NB_COEFF  (NB_COEFF  ),
      .NBF_COEFF (NBF_COEFF ),
      .INIT_FILE (INIT_FILE )
  )
  u_top_tx
  (
      .i_clock        (i_clock        ),
      .i_reset        (i_reset        ),
      .i_sw           (i_sw           ),
      .o_tx_full_symbI(o_tx_full_symbI),
      .o_tx_full_symbQ(o_tx_full_symbQ),
      .o_tx_symbI     (o_tx_symbI     ),
      .o_tx_symbQ     (o_tx_symbQ     ) 
  );

  // clock generator
  always #5 i_clock = ~i_clock;   

  // Block to monitor signals
  initial begin
    $monitor("Time: %0t | Reset: %b | i_sw: %b | o_tx_symbI: %d | o_tx_symbQ: %d", 
              $time, i_reset, i_sw, o_tx_symbI, o_tx_symbQ);
  end

  // Initial block for stimuli
  initial begin
    // Signal initialization
    i_clock   = 1'b0;
    i_reset = 1'b0;
    i_sw    = 4'b0000;

    // Open files for writing
    file_symb_txI      = $fopen("/home/danielito/Escritorio/run/ModuleFIlterTX/Module/logs/symbI_out_Tx.txt", "wb");
    file_symb_txQ      = $fopen("/home/danielito/Escritorio/run/ModuleFIlterTX/Module/logs/symbQ_out_Tx.txt", "wb");
    file_symb_full_txI = $fopen("/home/danielito/Escritorio/run/ModuleFIlterTX/Module/logs/symb_full_txI.txt", "wb");
    file_symb_full_txQ = $fopen("/home/danielito/Escritorio/run/ModuleFIlterTX/Module/logs/symb_full_txQ.txt", "wb");


    // Stimulus sequence
    #100; 
    i_reset = 1'b1; // Deactivate reset
    $display("Reset deactivated");
    
    #50; 
    i_sw = 4'b0001; // Activate PRBS and FIR
    $display("Activating PRBS and FIR");

    #500;
    i_sw = 4'b0010; // Activate BER
    $display("Activating BER");

    #500;
    i_sw = 4'b0111; // Complete configuration
    $display("Complete configuration activated");

    for (i = 0; i < n_logs; i = i + 1) begin
      $fwrite(file_symb_txI     , "%b\n", o_symb_txI     );
      $fwrite(file_symb_txQ     , "%b\n", o_symb_txQ     );
      $fwrite(file_symb_full_txI, "%b\n", o_symb_full_txI);
      $fwrite(file_symb_full_txQ, "%b\n", o_symb_full_txQ);
      #10; 
    end // End of for(i)

    $fclose(file_symb_txI     );
    $fclose(file_symb_txQ     );
    $fclose(file_symb_full_txI);
    $fclose(file_symb_full_txQ);

    $finish;

  end

endmodule