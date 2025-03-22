`timescale 1ns/1ps


module polyph_filter #(
    parameter FILE_COEFF = "",
    parameter NBT_COEF   = 8  ,
    parameter NBF_COEF   = 7  , 
    parameter NBT_OUT    = 8  ,
    parameter NBF_OUT    = 7  ,
    parameter NBAUD      = 5+1,
    parameter OS         = 4
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
  localparam NBT_ADD = NBT_COEF+$clog2(NBAUD);
  localparam NBI_ADD = NBT_ADD - NBF_COEF    ;
  localparam NBI_OUT = NBT_OUT - NBF_OUT     ;
  localparam NB_SAT  = NBI_ADD - NBI_OUT     ; 
  
  // Internal registers and wires
  reg         [     NBAUD:1] r_shifter               ; 
  reg  signed [NBT_COEF-1:0] r_coeff    [NBAUD*OS-1:0];
  wire signed [NBT_COEF-1:0] w_part_prod[     NBAUD:1]; // it's because optimization due QPSK mod.
  wire signed [ NBT_ADD-1:0] w_add                    ;
  
  // Load the filter coefficient values
  initial begin
    $readmemb (FILE_COEFF, r_coeff);    
  end   
  
  
  // Shift register: Sequentially updates input bits (representing QPSK symbols)
  integer i;
  always @(posedge clk) begin:shiftRegister
    if (i_reset == 1'b1) begin
        r_shifter <= {6'b0};
    end
    else begin
        if (i_ctrl==1'b1) begin
            for(i=1 ; i<=6 ; i=i+1) begin:shift
                if(i==1) begin
                    r_shifter[i] <= i_is_data;
                end
                else begin
                    r_shifter[i] <= r_shifter[i-1];
                end   
            end
        end
        else begin
            r_shifter <= r_shifter;
        end
    end
  end
  
  
  // Compute partial products based on filter phase and stored symbols (1 or -1)
  genvar j;
  generate
      for (j=1; j<=NBAUD ; j=j+1) begin
          assign w_part_prod[j] = (r_shifter[j] == 1'b1) 
                                   ? -r_coeff[(j-1)*OS + i_phase_num_of_coeff]
                                   :  r_coeff[(j-1)*OS + i_phase_num_of_coeff];
      end
  endgenerate
  
  // Add all the partial products
  assign w_add = w_part_prod[6] + w_part_prod[5] + w_part_prod[4] + w_part_prod[3] + w_part_prod[2] + w_part_prod[1];
    

  // Output assignment: Apply saturation and truncation to S(8,7) format
  assign o_os_data  = ( ~|w_add[(NBT_ADD-1) -: NBI_ADD] || &w_add[(NBT_ADD-1) -: NBI_ADD])
                        ? w_add[(NBT_ADD-1)-NB_SAT -: NBT_OUT]
                        :( (w_add[NBT_ADD-1])
                           ? { 1'b1, {(NBT_OUT-1){1'b0}} }
                           : { 1'b0, {(NBT_OUT-1){1'b1}} } );


endmodule

