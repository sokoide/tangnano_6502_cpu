# Day 07: CPU 実装 Part 2 - メモリインターフェース

## 🎯 学習目標

- メモリバスインターフェースの設計と実装
- スタック操作の詳細実装
- アドレス生成ユニットの実装
- メモリマップI/Oの基本理解

## 📚 理論学習

### メモリアクセスの種類

**命令フェッチ:**
- PCからの命令読み出し
- 1-3バイトの可変長

**データアクセス:**
- Load/Store命令によるデータ読み書き
- アドレッシングモードに依存

**スタックアクセス:**
- PUSH/POP操作
- JSR/RTS でのアドレス保存・復帰

**間接アドレッシング:**
- JMP ($nnnn)
- (zp,X) / (zp),Y アドレッシング

### スタックの動作

**6502スタックの特徴:**
- 固定領域: $0100-$01FF
- ダウンワード: 高位アドレスから低位アドレスへ
- 8bitスタックポインタ: $FF → $00

## 🛠️ 実習1: メモリコントローラ

```systemverilog
module memory_controller (
    input  logic clk,
    input  logic rst_n,

    // CPU側インターフェース
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  cpu_data_out,
    output logic [7:0]  cpu_data_in,
    input  logic        cpu_read,
    input  logic        cpu_write,
    output logic        cpu_ready,

    // 外部メモリインターフェース
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_read,
    output logic        mem_write,
    output logic        mem_enable,

    // 特殊領域制御
    output logic        vram_access,
    output logic        rom_access
);

    // メモリマップ判定
    always_comb begin
        vram_access = (cpu_addr >= 16'hE000) && (cpu_addr <= 16'hE3FF);
        rom_access  = (cpu_addr >= 16'hF000);

        // 通常のメモリアクセス
        mem_addr = cpu_addr;
        mem_data_out = cpu_data_out;
        mem_read = cpu_read && !vram_access && !rom_access;
        mem_write = cpu_write && !vram_access && !rom_access;
        mem_enable = cpu_read || cpu_write;
    end

    // CPUへのデータ返送
    always_comb begin
        if (rom_access) begin
            cpu_data_in = 8'h00;  // ROMデータ (別途実装)
        end else if (vram_access) begin
            cpu_data_in = 8'h00;  // VRAMデータ (別途実装)
        end else begin
            cpu_data_in = mem_data_in;
        end
    end

    // 簡易レディ制御 (実際は待機サイクルが必要な場合)
    assign cpu_ready = 1'b1;

endmodule
```

## 🛠️ 実習2: スタック制御ユニット

```systemverilog
module stack_controller (
    input  logic clk,
    input  logic rst_n,

    // スタック操作制御
    input  logic stack_push,
    input  logic stack_pop,
    input  logic [7:0] push_data,
    output logic [7:0] pop_data,

    // スタックポインタ
    input  logic sp_write,
    input  logic [7:0] sp_data_in,
    output logic [7:0] stack_pointer,

    // メモリインターフェース
    output logic [15:0] stack_addr,
    output logic [7:0]  stack_data_out,
    input  logic [7:0]  stack_data_in,
    output logic        stack_read,
    output logic        stack_write
);

    logic [7:0] sp_reg;

    // スタックポインタ管理
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sp_reg <= 8'hFF;  // 初期値は最上位
        end else begin
            if (sp_write) begin
                sp_reg <= sp_data_in;
            end else if (stack_push) begin
                sp_reg <= sp_reg - 1;  // プッシュ後にデクリメント
            end else if (stack_pop) begin
                sp_reg <= sp_reg + 1;  // ポップ前にインクリメント
            end
        end
    end

    assign stack_pointer = sp_reg;

    // スタックアドレス生成
    always_comb begin
        if (stack_push) begin
            stack_addr = {8'h01, sp_reg};  // プッシュ: 現在のSP
            stack_data_out = push_data;
            stack_write = 1'b1;
            stack_read = 1'b0;
        end else if (stack_pop) begin
            stack_addr = {8'h01, sp_reg + 1};  // ポップ: SP+1
            stack_data_out = 8'h00;
            stack_write = 1'b0;
            stack_read = 1'b1;
        end else begin
            stack_addr = {8'h01, sp_reg};
            stack_data_out = 8'h00;
            stack_write = 1'b0;
            stack_read = 1'b0;
        end
    end

    assign pop_data = stack_data_in;

endmodule
```

## 🛠️ 実習3: アドレス生成ユニット

