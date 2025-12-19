# ソフトウェアエンジニアのための SystemVerilog チートシート

このガイドは、ソフトウェア開発の背景を持つ方向けに、このコースで必要な SystemVerilog の構文と概念をまとめたものです。

---

🌐 Available languages:
[English](./SYSTEMVERILOG_CHEATSHEET.md) | [日本語](./SYSTEMVERILOG_CHEATSHEET_ja.md)

## 1. データ型: `logic` だけでOK

古い Verilog では `wire` と `reg` を使い分ける必要がありましたが、SystemVerilog ではほぼすべてを **`logic`** で記述できます。

| 型 | 説明 | 使用ルール |
| :--- | :--- | :--- |
| **`logic`** | **現代の標準。** 文脈に応じて配線にもレジスタにもなります。 | **基本はこれを使ってください。** |
| `wire` | 物理的な配線。複数のドライバを持つことができます（I2Cバスなど）。 | トライステートバッファなど特殊な用途でのみ使用します。 |
| `reg` | 値を保持するための古い Verilog 型。 | レガシーです。代わりに `logic` を使いましょう。 |

**例:**

```systemverilog
logic [7:0] data;  // 8ビット信号 (0〜255)
logic       flag;  // 1ビット信号 (0 または 1)
```

## 2. 代入: `=` vs `<=`

ここがソフトウェアエンジニアにとって最も混乱しやすい部分です。代入演算子は、記述しようとしている**回路の種類**によって使い分けます。

| 回路の種類 | ブロック | 演算子 | 意味 | アナロジー |
| :--- | :--- | :---: | :--- | :--- |
| **組み合わせ回路** | `always_comb` | **`=`** | **ブロッキング代入**<br>即座に更新されます。行の順番が重要です。 | CやPythonの通常の変数代入と同じ。 |
| **順序回路** | `always_ff` | **`<=`** | **ノンブロッキング代入**<br>クロックサイクルの*終わり*に更新が予約されます。すべて並列に起こります。 | 「スナップショット」更新。<br>`a <= b; b <= a;` で値を交換できます。 |

### ✅ 組み合わせ回路 (論理ゲート) -> `=` を使う

```systemverilog
// y = a AND b を記述
always_comb begin
    y = a & b; 
end
```

### ✅ 順序回路 (レジスタ/FF) -> `<=` を使う

```systemverilog
// クロックのタイミングで d を q にコピー
always_ff @(posedge clk) begin
    q <= d;
end
```

> **⚠️ 重要ルール:**
> ひとつのブロックの中で `=` と `<=` を混ぜてはいけません。

## 3. 回路ブロック

### `assign` (継続的代入)

単純な接続に使います。ハンダ付けでワイヤーを固定するイメージです。

```systemverilog
assign led = switch & enable; // switch と enable が両方 1 の時だけ LED が点灯
```

### `always_comb` (組み合わせ回路ブロック)

複雑なロジック（if-else, case）に使います。**メモリを持たない**回路を記述します。出力は現在の入力*だけ*に依存します。

```systemverilog
always_comb begin
    if (enable)
        result = a + b;
    else
        result = 0;
end
```

### `always_ff @(posedge clk)` (順序回路ブロック)

レジスタ、カウンタ、ステートマシンなどに使います。**メモリを持つ**回路を記述します。クロックの立ち上がりエッジでのみ更新されます。

```systemverilog
always_ff @(posedge clk) begin
    if (reset)
        count <= 0;
    else
        count <= count + 1;
end
```

## 4. よくある落とし穴

### ❌ 「ラッチ生成」の罠

ソフトウェアで `if (x) y = 1;` と書くと、「x でないなら y はそのまま」という意味になります。
ハードウェアの組み合わせ回路で「そのまま」を実現するには、値を記憶する「ラッチ」という回路が必要になりますが、これは通常意図しないものであり、タイミングバグの原因になります。

**ルール:** `always_comb` 内では、**すべての分岐**で値を代入しなければなりません。

**Bad:**

```systemverilog
always_comb begin
    if (valid) data = input_val; 
    // 暗黙の「else data = data」 -> ラッチが生成されてしまう！
end
```

**Good (デフォルト値戦略):**

```systemverilog
always_comb begin
    data = 0; // デフォルト値を先にセット
    if (valid) data = input_val; 
end
```

**Good (完全な if-else):**

```systemverilog
always_comb begin
    if (valid)
        data = input_val;
    else
        data = 0;
end
```

### ❌ 多重ドライバ (Multiple Drivers)

異なる `always` ブロックや `assign` 文から、同じ信号に値を代入することはできません。これは出力ピン同士をショートさせるようなもので、エラーになります。

**Bad:**

```systemverilog
assign led = a;
assign led = b; // エラー: led にはすでにドライバがあります
```

**解決策:** マルチプレクサ（セレクタ）ロジックを使います。

```systemverilog
assign led = select ? a : b;
```
