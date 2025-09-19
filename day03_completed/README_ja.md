# Day 03 Completed: SystemVerilog Sequential Circuits

SystemVerilogの順序回路設計の完成版プロジェクトです。

## ファイル構成

- `counter_8bit.sv` - 8bitアップカウンタ
- `pwm_generator.sv` - PWM信号生成器
- `traffic_light.sv` - 交通信号制御器（状態機械）
- `shift_register.sv` - 8bitシフトレジスタ
- `clock_divider.sv` - 可変分周器
- `top.sv` - 統合テストモジュール
- `tb_traffic_light.sv` - 交通信号テストベンチ
- `Makefile` - ビルド・テスト自動化

## 実装モジュール

### 1. 8bit カウンタ
- イネーブル制御付きアップカウンタ
- オーバーフロー検出
- 非同期リセット対応

### 2. PWM生成器
- 8bitデューティサイクル制御（0-255）
- 連続カウンタによる生成
- 可変パルス幅出力

### 3. 交通信号制御器
- 3状態のFSM（赤→緑→黄→赤）
- タイマーベースの自動遷移
- 実時間での動作確認可能

### 4. シフトレジスタ
- 8bit左シフトレジスタ
- パラレルロード機能
- シリアル入出力対応

### 5. クロック分周器
- 可変分周比（1-15）
- 50%デューティサイクル
- 高精度分周

## ビルド・テスト方法

### シミュレーションテスト
```bash
make test
```

### FPGAビルド
```bash
# Tang Nano 9K
make BOARD=9k download

# Tang Nano 20K
make BOARD=20k download
```

### 個別テスト
```bash
# 交通信号シミュレーション
make sim

# 波形表示
gtkwave tb_traffic_light.vcd
```

## ハードウェア動作確認

### 入力
- `rst_n`: リセットボタン
- `switches[3:0]`: 制御スイッチ

### 出力
- `count_out[7:0]`: カウンタ値（LEDまたは7セグメント表示）
- `pwm_out`: PWM信号出力
- `red_led`, `yellow_led`, `green_led`: 交通信号LED
- `shift_serial_out`: シフトレジスタ出力
- `div_clk_out`: 分周クロック出力

## 学習ポイント

### SystemVerilog順序回路
- `always_ff` による同期回路設計
- `typedef enum` による状態定義
- 非同期リセットの実装
- クロックドメイン設計

### 状態機械設計
- 状態遷移図の実装
- タイマーベース制御
- 組み合わせ論理と順序論理の分離

### 実用回路設計
- PWM制御技術
- シフトレジスタ応用
- クロック分周技術
- マルチモジュール統合

## 発展課題

1. **UART送信器**: シリアル通信用状態機械
2. **可変長シフトレジスタ**: 動的ビット幅制御
3. **多段分周器**: より柔軟な周波数生成

これらの順序回路は、CPUの制御部分やタイミング制御で重要な役割を果たします。