// Day 04: System Core (LCD + CPU Registers) - Skeleton
//
// 学習目標:
// 1. LCDレンダリングパイプラインの統合
// 2. CPUレジスタセットの実装と検証
// 3. 命令デコーダによる命令の分類

module top_core (
    input logic       rst_n,
    input logic       XTAL_IN,
    input logic [3:0] switches,

    // LCD Signals
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B,

    // Debug LEDs
    output logic led_load,
    output logic led_store,
    output logic led_arithmetic,
    output logic led_branch
);

    // -------------------------------------------------------------------------
    // STEP 1: LCD Demo Instance / LCDデモ・モジュールのインスタンス化
    // -------------------------------------------------------------------------
    // TODO: 液晶表示用の lcd_demo モジュールを "u_demo" という名前でインスタンス化してください。
    // XTAL_IN (27MHz) を入力し、各種LCD信号を出力に接続します。
    // これにより、実機での表示機能が有効になります。


    // -------------------------------------------------------------------------
    // STEP 2: CPU Register Set / CPUレジスタセットの統合
    // -------------------------------------------------------------------------
    // TODO: CPUレジスタセット (cpu_registers) を "registers" という名前でインスタンス化してください。
    // クロックには LCD_CLK を使用し、リセット信号を接続します。
    // テストシーケンス制御信号 (a_write, data_in等) を各ポートに接続してください。


    // -------------------------------------------------------------------------
    // STEP 3: Instruction Decoder / 命令デコーダ
    // -------------------------------------------------------------------------
    // TODO: 簡易デコーダ (simple_decoder) を "decoder" という名前でインスタンス化してください。
    // test_opcode を入力し、出力を led_load 等のLED出力信号に接続します。


    // -------------------------------------------------------------------------
    // STEP 4: Flag Calculator / フラグ計算
    // -------------------------------------------------------------------------
    // TODO: フラグ計算モジュール (flag_calculator) を "u_flags" という名前でインスタンス化してください。
    // 演算結果 (test_data等) を接続し、フラグが正しく変化することを確認します。
    // (注: Day 04ではモジュールを正しく接続できることが目標です)


    // --- テストシーケンス制御 (以下は実装済みですが、内容を理解してください) ---
    logic [ 7:0] test_opcode;
    logic [15:0] reg_pc;
    logic [7:0] reg_a, reg_x, reg_y, reg_sp, reg_p;
    logic a_write, x_write, y_write, sp_write, pc_write, p_write;
    logic [ 7:0] test_data;
    logic [15:0] test_addr;

    logic [24:0] test_counter;
    logic [ 2:0] test_state;

    always_ff @(posedge LCD_CLK or negedge rst_n) begin
        if (!rst_n) begin
            test_counter <= 25'b0;
            test_state <= 3'b000;
            {a_write, x_write, y_write, sp_write, pc_write, p_write} <= 6'b0;
            test_opcode <= 8'hEA;
        end else begin
            test_counter <= test_counter + 1;
            {a_write, x_write, y_write, sp_write, pc_write, p_write} <= 6'b000000;

            if (test_counter[24]) begin
                test_counter <= 25'b0;
                test_state   <= test_state + 1;

                case (test_state)
                    3'b000: begin
                        a_write <= 1'b1;
                        test_data <= 8'h55;
                        test_opcode <= 8'hA9;
                    end  // LDA
                    3'b001: begin
                        x_write <= 1'b1;
                        test_data <= 8'hAA;
                        test_opcode <= 8'hA2;
                    end  // LDX
                    3'b010: begin
                        y_write <= 1'b1;
                        test_data <= 8'h33;
                        test_opcode <= 8'hA0;
                    end  // LDY
                    3'b011: begin
                        pc_write <= 1'b1;
                        test_addr <= 16'h1234;
                        test_opcode <= 8'h4C;
                    end  // JMP
                    3'b100: begin
                        test_opcode <= 8'h85;
                    end  // STA
                    3'b101: begin
                        test_opcode <= 8'h69;
                    end  // ADC
                    3'b110: begin
                        test_opcode <= 8'h10;
                    end  // BPL
                    3'b111: begin
                        test_opcode <= 8'hEA;
                    end  // NOP
                endcase
            end

            if (switches[3]) begin
                case (switches[2:0])
                    3'b000: test_opcode <= 8'hA9;
                    3'b001: test_opcode <= 8'h85;
                    3'b010: test_opcode <= 8'h69;
                    3'b011: test_opcode <= 8'h10;
                    3'b100: test_opcode <= 8'hAA;
                    3'b101: test_opcode <= 8'h4C;
                    3'b110: test_opcode <= 8'hC9;
                    3'b111: test_opcode <= 8'hEA;
                endcase
            end
        end
    end

endmodule
