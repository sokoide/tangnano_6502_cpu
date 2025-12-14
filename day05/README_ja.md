# Day 05: 6502 命令セットとアドレッシングモード

## 🎯 学習目標

- 6502の13種類のアドレッシングモードを理解する
- 主要命令群の分類と動作を学ぶ
- 有効アドレス計算の実装方法を習得する
- 実際の命令エンコーディングを理解する

## 📚 理論学習

### アドレッシングモード一覧

1. **Implied** - オペランドなし (TAX, RTS)
2. **Accumulator** - Aレジスタ操作 (ASL A)
3. **Immediate** - 即値 (LDA #$80)
4. **Zero Page** - ゼロページ (LDA $80)
5. **Zero Page,X** - ゼロページ+X (LDA $80,X)
6. **Zero Page,Y** - ゼロページ+Y (LDX $80,Y)
7. **Absolute** - 絶対アドレス (LDA $1234)
8. **Absolute,X** - 絶対+X (LDA $1234,X)
9. **Absolute,Y** - 絶対+Y (LDA $1234,Y)
10. **Indirect** - 間接 (JMP ($1234))
11. **Indexed Indirect** - (zp,X) (LDA ($80,X))
12. **Indirect Indexed** - (zp),Y (LDA ($80),Y)
13. **Relative** - 相対分岐 (BEQ $80)

### 主要命令の分類

**データ転送:**

- LDA, LDX, LDY (ロード)
- STA, STX, STY (ストア)
- TAX, TAY, TXA, TYA, TSX, TXS (転送)

**演算:**

- ADC, SBC (加減算)
- AND, ORA, EOR (論理演算)
- ASL, LSR, ROL, ROR (シフト・ローテート)

**分岐・ジャンプ:**

- BEQ, BNE, BCS, BCC, BMI, BPL, BVS, BVC (条件分岐)
- JMP, JSR, RTS (ジャンプ・サブルーチン)

## 🛠️ 実習1: アドレッシングモード計算器

```systemverilog
module addressing_mode_calculator (
    input  logic [7:0]  opcode,
    input  logic [15:0] pc,           // プログラムカウンタ
    input  logic [7:0]  operand1,     // 1バイト目オペランド
    input  logic [7:0]  operand2,     // 2バイト目オペランド
    input  logic [7:0]  reg_x,
    input  logic [7:0]  reg_y,

    output logic [15:0] effective_addr,
    output logic [2:0]  addr_mode,
    output logic [1:0]  instruction_length
);

    // アドレッシングモード定義
    localparam IMMEDIATE     = 3'b000;
    localparam ZERO_PAGE     = 3'b001;
    localparam ZERO_PAGE_X   = 3'b010;
    localparam ABSOLUTE      = 3'b011;
    localparam ABSOLUTE_X    = 3'b100;
    localparam ABSOLUTE_Y    = 3'b101;
    localparam INDEXED_IND   = 3'b110;
    localparam INDIRECT_IND  = 3'b111;

    always_comb begin
        // デフォルト値
        effective_addr = 16'h0000;
        addr_mode = IMMEDIATE;
        instruction_length = 2'd1;

        case (opcode)
            // LDA Immediate - #$nn
            8'hA9: begin
                effective_addr = {8'h00, operand1};
                addr_mode = IMMEDIATE;
                instruction_length = 2'd2;
            end

            // LDA Zero Page - $nn
            8'hA5: begin
                effective_addr = {8'h00, operand1};
                addr_mode = ZERO_PAGE;
                instruction_length = 2'd2;
            end

            // LDA Zero Page,X - $nn,X
            8'hB5: begin
                effective_addr = {8'h00, operand1 + reg_x};
                addr_mode = ZERO_PAGE_X;
                instruction_length = 2'd2;
            end

            // LDA Absolute - $nnnn
            8'hAD: begin
                effective_addr = {operand2, operand1};  // リトルエンディアン
                addr_mode = ABSOLUTE;
                instruction_length = 2'd3;
            end

            // TODO: 他のアドレッシングモードを実装

            default: begin
                effective_addr = 16'h0000;
                addr_mode = IMMEDIATE;
                instruction_length = 2'd1;
            end
        endcase
    end

endmodule
```

## 🛠️ 実習2: 命令デコーダ拡張版

```systemverilog
module instruction_decoder (
    input  logic [7:0] opcode,

    // 命令タイプ
    output logic is_load,
    output logic is_store,
    output logic is_arithmetic,
    output logic is_logical,
    output logic is_shift,
    output logic is_branch,
    output logic is_jump,
    output logic is_transfer,

    // レジスタ選択
    output logic use_reg_a,
    output logic use_reg_x,
    output logic use_reg_y,

    // フラグ影響
    output logic affects_n,
    output logic affects_z,
    output logic affects_c,
    output logic affects_v
);

    always_comb begin
        // デフォルト値
        {is_load, is_store, is_arithmetic, is_logical} = 4'b0000;
        {is_shift, is_branch, is_jump, is_transfer} = 4'b0000;
        {use_reg_a, use_reg_x, use_reg_y} = 3'b000;
        {affects_n, affects_z, affects_c, affects_v} = 4'b0000;

        case (opcode)
            // LDA 命令群
            8'hA9, 8'hA5, 8'hB5, 8'hAD, 8'hBD, 8'hB9, 8'hA1, 8'hB1: begin
                is_load = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
            end

            // ADC 命令群
            8'h69, 8'h65, 8'h75, 8'h6D, 8'h7D, 8'h79, 8'h61, 8'h71: begin
                is_arithmetic = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                affects_c = 1'b1;
                affects_v = 1'b1;
            end

            // TAX
            8'hAA: begin
                is_transfer = 1'b1;
                use_reg_a = 1'b1;
                use_reg_x = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
            end

            // TODO: 他の命令を実装

            default: begin
                // 未知の命令
            end
        endcase
    end

endmodule
```

## 🛠️ 実習3: 分岐計算器

```systemverilog
module branch_calculator (
    input  logic [7:0]  branch_offset,  // 符号付き8bit
    input  logic [15:0] pc,             // 現在のPC
    output logic [15:0] branch_target
);

    logic [15:0] signed_offset;

    always_comb begin
        // 8bit符号付きを16bitに拡張
        if (branch_offset[7]) begin
            signed_offset = {8'hFF, branch_offset};  // 負数
        end else begin
            signed_offset = {8'h00, branch_offset};  // 正数
        end

        branch_target = pc + signed_offset;
    end

endmodule
```

## 📝 課題

### 基礎課題

1. 全アドレッシングモードの実装
2. 主要命令の完全なデコーダ
3. 分岐命令のテストケース作成

### 発展課題

1. 命令サイクル数計算器
2. ページ境界越えの検出
3. 不正命令の検出機能

## 📚 重要な実装のポイント

### リトルエンディアン

6502は16bitアドレスをリトルエンディアンで格納:

```bash
アドレス $1234 は メモリ上で [34] [12] の順
```

### ページ境界越え

一部のアドレッシングモードでページ境界を越えると追加サイクルが必要:

- Absolute,X / Absolute,Y
- (zp),Y

### 分岐の計算

相対分岐は現在のPCからの符号付きオフセット:

- 正の値: 前方分岐
- 負の値: 後方分岐
- 範囲: -128 ～ +127

## 📚 今日学んだこと

- [ ] 13種類のアドレッシングモード
- [ ] 命令の分類と特徴
- [ ] 有効アドレス計算方法
- [ ] リトルエンディアンの扱い
- [ ] 分岐計算の実装

## 🎯 明日の予習

Day 06ではCPU実装の第1段階として、デコーダとALUの詳細実装を行います:

- 完全な命令デコーダ
- ALU設計と実装
- フラグ生成ロジック
