// LCD demo repurposed from Day 09 so that Day 04 introduces the display early.
`include "include/consts.svh"
module lcd_demo (
    input  logic       rst_n,
    input  logic       XTAL_IN,
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B
);

    logic [9:0] vram_addr;
    logic [7:0] vram_data;
    logic [11:0] font_addr;
    logic [7:0] font_data;
    /* verilator lint_off UNUSEDSIGNAL */
    logic vsync;
    /* verilator lint_on UNUSEDSIGNAL */
    logic       vram_cea;
    logic [9:0] vram_ada;
    logic [7:0] vram_din;

`ifdef VERILATOR
    // Simulation path: keep everything in the PixelClk domain with simple models.
    Gowin_rPLL9 pll_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    font_rom font_inst (
        .clk (LCD_CLK),
        .addr(font_addr),
        .data(font_data)
    );

    vram vram_inst (
        .clk  (LCD_CLK),
        .rst_n(rst_n),
        .addr (vram_addr),
        .data (vram_data)
    );
`else
    // FPGA path: match the stable day99 display path (fast MEMORY_CLK + BRAM/pROM).
    logic MEMORY_CLK;

    Gowin_rPLL9 pll9_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    Gowin_rPLL40 pll40_inst (
        .clkout(MEMORY_CLK),
        .clkin (XTAL_IN)
    );

    // Font pROM (Sweet16Font, 4KB: 16 bytes/char x 256 chars)
    Gowin_pROM_font prom_font_inst (
        .dout (font_data),
        .clk  (MEMORY_CLK),
        .oce  (1'b1),
        .ce   (1'b1),
        .reset(1'b0),
        .ad   (font_addr)
    );

    // VRAM in SDPB (1KB)
    logic [9:0] vram_adb_sync1, vram_adb_sync2;
    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            vram_adb_sync1 <= 10'd0;
            vram_adb_sync2 <= 10'd0;
        end else begin
            vram_adb_sync1 <= vram_addr;
            vram_adb_sync2 <= vram_adb_sync1;
        end
    end

    Gowin_SDPB_vram vram_inst (
        .dout  (vram_data),
        .clka  (MEMORY_CLK),
        .cea   (vram_cea),
        .reseta(1'b0),
        .clkb  (MEMORY_CLK),
        .ceb   (1'b1),
        .resetb(1'b0),
        .oce   (1'b0),
        .ada   (vram_ada),
        .din   (vram_din),
        .adb   (vram_adb_sync2)
    );
`endif

    // --- Shared Logic (Common for Simulation and FPGA) ---

    // CPU and RAM/ROM signals
    logic [15:0] cpu_address_bus;
    logic [7:0]  cpu_data_in;
    logic [15:0] cpu_debug_pc;
    logic [7:0]  cpu_debug_a;
    logic [7:0]  cpu_debug_x;
    logic [7:0]  cpu_debug_y;
    logic [7:0]  cpu_debug_p;
    logic [7:0]  cpu_debug_s;
    logic [7:0]  cpu_data_out;
    logic        cpu_write_en;

    logic [7:0]  ram_data_out;
    logic [7:0]  rom_data_out;

    // Slow down PC increment for visual debugging (if on FPGA)
    logic [23:0] counter;
    logic        pc_enable;

