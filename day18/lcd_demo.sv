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

    logic [ 9:0] vram_addr;
    logic [ 7:0] vram_data;
    logic [11:0] font_addr;
    logic [ 7:0] font_data;
    /* verilator lint_off UNUSEDSIGNAL */
    logic        vsync;
    /* verilator lint_on UNUSEDSIGNAL */
    logic        vram_cea;
    logic [ 9:0] vram_ada;
    logic [ 7:0] vram_din;

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
        .rst_n(cpu_rst_n),
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
    logic [ 7:0] cpu_data_in;
    logic [15:0] cpu_debug_pc;
    logic [ 7:0] cpu_debug_a;
    logic [ 7:0] cpu_debug_x;
    logic [ 7:0] cpu_debug_y;
    logic [ 7:0] cpu_debug_p;
    logic [ 7:0] cpu_debug_s;
    logic [ 7:0] cpu_data_out;
    logic        cpu_write_en;

    logic [ 7:0] ram_data_out;
    logic [ 7:0] rom_data_out;

    logic [15:0] rom_addr;

    // Boot init: copy ROM program into RAM so CPU runs from BSRAM.
    localparam int BOOT_LEN = 10;
    logic [ 3:0] boot_index;
    logic        boot_done;
    logic [15:0] boot_addr;
    logic        boot_active;
    logic        cpu_rst_n;
    logic [14:0] ram_addr;
    logic [ 7:0] ram_din;
    logic        ram_we;

    // Run CPU at full speed (synchronization is handled by WVS instruction)
    logic        pc_enable;
    assign pc_enable = 1'b1;

    logic cpu_vram_clear;
    logic cpu_show_info;

    logic cpu_clk;
`ifdef VERILATOR
    assign cpu_clk = LCD_CLK;
`else
    assign cpu_clk = MEMORY_CLK;
