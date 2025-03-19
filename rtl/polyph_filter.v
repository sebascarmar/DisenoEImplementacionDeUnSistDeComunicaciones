`timescale 1ns/1ps


module polyph_filter #(
    parameter NBT_OUT     = 8  ,
    parameter NBF_OUT     = 7  ,
    parameter NBT_COEF_TX = 8  ,
    parameter NBF_COEF_TX = 7  , 
    parameter NBAUD       = 5+1,
    parameter OS          = 4
)
(
    output signed [   NBT_OUT-1:0] o_os_data           , 
    
    input                          i_is_data           , 
    input         [$clog2(OS)-1:0] i_phase_num_of_coeff,
    input                          i_ctrl              ,
    input                          i_reset             , 
    input                          clk        
);
  
  // Local parameters for internal operations and output saturation
  localparam NBT_ADD = NBT_COEF_TX+$clog2(NBAUD);
  localparam NBI_ADD = NBT_ADD - NBF_COEF_TX    ;
  localparam NBI_OUT = NBT_OUT - NBF_OUT        ;
  localparam NB_SAT  = NBI_ADD - NBI_OUT        ; 
  
  // Internal registers and wires
  reg         [            NBAUD:1] shiftreg               ; 
  reg  signed [    NBT_COEF_TX-1:0] coeff    [NBAUD*OS-1:0];
  wire signed [    NBT_COEF_TX-1:0] part_prod[     NBAUD:1];
  wire signed [NBT_ADD-1:0]         add                    ;
  
  // Load the filter coefficient values
  localparam INIT_FILE_COEFF    = "./../../../../../../../fixed_point/logs/coeffs_txf.dat";
  initial begin
    $readmemb (INIT_FILE_COEFF, coeff);    
  end   
  
  
  // Shift register: Sequentially updates input bits (representing QPSK symbols)
  integer i;
  always @(posedge clk) begin:shiftRegister
    if (i_reset == 1'b1) begin
        shiftreg <= {6'b0};
    end
    else begin
        if (i_ctrl==1'b1) begin
            for(i=1 ; i<=6 ; i=i+1) begin:shift
                if(i==1) begin
                    shiftreg[i] <= i_is_data;
                end
                else begin
                    shiftreg[i] <= shiftreg[i-1];
                end   
            end
        end
        else begin
            shiftreg <= shiftreg;
        end
    end
  end
  
  
  // Compute partial products based on filter phase and stored symbols (1 or -1)
  assign part_prod[1] =   i_phase_num_of_coeff==2'b00 ? ((shiftreg[1] == 1'b1) ? -coeff[ 0] : coeff[ 0])
                        : i_phase_num_of_coeff==2'b01 ? ((shiftreg[1] == 1'b1) ? -coeff[ 1] : coeff[ 1])
                        : i_phase_num_of_coeff==2'b10 ? ((shiftreg[1] == 1'b1) ? -coeff[ 2] : coeff[ 2])
                        :                               ((shiftreg[1] == 1'b1) ? -coeff[ 3] : coeff[ 3]);
  
  assign part_prod[2] =   i_phase_num_of_coeff==2'b00 ? ((shiftreg[2] == 1'b1) ? -coeff[ 4] : coeff[ 4])
                        : i_phase_num_of_coeff==2'b01 ? ((shiftreg[2] == 1'b1) ? -coeff[ 5] : coeff[ 5])
                        : i_phase_num_of_coeff==2'b10 ? ((shiftreg[2] == 1'b1) ? -coeff[ 6] : coeff[ 6])
                        :                               ((shiftreg[2] == 1'b1) ? -coeff[ 7] : coeff[ 7]);
  
  assign part_prod[3] =   i_phase_num_of_coeff==2'b00 ? ((shiftreg[3] == 1'b1) ? -coeff[ 8] : coeff[ 8])
                        : i_phase_num_of_coeff==2'b01 ? ((shiftreg[3] == 1'b1) ? -coeff[ 9] : coeff[ 9])
                        : i_phase_num_of_coeff==2'b10 ? ((shiftreg[3] == 1'b1) ? -coeff[10] : coeff[10])
                        :                               ((shiftreg[3] == 1'b1) ? -coeff[11] : coeff[11]);
  
  assign part_prod[4] =   i_phase_num_of_coeff==2'b00 ? ((shiftreg[4] == 1'b1) ? -coeff[12] : coeff[12])
                        : i_phase_num_of_coeff==2'b01 ? ((shiftreg[4] == 1'b1) ? -coeff[13] : coeff[13])
                        : i_phase_num_of_coeff==2'b10 ? ((shiftreg[4] == 1'b1) ? -coeff[14] : coeff[14])
                        :                               ((shiftreg[4] == 1'b1) ? -coeff[15] : coeff[15]);
  
  assign part_prod[5] =   i_phase_num_of_coeff==2'b00 ? ((shiftreg[5] == 1'b1) ? -coeff[16] : coeff[16])
                        : i_phase_num_of_coeff==2'b01 ? ((shiftreg[5] == 1'b1) ? -coeff[17] : coeff[17])
                        : i_phase_num_of_coeff==2'b10 ? ((shiftreg[5] == 1'b1) ? -coeff[18] : coeff[18])
                        :                               ((shiftreg[5] == 1'b1) ? -coeff[19] : coeff[19]);
  
  assign part_prod[6] =   i_phase_num_of_coeff==2'b00 ? ((shiftreg[6] == 1'b1) ? -coeff[20] : coeff[20])
                        : i_phase_num_of_coeff==2'b01 ? ((shiftreg[6] == 1'b1) ? -coeff[21] : coeff[21])
                        : i_phase_num_of_coeff==2'b10 ? ((shiftreg[6] == 1'b1) ? -coeff[22] : coeff[22])
                        :                               ((shiftreg[6] == 1'b1) ? -coeff[23] : coeff[23]);
  
  
  // Add all the partial products
  assign add = part_prod[6] + part_prod[5] + part_prod[4] + part_prod[3] + part_prod[2] + part_prod[1];
    
  // Output assignment: Apply saturation and truncation to S(8,7) format
  assign o_os_data  = ( ~|add[(NBT_ADD-1) -: NBI_ADD] || &add[(NBT_ADD-1) -: NBI_ADD])
                        ? add[(NBT_ADD-1)-NB_SAT -: NBT_OUT]
                        :( (add[NBT_ADD-1])
                           ? { 1'b1, {(NBT_OUT-1){1'b0}} }
                           : { 1'b1, {(NBT_OUT-1){1'b0}} } );


endmodule

