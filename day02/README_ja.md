# Day 02: SystemVerilog 基礎 (組み合わせ回路)

## 🎯 学習目標

- SystemVerilogの基本構文を理解する
- 組み合わせ回路の設計方法を習得する
- assign文とalways_comb文の使い分けを学ぶ
- テストベンチの基本を理解する

## 📚 理論学習

### SystemVerilog 基本構文

**データ型:**
```systemverilog
wire [7:0] data_bus;     // 8bit ワイヤ
reg [3:0] counter;       // 4bit レジスタ
logic select;            // 1bit ロジック
logic [15:0] address;    // 16bit アドレス
```

**演算子:**
```systemverilog
// 論理演算
a & b    // AND
a | b    // OR
a ^ b    // XOR
~a       // NOT

// 比較演算
a == b   // 等しい
a != b   // 等しくない
a > b    // より大きい

// ビット操作
data[7:4]  // 上位4ビット
data[0]    // 最下位ビット
{a, b}     // 連結
```

### 組み合わせ回路の記述方法

**方法1: assign文**
```systemverilog
assign output = input1 & input2;
assign sum = a + b;
```

**方法2: always_comb文**
```systemverilog
always_comb begin
    if (select)
        output = input1;
    else
        output = input2;
end
```

## 🛠️ 実習1: 7セグメントデコーダ

### 仕様
- 4bit 入力 (0-15) を7セグメント表示用の信号に変換
- アクティブローで駆動 (0で点灯)

### 実装のヒント

```systemverilog
module seven_seg_decoder (
    input  logic [3:0] digit,
    output logic [6:0] segments  // {g,f,e,d,c,b,a}
);

    always_comb begin
        case (digit)
            4'h0: segments = 7'b1000000;  // 0
            4'h1: segments = 7'b1111001;  // 1
            // TODO: 残りの数字を実装
            default: segments = 7'b1111111;  // 消灯
        endcase
    end

endmodule
```

## 🛠️ 実習2: 4bit ALU

### 仕様
- 2つの4bit入力 (A, B)
- 2bit操作選択 (OP)
- 4bit出力 + フラグ (Zero, Carry)

### 操作
- 00: A + B (加算)
- 01: A - B (減算)
- 10: A & B (AND)
- 11: A | B (OR)

### 実装テンプレート

```systemverilog
module alu_4bit (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [1:0] op,
    output logic [3:0] result,
    output logic zero,
    output logic carry
);

    logic [4:0] temp_result;  // キャリー計算用

    always_comb begin
        case (op)
            2'b00: begin  // 加算
                temp_result = a + b;
                result = temp_result[3:0];
                carry = temp_result[4];
            end
            // TODO: 他の操作を実装
            default: begin
                result = 4'b0000;
                carry = 1'b0;
            end
        endcase

        zero = (result == 4'b0000);
    end

endmodule
```

## 🛠️ 実習3: マルチプレクサ

### 8-to-1 マルチプレクサ
```systemverilog
module mux_8to1 (
    input  logic [7:0] data_in,
    input  logic [2:0] select,
    output logic data_out
);

    // TODO: selectに応じてdata_inの適切なビットを出力

endmodule
```

## 🧪 テストベンチの基本

### シンプルなテストベンチ例

```systemverilog
module tb_alu_4bit;

    logic [3:0] a, b;
    logic [1:0] op;
    logic [3:0] result;
    logic zero, carry;

    // テスト対象のインスタンス化
    alu_4bit uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .carry(carry)
    );

    initial begin
        // テストケース1: 5 + 3 = 8
        a = 4'd5;
        b = 4'd3;
        op = 2'b00;
        #10;

        // 結果チェック
        assert (result == 4'd8) else $error("Test failed: 5+3");

        // TODO: 他のテストケースを追加

        $display("All tests completed");
        $finish;
    end

endmodule
```

## 📝 課題

### 基礎課題
1. 7セグメントデコーダを完成させる (0-F表示)
2. 4bit ALUの全操作を実装する
3. 各モジュールのテストベンチを作成する

### 発展課題
1. BCD (Binary Coded Decimal) デコーダの実装
2. 優先エンコーダの実装
3. パリティ生成器の実装

## 🔧 デバッグのヒント

1. **合成エラー対策**
   - セミコロン忘れをチェック
   - begin-end の対応を確認
   - 信号名の重複をチェック

2. **論理エラー対策**
   - 真理値表と照合
   - 簡単なケースから段階的にテスト
   - 波形を使った動作確認

## 📚 今日学んだこと

- [ ] SystemVerilogの基本構文
- [ ] 組み合わせ回路の設計方法
- [ ] assign文とalways_comb文の使い分け
- [ ] case文とif-else文の使用
- [ ] テストベンチの基本構造

## 🎯 明日の予習

Day 03では順序回路について学習します:
- クロック同期回路
- フリップフロップとラッチ
- 状態機械 (FSM)
- カウンタとタイマー

**準備課題**: デジタル回路の基本 (フリップフロップ、クロック、セットアップ時間) を復習しておきましょう。