```systemverilog
module address_generator (
    input  logic [7:0]  opcode,
    input  logic [7:0]  operand1,
    input  logic [7:0]  operand2,
    input  logic [15:0] pc,
    input  logic [7:0]  reg_x,
    input  logic [7:0]  reg_y,

    // 間接アドレッシング用メモリ読み出し
    input  logic [7:0]  indirect_data_low,
    input  logic [7:0]  indirect_data_high,

    output logic [15:0] effective_address,
    output logic [15:0] indirect_read_addr,
    output logic        need_indirect_read,
    output logic        page_crossed
);

    logic [15:0] base_addr;
    logic [15:0] indexed_addr;

    always_comb begin
        // デフォルト値
        effective_address = 16'h0000;
        indirect_read_addr = 16'h0000;
        need_indirect_read = 1'b0;
        page_crossed = 1'b0;

        case (opcode)
            // Immediate - 次のバイトを直接使用
            8'hA9, 8'h69: begin
                effective_address = pc + 1;
            end

            // Zero Page
            8'hA5, 8'h85: begin
                effective_address = {8'h00, operand1};
            end

            // Zero Page,X
            8'hB5, 8'h95: begin
                effective_address = {8'h00, operand1 + reg_x};
            end

            // Absolute
            8'hAD, 8'h8D: begin
                effective_address = {operand2, operand1};
            end

            // Absolute,X
            8'hBD, 8'h9D: begin
                base_addr = {operand2, operand1};
                indexed_addr = base_addr + {8'h00, reg_x};
                effective_address = indexed_addr;
                // ページ境界越えチェック
                page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
            end

            // Absolute,Y
            8'hB9, 8'h99: begin
                base_addr = {operand2, operand1};
                indexed_addr = base_addr + {8'h00, reg_y};
                effective_address = indexed_addr;
                page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
            end

            // (Zero Page,X) - Indexed Indirect
            8'hA1, 8'h81: begin
                indirect_read_addr = {8'h00, operand1 + reg_x};
                need_indirect_read = 1'b1;
                effective_address = {indirect_data_high, indirect_data_low};
            end

            // (Zero Page),Y - Indirect Indexed
            8'hB1, 8'h91: begin
                indirect_read_addr = {8'h00, operand1};
                need_indirect_read = 1'b1;
                base_addr = {indirect_data_high, indirect_data_low};
                indexed_addr = base_addr + {8'h00, reg_y};
                effective_address = indexed_addr;
                page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
            end

            // Indirect (JMP only)
            8'h6C: begin
                indirect_read_addr = {operand2, operand1};
                need_indirect_read = 1'b1;
                effective_address = {indirect_data_high, indirect_data_low};
            end

            default: begin
                effective_address = pc;
            end
        endcase
    end

endmodule
```

## 🛠️ 実習4: JSR/RTS 実装

```systemverilog
module subroutine_controller (
    input  logic clk,
    input  logic rst_n,

    input  logic jsr_execute,  // JSR命令実行
    input  logic rts_execute,  // RTS命令実行
    input  logic [15:0] jsr_target,
    input  logic [15:0] current_pc,

    // スタック制御
    output logic stack_push,
    output logic stack_pop,
    output logic [7:0] push_data,
    input  logic [7:0] pop_data,

    // PC制御
    output logic pc_write,
    output logic [15:0] new_pc,

    // 状態
    output logic operation_complete
);

    typedef enum logic [2:0] {
        IDLE,
        JSR_PUSH_HIGH,
        JSR_PUSH_LOW,
        JSR_JUMP,
        RTS_POP_LOW,
        RTS_POP_HIGH,
        RTS_JUMP
    } state_t;

    state_t current_state, next_state;
    logic [15:0] return_address;
    logic [15:0] target_address;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            return_address <= 16'h0000;
            target_address <= 16'h0000;
        end else begin
            current_state <= next_state;
            if (jsr_execute) begin
                return_address <= current_pc + 2;  // JSRは3バイト命令
                target_address <= jsr_target;
            end
        end
    end

    always_comb begin
        next_state = current_state;
        stack_push = 1'b0;
        stack_pop = 1'b0;
        push_data = 8'h00;
        pc_write = 1'b0;
        new_pc = 16'h0000;
        operation_complete = 1'b0;

        case (current_state)
            IDLE: begin
                if (jsr_execute) begin
                    next_state = JSR_PUSH_HIGH;
                end else if (rts_execute) begin
                    next_state = RTS_POP_LOW;
                end
                operation_complete = 1'b1;
            end

            JSR_PUSH_HIGH: begin
                stack_push = 1'b1;
                push_data = return_address[15:8];  // 上位バイト
                next_state = JSR_PUSH_LOW;
            end

            JSR_PUSH_LOW: begin
                stack_push = 1'b1;
                push_data = return_address[7:0];   // 下位バイト
                next_state = JSR_JUMP;
            end

            JSR_JUMP: begin
                pc_write = 1'b1;
                new_pc = target_address;
                next_state = IDLE;
            end

            RTS_POP_LOW: begin
                stack_pop = 1'b1;
                next_state = RTS_POP_HIGH;
                return_address[7:0] <= pop_data;
            end

            RTS_POP_HIGH: begin
                stack_pop = 1'b1;
                next_state = RTS_JUMP;
                return_address[15:8] <= pop_data;
            end

            RTS_JUMP: begin
                pc_write = 1'b1;
                new_pc = return_address + 1;  // RTSは戻り先+1
                next_state = IDLE;
            end
        endcase
    end

endmodule
```

## 📝 課題

### 基礎課題
1. PHA/PLA (スタックへのレジスタプッシュ/ポップ) 実装
2. 間接アドレッシングのページ境界バグ再現
3. メモリアクセス待機サイクルの実装

### 発展課題
1. DMAコントローラとの協調動作
2. メモリ保護機能の実装
3. キャッシュメモリの基本設計

## 📚 今日学んだこと

- [ ] メモリバスインターフェース設計
- [ ] スタック操作の詳細実装
- [ ] アドレス生成の複雑さ
- [ ] JSR/RTSの状態機械実装
- [ ] メモリマップI/Oの基本

## 🎯 明日の予習

Day 08では CPU コアの統合とテストを行います:
- 各モジュールの結合
- 命令実行サイクル制御
- 基本プログラムでの動作確認