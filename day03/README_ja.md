# Day 03: SystemVerilog 基礎 (順序回路)

## 🎯 学習目標

- クロック同期回路の概念を理解する
- フリップフロップとラッチの違いを学ぶ
- always_ff文によるレジスタ設計を習得する
- 状態機械 (FSM) の基本を理解する

## 📚 理論学習

### クロック同期回路の基本

**クロックエッジ:**
```systemverilog
always_ff @(posedge clk) begin
    // 立ち上がりエッジで実行
end

always_ff @(negedge clk) begin
    // 立ち下がりエッジで実行
end
```

**リセット付きレジスタ:**
```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter <= 8'b0;
    else
        counter <= counter + 1;
end
```

### 状態機械 (FSM) の基本

**状態の定義:**
```systemverilog
typedef enum logic [1:0] {
    IDLE  = 2'b00,
    START = 2'b01,
    WORK  = 2'b10,
    DONE  = 2'b11
} state_t;

state_t current_state, next_state;
```

## 🛠️ 実習1: カウンタ回路

### 8bit アップカウンタ
```systemverilog
module counter_8bit (
    input  logic clk,
    input  logic rst_n,
    input  logic enable,
    output logic [7:0] count,
    output logic overflow
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'b0;
        end else if (enable) begin
            count <= count + 1;
        end
    end

    assign overflow = (count == 8'hFF) && enable;

endmodule
```

## 🛠️ 実習2: PWM生成器

### 仕様
- 8bit デューティサイクル制御
- 可変周波数対応

```systemverilog
module pwm_generator (
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] duty_cycle,  // 0-255
    output logic pwm_out
);

    logic [7:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'b0;
        end else begin
            counter <= counter + 1;
        end
    end

    assign pwm_out = (counter < duty_cycle);

endmodule
```

## 🛠️ 実習3: 交通信号制御器

### 状態機械による信号制御

```systemverilog
module traffic_light (
    input  logic clk,
    input  logic rst_n,
    output logic red,
    output logic yellow,
    output logic green
);

    typedef enum logic [1:0] {
        RED_STATE    = 2'b00,
        GREEN_STATE  = 2'b01,
        YELLOW_STATE = 2'b10
    } state_t;

    state_t current_state, next_state;
    logic [25:0] timer;

    // 状態遷移ロジック
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RED_STATE;
            timer <= 26'b0;
        end else begin
            current_state <= next_state;
            timer <= timer + 1;
        end
    end

    // 次状態決定ロジック
    always_comb begin
        case (current_state)
            RED_STATE: begin
                if (timer >= 26'd50_000_000)  // 約2秒
                    next_state = GREEN_STATE;
                else
                    next_state = RED_STATE;
            end
            // TODO: 他の状態を実装
            default: next_state = RED_STATE;
        endcase
    end

    // 出力ロジック
    assign red    = (current_state == RED_STATE);
    assign green  = (current_state == GREEN_STATE);
    assign yellow = (current_state == YELLOW_STATE);

endmodule
```

## 📝 課題

### 基礎課題
1. アップ/ダウンカウンタの実装
2. PWMでLEDの明度制御
3. 交通信号制御器の完成

### 発展課題
1. UART送信器の状態機械
2. 可変長シフトレジスタ
3. 分周器の実装

## 📚 今日学んだこと

- [ ] クロック同期回路の基本
- [ ] always_ff文の使用方法
- [ ] 状態機械の設計手法
- [ ] タイマーとカウンタの実装

## 🎯 明日の予習

Day 04では6502 CPUアーキテクチャについて学習します:
- CPUの基本構成要素
- レジスタとメモリの関係
- 命令実行サイクル