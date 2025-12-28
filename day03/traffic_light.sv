// Traffic Light Controller
// 交通信号制御器 (状態機械)

module traffic_light #(
    parameter TIMER_LIMIT_RED    = 26'd50_000_000,  // Approx. 2 seconds @ 27MHz
    parameter TIMER_LIMIT_GREEN  = 26'd50_000_000,
    parameter TIMER_LIMIT_YELLOW = 26'd25_000_000   // Approx. 1 second
) (
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

    // State transition logic (Sequential)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RED_STATE;
            timer <= 26'b0;
        end else begin
            if (current_state != next_state) begin
                current_state <= next_state;
                timer <= 26'b0;
            end else begin
                timer <= timer + 1;
            end
        end
    end

    // Next state decision logic (Combinational)
    always_comb begin
        case (current_state)
            RED_STATE: begin
                if (timer >= TIMER_LIMIT_RED)
                    next_state = GREEN_STATE;
                else
                    next_state = RED_STATE;
            end

            // TODO: Implement GREEN_STATE (transitions to YELLOW_STATE)
            // TODO: Implement YELLOW_STATE (transitions back to RED_STATE)

            default: begin
                next_state = RED_STATE;
            end
        endcase
    end

    // Output logic
    assign red    = (current_state == RED_STATE);
    assign green  = (current_state == GREEN_STATE);
    assign yellow = (current_state == YELLOW_STATE);

endmodule
