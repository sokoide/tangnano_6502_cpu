# Day 04: 6502 CPU アーキテクチャ概論

## 🎯 学習目標

- 6502 CPUの歴史と特徴を理解する
- レジスタ構成とその役割を学ぶ
- メモリマップとアドレッシングの基本を理解する
- 命令実行サイクルの流れを把握する

## 📚 理論学習

### 6502 CPUの歴史

**開発背景:**
- 1975年にMOS Technology社が開発
- 当時としては革新的な低価格 ($25)
- Apple II, Commodore 64, NES等で使用
- シンプルな設計で教育用途にも最適

### レジスタ構成

**8bit レジスタ:**
- **A (Accumulator)**: 演算の主役、多くの命令で使用
- **X, Y (Index)**: アドレッシングでのインデックス用
- **SP (Stack Pointer)**: スタック位置を指示 (0x0100-0x01FF)

**16bit レジスタ:**
- **PC (Program Counter)**: 次に実行する命令のアドレス

**1bit フラグ (Pレジスタ):**
- **N (Negative)**: 結果が負数の時セット
- **V (Overflow)**: 符号ありオーバーフローでセット
- **B (Break)**: BRK命令実行時にセット
- **D (Decimal)**: BCD演算モード (通常は未使用)
- **I (Interrupt)**: 割り込み禁止フラグ
- **Z (Zero)**: 結果がゼロの時セット
- **C (Carry)**: キャリー/ボローでセット

### メモリマップの基本

```
0x0000-0x00FF : Zero Page (高速アクセス領域)
0x0100-0x01FF : Stack (スタック領域)
0x0200-0x7FFF : General RAM
0x8000-0xFFFF : Program ROM (通常)
```

## 🛠️ 実習1: 6502レジスタセット

### SystemVerilogでの実装

```systemverilog
module cpu_registers (
    input  logic clk,
    input  logic rst_n,

    // レジスタ制御
    input  logic a_write,
    input  logic x_write,
    input  logic y_write,
    input  logic sp_write,
    input  logic pc_write,
    input  logic p_write,

    // データバス
    input  logic [7:0]  data_in,
    input  logic [15:0] addr_in,

    // レジスタ出力
    output logic [7:0]  reg_a,
    output logic [7:0]  reg_x,
    output logic [7:0]  reg_y,
    output logic [7:0]  reg_sp,
    output logic [15:0] reg_pc,
    output logic [7:0]  reg_p
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a  <= 8'h00;
            reg_x  <= 8'h00;
            reg_y  <= 8'h00;
            reg_sp <= 8'hFF;  // スタックは上位から
            reg_pc <= 16'h0200;  // プログラム開始アドレス
            reg_p  <= 8'h20;     // 割り込み禁止状態で開始
        end else begin
            if (a_write)  reg_a  <= data_in;
            if (x_write)  reg_x  <= data_in;
            if (y_write)  reg_y  <= data_in;
            if (sp_write) reg_sp <= data_in;
            if (pc_write) reg_pc <= addr_in;
            if (p_write)  reg_p  <= data_in;
        end
    end

endmodule
```

## 🛠️ 実習2: 簡単な命令デコーダ

### 基本的な命令の分類

```systemverilog
module simple_decoder (
    input  logic [7:0] opcode,
    output logic is_load,      // LDA, LDX, LDY
    output logic is_store,     // STA, STX, STY
    output logic is_transfer,  // TAX, TAY, TXA, etc.
    output logic is_arithmetic // ADC, SBC
);

    always_comb begin
        // デフォルト値
        is_load = 1'b0;
        is_store = 1'b0;
        is_transfer = 1'b0;
        is_arithmetic = 1'b0;

        case (opcode)
            // LDA命令群
            8'hA9, 8'hA5, 8'hB5, 8'hAD, 8'hBD, 8'hB9, 8'hA1, 8'hB1:
                is_load = 1'b1;

            // STA命令群
            8'h85, 8'h95, 8'h8D, 8'h9D, 8'h99, 8'h81, 8'h91:
                is_store = 1'b1;

            // TODO: 他の命令グループを実装

            default: begin
                // 未知の命令
            end
        endcase
    end

endmodule
```

## 🛠️ 実習3: フラグ計算ロジック

### N, Z フラグの実装

```systemverilog
module flag_calculator (
    input  logic [7:0] result,
    input  logic [7:0] operand_a,
    input  logic [7:0] operand_b,
    input  logic       operation,  // 0:ADD, 1:SUB

    output logic flag_n,  // Negative
    output logic flag_z,  // Zero
    output logic flag_c,  // Carry
    output logic flag_v   // Overflow
);

    logic [8:0] temp_result;

    always_comb begin
        // 9bitで計算してキャリーを検出
        if (operation) begin
            temp_result = {1'b0, operand_a} - {1'b0, operand_b};
        end else begin
            temp_result = {1'b0, operand_a} + {1'b0, operand_b};
        end

        // フラグ計算
        flag_n = result[7];              // 最上位ビット
        flag_z = (result == 8'h00);      // ゼロ判定
        flag_c = temp_result[8];         // キャリー

        // オーバーフロー判定 (符号付き演算)
        flag_v = (operand_a[7] == operand_b[7]) &&
                 (operand_a[7] != result[7]);
    end

endmodule
```

## 📝 課題

### 基礎課題
1. 全レジスタの動作確認テストベンチ
2. 主要命令の分類機能拡張
3. 全フラグの計算ロジック実装

### 発展課題
1. アドレッシングモード判定器
2. 命令長計算器
3. スタック操作シミュレータ

## 📚 重要なポイント

### 6502の特徴
- **シンプルな設計**: 複雑な命令はなし
- **メモリマップドI/O**: 特別なI/O命令は不要
- **ゼロページ**: 高速アクセス可能な最初の256バイト
- **スタック固定**: 0x0100-0x01FFに固定

### アーキテクチャの利点
- **教育的価値**: 理解しやすい構造
- **実装コスト**: 少ないトランジスタ数
- **プログラマビリティ**: 直感的な命令セット

## 📚 今日学んだこと

- [ ] 6502 CPUの歴史と特徴
- [ ] レジスタ構成と役割
- [ ] メモリマップの基本
- [ ] 命令分類の方法
- [ ] フラグ計算の仕組み

## 🎯 明日の予習

Day 05では6502の命令セットとアドレッシングモードを詳しく学習します:
- 13種類のアドレッシングモード
- 主要命令の動作
- 有効アドレス計算