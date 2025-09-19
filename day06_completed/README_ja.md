# Day 06: CPUデコーダーとALU

## 学習目標

Day 06では、6502 CPUの中核となる命令デコーダーとALU（算術論理演算装置）を実装します。これまでに作成したコンポーネントを活用して、実際の6502命令を解釈・実行できるシステムを構築します。

### 今日学ぶこと

1. **命令デコーダー設計**
   - 6502命令セットの解析
   - オペコードから制御信号生成
   - アドレッシングモード判定

2. **ALU実装**
   - 算術演算（ADD, SUB）
   - 論理演算（AND, OR, XOR）
   - シフト・ローテート演算
   - フラグ生成（N, Z, C, V）

3. **ステータスレジスタ管理**
   - 6502フラグの正確な実装
   - 命令ごとのフラグ更新制御
   - NV-BDIZC形式の実装

4. **システム統合**
   - デコーダー、ALU、ステータスの連携
   - 実際の6502命令実行
   - デバッグとテスト

## 実装内容

### 1. CPU Decoder (`cpu_decoder.sv`)

6502命令の完全なデコーダー：

```systemverilog
// 主要な命令グループ
// - Load/Store: LDA, LDX, LDY, STA, STX, STY
// - Arithmetic: ADC, SBC
// - Logical: AND, OR, EOR
// - Transfer: TAX, TAY, TXA, TYA
// - Shift: ASL, LSR, ROL, ROR
// - Compare: CMP, CPX, CPY
// - Branch: BCC, BCS, BEQ, BNE, etc.
// - Jump: JMP, JSR, RTS
// - Stack: PHA, PLA, PHP, PLP
// - Flag: SEC, CLC, SEI, CLI, etc.
```

**制御信号生成**：
- ALU操作選択（alu_op[3:0]）
- レジスタ書き込み制御
- メモリアクセス制御
- フラグ更新制御
- データパス選択

### 2. CPU ALU (`cpu_alu.sv`)

完全な6502互換ALU：

#### 算術演算
```systemverilog
ALU_ADD: ADC命令（キャリー付き加算）
ALU_SUB: SBC命令（ボロー付き減算）
```

#### 論理演算
```systemverilog
ALU_AND: AND命令
ALU_OR:  ORA命令
ALU_XOR: EOR命令
```

#### シフト・ローテート
```systemverilog
ALU_ASL: 算術左シフト
ALU_LSR: 論理右シフト
ALU_ROL: 左ローテート（キャリー経由）
ALU_ROR: 右ローテート（キャリー経由）
```

#### その他
```systemverilog
ALU_INC: インクリメント（キャリーに影響しない）
ALU_DEC: デクリメント（キャリーに影響しない）
ALU_CMP: 比較（減算結果のフラグのみ使用）
```

### 3. Status Register (`status_register.sv`)

6502ステータスレジスタ（NV-BDIZC）：

| ビット | フラグ | 名前 | 機能 |
|--------|--------|------|------|
| 7 | N | Negative | 結果の最上位ビット |
| 6 | V | Overflow | 符号付き演算のオーバーフロー |
| 5 | - | Unused | 常に1 |
| 4 | B | Break | BRK命令実行時に設定 |
| 3 | D | Decimal | BCD演算モード |
| 2 | I | Interrupt | 割り込み禁止 |
| 1 | Z | Zero | 結果がゼロ |
| 0 | C | Carry | キャリー/ボロー |

**特徴**：
- 命令ごとの適切なフラグ更新
- SEC/CLC命令での手動制御
- 条件分岐での参照

### 4. Integration Test (`top.sv`)

統合テストシステム：
- 各コンポーネントの連携確認
- 実際の6502命令シーケンス実行
- デバッグ出力による動作確認

## 6502命令セット実装

### Load/Store命令

```systemverilog
LDA #$42    // A = $42, N=0, Z=0
LDA $80     // A = memory[$80]
STA $90     // memory[$90] = A
```

### 算術命令

```systemverilog
CLC         // C = 0
ADC #$10    // A = A + $10 + C
SEC         // C = 1
SBC #$05    // A = A - $05 - (1-C)
```

### 論理命令

```systemverilog
AND #$F0    // A = A & $F0
ORA #$0F    // A = A | $0F
EOR #$FF    // A = A ^ $FF
```

### シフト命令

```systemverilog
ASL A       // A = A << 1, C = old A[7]
LSR A       // A = A >> 1, C = old A[0]
```

### 比較命令

```systemverilog
CMP #$42    // フラグ設定: A - $42
CPX #$10    // フラグ設定: X - $10
```

### レジスタ転送

```systemverilog
TAX         // X = A, N=A[7], Z=(A==0)
TXA         // A = X, N=X[7], Z=(X==0)
```

## ビルドと実行

### 必要なファイル

