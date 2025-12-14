# Day 08: CPU 実装 Part 3 - 統合とテスト

## 🎯 学習目標

- CPU各モジュールの統合と結合
- 命令実行サイクル制御の実装
- 基本的な6502プログラムによる動作テスト
- デバッグ手法とシミュレーション技術の習得

## 📚 理論学習

### 命令実行サイクル

**基本サイクル (最低2クロック):**

1. **フェッチ**: PCからオペコード読み出し
2. **デコード**: 命令解析とオペランド読み出し
3. **実行**: ALU演算とレジスタ更新
4. **ライトバック**: 結果の書き込み

**可変サイクル数:**

- アドレッシングモードにより2-7サイクル
- ページ境界越えで+1サイクル
- 分岐成功で+1サイクル

### CPUの状態機械

**主要状態:**

- FETCH: 命令フェッチ
- DECODE: 命令デコードとアドレス計算
- EXECUTE: ALU演算実行
- MEMORY: メモリアクセス
- WRITEBACK: 結果書き込み

## 🛠️ 実習1: CPU統合モジュール

```systemverilog
module cpu_6502 (
    input  logic clk,
    input  logic rst_n,

    // メモリインターフェース
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_read,
    output logic        mem_write,
    input  logic        mem_ready,

    // デバッグ用出力
    output logic [7:0]  debug_reg_a,
    output logic [7:0]  debug_reg_x,
    output logic [7:0]  debug_reg_y,
    output logic [7:0]  debug_reg_sp,
    output logic [15:0] debug_reg_pc,
    output logic [7:0]  debug_status,
    output logic [7:0]  debug_opcode,

    // 制御信号
    input  logic        cpu_enable,
    output logic        cpu_halted
);

    // 内部信号
    logic [7:0] current_opcode;
    logic [7:0] operand1, operand2;
    logic [15:0] effective_addr;

    // レジスタセット
    logic [7:0]  reg_a, reg_x, reg_y, reg_sp, status_reg;
    logic [15:0] reg_pc;

    // ALU関連
    logic [7:0]  alu_result;
    logic [3:0]  alu_op;
    logic        alu_carry_in, alu_carry_out;
    logic        alu_overflow, alu_negative, alu_zero;

    // 制御信号
    logic reg_a_write, reg_x_write, reg_y_write;
    logic reg_sp_write, reg_pc_write;
    logic update_nz, update_c, update_v;

    // 状態機械
    typedef enum logic [2:0] {
        STATE_FETCH,
        STATE_DECODE,
        STATE_EXECUTE,
        STATE_MEMORY,
        STATE_WRITEBACK,
        STATE_HALT
    } cpu_state_t;

    cpu_state_t current_state, next_state;
    logic [2:0] cycle_counter;

    // 状態遷移
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_FETCH;
            cycle_counter <= 3'b000;
            reg_pc <= 16'h0200;  // プログラム開始アドレス
        end else if (cpu_enable && mem_ready) begin
            current_state <= next_state;
            if (next_state != current_state) begin
                cycle_counter <= 3'b000;
            end else begin
                cycle_counter <= cycle_counter + 1;
            end
        end
    end

    // 次状態決定
    always_comb begin
        next_state = current_state;

        case (current_state)
            STATE_FETCH: begin
                if (mem_ready) begin
                    next_state = STATE_DECODE;
                end
            end

            STATE_DECODE: begin
                // 命令タイプに応じて分岐
                case (current_opcode)
                    8'hEF: next_state = STATE_HALT;  // HLT命令
                    default: next_state = STATE_EXECUTE;
                endcase
            end

            STATE_EXECUTE: begin
                // 実行完了判定 (命令により異なる)
                next_state = STATE_WRITEBACK;
            end

            STATE_MEMORY: begin
                if (mem_ready) begin
                    next_state = STATE_WRITEBACK;
                end
            end

            STATE_WRITEBACK: begin
                next_state = STATE_FETCH;
            end

            STATE_HALT: begin
                // ハルト状態維持
                next_state = STATE_HALT;
            end
        endcase
    end

    // メモリアクセス制御
    always_comb begin
        mem_addr = 16'h0000;
        mem_data_out = 8'h00;
        mem_read = 1'b0;
        mem_write = 1'b0;

        case (current_state)
            STATE_FETCH: begin
                mem_addr = reg_pc;
                mem_read = 1'b1;
            end

            STATE_DECODE: begin
                // オペランド読み出し
                if (cycle_counter == 0) begin
                    mem_addr = reg_pc + 1;
                    mem_read = 1'b1;
                end else if (cycle_counter == 1) begin
                    mem_addr = reg_pc + 2;
                    mem_read = 1'b1;
                end
            end

            STATE_MEMORY: begin
                mem_addr = effective_addr;
                if (/* store命令 */) begin
                    mem_write = 1'b1;
                    mem_data_out = reg_a;  // 例: STA命令
                end else begin
                    mem_read = 1'b1;
                end
            end
        endcase
    end

    // オペコード・オペランド取得
    always_ff @(posedge clk) begin
        if (current_state == STATE_FETCH && mem_ready) begin
            current_opcode <= mem_data_in;
        end else if (current_state == STATE_DECODE && mem_ready) begin
            if (cycle_counter == 0) begin
                operand1 <= mem_data_in;
            end else if (cycle_counter == 1) begin
                operand2 <= mem_data_in;
            end
        end
    end

    // CPU各モジュールのインスタンス化
    cpu_decoder decoder_inst (
        .opcode(current_opcode),
        .status_reg(status_reg),
        .alu_op(alu_op),
        .alu_carry_in(alu_carry_in),
        .reg_a_write(reg_a_write),
        // ... その他の制御信号
    );

    cpu_alu alu_inst (
        .operand_a(reg_a),
        .operand_b(mem_data_in),  // 簡略化
        .operation(alu_op),
        .carry_in(alu_carry_in),
        .result(alu_result),
        .carry_out(alu_carry_out),
        .overflow(alu_overflow),
        .negative(alu_negative),
        .zero(alu_zero)
    );

    // レジスタ更新
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= 8'h00;
            reg_x <= 8'h00;
            reg_y <= 8'h00;
            reg_sp <= 8'hFF;
            status_reg <= 8'h20;
        end else if (current_state == STATE_WRITEBACK) begin
            if (reg_a_write) reg_a <= alu_result;
            if (reg_x_write) reg_x <= alu_result;
            if (reg_y_write) reg_y <= alu_result;

            // フラグ更新
            if (update_nz) begin
                status_reg[7] <= alu_negative;
                status_reg[1] <= alu_zero;
            end
            if (update_c) status_reg[0] <= alu_carry_out;
            if (update_v) status_reg[6] <= alu_overflow;

            // PC更新
            reg_pc <= reg_pc + instruction_length;
        end
    end

    // デバッグ出力
    assign debug_reg_a = reg_a;
    assign debug_reg_x = reg_x;
    assign debug_reg_y = reg_y;
    assign debug_reg_sp = reg_sp;
    assign debug_reg_pc = reg_pc;
    assign debug_status = status_reg;
    assign debug_opcode = current_opcode;
    assign cpu_halted = (current_state == STATE_HALT);

endmodule
```

