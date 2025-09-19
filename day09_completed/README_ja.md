# Day 09: LCDコントローラーシステム

## 学習目標

Day 09では、6502 CPUシステムにLCDディスプレイコントローラーを追加し、CPUレジスタ値をリアルタイムで表示するシステムを実装します。

### 今日学ぶこと

1. **LCDコントローラー設計**
   - HD44780互換ディスプレイ制御
   - 4ビットインターフェース実装
   - 適切な初期化シーケンス

2. **タイミング制御**
   - LCDタイミング要件
   - 状態機械による制御
   - 非同期インターフェース処理

3. **システム統合**
   - CPUとLCDの統合
   - リアルタイムデータ表示
   - パフォーマンス最適化

4. **ユーザーインターフェース**
   - レジスタ値の視覚化
   - システム状態表示
   - デバッグ情報提供

## 実装内容

### 1. LCD Controller (`lcd_controller.sv`)

HD44780互換LCDの低レベル制御：

```systemverilog
// 初期化シーケンス
// 1. 15ms電源安定化待機
// 2. Function Set (8-bit) × 3回
// 3. Function Set (4-bit)
// 4. Display Off → Clear → Entry Mode → Display On
```

主要機能：
- 4ビットモード通信
- 適切なタイミング制御（27MHz基準）
- コマンド/データ切り替え
- ビジー状態管理

### 2. LCD Display (`lcd_display.sv`)

高レベルディスプレイインターフェース：

```systemverilog
// 機能
// - 文字表示
// - カーソル位置制御
// - 画面クリア
// - 16x2ディスプレイ対応
```

特徴：
- ASCII文字表示
- カーソル位置指定（0-31）
- DDRAMアドレス自動計算
- 操作キューイング

### 3. CPU + LCD System (`cpu_lcd_system.sv`)

統合システム：

```systemverilog
// ディスプレイ内容
// Line 1: "A:XX X:XX"    (AccumulatorとXレジスタ)
// Line 2: "PC:XXXX"      (プログラムカウンタ)
```

リアルタイム更新：
- 0.5秒間隔での自動更新
- 16進数表示（ASCII変換）
- CPUレジスタ監視

### 4. Top Module (`top.sv`)

完全なシステム：
- CPU + メモリ + LCD統合
- デバッグLED制御
- システムアクティビティ表示

## ハードウェア接続

### LCD接続（HD44780互換）

| 信号 | Tang Nanoピン | LCD機能 |
|------|---------------|---------|
| lcd_rs | 71 | Register Select (0=cmd, 1=data) |
| lcd_rw | 53 | Read/Write (常に0=write) |
| lcd_en | 54 | Enable pulse |
| lcd_data[0] | 55 | Data bit 0 |
| lcd_data[1] | 56 | Data bit 1 |
| lcd_data[2] | 57 | Data bit 2 |
| lcd_data[3] | 68 | Data bit 3 |

### 電源接続

```
LCD Pin  Connection
1 (VSS)  -> GND
2 (VDD)  -> +5V
3 (V0)   -> GND (or potentiometer for contrast)
4 (RS)   -> Pin 71
5 (RW)   -> Pin 53
6 (EN)   -> Pin 54
7-10     -> Not connected (4-bit mode)
11 (D4)  -> Pin 55
12 (D5)  -> Pin 56
13 (D6)  -> Pin 57
14 (D7)  -> Pin 68
15 (A)   -> +5V (backlight anode)
16 (K)   -> GND (backlight cathode)
```

## スイッチ制御

### CPUクロック速度制御

| switches[1:0] | CPU速度 | 用途 |
|---------------|---------|------|
| 00 | 1.69MHz | デバッグ（最低速） |
| 01 | 3.375MHz | 観察用（低速） |
| 10 | 6.75MHz | 通常動作（中速） |
| 11 | 27MHz | 最高性能（高速） |

### システム設定

- `switches[2]` - 予約（将来拡張用）
- `switches[3]` - 予約（将来拡張用）

## デバッグLED

| LED | 機能 | 説明 |
|-----|------|------|
| 0 | Heartbeat | システム動作表示（約0.6Hz点滅） |
| 1 | System Active | CPU実行またはLCD更新中 |
| 2 | LCD Ready | LCD操作準備完了 |
| 3 | Switch Echo | switches[0]のエコー |
| 7:4 | Accumulator | Aレジスタ下位4ビット |

## ビルドと実行

