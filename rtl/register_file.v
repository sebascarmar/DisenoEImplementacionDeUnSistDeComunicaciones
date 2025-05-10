
//==========================================
//            Register file               //
//==========================================

module reg_file #(
  parameter NBT_GPIOS          = 32   ,
  parameter RAM_DEPTH          = 32768,
  parameter NBT_COUNT_BITS_ERR = 64
)(
    //  Input 
  output        [ $clog2(RAM_DEPTH)-1:0] o_read_adrs       ,
  output signed [         NBT_GPIOS-1:0] o_regf_to_gpio    ,
  output        [                   2:0] o_data_sel_for_log,
  output                                 o_en_write        ,
  output                                 o_en_read_from_ram,
  output                                 o_rst_soft        ,
  output                                 o_en_rx_soft      ,
  //  Output   
  input        [NBT_COUNT_BITS_ERR-1:0] i_accum_err_Q      ,
  input        [NBT_COUNT_BITS_ERR-1:0] i_accum_err_I      ,
  input        [NBT_COUNT_BITS_ERR-1:0] i_accum_bit_Q      ,
  input        [NBT_COUNT_BITS_ERR-1:0] i_accum_bit_I      ,
  input signed [         NBT_GPIOS-1:0] i_data_ram_for_read,
  input        [         NBT_GPIOS-1:0] i_gpio_to_regf     , 
  input                                 i_reset            ,
  input                                 clk                
);


  // wires 
  wire [NBT_GPIOS-1 :0] w_data_bits_and_errs;

  // Register 
  reg                          r_rst_soft              ;
  reg                          r_en_rx_soft            ;  
  reg                          r_en_read_bits_and_errs ;
  reg                          r_en_write              ;
  reg                          r_en_read_from_ram      ;
  reg                          r_log_bits_and_errs     ;
  reg [                   2:0] r_data_sel_for_log      ;
  reg [                   2:0] r_mux_read_bits_and_errs;
  reg [ $clog2(RAM_DEPTH)-1:0] r_read_adrs             ;
  reg [NBT_COUNT_BITS_ERR-1:0] r_accum_err_Q           ;
  reg [NBT_COUNT_BITS_ERR-1:0] r_accum_err_I           ;
  reg [NBT_COUNT_BITS_ERR-1:0] r_accum_bit_Q           ;
  reg [NBT_COUNT_BITS_ERR-1:0] r_accum_bit_I           ;


  always @(posedge clk)	begin      
    if(i_reset== 1'b1) begin
        r_rst_soft               <= 1'b1;
        r_en_rx_soft             <= 1'b1; 
        r_en_read_bits_and_errs  <= 1'b0;
        r_en_write               <= 1'b0;
        r_en_read_from_ram       <= 1'b0;
        r_log_bits_and_errs      <= 1'b0;
        r_data_sel_for_log       <= {3{1'b0}};
        r_mux_read_bits_and_errs <= {3{1'b0}};
        r_read_adrs              <= {$clog2(RAM_DEPTH){1'b0}};
        r_accum_err_Q            <= {NBT_COUNT_BITS_ERR{1'b0}};
        r_accum_err_I            <= {NBT_COUNT_BITS_ERR{1'b0}};
        r_accum_bit_Q            <= {NBT_COUNT_BITS_ERR{1'b0}};
        r_accum_bit_I            <= {NBT_COUNT_BITS_ERR{1'b0}};   
  
    end
    else begin   
                 
      if (i_gpio_to_regf[23] == 1'b1)begin
          case (i_gpio_to_regf[31:24])
              8'h01: begin
                  r_rst_soft               <= i_gpio_to_regf[0]       ;// 0 Reset for sys comm (nedge)
                  r_en_rx_soft             <= r_en_rx_soft            ;
                  r_en_read_bits_and_errs  <= r_en_read_bits_and_errs ; 
                  r_en_write               <= r_en_write              ; 
                  r_en_read_from_ram       <= r_en_read_from_ram      ; 
                  r_log_bits_and_errs      <= r_log_bits_and_errs     ; 
                  r_data_sel_for_log       <= r_data_sel_for_log      ; 
                  r_mux_read_bits_and_errs <= r_mux_read_bits_and_errs; 
                  r_read_adrs              <= r_read_adrs             ; 
                  r_accum_err_Q            <= r_accum_err_Q           ; 
                  r_accum_err_I            <= r_accum_err_I           ; 
                  r_accum_bit_Q            <= r_accum_bit_Q           ; 
                  r_accum_bit_I            <= r_accum_bit_I           ; 
              end
              
              8'h02: begin
                  r_en_rx_soft             <= i_gpio_to_regf[0]       ;// 0 Reset for sys comm (nedge)

                  r_rst_soft               <= r_rst_soft              ;
                  r_en_read_bits_and_errs  <= r_en_read_bits_and_errs ; 
                  r_en_write               <= r_en_write              ; 
                  r_en_read_from_ram       <= r_en_read_from_ram      ; 
                  r_log_bits_and_errs      <= r_log_bits_and_errs     ; 
                  r_data_sel_for_log       <= r_data_sel_for_log      ; 
                  r_mux_read_bits_and_errs <= r_mux_read_bits_and_errs; 
                  r_read_adrs              <= r_read_adrs             ; 
                  r_accum_err_Q            <= r_accum_err_Q           ; 
                  r_accum_err_I            <= r_accum_err_I           ; 
                  r_accum_bit_Q            <= r_accum_bit_Q           ; 
                  r_accum_bit_I            <= r_accum_bit_I           ; 
              end
              
              8'h03: begin
                  r_data_sel_for_log       <= i_gpio_to_regf[2:0]     ;	// 3 Login data in RAM,
                  r_en_write               <= i_gpio_to_regf[3]       ;	// Signal enbl for write data in RAM
                  
                  r_rst_soft               <= r_rst_soft              ;
                  r_en_rx_soft             <= r_en_rx_soft            ;
                  r_en_read_bits_and_errs  <= r_en_read_bits_and_errs ; 
                  r_en_read_from_ram       <= r_en_read_from_ram      ; 
                  r_log_bits_and_errs      <= r_log_bits_and_errs     ; 
                  r_mux_read_bits_and_errs <= r_mux_read_bits_and_errs; 
                  r_read_adrs              <= r_read_adrs             ; 
                  r_accum_err_Q            <= r_accum_err_Q           ; 
                  r_accum_err_I            <= r_accum_err_I           ; 
                  r_accum_bit_Q            <= r_accum_bit_Q           ; 
                  r_accum_bit_I            <= r_accum_bit_I           ; 
              end								 
              
              8'h04: begin // 4 Read data from RAM
                  r_en_read_from_ram                 <= i_gpio_to_regf[16]                   ;      
                  r_read_adrs[$clog2(RAM_DEPTH)-1:0] <= i_gpio_to_regf[$clog2(RAM_DEPTH)-1:0];// Addrs for read in RAM
                  
                  r_rst_soft                <= r_rst_soft              ;
                  r_en_rx_soft              <= r_en_rx_soft            ;
                  r_en_read_bits_and_errs   <= r_en_read_bits_and_errs ;  
                  r_en_write                <= r_en_write              ;  
                  r_log_bits_and_errs       <= r_log_bits_and_errs     ;  
                  r_data_sel_for_log        <= r_data_sel_for_log      ;  
                  r_mux_read_bits_and_errs  <= r_mux_read_bits_and_errs;  
                  r_accum_err_Q             <= r_accum_err_Q           ;  
                  r_accum_err_I             <= r_accum_err_I           ;  
                  r_accum_bit_Q             <= r_accum_bit_Q           ;  
                  r_accum_bit_I             <= r_accum_bit_I           ;  				
              end
             
              8'h05: begin 
                  r_log_bits_and_errs	   <= i_gpio_to_regf[0]       ;
                  
                  r_rst_soft               <= r_rst_soft              ; 
                  r_en_rx_soft             <= r_en_rx_soft            ;
                  r_en_read_bits_and_errs  <= r_en_read_bits_and_errs ;
                  r_en_write               <= r_en_write              ;
                  r_en_read_from_ram       <= r_en_read_from_ram      ;
                  r_data_sel_for_log       <= r_data_sel_for_log      ;
                  r_mux_read_bits_and_errs <= r_mux_read_bits_and_errs;
                  r_read_adrs              <= r_read_adrs             ;
                  r_accum_bit_I            <= r_accum_bit_I           ;
              end
              
              8'h06: begin
                  r_mux_read_bits_and_errs <= i_gpio_to_regf[2:0];  // 6 Read bits and err
                  r_en_read_bits_and_errs  <= i_gpio_to_regf[16] ;
                  
                  r_rst_soft              <= r_rst_soft         ; 
                  r_en_rx_soft            <= r_en_rx_soft       ;
                  r_en_write              <= r_en_write         ;
                  r_en_read_from_ram      <= r_en_read_from_ram ;
                  r_log_bits_and_errs     <= r_log_bits_and_errs;
                  r_read_adrs             <= r_read_adrs        ;
                  r_accum_err_Q           <= r_accum_err_Q      ;
                  r_accum_err_I           <= r_accum_err_I      ;
                  r_accum_bit_Q           <= r_accum_bit_Q      ;
                  r_accum_bit_I           <= r_accum_bit_I      ;
              end		
              
              default: begin 
                  r_rst_soft               <= r_rst_soft              ;                        
                  r_en_rx_soft             <= r_en_rx_soft            ;
                  r_en_read_bits_and_errs  <= r_en_read_bits_and_errs ; 
                  r_en_write               <= r_en_write              ; 
                  r_en_read_from_ram       <= r_en_read_from_ram      ; 
                  r_log_bits_and_errs      <= r_log_bits_and_errs     ; 
                  r_data_sel_for_log       <= r_data_sel_for_log      ; 
                  r_mux_read_bits_and_errs <= r_mux_read_bits_and_errs; 
                  r_read_adrs              <= r_read_adrs             ; 
                  r_accum_err_Q            <= r_accum_err_Q           ; 
                  r_accum_err_I            <= r_accum_err_I           ; 
                  r_accum_bit_Q            <= r_accum_bit_Q           ; 
                  r_accum_bit_I            <= r_accum_bit_I           ;
              end  
          endcase
  
          if (i_gpio_to_regf[31:24] == 8'h05 && r_log_bits_and_errs) begin
              r_accum_err_Q  <= i_accum_err_Q;	 
              r_accum_err_I  <= i_accum_err_I;	 
              r_accum_bit_Q  <= i_accum_bit_Q; 	 
              r_accum_bit_I  <= i_accum_bit_I; 	 
          end 
          else begin  
              r_accum_err_Q  <= r_accum_err_Q;
              r_accum_err_I  <= r_accum_err_I;
              r_accum_bit_Q  <= r_accum_bit_Q;
              r_accum_bit_I  <= r_accum_bit_I;
          end    
      end //Fin de if(i_gpio_to_regf[23] == 1'b1)

    end //Fin de else begin    
  end //Fin de always
  
  assign o_regf_to_gpio	=  (r_en_read_from_ram == 1'b1) ? i_data_ram_for_read
                            :((r_en_read_bits_and_errs == 1'b1)
                            ? w_data_bits_and_errs
                            : 32'b0); // Select data for Micro

  assign w_data_bits_and_errs = (r_mux_read_bits_and_errs == 3'b000)
                              ? r_accum_err_I [31:0]
                              :(r_mux_read_bits_and_errs == 3'b001)
                              ? r_accum_err_I [63:32]
                              :(r_mux_read_bits_and_errs == 3'b010)
                              ? r_accum_bit_I [31:0]
                              :(r_mux_read_bits_and_errs == 3'b011)
                              ? r_accum_bit_I [63:32]
                              :(r_mux_read_bits_and_errs == 3'b100)
                              ? r_accum_err_Q [31:0]
                              :(r_mux_read_bits_and_errs == 3'b101)
                              ? r_accum_err_Q [63:32]
                              :(r_mux_read_bits_and_errs == 3'b110)
                              ? r_accum_bit_Q [31:0]
                              : r_accum_bit_Q [63:32]              ;


  assign  o_data_sel_for_log = r_data_sel_for_log; 
  assign  o_en_write         = r_en_write        ; 
  assign  o_en_read_from_ram = r_en_read_from_ram; 
  assign  o_read_adrs        = r_read_adrs       ; 
  assign  o_rst_soft         = r_rst_soft        ;                             
  assign  o_en_rx_soft       = r_en_rx_soft      ; 

endmodule