## 🛠️ 実習2: テストベンチ実装

```systemverilog
module tb_cpu_integration;

    logic clk;
    logic rst_n;
    logic [7:0] mem_data_in;
    logic [15:0] mem_addr;
    logic [7:0] mem_data_out;
    logic mem_read, mem_write;

    // メモリモデル (32KB)
    logic [7:0] memory [0:32767];

    // CPU インスタンス
    cpu_6502 cpu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_data_in(mem_data_in),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_ready(1'b1),
        .cpu_enable(1'b1)
    );

    // クロック生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // メモリアクセス
    always_comb begin
        if (mem_read) begin
            mem_data_in = memory[mem_addr[14:0]];
        end else begin
            mem_data_in = 8'h00;
        end
    end

    always_ff @(posedge clk) begin
        if (mem_write) begin
            memory[mem_addr[14:0]] <= mem_data_out;
        end
    end

    // テストプログラム実行
    initial begin
        // リセット
        rst_n = 0;
        #20 rst_n = 1;

        // テストプログラム1: LDA #$55
        memory[16'h0200] = 8'hA9;  // LDA Immediate
        memory[16'h0201] = 8'h55;  // オペランド

        // テストプログラム2: STA $80
        memory[16'h0202] = 8'h85;  // STA Zero Page
        memory[16'h0203] = 8'h80;  // アドレス

        // テストプログラム3: HLT
        memory[16'h0204] = 8'hEF;  // HLT命令

        // シミュレーション実行
        #1000;

        // 結果確認
        assert (cpu_inst.debug_reg_a == 8'h55) else
            $error("Test failed: A register should be 0x55");

        assert (memory[16'h0080] == 8'h55) else
            $error("Test failed: Memory[0x80] should be 0x55");

        $display("All tests passed!");
        $finish;
    end

    // 波形出力
    initial begin
        $dumpfile("cpu_test.vcd");
        $dumpvars(0, tb_cpu_integration);
    end

endmodule
```

