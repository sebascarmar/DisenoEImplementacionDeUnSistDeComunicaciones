`timescale 1ns / 1ps

module tb_top_phase_gen;

    parameter READ_DEPTH  = 2500;
    parameter READ_WIDTH  = 8   ;     
    parameter NB_OUTPUT   = 8   ;   
    parameter NBF_OUTPUT  = 6   ;   
    parameter NB_COEFF    = 8   ;   
    parameter NBF_COEFF   = 6   ;   
	parameter INIT_FILE_SIN = "/home/danielito/Escritorio/run/FaceGenerator/Modules/CuartoSin.dat", // path to the file with the data     
	parameter INIT_FILE_COS = "/home/danielito/Escritorio/run/FaceGenerator/Modules/CuartoCos.dat"  // 		

    parameter INIT_FILE_I = "/home/danielito/Escritorio/run/FaceGenerator/Modules/symbol_I.dat";
    parameter INIT_FILE_Q = "/home/danielito/Escritorio/run/FaceGenerator/Modules/symbol_Q.dat";


    reg                                i_clock        ;
    reg                                i_reset        ;
    reg                                i_enable       ;
    reg signed  [NB_OUTPUT-1:0]        i_dataI        ;
    reg signed  [NB_OUTPUT-1:0]        i_dataQ        ;
    wire signed [NB_INPUT+NB_OUTPUT:0] o_ph_full_symbI;
    wire signed [NB_INPUT+NB_OUTPUT:0] o_ph_full_symbQ;
    wire signed [NB_OUTPUT-1:0]        o_ph_symbI     ;
    wire signed [NB_OUTPUT-1:0]        o_ph_symbQ     ;

    // Variables for loading input data
    reg [NB_OUTPUT-1:0] symbol_I [0:(1024*50)-1];
    reg [NB_OUTPUT-1:0] symbol_Q [0:(1024*50)-1];
    integer i; 


    // Load data from files
    initial begin
        $readmemb(INIT_FILE_I, symbol_I, 0, (1024*50)-1);
        $readmemb(INIT_FILE_Q, symbol_Q, 0, (1024*50)-1);
    end  

    // Instantiate the top_rotation module
    top_phase_gen
    #(
        .READ_DEPTH   (READ_DEPTH   ), 
        .READ_WIDTH   (READ_WIDTH   ),  
        .NB_OUTPUT    (NB_OUTPUT    ), 
        .NBF_OUTPUT   (NBF_OUTPUT   ), 
        .NB_COEFF     (NB_COEFF     ), 
        .NBF_COEFF    (NBF_COEFF    ),
        .INIT_FILE_SIN(INIT_FILE_SIN),
        .INIT_FILE_COS(INIT_FILE_COS)
    )
    u_top_phase_gen
    (
        .i_clock        (i_clock        ),
        .i_reset        (i_reset        ),
        .i_enable       (i_enable       ),
        .i_dataI        (i_dataI        ),
        .i_dataQ        (i_dataQ        ),
        .o_ph_full_symbI(o_ph_full_symbI),
        .o_ph_full_symbQ(o_ph_full_symbQ),
        .o_ph_symbI     (o_ph_symbI     ),
        .o_ph_symbQ     (o_ph_symbQ     )
    );

    // Clock generation
    always #5 i_clock = ~i_clock;

    // Initial block to initialize and drive the signals
    initial begin
        i_clock  = 1'b0   ;
        i_reset  = 1'b1;
        i_enable = 1'b0;
        i_dataI  = 0;
        i_dataQ  = 0;
        #100;
        i_reset  = 1'b0;
        i_enable = 1'b1;

        for (i = 0; i < (1024*50); i = i + 1) begin
            i_dataI = symbol_I[i];
            i_dataQ = symbol_Q[i];
            #10;
        end 
        $finish;
    end

endmodule
