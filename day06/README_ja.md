# Day 06: CPU 実装 Part 1 - デコーダとALU

## 🎯 学習目標

- 完全な命令デコーダの設計と実装
- 6502互換ALUの詳細実装
- フラグ生成ロジックの正確な実装
- マイクロ命令制御の概念理解

## 📚 理論学習

### 命令デコーダの設計方針

**階層的デコード:**
1. **第1段階**: 命令タイプの判定 (Load/Store/ALU等)
2. **第2段階**: アドレッシングモードの判定
3. **第3段階**: 制御信号の生成

**制御信号の種類:**
- ALU操作選択
- レジスタ書き込み制御
- メモリアクセス制御
- フラグ更新制御

### ALUの設計要件

**対応演算:**
- 算術演算: ADD, SUB (キャリー付き)
- 論理演算: AND, OR, XOR
- シフト演算: ASL, LSR, ROL, ROR
- 比較演算: CMP, CPX, CPY
- インクリメント/デクリメント: INC, DEC

## 🛠️ 実習1: 完全な命令デコーダ

```systemverilog
module cpu_decoder (
    input  logic [7:0] opcode,
    input  logic [7:0] status_reg,

    // ALU制御
    output logic [3:0] alu_op,
    output logic       alu_carry_in,

    // レジスタ制御
    output logic reg_a_write,
    output logic reg_x_write,
    output logic reg_y_write,
    output logic reg_sp_write,
    output logic reg_pc_write,

    // メモリ制御
    output logic mem_read,
    output logic mem_write,

    // フラグ制御
    output logic update_nz,
    output logic update_c,
    output logic update_v,

    // データパス制御
    output logic [2:0] reg_src_sel,    // レジスタ入力選択
    output logic [1:0] alu_a_sel,     // ALU A入力選択
    output logic [1:0] alu_b_sel,     // ALU B入力選択

    // アドレッシング
    output logic [2:0] addr_mode,
    output logic [1:0] instruction_length
);

    // ALU操作定義
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_ASL = 4'b0101;
    localparam ALU_LSR = 4'b0110;
    localparam ALU_ROL = 4'b0111;
    localparam ALU_ROR = 4'b1000;
    localparam ALU_INC = 4'b1001;
    localparam ALU_DEC = 4'b1010;
    localparam ALU_PASS_A = 4'b1011;
    localparam ALU_PASS_B = 4'b1100;

    always_comb begin
        // デフォルト値
        alu_op = ALU_PASS_A;
        alu_carry_in = 1'b0;

        {reg_a_write, reg_x_write, reg_y_write} = 3'b000;
        {reg_sp_write, reg_pc_write} = 2'b00;

        {mem_read, mem_write} = 2'b00;
        {update_nz, update_c, update_v} = 3'b000;

        reg_src_sel = 3'b000;
        alu_a_sel = 2'b00;
        alu_b_sel = 2'b00;

        addr_mode = 3'b000;
        instruction_length = 2'd1;

        case (opcode)
            // LDA Immediate
            8'hA9: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_B;
                reg_src_sel = 3'b001;  // ALU結果
                addr_mode = 3'b000;    // Immediate
                instruction_length = 2'd2;
            end

            // ADC Immediate
            8'h69: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                update_c = 1'b1;
                update_v = 1'b1;
                alu_op = ALU_ADD;
                alu_carry_in = status_reg[0];  // Cフラグ
                alu_a_sel = 2'b00;    // A レジスタ
                alu_b_sel = 2'b01;    // メモリデータ
                reg_src_sel = 3'b001; // ALU結果
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // STA Zero Page
            8'h85: begin
                mem_write = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = 2'b00;    // A レジスタ
                addr_mode = 3'b001;   // Zero Page
                instruction_length = 2'd2;
            end

            // TAX
            8'hAA: begin
                reg_x_write = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = 2'b00;    // A レジスタ
                reg_src_sel = 3'b001; // ALU結果
                instruction_length = 2'd1;
            end

            // TODO: 他の重要な命令を実装

            default: begin
                // NOP または未実装命令
                instruction_length = 2'd1;
            end
        endcase
    end

endmodule
```

## 🛠️ 実習2: 6502 ALU実装

