module boot_rom #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst_n,
    input logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data_out,
    input logic oe,
    input logic cs
);

`include "include/consts.svh"
`include "include/boot_program.sv"

    localparam logic [DATA_WIDTH-1:0] FILL_BYTE = 8'hEA;

    always_comb begin
        if (cs && oe && addr >= PROGRAM_START && addr < BOOT_ROM_END) begin
            data_out = boot_program[addr - PROGRAM_START];
        end else if (cs && oe) begin
            data_out = FILL_BYTE;
        end else begin
            data_out = 'bz;
        end
    end

endmodule
