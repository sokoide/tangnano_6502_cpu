// Day 06: Data Movement (LDA Immediate) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Instruction Fetch and Decode / 命令フェッチ (Fetch) とデコード (Decode)
// 2. Implementation of A register / A レジスタの実装
// 3. Immediate Addressing / 即値アドレッシング (Immediate Addressing)

module cpu (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [ 7:0] data_in,      // Data from memory
    output logic [15:0] address_bus,
    output logic [ 7:0] debug_a,
    output logic [15:0] debug_pc
);

    logic [15:0] pc;
    logic [ 7:0] a;
    logic [ 7:0] ir;  // Instruction Register

    typedef enum logic [1:0] {
        S_FETCH,
        S_DECODE,
        S_EXECUTE
    } state_t;
    state_t state;

    // -------------------------------------------------------------------------
    // TODO: Implementation of A register and LDA instruction
    // TODO: A レジスタと LDA 命令の実装
    // -------------------------------------------------------------------------
    // 1. At reset: / リセット時:
    //    PC = 0x8000, A = 0x00, state = S_FETCH
    //
    // 2. S_FETCH:
    //    Read the instruction from memory (data_in) and store it in IR.
    //    メモリから命令を読み込み (data_in)、IR に格納します。
    //    Increment PC by 1 and transition to state = S_DECODE.
    //    PC を 1 増加させ、state = S_DECODE に遷移します。
    //
    // 3. S_DECODE:
    //    Determine if it is LDA Immediate (0xA9).
    //    LDA Immediate (0xA9) かどうかを判定します。
    //    Transition to state = S_EXECUTE to read the immediate value (next byte).
    //    即値（次のバイト）を読み込むため、state = S_EXECUTE に遷移します。
    //
    // 4. S_EXECUTE (for LDA): / 4. S_EXECUTE (LDAの場合):
    //    Store the value of data_in in the A register.
    //    data_in の値を A レジスタに格納します。
    //    Increment PC by 1 and return to state = S_FETCH.
    //    PC を 1 増加させ、state = S_FETCH に戻ります。

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
            a <= 8'h00;
            ir <= 8'h00;
            state <= S_FETCH;
        end else begin
            case (state)
                S_FETCH: begin
                    // TODO: Fetch
                end
                S_DECODE: begin
                    // TODO: Decode
                end
                S_EXECUTE: begin
                    // TODO: Execute
                end
            endcase
        end
    end

    assign address_bus = pc;
    assign debug_a = a;
    assign debug_pc = pc;

endmodule