### 必要なファイル

```
day09_completed/
├── lcd_controller.sv        # LCDハードウェア制御
├── lcd_display.sv           # LCD高レベルAPI
├── cpu_lcd_system.sv        # CPU+LCD統合
├── top.sv                   # トップレベルモジュール
├── tb_lcd_system.sv         # テストベンチ
├── Makefile                 # ビルドシステム
└── README_ja.md             # この文書

依存ファイル:
└── day08_completed/ (complete CPU core)
└── day07_completed/ (memory system)
└── day06_completed/ (ALU, decoder, status)
└── day05_completed/ (addressing modes)
```

### ビルドコマンド

```bash
# Tang Nano 9K用ビルド
make tang_nano_9k

# Tang Nano 20K用ビルド
make tang_nano_20k

# シミュレーション実行
make run_sim

# FPGAへの書き込み
make program_9k    # Tang Nano 9K
make program_20k   # Tang Nano 20K

# 制約ファイル生成
make constraints
```

## 動作確認

### 初期化シーケンス

1. **電源投入**：Tang Nanoへの電源供給
2. **リセット解除**：reset buttonを離す
3. **LCD初期化**：約20ms後にLCD準備完了
4. **CPU開始**：$C000からプログラム実行開始

### 正常動作の確認

1. **LED確認**：
   - LED0が約0.6Hzで点滅（heartbeat）
   - LED1がシステム動作時に点灯
   - LED2がLCD準備完了時に点灯

2. **LCD表示確認**：
   ```
   A:42 X:00
   PC:C008
   ```

3. **レジスタ値変化**：
   - CPU実行に伴ってA, X値が変化
   - PC値が連続的にインクリメント

### トラブルシューティング

#### LCD表示されない場合

1. **配線確認**：
   - 電源電圧（+5V, GND）
   - 信号線接続
   - コントラスト調整（V0）

2. **タイミング確認**：
   - 初期化待機時間
   - Enable pulse幅
   - セットアップ/ホールドタイム

3. **シミュレーション**：
   ```bash
   make run_sim
   ```

#### CPU動作異常の場合

1. **クロック確認**：スイッチでCPU速度を最低に
2. **レジスタ監視**：デバッグLEDでA値確認
3. **プログラム確認**：ROMコンテンツ検証

## LCD表示内容

### 通常表示

```
Line 1: "A:XX X:XX"
Line 2: "PC:XXXX"
```

例：
```
A:42 X:AA
PC:C010
```

### 16進数表示

- すべて大文字16進数
- レジスタ値は2桁（XX）
- PC値は4桁（XXXX）

## 学習ポイント

### LCDインターフェース設計

1. **タイミング要件**：
   - セットアップタイム：40ns
   - ホールドタイム：10ns
   - Enable pulse幅：1μs以上

2. **初期化シーケンス**：
   - 電源安定化待機（15ms）
   - 機能設定の段階的実行
   - ディスプレイ制御の適切な順序

3. **4ビット通信**：
   - 上位/下位ニブル分割送信
   - Enable pulse制御
   - 適切な遅延挿入

### システム統合

1. **非同期インターフェース**：
   - CPUとLCDの独立動作
   - ビジー状態による排他制御
   - 更新タイミング管理

2. **リアルタイム性**：
   - 定期的データ更新
   - CPUパフォーマンスへの影響最小化
   - ユーザビリティ最適化

3. **デバッグ性**：
   - 複数レベルの状態表示
   - 視覚的フィードバック
   - 段階的トラブルシューティング

## 応用例

### カスタム表示

レジスタ表示をカスタマイズ：

```systemverilog
// Y register とステータスレジスタも表示
Line 1: "A:XX Y:XX"
Line 2: "S:XX PC:XXXX"
```

### 複数ページ表示

スイッチで表示内容切り替え：

```systemverilog
// Page 0: レジスタ
// Page 1: メモリ内容
// Page 2: 実行統計
```

### メッセージ表示

特定条件でのメッセージ：

```systemverilog
// エラー時: "ERROR: HALT"
// 完了時: "PROGRAM DONE"
```

## 次のステップ

Day 10では、実際のアセンブリプログラミング例を作成し、完全な6502開発環境を構築します。

## 参考資料

- HD44780 LCD Controller データシート
- 6502 レジスタ仕様
- Tang Nano I/O制約設計
- SystemVerilog インターフェース設計パターン
- リアルタイムシステム設計原則