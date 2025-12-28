// Day 15: Control Flow & Basic Memory (Memory Map Integration) - Skeleton
//
// 学習目標:
// 1. メモリマップド I/O の理解
// 2. ROM (プログラム) と RAM (データ) の共存
// 3. 複雑なステートマシンの整理

`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pc_enable,
    output logic [15:0] address_bus,
    input  logic [ 7:0] data_in,
    output logic [ 7:0] data_out,
    output logic        write_en,
    output logic [15:0] debug_pc,
    output logic [ 7:0] debug_a,
    output logic [ 7:0] debug_x,
    output logic [ 7:0] debug_y,
    output logic [ 7:0] debug_p,
    output logic [ 7:0] debug_s
);

    logic [15:0] pc;
    logic [ 7:0] a, x, y, s;
    logic n, v, z, c;

    typedef enum logic [2:0] {
        S_FETCH_OPCODE,
        S_FETCH_OPERAND,
        S_FETCH_LOW,
        S_FETCH_HIGH,
        S_EXECUTE
    } state_t;
    state_t state;
    logic [7:0] current_opcode;
    logic [15:0] temp_addr;

    // -------------------------------------------------------------------------
    // TODO: メモリマップに基づく命令の最終調整
    // -------------------------------------------------------------------------
    // これまでに実装した以下の命令がすべて正しく動作するように統合してください：
    // - LDA (imm, zp, abs), STA (zp, abs)
    // - LDX/LDY (imm, zp), STX/STY (zp)
    // - ADC/SBC (imm)
    // - TAX, TAY, TXA, TYA, INX, INY, CLC, SEC
    // - JMP (abs)
    // - BNE, BEQ, BPL, BMI (rel)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
            a <= 8'h00; x <= 8'h00; y <= 8'h00; s <= 8'hFF;
            n <= 1'b0; v <= 1'b0; z <= 1'b0; c <= 1'b0;
            state <= S_FETCH_OPCODE;
            write_en <= 1'b0;
        end else if (pc_enable) begin
            write_en <= 1'b0;
            case (state)
                S_FETCH_OPCODE: begin
                    current_opcode <= data_in;
                    // ...
                    pc <= pc + 1;
                end
                // ...
            endcase
        end
    end

    assign address_bus = pc;
    assign debug_pc = pc;
    assign debug_a = a;
    assign debug_x = x;
    assign debug_y = y;
    assign debug_p = {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};
    assign debug_s = s;

endmodule