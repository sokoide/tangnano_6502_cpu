/* verilator lint_off DECLFILENAME */
// READ_MODE=0 simulation using the real MI font, not an all-zero placeholder.
module Gowin_pROM_font #(parameter FONT_FILE = "data/font.mi") (
  output logic [7:0] dout,
  input logic clk, oce, ce, reset,
  input logic [11:0] ad
);
  logic [7:0] rom[0:4095];
  integer fd, count, parsed, value;
  string line;
  initial begin
    fd = $fopen(FONT_FILE, "r");
    if (!fd) $fatal(1, "Cannot open font %s", FONT_FILE);
    for (int i=0; i<4096; i++) rom[i]=0;
    count = 0;
    while ($fgets(line, fd)) begin
      if (line.len() > 0 && line.getc(0) != 8'h23) begin
        parsed = $sscanf(line, "%h", value);
        if (parsed != 1 || value < 0 || value > 255 || count >= 4096)
          $fatal(1, "Invalid font MI data at byte %0d", count);
        rom[count] = 8'(value);
        count++;
      end
    end
    $fclose(fd);
    // MI contains the supported 128 characters; vendor initializes the rest to zero.
    if (count != 2048) $fatal(1, "Expected 2048 font bytes, got %0d", count);
    dout = 0;
  end
  always_ff @(posedge clk) begin
    if (reset) dout <= 0;
    else if (ce) dout <= rom[ad];
  end
endmodule
/* verilator lint_on DECLFILENAME */
