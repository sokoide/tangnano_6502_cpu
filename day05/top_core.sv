// Day 05: CPU Core (Registers & Program Counter) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Instantiation of CPU module / CPUモジュールのインスタンス化
// 2. Implementation of Register Set / レジスタセットの実装
// 3. Wiring to display the PC value on the LCD / PCの値をLCDに表示するための配線

module top_core (
    input logic       clk,
    input logic       rst_n,
    input logic [3:0] switches,

    // Debug outputs for LCD
    output logic [15:0] debug_pc,
    output logic [ 7:0] debug_reg_a,
    output logic [ 7:0] debug_reg_x,
    output logic [ 7:0] debug_reg_y
);

    // -------------------------------------------------------------------------
    // STEP 1: Register Set / レジスタセットの統合
    // -------------------------------------------------------------------------
    // TODO: Instantiate the CPU register set (cpu_registers) as "registers".
    // TODO: CPUレジスタセット (cpu_registers) を "registers" という名前でインスタンス化してください。

    logic [7:0] reg_a, reg_x, reg_y, reg_sp, reg_p;
    logic [15:0] reg_pc;

    /*
    cpu_registers registers (
        .clk(clk),
        .rst_n(rst_n),
        .a_write(1'b0),
        .x_write(1'b0),
        .y_write(1'b0),
        .sp_write(1'b0),
        .pc_write(1'b0),
        .p_write(1'b0),
        .data_in(8'h00),
        .addr_in(16'h0000),
        .reg_a(reg_a),
        .reg_x(reg_x),
        .reg_y(reg_y),
        .reg_sp(reg_sp),
        .reg_pc(reg_pc),
        .reg_p(reg_p)
    );
    */

    // -------------------------------------------------------------------------
    // STEP 2: CPU Heart / CPU 本体の統合
    // -------------------------------------------------------------------------
    // TODO: Instantiate the CPU module as "u_cpu".
    // TODO: CPU モジュールを "u_cpu" という名前でインスタンス化してください。

    logic [15:0] cpu_pc;
    logic        pc_enable;

    /*
    cpu u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .address_bus(),
        .debug_pc(cpu_pc)
    );
    */

    // --- Debug enable signal generation ---
    // LCD表示で数値の変化を確認しやすくするため、クロックを分周します。
    logic [23:0] counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 24'd0;
        end else begin
            counter <= counter + 1'b1;
        end
    end
    assign pc_enable = (counter == 24'd0);

    // Output connections
    assign debug_pc = cpu_pc;
    assign debug_reg_a = reg_a;
    assign debug_reg_x = reg_x;
    assign debug_reg_y = reg_y;

endmodule
