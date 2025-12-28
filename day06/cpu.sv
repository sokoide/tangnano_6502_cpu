// Day 06: Data Movement (LDA Immediate) - Skeleton
//
// 学習目標:
// 1. 命令フェッチ (Fetch) とデコード (Decode)
// 2. A レジスタの実装
// 3. 即値アドレッシング (Immediate Addressing)

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
    // TODO: A レジスタと LDA 命令の実装
    // -------------------------------------------------------------------------
    // 1. リセット時:
    //    PC = 0x8000, A = 0x00, state = S_FETCH
    //
    // 2. S_FETCH:
    //    メモリから命令を読み込み (data_in)、IR に格納します。
    //    PC を 1 増加させ、state = S_DECODE に遷移します。
    //
    // 3. S_DECODE:
    //    LDA Immediate (0xA9) かどうかを判定します。
    //    即値（次のバイト）を読み込むため、state = S_EXECUTE に遷移します。
    //
    // 4. S_EXECUTE (LDAの場合):
    //    data_in の値を A レジスタに格納します。
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
