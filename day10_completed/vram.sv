`include "include/consts.svh"

module vram (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       cpu_we,
    input  logic [9:0] cpu_addr,
    input  logic [7:0] cpu_data,

    input  logic [9:0] lcd_addr,
    output logic [7:0] lcd_data
);

`ifdef VERILATOR
    localparam int DEPTH = COLUMNS * ROWS;

    logic [7:0] ram [0:DEPTH-1];
    logic [9:0] lcd_addr_reg;
    logic [7:0] lcd_data_reg;

    assign lcd_data = lcd_data_reg;

    initial begin
        for (int idx = 0; idx < DEPTH; idx = idx + 1) begin
            ram[idx] = 8'h20;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lcd_addr_reg <= 10'd0;
            lcd_data_reg <= 8'h20;
        end else begin
            lcd_addr_reg <= lcd_addr;
            lcd_data_reg <= ram[lcd_addr_reg];
            if (cpu_we) begin
                ram[cpu_addr] <= cpu_data;
            end
        end
    end
`else
    // Synthesis path: use Gowin SDPB (single write port + single read port)
    // This avoids DPB WRITE_MODE0=2'b10 errors on Tang Nano.
    Gowin_SDPB_vram vram_inst (
        .dout  (lcd_data),
        .clka  (clk),
        .cea   (cpu_we),
        .reseta(1'b0),
        .clkb  (clk),
        .ceb   (1'b1),
        .resetb(1'b0),
        .oce   (1'b1),
        .ada   (cpu_addr),
        .din   (cpu_data),
        .adb   (lcd_addr)
    );
`endif

endmodule

