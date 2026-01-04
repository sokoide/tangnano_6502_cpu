`include "include/consts.svh"

module vram (
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic       clk,
    input  logic       rst_n,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic [9:0] addr,
    output logic [7:0] data
);

    localparam int DEPTH = COLUMNS * ROWS;

    localparam int ROW0_LEN = 9;
    localparam logic [7:0] ROW0_TEXT[0:ROW0_LEN-1] = '{"V", "R", "A", "M", " ", "T", "E", "X", "T"};
    localparam int ROW1_LEN = 8;
    localparam logic [7:0] ROW1_TEXT[0:ROW1_LEN-1] = '{"C", "H", "A", "R", " ", "L", "C", "D"};
    localparam int ROW2_LEN = 9;
    localparam logic [7:0] ROW2_TEXT[0:ROW2_LEN-1] = '{"F", "P", "G", "A", " ", "S", "H", "O", "W"};

    logic [7:0] ram[0:DEPTH-1];
    integer idx;

    assign data = ram[addr];

    initial begin
        for (idx = 0; idx < DEPTH; idx = idx + 1) begin
            ram[idx] = 8'h20;
        end

        for (idx = 0; idx < ROW0_LEN; idx = idx + 1) begin
            ram[1*COLUMNS+4+idx] = ROW0_TEXT[idx];
        end

        for (idx = 0; idx < ROW1_LEN; idx = idx + 1) begin
            ram[5*COLUMNS+8+idx] = ROW1_TEXT[idx];
        end

        for (idx = 0; idx < ROW2_LEN; idx = idx + 1) begin
            ram[9*COLUMNS+10+idx] = ROW2_TEXT[idx];
        end
    end

endmodule
