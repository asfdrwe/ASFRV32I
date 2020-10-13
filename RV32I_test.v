module RV32I_test;
  reg clock = 1'b0;
  reg reset_n = 1'b0;
  wire [31:0] pc_out, op_out, alu_out;
  
  RV32I rv1(clock, reset_n, pc_out, op_out, alu_out);

  initial begin
    $dumpfile("RV32I.vcd");
    $dumpvars(0, RV32I_test);
    $monitor("%t: PC = %h, OPCODE = %h, ALU_DATA = %h",
             $time, pc_out, op_out, alu_out);
  end

  initial begin
    clock = 1'b0;
    forever begin
      #1 clock = ~clock;
    end
  end

  initial begin
    reset_n = 1'b0;

    #1 reset_n = 1'b1;
    #5000 $finish;
  end

endmodule
