/* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off UNUSEDSIGNAL */
// Day 04 Completed: System Core (LCD + CPU Registers)
//
// This module integrates the foundational blocks of our 6502-based FPGA system:
// 1. LCD Rendering Pipeline: Displays internal states visually.
// 2. CPU Register Set: Implements the 6502 internal registers (A, X, Y, PC, SP, P).
// 3. Instruction Decoder: Classifies opcodes into categories for control logic.
//
// 学習目標:
// 1. LCDレンダリングパイプラインの統合 (内部状態の可視化)
// 2. 6502内部レジスタセット (A, X, Y, PC, SP, P) の実装
// 3. 命令デコーダによるオペコードの分類と制御信号の生成

module top_core (
    input logic       rst_n,    // Active-low reset / 非アクティブ低レベル・リセット
    input logic       XTAL_IN,  // 27MHz Main Clock / 27MHz メインクロック入力
    input logic [3:0] switches, // Debug switches / デバッグ用スイッチ

    // LCD Signals / LCDインターフェース信号
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B,

    // Debug LEDs (Instruction categories) / デバッグ用LED (命令カテゴリ表示)
    output logic led_load,        // Lit if LDA/LDX/LDY / LDA/LDX/LDYの時に点灯
    output logic led_store,       // Lit if STA/STX/STY / STA/STX/STYの時に点灯
    output logic led_arithmetic,  // Lit if ADC/SBC etc. / ADC/SBC等の算術演算時に点灯
    output logic led_branch       // Lit if BNE/BEQ etc. / BNE/BEQ等の分岐命令時に点灯
);

    // -------------------------------------------------------------------------
    // 1. LCD Demo Instance / LCDデモ・モジュールのインスタンス化
    // -------------------------------------------------------------------------
    // Generates the timing and pixel data for the TFT display.
    // 液晶表示用のタイミング信号とピクセルデータを生成します。
    lcd_demo u_demo (
        .rst_n  (rst_n),
        .XTAL_IN(XTAL_IN),
        .LCD_CLK(LCD_CLK),
        .LCD_DEN(LCD_DEN),
        .LCD_R  (LCD_R),
        .LCD_G  (LCD_G),
        .LCD_B  (LCD_B)
    );

    // -------------------------------------------------------------------------
    // 2. CPU Register Set / CPUレジスタセットの統合
    // -------------------------------------------------------------------------
    // We instantiate the register set and connect it to a test controller.
    // In this stage, we use LCD_CLK (approx. 9MHz) as the CPU clock for simplicity.
    // The CPU registers (A, X, Y, PC, SP, P) hold the internal state of the 6502.
    //
    // レジスタセットをインスタンス化し、テストコントローラに接続します。
    // この段階では、簡略化のためLCD_CLK(約9MHz)をCPUクロックとして使用します。
    // CPUレジスタ(A, X, Y, PC, SP, P)は6502の内部状態を保持します。

    logic [ 7:0] demo_opcode;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [15:0] reg_pc;
    logic [7:0] reg_a, reg_x, reg_y, reg_sp, reg_p;

    logic a_write, x_write, y_write, sp_write, pc_write, p_write;
    logic [ 7:0] demo_data;
    logic [15:0] demo_addr;

    cpu_registers registers (
        .clk(LCD_CLK),
        .rst_n(rst_n),
        .a_write(a_write),  // Enable write to A / Aレジスタへの書き込み有効
        .x_write(x_write),  // Enable write to X / Xレジスタへの書き込み有効
        .y_write(y_write),  // Enable write to Y / Yレジスタへの書き込み有効
        .sp_write(sp_write),  // Enable write to SP / SPへの書き込み有効
        .pc_write(pc_write),  // Enable write to PC / PCへの書き込み有効
        .p_write(p_write),  // Enable write to P / Pレジスタへの書き込み有効
        .data_in(demo_data),  // 8-bit data input / 8ビットデータ入力
        .addr_in(demo_addr),  // 16-bit address input (for PC) / 16ビットアドレス入力(PC用)
        .reg_a(reg_a),
        .reg_x(reg_x),
        .reg_y(reg_y),
        .reg_sp(reg_sp),
        .reg_pc(reg_pc),
        .reg_p(reg_p)
    );

    // -------------------------------------------------------------------------
    // 3. Instruction Decoder / 命令デコーダ
    // -------------------------------------------------------------------------
    // Decodes the current 'demo_opcode' and drives the LEDs based on category.
    // This allows us to visually verify that the decoder correctly identifies
    // the current instruction being executed (or tested).
    //
    // 現在の'demo_opcode'をデコードし、命令のカテゴリに応じてLEDを駆動します。
    // これにより、デコーダが現在実行(またはテスト)されている命令を正しく
    // 識別していることを視覚的に確認できます。
    /* verilator lint_off PINCONNECTEMPTY */
    simple_decoder decoder (
        .opcode       (demo_opcode),
        .is_load      (led_load),        // LDA, LDX, LDY
        .is_store     (led_store),       // STA, STX, STY
        .is_transfer  (),
        .is_arithmetic(led_arithmetic),  // ADC, SBC
        .is_logical   (),
        .is_shift     (),
        .is_branch    (led_branch),      // BPL, BMI, BNE, BEQ, etc.
        .is_jump      (),
        .is_compare   (),
        .is_flag      (),
        .is_stack     (),
        .is_nop       ()
    );


    // -------------------------------------------------------------------------
    // 4. Flag Calculator / フラグ計算
    // -------------------------------------------------------------------------
    // Calculates status flags (N, V, Z, C) based on ALU results.
    // ALUの結果に基づき、ステータスフラグ(N, V, Z, C)を計算します。
    // In Day 04, we just check its existence.
    // Day 04では、存在確認とインスタンス化のみを行います。
    logic [7:0] dummy_res;
    /* verilator lint_off UNUSEDSIGNAL */
    logic dummy_c_in, dummy_c_out, dummy_v_out, dummy_z_out, dummy_n_out;

    assign dummy_res  = demo_data;
    assign dummy_c_in = 1'b0;

    flag_calculator u_flags (
        .result(dummy_res),
        .operand_a(reg_a),
        .operand_b(demo_data),
        .operation(1'b0),  // ADC
        .carry_in(dummy_c_in),
        .flag_n(dummy_n_out),
        .flag_z(dummy_z_out),
        .flag_c(dummy_c_out),
        .flag_v(dummy_v_out)
    );

    // -------------------------------------------------------------------------
    // 5. Demo Sequence Controller / デモシーケンス制御
    // -------------------------------------------------------------------------
    // A simple state machine that rotates through several opcodes and
    // register writes every ~1.8 seconds (2^24 clock cycles) for observation.
    // This allows us to see the LEDs and LCD change without high-speed capture.
    //
    // 約1.8秒毎(2^24クロック)にオペコードとレジスタへの書き込みを切り替え、
    // 実機での動作確認を容易にするための簡易ステートマシンです。
    // これにより、高速なキャプチャ機器がなくてもLEDやLCDの変化を目視で確認できます。
    logic [24:0] demo_counter;
    logic [ 2:0] demo_state;

    always_ff @(posedge LCD_CLK or negedge rst_n) begin
        if (!rst_n) begin
            demo_counter <= 25'b0;
            demo_state <= 3'b000;
            {a_write, x_write, y_write, sp_write, pc_write, p_write} <= 6'b0;
            demo_opcode <= 8'hEA;  // NOP (No Operation)
        end else begin
            demo_counter <= demo_counter + 1;
            {a_write, x_write, y_write, sp_write, pc_write, p_write} <= 6'b000000;

            if (demo_counter[24]) begin
                // Transition to the next test state periodically.
                // 定期的に次のテストステートへ遷移します。
                demo_counter <= 25'b0;
                demo_state   <= demo_state + 1;

                case (demo_state)
                    // Write 0x55 to A (LDA Immediate)
                    3'b000: begin
                        a_write <= 1'b1;
                        demo_data <= 8'h55;
                        demo_opcode <= 8'hA9;
                    end
                    // Write 0xAA to X (LDX Immediate)
                    3'b001: begin
                        x_write <= 1'b1;
                        demo_data <= 8'hAA;
                        demo_opcode <= 8'hA2;
                    end
                    // Write 0x33 to Y (LDY Immediate)
                    3'b010: begin
                        y_write <= 1'b1;
                        demo_data <= 8'h33;
                        demo_opcode <= 8'hA0;
                    end
                    // Jump to 0x1234 (JMP Absolute)
                    3'b011: begin
                        pc_write <= 1'b1;
                        demo_addr <= 16'h1234;
                        demo_opcode <= 8'h4C;
                    end
                    // STA (Store A) - Lit LED Store
                    3'b100: begin
                        demo_opcode <= 8'h85;
                    end
                    // ADC (Add with Carry) - Lit LED Arithmetic
                    3'b101: begin
                        demo_opcode <= 8'h69;
                    end
                    // BPL (Branch on Plus) - Lit LED Branch
                    3'b110: begin
                        demo_opcode <= 8'h10;
                    end
                    // NOP (No Operation)
                    3'b111: begin
                        demo_opcode <= 8'hEA;
                    end
                endcase
            end

            // Manual override via switches / スイッチによる手動オペコード指定
            // If switch[3] is ON, the opcode is forced based on switch[2:0].
            // switch[3]がONの場合、switch[2:0]に基づいてオペコードを強制指定します。
            if (switches[3]) begin
                case (switches[2:0])
                    3'b000: demo_opcode <= 8'hA9;  // LDA
                    3'b001: demo_opcode <= 8'h85;  // STA
                    3'b010: demo_opcode <= 8'h69;  // ADC
                    3'b011: demo_opcode <= 8'h10;  // BPL
                    3'b100: demo_opcode <= 8'hAA;  // TAX
                    3'b101: demo_opcode <= 8'h4C;  // JMP
                    3'b110: demo_opcode <= 8'hC9;  // CMP
                    3'b111: demo_opcode <= 8'hEA;  // NOP
                endcase
            end
        end
    end

endmodule