## 🛠️ 実習3: より複雑なテストプログラム

```assembly
; 6502 Assembly Test Program
; カウンタプログラム

.org $0200

START:
    LDA #$00        ; A = 0
    STA $80         ; メモリ[0x80] = A

LOOP:
    LDA $80         ; A = メモリ[0x80]
    CLC             ; キャリアクリア
    ADC #$01        ; A = A + 1
    STA $80         ; メモリ[0x80] = A
    CMP #$10        ; A と 16 を比較
    BNE LOOP        ; A ≠ 16 なら LOOP へ

    HLT             ; プログラム終了
```

対応するSystemVerilogテストベンチ:

```systemverilog
// テストプログラムをメモリに書き込み
initial begin
    memory[16'h0200] = 8'hA9; memory[16'h0201] = 8'h00; // LDA #$00
    memory[16'h0202] = 8'h85; memory[16'h0203] = 8'h80; // STA $80
    memory[16'h0204] = 8'hA5; memory[16'h0205] = 8'h80; // LDA $80
    memory[16'h0206] = 8'h18;                            // CLC
    memory[16'h0207] = 8'h69; memory[16'h0208] = 8'h01; // ADC #$01
    memory[16'h0209] = 8'h85; memory[16'h020A] = 8'h80; // STA $80
    memory[16'h020B] = 8'hC9; memory[16'h020C] = 8'h10; // CMP #$10
    memory[16'h020D] = 8'hD0; memory[16'h020E] = 8'hF5; // BNE LOOP (-11)
    memory[16'h020F] = 8'hEF;                            // HLT
end
```

## 📝 課題

### 基礎課題

1. 分岐命令の実装とテスト
2. スタック操作のテスト (JSR/RTS)
3. 算術演算のフラグ動作確認

### 発展課題

1. 割り込み処理の基本実装
2. パフォーマンス最適化
3. エラー検出機能の追加

## 🔧 デバッグ技法

### 1. 波形解析

- クロックサイクル単位での動作確認
- 信号のタイミング関係
- 状態遷移の確認

### 2. アサーション

- 期待値との比較
- 不正状態の検出
- レジスタ値の妥当性確認

### 3. ログ出力

```systemverilog
always_ff @(posedge clk) begin
    if (current_state == STATE_FETCH) begin
        $display("Time %t: Fetch PC=%04X, Opcode=%02X",
                 $time, reg_pc, mem_data_in);
    end
end
```

## 📚 今日学んだこと

- [ ] CPU各モジュールの統合方法
- [ ] 命令実行サイクルの実装
- [ ] 状態機械による制御
- [ ] テストベンチの設計
- [ ] デバッグ技法の活用

## 🎯 明日の予習

Day 09ではLCD制御とシステム統合を学習します:

- LCD タイミング制御
- 文字表示システム
- VRAM の実装
