// Traffic Light Controller
// 交通信号制御器 (状態機械)

module traffic_light (
    input  logic clk,
    input  logic rst_n,
    output logic red,
    output logic yellow,
    output logic green
);

    // 状態定義
    typedef enum logic [1:0] {
        RED_STATE    = 2'b00,
        GREEN_STATE  = 2'b01,
        YELLOW_STATE = 2'b10
    } state_t;

    state_t current_state, next_state;
    logic [25:0] timer;

    // 状態遷移とタイマー
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RED_STATE;
            timer <= 26'b0;
        end else begin
            if (timer == 26'd67_108_863) begin  // 約2.5秒 (27MHz基準)
                current_state <= next_state;
                timer <= 26'b0;
            end else begin
                timer <= timer + 1;
                current_state <= current_state;
            end
        end
    end

    // 次状態決定ロジック
    always_comb begin
        case (current_state)
            RED_STATE: begin
                next_state = GREEN_STATE;
            end

            GREEN_STATE: begin
                next_state = YELLOW_STATE;
            end

            YELLOW_STATE: begin
                next_state = RED_STATE;
            end

            default: begin
                next_state = RED_STATE;
            end
        endcase
    end

    // 出力ロジック
    assign red    = (current_state == RED_STATE);
    assign green  = (current_state == GREEN_STATE);
    assign yellow = (current_state == YELLOW_STATE);

endmodule