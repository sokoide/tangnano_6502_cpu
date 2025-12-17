`include "include/consts.svh"

module memory_interface_lcd (
    input logic clk,
    input logic rst_n,

    input  logic [15:0] address,
    input  logic [ 7:0] write_data,
    input  logic        mem_read,
    input  logic        mem_write,
    output logic [ 7:0] read_data,
    output logic        ready,

    output logic ram_cs,
    output logic rom_cs,
    output logic io_cs,
    output logic vram_cs,

    output logic [15:0] mem_addr,
    output logic [ 7:0] mem_data_out,
    input  logic [ 7:0] mem_data_in,
    output logic        mem_oe,
    output logic        mem_we
);

    logic [1:0] state;
    logic [1:0] next_state;
    logic [7:0] read_latch;
    logic       is_vram_addr;
    logic       is_boot_addr;

    localparam IDLE  = 2'b00;
    localparam READ  = 2'b01;
    localparam WRITE = 2'b10;
    localparam WAIT  = 2'b11;

    always_comb begin
        is_vram_addr = (address >= VRAM_START) && (address < VRAM_START + VRAM_DEPTH);
        is_boot_addr = (address >= PROGRAM_START) && (address < BOOT_ROM_END);
        io_cs = (address[15:14] == 2'b10);
        rom_cs = is_boot_addr && mem_read;
        ram_cs = (address[15] == 1'b0) && !is_boot_addr;
        vram_cs = is_vram_addr && mem_write;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            read_latch <= 8'h00;
        end else begin
            state <= next_state;
            if (state == READ) begin
                read_latch <= mem_data_in;
            end
        end
    end

    always_comb begin
        mem_addr = address;
        mem_data_out = write_data;
        mem_oe = 1'b0;
        mem_we = 1'b0;
        read_data = read_latch;
        ready = 1'b0;

        case (state)
            IDLE: begin
                if (mem_read || mem_write) begin
                    next_state = mem_read ? READ : WRITE;
                end else begin
                    next_state = IDLE;
                end
            end

            READ: begin
                next_state = WAIT;
                mem_addr = address;
                mem_oe = 1'b1;
            end

            WRITE: begin
                next_state = WAIT;
                mem_addr = address;
                mem_data_out = write_data;
                mem_we = 1'b1;
            end

            WAIT: begin
                ready = 1'b1;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase

        if (state == IDLE && !(mem_read || mem_write)) begin
            ready = 1'b1;
        end
    end

endmodule
