// Simple RAM Module for 6502 System
// Implements basic RAM with synchronous read/write

/* verilator lint_off UNUSEDSIGNAL */
module simple_ram #(
    parameter ADDR_WIDTH = 15,  // 32KB RAM
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst_n,

    // Memory interface
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    input  logic                  we,        // Write enable
    input  logic                  oe,        // Output enable
    input  logic                  cs         // Chip select
);

    // RAM array
    logic [DATA_WIDTH-1:0] ram_array[0:(1<<ADDR_WIDTH)-1];

    // RAM operations
    always_ff @(posedge clk) begin
        if (cs && we) begin
            ram_array[addr] <= data_in;
        end
    end

    // Read operation
    always_comb begin
        if (cs && oe) begin
            data_out = ram_array[addr];
        end else begin
            data_out = 8'hZZ;  // High impedance when not selected
        end
    end

    /* verilator lint_on UNUSEDSIGNAL */
endmodule