```
day06_completed/
├── cpu_decoder.sv           # 命令デコーダー
├── cpu_alu.sv              # 算術論理演算装置
├── status_register.sv      # ステータスレジスタ
├── top.sv                  # 統合テストシステム
├── tb_cpu_alu.sv          # ALUテストベンチ
├── Makefile               # ビルドシステム
└── README_ja.md           # この文書

依存ファイル:
└── day05_completed/addressing_mode_calculator.sv
```

### ビルドコマンド

```bash
# Tang Nano 9K用ビルド
make tang_nano_9k

# Tang Nano 20K用ビルド
make tang_nano_20k

# ALUシミュレーション実行
make run_sim

# FPGAへの書き込み
make program_9k    # Tang Nano 9K
make program_20k   # Tang Nano 20K
```

### テスト実行

```bash
# ALU単体テスト
make run_sim

# 統合システムテスト
# Tang NanoのLEDとスイッチで動作確認
```

## デバッグ出力

Tang Nanoのピンでモニターできる信号：

### ALU状態
- `debug_alu_result[7:0]` - ALU演算結果
- `debug_alu_carry` - キャリー出力
- `debug_alu_zero` - ゼロフラグ
- `debug_alu_negative` - ネガティブフラグ
- `debug_alu_overflow` - オーバーフローフラグ

### デコーダー状態
- `debug_alu_op[3:0]` - ALU操作コード
- `debug_reg_a_write` - Aレジスタ書き込み
- `debug_mem_read` - メモリ読み取り
- `debug_mem_write` - メモリ書き込み

### システム状態
- `debug_opcode[7:0]` - 現在の命令コード
- `debug_inst_length[1:0]` - 命令長

## テストプログラム例

### 基本算術テスト

```assembly
LDA #$50    ; A = $50 (80 decimal)
ADC #$30    ; A = $50 + $30 = $80
            ; N=1 (結果が負), V=1 (オーバーフロー)

LDA #$FF    ; A = $FF
ADC #$01    ; A = $FF + $01 = $00
            ; Z=1 (結果がゼロ), C=1 (キャリー発生)
```

### 論理演算テスト

```assembly
LDA #$F0    ; A = $F0 (11110000)
AND #$0F    ; A = $F0 & $0F = $00
            ; Z=1 (結果がゼロ)

LDA #$AA    ; A = $AA (10101010)
EOR #$55    ; A = $AA ^ $55 = $FF
            ; N=1 (結果が負)
```

### シフト演算テスト

```assembly
LDA #$81    ; A = $81 (10000001)
ASL A       ; A = $02 (00000010), C=1
            ; 最上位ビットがキャリーに

LDA #$81    ; A = $81 (10000001)
LSR A       ; A = $40 (01000000), C=1
            ; 最下位ビットがキャリーに
```

## 学習ポイント

### 命令デコーディング

1. **オペコード解析**：
   - 8ビットオペコードから命令特定
   - アドレッシングモード判定
   - 即値/メモリアクセス判定

2. **制御信号生成**：
   - ALU操作選択
   - データパス制御
   - メモリアクセス制御

### ALU設計

1. **演算実装**：
   - 組み合わせ回路での並列演算
   - キャリー伝播の考慮
   - オーバーフロー検出ロジック

2. **フラグ生成**：
   - 各演算でのフラグ更新ルール
   - 6502特有の動作（INC/DECはキャリーに影響しない）

### システム統合

1. **モジュール間連携**：
   - デコーダー → ALU → ステータス
   - 適切なタイミング制御
   - デバッグ可能性の確保

2. **実機検証**：
   - Tang Nanoでの動作確認
   - LEDによる状態表示
   - スイッチによる制御

## トラブルシューティング

### よくある問題

1. **フラグが正しく設定されない**
   - ALUのフラグ生成ロジック確認
   - ステータスレジスタの更新制御確認
   - 命令ごとのフラグ更新ルール確認

2. **演算結果が期待値と異なる**
   - ALU内の演算ロジック確認
   - キャリー入力の設定確認
   - オペランド選択の確認

3. **命令が正しくデコードされない**
   - オペコードパターンマッチング確認
   - case文の網羅性確認
   - デフォルト動作の適切性確認

### デバッグ手法

1. **シミュレーション活用**：
   ```bash
   make run_sim
   # テストベンチでの詳細確認
   ```

2. **段階的テスト**：
   - ALU単体テスト
   - デコーダー単体テスト
   - 統合テスト

3. **実機での確認**：
   - LEDでの状態確認
   - スイッチでの手動制御

## 応用課題

### 機能拡張

1. **命令追加**：
   - 未実装命令の追加
   - 拡張命令セット

2. **最適化**：
   - タイミング改善
   - リソース効率化

3. **デバッグ機能**：
   - ブレークポイント
   - ステップ実行

### 次のステップ

Day 07では、メモリインターフェースとスタック操作を実装し、完全なCPUシステムに向けて進歩します。

## 参考資料

- 6502 Instruction Set Reference
- 6502 Status Register Specification
- SystemVerilog ALU Design Patterns
- CPU Architecture Design Principles