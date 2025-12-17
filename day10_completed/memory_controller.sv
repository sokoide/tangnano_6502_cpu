module memory_controller (
    input logic clk,
    input logic rst_n,
    input logic [15:0] cpu_addr,
    input logic [ 7:0] cpu_data_out,
    output logic [ 7:0] cpu_data_in,
    input logic        cpu_mem_read,
    input logic        cpu_mem_write,
    output logic       cpu_ready,
    input logic        stack_push,
    input logic        stack_pop,
    input logic [ 7:0] stack_data_out,
    output logic [ 7:0] stack_data_in,
    output logic [ 7:0] stack_pointer,
    output logic [15:0] ext_addr,
    output logic [ 7:0] ext_data_out,
    input logic [ 7:0] ext_data_in,
    output logic       ext_oe,
    output logic       ext_we,
    output logic       ram_select,
    output logic       rom_select,
    output logic       io_select,
    output logic       vram_select
);

    logic [15:0] mem_address;
    logic [ 7:0] mem_write_data;
    logic [ 7:0] mem_read_data;
    logic        mem_read_req;
    logic        mem_write_req;
    logic        mem_ready;

    logic [15:0] stack_address;
    logic        stack_overflow;
    logic        stack_underflow;

    stack_pointer sp_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .push           (stack_push),
        .pop            (stack_pop),
        .load_sp        (1'b0),
        .sp_data        (8'h00),
        .sp             (stack_pointer),
        .stack_addr     (stack_address),
        .stack_overflow (stack_overflow),
        .stack_underflow(stack_underflow)
    );

    memory_interface_lcd mem_if (
        .clk(clk),
        .rst_n(rst_n),
        .address(mem_address),
        .write_data(mem_write_data),
        .mem_read(mem_read_req),
        .mem_write(mem_write_req),
        .read_data(mem_read_data),
        .ready(mem_ready),
        .ram_cs(ram_select),
        .rom_cs(rom_select),
        .io_cs(io_select),
        .vram_cs(vram_select),
        .mem_addr(ext_addr),
        .mem_data_out(ext_data_out),
        .mem_data_in(ext_data_in),
        .mem_oe(ext_oe),
        .mem_we(ext_we)
    );

    always_comb begin
        if (stack_push || stack_pop) begin
            mem_address = stack_address;
            mem_write_data = stack_data_out;
            mem_read_req = stack_pop;
            mem_write_req = stack_push;

            cpu_data_in = 8'h00;
            cpu_ready = mem_ready;

            stack_data_in = mem_read_data;
        end else begin
            mem_address = cpu_addr;
            mem_write_data = cpu_data_out;
            mem_read_req = cpu_mem_read;
            mem_write_req = cpu_mem_write;

            cpu_data_in = mem_read_data;
            cpu_ready = mem_ready;

            stack_data_in = 8'h00;
        end
    end

    always_ff @(posedge clk) begin
        if (stack_overflow) begin
            $error("Stack overflow detected at addr=%h", stack_address);
        end
        if (stack_underflow) begin
            $error("Stack underflow detected");
        end
    end

endmodule