```systemverilog
module cpu_alu (
    input  logic [7:0]  operand_a,
    input  logic [7:0]  operand_b,
    input  logic [3:0]  operation,
    input  logic        carry_in,

    output logic [7:0]  result,
    output logic        carry_out,
    output logic        overflow,
    output logic        negative,
    output logic        zero
);

    logic [8:0] temp_result;

    always_comb begin
        // デフォルト値
        temp_result = 9'b000000000;
        overflow = 1'b0;

        case (operation)
            4'b0000: begin // ADD
                temp_result = {1'b0, operand_a} + {1'b0, operand_b} + {8'b0, carry_in};
                // オーバーフロー検出 (符号付き演算)
                overflow = (operand_a[7] == operand_b[7]) &&
                          (operand_a[7] != temp_result[7]);
            end

            4'b0001: begin // SUB
                temp_result = {1'b0, operand_a} - {1'b0, operand_b} - {8'b0, ~carry_in};
                // 減算のオーバーフロー
                overflow = (operand_a[7] != operand_b[7]) &&
                          (operand_a[7] != temp_result[7]);
            end

            4'b0010: begin // AND
                temp_result = {1'b0, operand_a & operand_b};
            end

            4'b0011: begin // OR
                temp_result = {1'b0, operand_a | operand_b};
            end

            4'b0100: begin // XOR
                temp_result = {1'b0, operand_a ^ operand_b};
            end

            4'b0101: begin // ASL (Arithmetic Shift Left)
                temp_result = {operand_a, 1'b0};
            end

            4'b0110: begin // LSR (Logical Shift Right)
                temp_result = {operand_a[0], 1'b0, operand_a[7:1]};
            end

            4'b0111: begin // ROL (Rotate Left)
                temp_result = {operand_a, carry_in};
            end

            4'b1000: begin // ROR (Rotate Right)
                temp_result = {operand_a[0], carry_in, operand_a[7:1]};
            end

            4'b1001: begin // INC
                temp_result = {1'b0, operand_a} + 9'b000000001;
            end

            4'b1010: begin // DEC
                temp_result = {1'b0, operand_a} - 9'b000000001;
            end

            4'b1011: begin // PASS A
                temp_result = {1'b0, operand_a};
            end

            4'b1100: begin // PASS B
                temp_result = {1'b0, operand_b};
            end

            default: begin
                temp_result = {1'b0, operand_a};
            end
        endcase

        // 結果とフラグの生成
        result = temp_result[7:0];
        carry_out = temp_result[8];
        negative = temp_result[7];
        zero = (temp_result[7:0] == 8'h00);
    end

endmodule
```

## 🛠️ 実習3: フラグレジスタ管理

```systemverilog
module status_register (
    input  logic clk,
    input  logic rst_n,

    // フラグ更新制御
    input  logic update_n,
    input  logic update_z,
    input  logic update_c,
    input  logic update_v,

    // 新しいフラグ値
    input  logic new_n,
    input  logic new_z,
    input  logic new_c,
    input  logic new_v,

    // 特殊フラグ制御
    input  logic set_i,     // 割り込み禁止セット
    input  logic clear_i,   // 割り込み禁止クリア
    input  logic set_d,     // デシマルモードセット
    input  logic clear_d,   // デシマルモードクリア

    // ステータスレジスタ
    output logic [7:0] status_reg
);

    // フラグビット定義
    // Bit 7: N (Negative)
    // Bit 6: V (Overflow)
    // Bit 5: - (未使用、常に1)
    // Bit 4: B (Break)
    // Bit 3: D (Decimal)
    // Bit 2: I (Interrupt)
    // Bit 1: Z (Zero)
    // Bit 0: C (Carry)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 8'b00100100;  // I=1, unused=1
        end else begin
            // 条件付きフラグ更新
            if (update_n) status_reg[7] <= new_n;
            if (update_v) status_reg[6] <= new_v;
            // Bit 5は常に1
            status_reg[5] <= 1'b1;
            // Break フラグは命令により制御
            if (update_z) status_reg[1] <= new_z;
            if (update_c) status_reg[0] <= new_c;

            // 特殊制御
            if (set_i)    status_reg[2] <= 1'b1;
            if (clear_i)  status_reg[2] <= 1'b0;
            if (set_d)    status_reg[3] <= 1'b1;
            if (clear_d)  status_reg[3] <= 1'b0;
        end
    end

endmodule
```

## 📝 課題

### 基礎課題
1. 残りの算術・論理命令の実装
2. 全シフト・ローテート命令の実装
3. 比較命令 (CMP, CPX, CPY) の実装

### 発展課題
1. BCD (Binary Coded Decimal) 演算の実装
2. 未実装命令の動作定義
3. 命令実行サイクル最適化

## 📚 今日学んだこと

- [ ] 階層的命令デコーダの設計
- [ ] ALUの完全実装
- [ ] フラグ生成ロジック
- [ ] 制御信号の体系的設計

## 🎯 明日の予習

Day 07ではメモリインターフェースとスタック制御を実装します:
- メモリバス設計
- スタック操作の実装
- アドレス生成ユニット