`endif

    cpu u_cpu (
        .clk(cpu_clk),
        .rst_n(cpu_rst_n),
        .pc_enable(pc_enable),
        .address_bus(cpu_address_bus),
        .data_in(cpu_data_in),
        .data_out(cpu_data_out),
        .write_en(cpu_write_en),
        .vsync(vsync),
        .vram_clear(cpu_vram_clear),
        .show_info(cpu_show_info),
        .debug_pc(cpu_debug_pc),
        .debug_a(cpu_debug_a),
        .debug_x(cpu_debug_x),
        .debug_y(cpu_debug_y),
        .debug_p(cpu_debug_p),
        .debug_s(cpu_debug_s)
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
        S_CLEAR,
        S_WRITE_REGS,
        S_WRITE_MEM_HEADER,
        S_WRITE_MEM_LOOP
    } debug_state_t;
    debug_state_t        debug_state;

    logic         [11:0] debug_counter;
    logic         [15:0] debug_addr;
    logic         [ 3:0] sub_state;
    logic                cpu_show_info_prev;

    always_ff @(posedge cpu_clk or negedge rst_n) begin
        if (!rst_n) begin
            vram_cea <= 1'b0;
            vram_ada <= 10'd0;
            vram_din <= 8'h20;
            debug_state <= S_IDLE;
            debug_counter <= 12'd0;
            debug_addr <= 16'h0000;
            sub_state <= 4'd0;
            cpu_show_info_prev <= 1'b0;
        end else begin
            cpu_show_info_prev <= cpu_show_info;
            vram_cea <= 1'b0;
            case (debug_state)
                S_IDLE: begin
                    if (cpu_show_info && !cpu_show_info_prev) begin
                        debug_state   <= S_CLEAR;
                        debug_counter <= 12'd0;
                    end
                end

                S_CLEAR: begin
                    vram_cea <= 1'b1;
                    vram_ada <= debug_counter[9:0];
                    vram_din <= 8'h20;
                    if (debug_counter == 1023) begin
                        debug_counter <= 0;
                        debug_state   <= S_WRITE_REGS;
                    end else begin
                        debug_counter <= debug_counter + 1;
                    end
                end

                S_WRITE_REGS: begin
                    vram_cea <= 1'b1;
                    case (debug_counter)
                        0: begin
                            vram_ada <= 0 * COLUMNS + 0;
                            vram_din <= "R";
                        end
                        1: begin
                            vram_ada <= 0 * COLUMNS + 1;
                            vram_din <= "e";
                        end
                        2: begin
                            vram_ada <= 0 * COLUMNS + 2;
                            vram_din <= "g";
                        end
                        3: begin
                            vram_ada <= 0 * COLUMNS + 3;
                            vram_din <= "i";
                        end
                        4: begin
                            vram_ada <= 0 * COLUMNS + 4;
                            vram_din <= "s";
                        end
                        5: begin
                            vram_ada <= 0 * COLUMNS + 5;
                            vram_din <= "t";
                        end
                        6: begin
                            vram_ada <= 0 * COLUMNS + 6;
                            vram_din <= "e";
                        end
                        7: begin
                            vram_ada <= 0 * COLUMNS + 7;
                            vram_din <= "r";
                        end
                        8: begin
                            vram_ada <= 0 * COLUMNS + 8;
                            vram_din <= "s";
                        end
                        9: begin
                            vram_ada <= 0 * COLUMNS + 9;
                            vram_din <= ")";
                        end
                        10: begin
                            vram_ada <= 1 * COLUMNS + 0;
                            vram_din <= "A";
                        end
                        11: begin
                            vram_ada <= 1 * COLUMNS + 1;
                            vram_din <= " ";
                        end
                        12: begin
                            vram_ada <= 1 * COLUMNS + 2;
                            vram_din <= ":";
                        end
                        13: begin
                            vram_ada <= 1 * COLUMNS + 3;
                            vram_din <= "0";
                        end
                        14: begin
                            vram_ada <= 1 * COLUMNS + 4;
                            vram_din <= "x";
                        end
                        15: begin
                            vram_ada <= 1 * COLUMNS + 5;
                            vram_din <= to_hex(cpu_debug_a[7:4]);
                        end
                        16: begin
                            vram_ada <= 1 * COLUMNS + 6;
                            vram_din <= to_hex(cpu_debug_a[3:0]);
                        end
                        17: begin
                            vram_ada <= 2 * COLUMNS + 0;
                            vram_din <= "X";
                        end
                        18: begin
                            vram_ada <= 2 * COLUMNS + 1;
                            vram_din <= " ";
                        end
                        19: begin
                            vram_ada <= 2 * COLUMNS + 2;
                            vram_din <= ":";
                        end
                        20: begin
                            vram_ada <= 2 * COLUMNS + 3;
                            vram_din <= "0";
                        end
                        21: begin
                            vram_ada <= 2 * COLUMNS + 4;
                            vram_din <= "x";
                        end
                        22: begin
                            vram_ada <= 2 * COLUMNS + 5;
                            vram_din <= to_hex(cpu_debug_x[7:4]);
                        end
                        23: begin
                            vram_ada <= 2 * COLUMNS + 6;
                            vram_din <= to_hex(cpu_debug_x[3:0]);
                        end
                        24: begin
                            vram_ada <= 3 * COLUMNS + 0;
                            vram_din <= "Y";
                        end
                        25: begin
                            vram_ada <= 3 * COLUMNS + 1;
                            vram_din <= " ";
                        end
                        26: begin
                            vram_ada <= 3 * COLUMNS + 2;
                            vram_din <= ":";
                        end
                        27: begin
                            vram_ada <= 3 * COLUMNS + 3;
                            vram_din <= "0";
                        end
                        28: begin
                            vram_ada <= 3 * COLUMNS + 4;
                            vram_din <= "x";
                        end
                        29: begin
                            vram_ada <= 3 * COLUMNS + 5;
                            vram_din <= to_hex(cpu_debug_y[7:4]);
                        end
                        30: begin
                            vram_ada <= 3 * COLUMNS + 6;
                            vram_din <= to_hex(cpu_debug_y[3:0]);
                        end
                        31: begin
                            vram_ada <= 4 * COLUMNS + 0;
                            vram_din <= "P";
                        end
                        32: begin
                            vram_ada <= 4 * COLUMNS + 1;
                            vram_din <= "C";
                        end
                        33: begin
                            vram_ada <= 4 * COLUMNS + 2;
                            vram_din <= ":";
                        end
                        34: begin
                            vram_ada <= 4 * COLUMNS + 3;
                            vram_din <= "0";
                        end
                        35: begin
                            vram_ada <= 4 * COLUMNS + 4;
                            vram_din <= "x";
                        end
                        36: begin
                            vram_ada <= 4 * COLUMNS + 5;
                            vram_din <= to_hex(cpu_debug_pc[15:12]);
                        end
                        37: begin
                            vram_ada <= 4 * COLUMNS + 6;
                            vram_din <= to_hex(cpu_debug_pc[11:8]);
                        end
                        38: begin
                            vram_ada <= 4 * COLUMNS + 7;
                            vram_din <= to_hex(cpu_debug_pc[7:4]);
                        end
                        39: begin
                            vram_ada <= 4 * COLUMNS + 8;
                            vram_din <= to_hex(cpu_debug_pc[3:0]);
                        end
                        40: begin
                            vram_ada <= 5 * COLUMNS + 0;
                            vram_din <= "S";
                        end
                        41: begin
                            vram_ada <= 5 * COLUMNS + 1;
                            vram_din <= "P";
                        end
                        42: begin
                            vram_ada <= 5 * COLUMNS + 2;
                            vram_din <= ":";
                        end
                        43: begin
                            vram_ada <= 5 * COLUMNS + 3;
                            vram_din <= "0";
                        end
                        44: begin
                            vram_ada <= 5 * COLUMNS + 4;
                            vram_din <= "x";
                        end
                        45: begin
                            vram_ada <= 5 * COLUMNS + 5;
                            vram_din <= "1";
                        end
                        46: begin
                            vram_ada <= 5 * COLUMNS + 6;
                            vram_din <= to_hex(cpu_debug_s[7:4]);
                        end
                        47: begin
                            vram_ada <= 5 * COLUMNS + 7;
                            vram_din <= to_hex(cpu_debug_s[3:0]);
                        end
                        48: begin
                            vram_ada <= 6 * COLUMNS + 0;
                            vram_din <= "P";
                        end
                        49: begin
                            vram_ada <= 6 * COLUMNS + 1;
                            vram_din <= " ";
                        end
                        50: begin
                            vram_ada <= 6 * COLUMNS + 2;
                            vram_din <= ":";
                        end
                        51: begin
                            vram_ada <= 6 * COLUMNS + 3;
                            vram_din <= "0";
                        end
                        52: begin
                            vram_ada <= 6 * COLUMNS + 4;
                            vram_din <= "x";
                        end
                        53: begin
                            vram_ada <= 6 * COLUMNS + 5;
                            vram_din <= to_hex(cpu_debug_p[7:4]);
                        end
                        54: begin
                            vram_ada <= 6 * COLUMNS + 6;
                            vram_din <= to_hex(cpu_debug_p[3:0]);
                        end
                        default: vram_cea <= 1'b0;
                    endcase
                    if (debug_counter == 54) begin
                        debug_counter <= 0;
                        debug_state   <= S_WRITE_MEM_HEADER;
                    end else begin
                        debug_counter <= debug_counter + 1;
                    end
                end

                S_WRITE_MEM_HEADER: begin
                    vram_cea <= 1'b1;
                    vram_ada <= 8 * COLUMNS + debug_counter[5:0];
                    case (debug_counter)
                        0: vram_din <= "M";
                        1: vram_din <= "e";
                        2: vram_din <= "m";
                        3: vram_din <= "o";
                        4: vram_din <= "r";
                        5: vram_din <= "y";
                        6: vram_din <= ")";
                        9: vram_din <= "+";
                        10: vram_din <= "0";
                        11: vram_din <= "+";
                        12: vram_din <= "1";
                        13: vram_din <= "+";
                        14: vram_din <= "2";
                        15: vram_din <= "+";
                        16: vram_din <= "3";
                        18: vram_din <= "+";
                        19: vram_din <= "4";
                        20: vram_din <= "+";
                        21: vram_din <= "5";
                        22: vram_din <= "+";
                        23: vram_din <= "6";
                        24: vram_din <= "+";
                        25: vram_din <= "7";
                        28: vram_din <= "+";
                        29: vram_din <= "8";
                        30: vram_din <= "+";
                        31: vram_din <= "9";
                        32: vram_din <= "+";
                        33: vram_din <= "A";
                        34: vram_din <= "+";
                        35: vram_din <= "B";
                        37: vram_din <= "+";
                        38: vram_din <= "C";
                        39: vram_din <= "+";
                        40: vram_din <= "D";
                        41: vram_din <= "+";
                        42: vram_din <= "E";
                        43: vram_din <= "+";
                        44: vram_din <= "F";
                        52: vram_din <= "7";
                        53: vram_din <= "6";
                        54: vram_din <= "5";
                        55: vram_din <= "4";
                        56: vram_din <= "3";
                        57: vram_din <= "2";
                        58: vram_din <= "1";
                        59: vram_din <= "0";
                        default: vram_din <= 8'h20;
                    endcase
                    if (debug_counter == 59) begin
                        debug_counter <= 0;
                        debug_addr <= 16'h0000;
                        sub_state <= 0;
                        debug_state <= S_WRITE_MEM_LOOP;
                    end else begin
                        debug_counter <= debug_counter + 1;
                    end
                end

                S_WRITE_MEM_LOOP: begin
                    automatic logic [4:0] row = 9 + debug_addr[6:4];
                    automatic logic [5:0] col;
                    if (debug_addr[3:2] == 0) col = 9 + (debug_addr[1:0] * 2);
                    else if (debug_addr[3:2] == 1) col = 18 + (debug_addr[1:0] * 2);
                    else if (debug_addr[3:2] == 2) col = 28 + (debug_addr[1:0] * 2);
                    else col = 37 + (debug_addr[1:0] * 2);

                    case (sub_state)
                        0: begin  // Row label "0xXX:"
                            vram_cea  <= 1'b1;
                            vram_ada  <= row * COLUMNS + 0;
                            vram_din  <= "0";
                            sub_state <= 1;
                        end
                        1: begin
                            vram_cea  <= 1'b1;
                            vram_ada  <= row * COLUMNS + 1;
                            vram_din  <= "x";
                            sub_state <= 2;
                        end
                        2: begin
                            vram_cea  <= 1'b1;
                            vram_ada  <= row * COLUMNS + 2;
                            vram_din  <= to_hex(debug_addr[7:4]);
                            sub_state <= 3;
                        end
                        3: begin
                            vram_cea  <= 1'b1;
                            vram_ada  <= row * COLUMNS + 3;
                            vram_din  <= to_hex(debug_addr[3:0]);
                            sub_state <= 4;
                        end
                        4: begin
                            vram_cea  <= 1'b1;
                            vram_ada  <= row * COLUMNS + 4;
                            vram_din  <= ":";
                            sub_state <= 5;
                        end
                        5: begin  // Data High Nibble
                            vram_cea  <= 1'b1;
                            vram_ada  <= row * COLUMNS + col;
                            vram_din  <= to_hex(ram_data_out[7:4]);
                            sub_state <= 6;
                        end
                        6: begin  // Data Low Nibble
                            vram_cea  <= 1'b1;
                            vram_ada  <= row * COLUMNS + col + 1;
                            vram_din  <= to_hex(ram_data_out[3:0]);
                            sub_state <= 7;
                        end
                        7: begin
                            vram_cea <= 1'b0;
                            if (debug_addr[3:0] == 4'hF) begin
                                sub_state <= 8;
                                debug_counter <= 0;
                            end else begin
                                debug_addr <= debug_addr + 1;
                                sub_state  <= 5;
                            end
                        end
                        8: begin  // Bit pattern (LED)
                            vram_cea <= 1'b1;
                            vram_ada <= row * COLUMNS + 52 + debug_counter[2:0];
                            vram_din <= ram_data_out[7-debug_counter[2:0]] ? "1" : "0";
                            if (debug_counter == 7) begin
                                if (debug_addr == 16'h007F) begin
                                    debug_state <= S_IDLE;
                                end else begin
                                    debug_addr <= debug_addr + 1;
                                    sub_state  <= 0;
                                end
                            end else begin
                                debug_counter <= debug_counter + 1;
                            end
                        end
                        default: sub_state <= 0;
                    endcase
                end
                default: debug_state <= S_IDLE;
            endcase
        end
    end

    logic [15:0] ram_addr_final;
    assign ram_addr_final = boot_active ? boot_addr :
        (debug_state == S_WRITE_MEM_LOOP) ? debug_addr : cpu_address_bus;
    assign ram_addr = ram_addr_final[14:0];

    // Memory (RAM for $0000-$7FFF)
    ram u_ram (
        .clk(cpu_clk),
        .addr(ram_addr),
        .write_en(ram_we),
        .din(ram_din),
        .dout(ram_data_out)
    );

    rom u_rom (
        .addr(rom_addr),
        .data(rom_data_out)
    );

    assign boot_addr = 16'h0200 + boot_index;
    assign boot_active = !boot_done;
    assign cpu_rst_n = rst_n && boot_done;
    assign rom_addr = boot_active ? boot_addr : cpu_address_bus;
    assign ram_din = boot_active ? rom_data_out : cpu_data_out;
    assign ram_we = boot_active ? 1'b1 : (cpu_write_en && (!cpu_address_bus[15]));

    always_ff @(posedge cpu_clk or negedge rst_n) begin
        if (!rst_n) begin
            boot_index <= 4'd0;
            boot_done  <= 1'b0;
        end else if (!boot_done) begin
            if (boot_index == (BOOT_LEN - 1)) begin
                boot_done <= 1'b1;
            end else begin
                boot_index <= boot_index + 1'b1;
            end
        end
    end


    always_comb begin
        if (!cpu_address_bus[15]) begin
            cpu_data_in = ram_data_out;
        end else begin
            cpu_data_in = rom_data_out;
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
