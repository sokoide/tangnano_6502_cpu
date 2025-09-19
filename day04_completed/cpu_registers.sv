// 6502 CPU Register Set
// Complete register implementation for 6502 processor

module cpu_registers (
    input  logic clk,
    input  logic rst_n,

    // Register control
    input  logic a_write,
    input  logic x_write,
    input  logic y_write,
    input  logic sp_write,
    input  logic pc_write,
    input  logic p_write,

    // Data bus
    input  logic [7:0]  data_in,
    input  logic [15:0] addr_in,

    // Register outputs
    output logic [7:0]  reg_a,
    output logic [7:0]  reg_x,
    output logic [7:0]  reg_y,
    output logic [7:0]  reg_sp,
    output logic [15:0] reg_pc,
    output logic [7:0]  reg_p
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a  <= 8'h00;
            reg_x  <= 8'h00;
            reg_y  <= 8'h00;
            reg_sp <= 8'hFF;        // Stack starts at top
            reg_pc <= 16'h0200;     // Program start address
            reg_p  <= 8'h20;        // Interrupt disable + unused bit
        end else begin
            if (a_write)  reg_a  <= data_in;
            if (x_write)  reg_x  <= data_in;
            if (y_write)  reg_y  <= data_in;
            if (sp_write) reg_sp <= data_in;
            if (pc_write) reg_pc <= addr_in;
            if (p_write)  reg_p  <= data_in;
        end
    end

endmodule