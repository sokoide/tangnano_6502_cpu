# Day 03 Completed: SystemVerilog Sequential Circuits

SystemVerilog の順序回路設計の完成版プロジェクトです。

## 実習の見取り図

完成例では下記の課題が実装済みです。

| 項目           | 内容                                               |
| -------------- | -------------------------------------------------- |
| 編集する箇所   | traffic_light.svの状態遷移TODO。独立部品は追加課題 |
| 提供済みの前提 | カウンタ・PWM・分周器のinterface                   |
| テストの期待値 | `make test` で交通信号の遷移と分周器の比率0～15    |
| 実機で見るもの | 信号機LEDが赤→緑→黄。外部入力はボードtopで固定     |

## ファイル構成

- `counter_8bit.sv` - 8bit アップカウンタ
- `pwm_generator.sv` - PWM 信号生成器
- `traffic_light.sv` - 交通信号制御器（状態機械）
- `shift_register.sv` - 8bit シフトレジスタ
- `clock_divider.sv` - 可変分周器
- `top_9k.sv` / `top_20k.sv` - ボード別トップ（入力を定数接続）
- `top_core.sv` - 内部回路の統合モジュール
- `tb_traffic_light.sv` - 交通信号テストベンチ
- `Makefile` - ビルド・テスト自動化

## 実装モジュール

### 1. 8bit カウンタ

- イネーブル制御付きアップカウンタ
- オーバーフロー検出
- 非同期リセット対応

### 2. PWM生成器

- 8bit デューティサイクル制御（0-255）
- 連続カウンタによる生成
- 可変パルス幅出力

### 3. 交通信号制御器

- 3 状態の FSM（赤→緑→黄→赤）
- タイマーベースの自動遷移
- 実時間での動作確認可能

### 4. シフトレジスタ

- 8bit 左シフトレジスタ
- パラレルロード機能
- シリアル入出力対応

### 5. クロック分周器

- 可変分周比（1-15）
- 偶数分周は 50%、奇数分周は floor(N/2)/N のデューティ比
- 高精度分周

## ビルド・テスト方法

### シミュレーションテスト

```bash
make test
```

#### シミュレータについて

- シミュレータ: Verilator（macOS/Linux/Windows で動作）。
- 出力: `tb_traffic_light.sv` を実行し、波形 `tb_traffic_light.vcd` を生成します（`gtkwave tb_traffic_light.vcd` で確認）。
- 前提: `verilator` が `PATH` にあること（macOS 例: `brew install verilator`）。

### FPGAビルド & ダウンロード

```bash
# Tang Nano 9K
make BOARD=9k download

# Tang Nano 20K
make BOARD=20k download
```

### 個別テスト

```bash
# 交通信号シミュレーション
make test

# 波形表示
gtkwave tb_traffic_light.vcd
```

## ハードウェア動作確認

この完成版のボードトップは `clk`、`ResetButton`、`led[5:0]` のみを外部ポートとして持ちます。スイッチ入力や 7 セグメント表示はありません。`top_9k.sv` / `top_20k.sv` は `top_core.sv` の `switches` を `4'b0` に固定し、PWM 出力を未接続にしています。

`top_core.sv` 内では交通信号の状態とカウンタ下位ビットを 6 個の LED 信号へ割り当てています。リセットボタンで初期状態へ戻ること、LED の状態が回路動作に応じて変化することを確認してください。内部の `count_out`、`pwm_out`、シフト出力、分周クロックはボードの外部ピンには出ていません。

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

- PWM 制御技術
- シフトレジスタ応用
- クロック分周技術
- マルチモジュール統合

## 発展課題

1. **UART送信器**: シリアル通信用状態機械
2. **可変長シフトレジスタ**: 動的ビット幅制御
3. **多段分周器**: より柔軟な周波数生成

これらの順序回路は、CPU の制御部分やタイミング制御で重要な役割を果たします。

分周器は `div_ratio=0` で停止、`1` で入力クロックを通過、`2..15` で整数分周します。比率はリセット中に変更してください。内部回路の低速化には、派生クロックより元クロックと clock enable を使う方法を優先します。
