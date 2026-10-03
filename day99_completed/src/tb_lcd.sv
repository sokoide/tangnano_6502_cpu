// Compatibility entry point for the self-checking pixel test.
`include "tb_lcd_pipeline.sv"
module tb_lcd;
  tb_lcd_pipeline checks();
endmodule
