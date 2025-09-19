# Day 01: Tang Nano + GoWin EDA 基礎

## 🎯 学習目標

- Tang Nano 9K/20K の基本仕様を理解する
- GoWin EDA の基本操作をマスターする
- 最初のHDLプロジェクトとしてLEDチカチカを作成する
- FPGA開発の基本的なワークフローを習得する

## 📚 事前準備

### ハードウェア
- Tang Nano 9K または Tang Nano 20K
- USB-C ケーブル
- PC (Windows/Linux/macOS)

### ソフトウェア
- GoWin EDA (公式サイトからダウンロード・インストール)

## 📖 理論学習

### Tang Nano の基本仕様

**Tang Nano 9K:**
- FPGA: Gowin GW1NR-9C
- 論理エレメント: 8,640 LUT4
- メモリ: 468Kbit BSRAM
- PLL: 2個
- I/Oピン数: 63

**Tang Nano 20K:**
- FPGA: Gowin GW2AR-18C
- 論理エレメント: 20,736 LUT4
- メモリ: 828Kbit BSRAM
- PLL: 4個
- I/Oピン数: 107

### FPGA開発の基本フロー

1. **設計** - HDL (Hardware Description Language) でロジックを記述
2. **合成** - HDLコードを論理回路に変換
3. **配置配線** - 論理回路をFPGA内の物理リソースにマッピング
4. **ビットストリーム生成** - FPGAに書き込むバイナリファイルを生成
5. **プログラミング** - FPGAにビットストリームを書き込み

## 🛠️ 実習: LEDチカチカプロジェクト

### Step 1: プロジェクト作成

1. GoWin EDA を起動
2. "File" → "New Project" を選択
3. プロジェクト名: `led_blink`
4. デバイス選択:
   - Tang Nano 9K: `GW1NR-LV9QN88PC6/I5`
   - Tang Nano 20K: `GW2AR-LV18QN88C8/I7`

### Step 2: HDLコード作成

`top.sv` ファイルを作成し、以下のコードを記述:

```systemverilog
module top (
    input  wire clk,     // 27MHz clock
    output wire led      // LED output
);

    // Clock divider for visible blinking (約1Hz)
    reg [24:0] counter;

    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // LED点滅 (counterの最上位ビットを使用)
    assign led = counter[24];

endmodule
```

### Step 3: 制約ファイル作成

`tang_nano.cst` ファイルを作成:

**Tang Nano 9K:**
```
IO_LOC "clk" 52;
IO_PORT "clk" PULL_MODE=UP;
IO_LOC "led" 10;
```

**Tang Nano 20K:**
```
IO_LOC "clk" 4;
IO_PORT "clk" PULL_MODE=UP;
IO_LOC "led" 15;
```

### Step 4: 合成・配置配線

1. "Process" → "Synthesize" を実行
2. エラーがないことを確認
3. "Process" → "Place & Route" を実行

### Step 5: プログラミング

1. "Process" → "Program Device" を選択
2. Tang Nano をUSBで接続
3. "SRAM Program" を実行
4. LEDが約0.8秒間隔で点滅することを確認

## 🔧 トラブルシューティング

### よくある問題

1. **デバイスが認識されない**
   - USBドライバーが正しくインストールされているか確認
   - Tang Nanoのスイッチが適切な位置にあるか確認

2. **合成エラー**
   - SystemVerilogの構文エラーをチェック
   - モジュール名とファイル名が一致しているか確認

3. **配置配線エラー**
   - 制約ファイルのピン番号が正しいか確認
   - 使用しているボードに対応した制約ファイルか確認

## 📝 課題

### 基礎課題
1. 点滅速度を変更してみる (counterのビット位置を変更)
2. 2つのLEDを交互に点滅させる
3. PWMを使ってLEDの明度を変化させる

### 発展課題
1. スイッチ入力でLEDの点滅速度を制御
2. 7セグメントディスプレイにカウンタ表示
3. RGB LEDで様々な色を表示

## 📚 今日学んだこと

- [ ] Tang Nano の基本仕様
- [ ] GoWin EDA の基本操作
- [ ] SystemVerilog の基本構文
- [ ] FPGA開発フローの理解
- [ ] 制約ファイルの役割
- [ ] 実機での動作確認

## 🎯 明日の予習

Day 02では SystemVerilog の組み合わせ回路について詳しく学習します:
- always_comb文の使い方
- 条件分岐 (if-else, case)
- 論理演算とビット操作
- モジュール間の接続

**準備課題**: 2進数、16進数、論理演算の基本を復習しておきましょう。