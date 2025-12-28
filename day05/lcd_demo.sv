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

    logic       vram_cea;
    logic [9:0] vram_ada;
    logic [7:0] vram_din;

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

    // CPU
    logic [15:0] cpu_address_bus;
    logic [15:0] cpu_debug_pc;

    // Slow down PC increment for visual debugging
    logic [23:0] counter;
    logic        pc_enable;

    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 24'd0;
        end else begin
            counter <= counter + 1;
        end
    end

    assign pc_enable = (counter == 24'd0);

    cpu u_cpu (
        .clk(MEMORY_CLK),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .address_bus(cpu_address_bus),
        .debug_pc(cpu_debug_pc)
    );

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

    typedef enum logic [3:0] {
        S_IDLE,
        S_WRITE_P,
        S_WRITE_C,
        S_WRITE_COLON,
        S_WRITE_D3,
        S_WRITE_D2,
        S_WRITE_D1,
        S_WRITE_D0
    } vram_write_state_t;
    vram_write_state_t vram_write_state;

    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            vram_cea <= 1'b0;
            vram_ada <= 10'd0;
            vram_din <= 8'h20;
            vram_write_state <= S_IDLE;
        end else begin
            vram_cea <= 1'b0;  // Default to no write
            case (vram_write_state)
                S_IDLE:  if (vsync) vram_write_state <= S_WRITE_P;  // Start writing on vsync
                S_WRITE_P: begin
                    vram_cea <= 1'b1;
                    vram_ada <= 0;
                    vram_din <= "P";
                    vram_write_state <= S_WRITE_C;
                end
                S_WRITE_C: begin
                    vram_cea <= 1'b1;
                    vram_ada <= 1;
                    vram_din <= "C";
                    vram_write_state <= S_WRITE_COLON;
                end
                S_WRITE_COLON: begin
                    vram_cea <= 1'b1;
                    vram_ada <= 2;
                    vram_din <= ":";
                    vram_write_state <= S_WRITE_D3;
                end
                S_WRITE_D3: begin
                    vram_cea <= 1'b1;
                    vram_ada <= 4;
                    vram_din <= to_hex(cpu_debug_pc[15:12]);
                    vram_write_state <= S_WRITE_D2;
                end
                S_WRITE_D2: begin
                    vram_cea <= 1'b1;
                    vram_ada <= 5;
                    vram_din <= to_hex(cpu_debug_pc[11:8]);
                    vram_write_state <= S_WRITE_D1;
                end
                S_WRITE_D1: begin
                    vram_cea <= 1'b1;
                    vram_ada <= 6;
                    vram_din <= to_hex(cpu_debug_pc[7:4]);
                    vram_write_state <= S_WRITE_D0;
                end
                S_WRITE_D0: begin
                    vram_cea <= 1'b1;
                    vram_ada <= 7;
                    vram_din <= to_hex(cpu_debug_pc[3:0]);
                    vram_write_state <= S_IDLE;  // Done
                end
                default: vram_write_state <= S_IDLE;
            endcase
        end
    end
`endif

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
