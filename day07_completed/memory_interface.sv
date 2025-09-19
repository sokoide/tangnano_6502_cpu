// 6502 Memory Interface Controller
// Handles memory read/write operations with proper timing

module memory_interface (
    input  logic        clk,
    input  logic        rst_n,

    // CPU interface
    input  logic [15:0] address,
    input  logic [7:0]  write_data,
    input  logic        mem_read,
    input  logic        mem_write,
    output logic [7:0]  read_data,
    output logic        ready,

    // Memory map control
    output logic        ram_cs,      // RAM chip select
    output logic        rom_cs,      // ROM chip select
    output logic        io_cs,       // I/O chip select

    // External memory interface
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_oe,      // Output enable
    output logic        mem_we       // Write enable
);

    // Memory map definitions
    // $0000-$7FFF: RAM (32KB)
    // $8000-$BFFF: I/O space (16KB)
    // $C000-$FFFF: ROM (16KB)

    logic [1:0] state;
    logic [1:0] next_state;

    // State machine states
    localparam IDLE  = 2'b00;
    localparam READ  = 2'b01;
    localparam WRITE = 2'b10;
    localparam WAIT  = 2'b11;

    // Address decoding
    always_comb begin
        ram_cs = (address[15] == 1'b0);                    // $0000-$7FFF
        rom_cs = (address[15:14] == 2'b11);                // $C000-$FFFF
        io_cs  = (address[15:14] == 2'b10);                // $8000-$BFFF
    end

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
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
            end

            WRITE: begin
                next_state = WAIT;
            end

            WAIT: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output control
    always_comb begin
        // Default values
        mem_addr = 16'h0000;
        mem_data_out = 8'h00;
        mem_oe = 1'b0;
        mem_we = 1'b0;
        read_data = 8'h00;
        ready = 1'b0;

        case (state)
            IDLE: begin
                ready = 1'b1;
            end

            READ: begin
                mem_addr = address;
                mem_oe = 1'b1;
                read_data = mem_data_in;
            end

            WRITE: begin
                mem_addr = address;
                mem_data_out = write_data;
                mem_we = 1'b1;
            end

            WAIT: begin
                ready = 1'b1;
                if (state == READ) begin
                    read_data = mem_data_in;
                end
            end
        endcase
    end

endmodule