`ifdef VERILATOR
    assign pc_enable = 1'b1; // Run full speed in simulation
`else
    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) counter <= 24'd0;
        else counter <= counter + 1;
    end
    assign pc_enable = (counter == 24'd0);
`endif

    cpu u_cpu (
        .clk(`ifdef VERILATOR LCD_CLK `else MEMORY_CLK `endif),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .address_bus(cpu_address_bus),
        .data_in(cpu_data_in),
        .data_out(cpu_data_out),
        .write_en(cpu_write_en),
        .debug_pc(cpu_debug_pc),
        .debug_a(cpu_debug_a),
        .debug_x(cpu_debug_x),
        .debug_y(cpu_debug_y),
        .debug_p(cpu_debug_p),
        .debug_s(cpu_debug_s)
    );

    // Memory (ROM)
    rom u_rom (
        .addr(cpu_address_bus),
        .data(rom_data_out)
    );

    // Memory (RAM for ZP and Stack: $0000-$01FF)
    ram u_ram (
        .clk(`ifdef VERILATOR LCD_CLK `else MEMORY_CLK `endif),
        .addr(cpu_address_bus[8:0]),
        .write_en(cpu_write_en && (cpu_address_bus[15:9] == 7'b0000000)), // $0000-$01FF
        .din(cpu_data_out),
        .dout(ram_data_out)
    );

    always_comb begin
        if (cpu_address_bus[15:9] == 7'b0000000) begin
            cpu_data_in = ram_data_out;
        end else begin
            cpu_data_in = rom_data_out;
        end
    end

    // --- End of Shared Logic ---

    // VRAM writer for CPU debug info (Continue with VRAM update logic...)


    // VRAM writer for CPU debug info
    function automatic logic [7:0] to_hex(input logic [3:0] val);
        case (val)
            4'h0: to_hex = "0";
            4'h1: to_hex = "1";
            4'h2: to_hex = "2";
            4'h3: to_hex = "3";
            4'h4: to_hex = "4";
            4'h5: to_hex = "5";
            4'h6: to_hex = "6";
            4'h7: to_hex = "7";
            4'h8: to_hex = "8";
            4'h9: to_hex = "9";
            4'hA: to_hex = "A";
            4'hB: to_hex = "B";
            4'hC: to_hex = "C";
            4'hD: to_hex = "D";
            4'hE: to_hex = "E";
            4'hF: to_hex = "F";
            default: to_hex = "?";
        endcase
    endfunction

    typedef enum logic [5:0] {
        S_IDLE,
        S_WRITE_P, S_WRITE_C, S_WRITE_COLON, S_WRITE_PC3, S_WRITE_PC2, S_WRITE_PC1, S_WRITE_PC0,
        S_WRITE_SPACE1,
        S_WRITE_A_LABEL, S_WRITE_A_COLON, S_WRITE_A1, S_WRITE_A0,
        S_WRITE_SPACE2,
        S_WRITE_X_LABEL, S_WRITE_X_COLON, S_WRITE_X1, S_WRITE_X0,
        S_WRITE_SPACE3,
        S_WRITE_Y_LABEL, S_WRITE_Y_COLON, S_WRITE_Y1, S_WRITE_Y0,
        S_WRITE_SPACE4,
        S_WRITE_S_LABEL, S_WRITE_S_COLON, S_WRITE_S1, S_WRITE_S0,
        S_WRITE_SPACE5,
        S_WRITE_P_LABEL, S_WRITE_P_COLON, S_WRITE_P1, S_WRITE_P0
    } vram_write_state_t;
    vram_write_state_t vram_write_state;

    always_ff @(posedge `ifdef VERILATOR LCD_CLK `else MEMORY_CLK `endif or negedge rst_n) begin
        if (!rst_n) begin
            vram_cea <= 1'b0;
            vram_ada <= 10'd0;
            vram_din <= 8'h20;
            vram_write_state <= S_IDLE;
        end else begin
            vram_cea <= 1'b0; // Default to no write
            case (vram_write_state)
                S_IDLE: if (vsync) vram_write_state <= S_WRITE_P; // Start writing on vsync
                S_WRITE_P: begin
                    vram_cea <= 1'b1; vram_ada <= 0; vram_din <= "P";
                    vram_write_state <= S_WRITE_C;
                end
                S_WRITE_C: begin
                    vram_cea <= 1'b1; vram_ada <= 1; vram_din <= "C";
                    vram_write_state <= S_WRITE_COLON;
                end
                S_WRITE_COLON: begin
                    vram_cea <= 1'b1; vram_ada <= 2; vram_din <= ":";
                    vram_write_state <= S_WRITE_PC3;
                end
                S_WRITE_PC3: begin
                    vram_cea <= 1'b1; vram_ada <= 3; vram_din <= to_hex(cpu_debug_pc[15:12]);
                    vram_write_state <= S_WRITE_PC2;
                end
                S_WRITE_PC2: begin
                    vram_cea <= 1'b1; vram_ada <= 4; vram_din <= to_hex(cpu_debug_pc[11:8]);
                    vram_write_state <= S_WRITE_PC1;
                end
                S_WRITE_PC1: begin
                    vram_cea <= 1'b1; vram_ada <= 5; vram_din <= to_hex(cpu_debug_pc[7:4]);
                    vram_write_state <= S_WRITE_PC0;
                end
                S_WRITE_PC0: begin
                    vram_cea <= 1'b1; vram_ada <= 6; vram_din <= to_hex(cpu_debug_pc[3:0]);
                    vram_write_state <= S_WRITE_SPACE1;
                end
                S_WRITE_SPACE1: begin
                    vram_cea <= 1'b1; vram_ada <= 7; vram_din <= " ";
                    vram_write_state <= S_WRITE_A_LABEL;
                end
                S_WRITE_A_LABEL: begin
                    vram_cea <= 1'b1; vram_ada <= 8; vram_din <= "A";
                    vram_write_state <= S_WRITE_A_COLON;
                end
                S_WRITE_A_COLON: begin
                    vram_cea <= 1'b1; vram_ada <= 9; vram_din <= ":";
                    vram_write_state <= S_WRITE_A1;
                end
                S_WRITE_A1: begin
                    vram_cea <= 1'b1; vram_ada <= 10; vram_din <= to_hex(cpu_debug_a[7:4]);
                    vram_write_state <= S_WRITE_A0;
                end
                S_WRITE_A0: begin
                    vram_cea <= 1'b1; vram_ada <= 11; vram_din <= to_hex(cpu_debug_a[3:0]);
                    vram_write_state <= S_WRITE_SPACE2;
                end
                S_WRITE_SPACE2: begin
                    vram_cea <= 1'b1; vram_ada <= 12; vram_din <= " ";
                    vram_write_state <= S_WRITE_X_LABEL;
                end
                S_WRITE_X_LABEL: begin
                    vram_cea <= 1'b1; vram_ada <= 13; vram_din <= "X";
                    vram_write_state <= S_WRITE_X_COLON;
                end
                S_WRITE_X_COLON: begin
                    vram_cea <= 1'b1; vram_ada <= 14; vram_din <= ":";
                    vram_write_state <= S_WRITE_X1;
                end
                S_WRITE_X1: begin
                    vram_cea <= 1'b1; vram_ada <= 15; vram_din <= to_hex(cpu_debug_x[7:4]);
                    vram_write_state <= S_WRITE_X0;
                end
                S_WRITE_X0: begin
                    vram_cea <= 1'b1; vram_ada <= 16; vram_din <= to_hex(cpu_debug_x[3:0]);
                    vram_write_state <= S_WRITE_SPACE3;
                end
                S_WRITE_SPACE3: begin
                    vram_cea <= 1'b1; vram_ada <= 17; vram_din <= " ";
                    vram_write_state <= S_WRITE_Y_LABEL;
                end
                S_WRITE_Y_LABEL: begin
                    vram_cea <= 1'b1; vram_ada <= 18; vram_din <= "Y";
                    vram_write_state <= S_WRITE_Y_COLON;
                end
                S_WRITE_Y_COLON: begin
                    vram_cea <= 1'b1; vram_ada <= 19; vram_din <= ":";
                    vram_write_state <= S_WRITE_Y1;
                end
                S_WRITE_Y1: begin
                    vram_cea <= 1'b1; vram_ada <= 20; vram_din <= to_hex(cpu_debug_y[7:4]);
                    vram_write_state <= S_WRITE_Y0;
                end
                S_WRITE_Y0: begin
                    vram_cea <= 1'b1; vram_ada <= 21; vram_din <= to_hex(cpu_debug_y[3:0]);
                    vram_write_state <= S_WRITE_SPACE4;
                end
                S_WRITE_SPACE4: begin
                    vram_cea <= 1'b1; vram_ada <= 22; vram_din <= " ";
                    vram_write_state <= S_WRITE_S_LABEL;
                end
                S_WRITE_S_LABEL: begin
                    vram_cea <= 1'b1; vram_ada <= 23; vram_din <= "S";
                    vram_write_state <= S_WRITE_S_COLON;
                end
                S_WRITE_S_COLON: begin
                    vram_cea <= 1'b1; vram_ada <= 24; vram_din <= ":";
                    vram_write_state <= S_WRITE_S1;
                end
                S_WRITE_S1: begin
                    vram_cea <= 1'b1; vram_ada <= 25; vram_din <= to_hex(cpu_debug_s[7:4]);
                    vram_write_state <= S_WRITE_S0;
                end
                S_WRITE_S0: begin
                    vram_cea <= 1'b1; vram_ada <= 26; vram_din <= to_hex(cpu_debug_s[3:0]);
                    vram_write_state <= S_WRITE_SPACE5;
                end
                S_WRITE_SPACE5: begin
                    vram_cea <= 1'b1; vram_ada <= 27; vram_din <= " ";
                    vram_write_state <= S_WRITE_P_LABEL;
                end
                S_WRITE_P_LABEL: begin
                    vram_cea <= 1'b1; vram_ada <= 28; vram_din <= "P";
                    vram_write_state <= S_WRITE_P_COLON;
                end
                S_WRITE_P_COLON: begin
                    vram_cea <= 1'b1; vram_ada <= 29; vram_din <= ":";
                    vram_write_state <= S_WRITE_P1;
                end
                S_WRITE_P1: begin
                    vram_cea <= 1'b1; vram_ada <= 30; vram_din <= to_hex(cpu_debug_p[7:4]);
                    vram_write_state <= S_WRITE_P0;
                end
                S_WRITE_P0: begin
                    vram_cea <= 1'b1; vram_ada <= 31; vram_din <= to_hex(cpu_debug_p[3:0]);
                    vram_write_state <= S_IDLE;
                end
                default: vram_write_state <= S_IDLE;
            endcase
        end
    end


    lcd lcd_inst (
        .PixelClk(LCD_CLK),
        .nRST(rst_n),
        .v_dout(vram_data),
        .f_dout(font_data),
        .LCD_DE(LCD_DEN),
        .LCD_B(LCD_B),
        .LCD_G(LCD_G),
        .LCD_R(LCD_R),
        .v_adb(vram_addr),
        .f_ad(font_addr),
        .vsync(vsync)
    );

endmodule
