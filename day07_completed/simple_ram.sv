// Simple RAM Module for 6502 System
// Implements basic RAM with synchronous read/write

module simple_ram #(
    parameter ADDR_WIDTH = 15,  // 32KB RAM
    parameter DATA_WIDTH = 8
) (
    input  logic                    clk,
    input  logic                    rst_n,

    // Memory interface
    input  logic [ADDR_WIDTH-1:0]  addr,
    input  logic [DATA_WIDTH-1:0]  data_in,
    output logic [DATA_WIDTH-1:0]  data_out,
    input  logic                    we,      // Write enable
    input  logic                    oe,      // Output enable
    input  logic                    cs       // Chip select
);

    // RAM array
    logic [DATA_WIDTH-1:0] ram_array [0:(1<<ADDR_WIDTH)-1];

    // Initialize RAM with some test patterns
    initial begin
        for (int i = 0; i < (1<<ADDR_WIDTH); i++) begin
            ram_array[i] = 8'h00;
        end

        // Initialize zero page with some test values
        ram_array[16'h0000] = 8'h00;  // Zero page start
        ram_array[16'h0001] = 8'h01;
        ram_array[16'h0002] = 8'h02;
        ram_array[16'h0003] = 8'h03;

        // Initialize stack page
        ram_array[16'h0100] = 8'h00;  // Stack page start
        ram_array[16'h01FF] = 8'hFF;  // Stack top

        // Test data area
        ram_array[16'h0200] = 8'hAA;
        ram_array[16'h0201] = 8'h55;
        ram_array[16'h0202] = 8'hFF;
        ram_array[16'h0203] = 8'h00;
    end

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

endmodule