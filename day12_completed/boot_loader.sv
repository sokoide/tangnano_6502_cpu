// boot_loader.sv - ROM to RAM copy for Day 10
//
// Copies a small ROM program into RAM after reset so the CPU can run from BSRAM.

module boot_loader (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] cpu_address_bus,
    input  logic [ 7:0] cpu_data_out,
    input  logic        cpu_write_en,
    input  logic [ 7:0] rom_data_out,
    output logic        cpu_rst_n,
    output logic [15:0] rom_addr,
    output logic [14:0] ram_addr,
    output logic [ 7:0] ram_din,
    output logic        ram_we
);
    localparam int BOOT_LEN = 256;
    localparam int BOOT_INDEX_W = $clog2(BOOT_LEN);
    localparam int unsigned BOOT_MAX_U = BOOT_LEN - 1;
    localparam logic [BOOT_INDEX_W-1:0] BOOT_MAX = BOOT_MAX_U[BOOT_INDEX_W-1:0];
    logic [BOOT_INDEX_W-1:0] boot_index;
    logic                    boot_done;
    logic [            15:0] boot_addr;
    logic [            15:0] boot_index_ext;
    logic                    boot_active;

    assign boot_index_ext = {{(16 - BOOT_INDEX_W) {1'b0}}, boot_index};
    assign boot_addr = 16'h0200 + boot_index_ext;
    assign boot_active = !boot_done;
    assign cpu_rst_n = rst_n && boot_done;
    assign rom_addr = boot_active ? boot_addr : cpu_address_bus;
    assign ram_addr = boot_active ? boot_addr[14:0] : cpu_address_bus[14:0];
    assign ram_din = boot_active ? rom_data_out : cpu_data_out;
    assign ram_we = boot_active ? 1'b1 : (cpu_write_en && (!cpu_address_bus[15]));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            boot_index <= {BOOT_INDEX_W{1'b0}};
            boot_done  <= 1'b0;
        end else if (!boot_done) begin
            if (boot_index == BOOT_MAX) begin
                boot_done <= 1'b1;
            end else begin
                boot_index <= boot_index + 1'b1;
            end
        end
    end
endmodule
