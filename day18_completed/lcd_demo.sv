/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off UNUSEDSIGNAL */
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

    logic        vram_cea;
    logic [ 9:0] vram_ada;
    logic [ 7:0] vram_din;

    // Memory-domain reset. On FPGA it is gated by PLL LOCK (day99-style) to
    // keep the boot copy stable through the post-configuration unlock window.
    logic mem_rst_n;
`ifdef VERILATOR
    assign mem_rst_n = rst_n;
`endif

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
        .write_en(vram_cea),
        .write_addr(vram_ada),
        .write_data(vram_din),
        .data (vram_data)
    );
`else
    // FPGA path: CPU/VRAM writes use MEMORY_CLK; display reads use LCD_CLK.
    // Hold the memory domain in reset until the PLL LOCK stays asserted for 16
    // cycles: during the post-configuration unlock window the boot copy into RAM
    // gets corrupted on real hardware (day99-style LOCK-gated reset).
    logic MEMORY_CLK;
    logic locked_raw, locked_meta, locked_sync, lock_stable;
    logic [3:0] lock_count;
    assign mem_rst_n = rst_n && lock_stable;

    Gowin_rPLL9 pll9_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    Gowin_rPLL40 pll40_inst (
        .clkout(MEMORY_CLK),
        .clkin (XTAL_IN),
        .locked(locked_raw)
    );

    // 2FF synchronizer for the asynchronous PLL LOCK into MEMORY_CLK.
    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            locked_meta <= 1'b0;
            locked_sync <= 1'b0;
        end else begin
            locked_meta <= locked_raw;
            locked_sync <= locked_meta;
        end
    end

    // Release the memory-domain reset only after LOCK has held for 16 cycles.
    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            lock_count  <= 4'd0;
            lock_stable <= 1'b0;
        end else if (!locked_sync) begin
            lock_count  <= 4'd0;
            lock_stable <= 1'b0;
        end else if (lock_count != 4'd15) begin
            lock_count  <= lock_count + 1'b1;
            lock_stable <= 1'b0;
        end else begin
            lock_stable <= 1'b1;
        end
    end

    // Font pROM (Sweet16Font, 4KB: 16 bytes/char x 256 chars)
    Gowin_pROM_font prom_font_inst (
        .dout (font_data),
        .clk  (LCD_CLK),
        .oce  (1'b1),
        .ce   (1'b1),
        .reset(1'b0),
        .ad   (font_addr)
    );

    // Dual-port VRAM: memory-domain writes, pixel-domain synchronous reads.
    Gowin_SDPB_vram vram_inst (
        .dout  (vram_data),
        .clka  (MEMORY_CLK),
        .cea   (vram_cea),
        .reseta(1'b0),
        .clkb  (LCD_CLK),
        .ceb   (1'b1),
        .resetb(1'b0),
        .oce   (1'b0),
        .ada   (vram_ada),
        .din   (vram_din),
        .adb   (vram_addr)
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

    // Boot loader: copy ROM program into RAM so CPU runs from BSRAM.
    logic        cpu_rst_n;
    logic [14:0] ram_addr_boot;
    logic [14:0] ram_addr_final;
    logic [ 7:0] ram_din;
    logic        ram_we;
    logic        ram_we_final;
    logic [7:0]  ram_din_final;
    logic        memory_hold;
    logic        boot_active;

    // Run CPU at full speed (synchronization is handled by WVS instruction)
    logic        pc_enable;
    assign pc_enable = 1;

    logic cpu_vram_clear;
    logic cpu_show_info;

    logic cpu_clk;
`ifdef VERILATOR
    assign cpu_clk = LCD_CLK;
`else
    assign cpu_clk = MEMORY_CLK;
`endif

    logic vsync_meta, vsync_cpu;
    always_ff @(posedge cpu_clk or negedge mem_rst_n) begin
        if (!mem_rst_n) begin
            vsync_meta <= 0;
            vsync_cpu <= 0;
        end else begin
            vsync_meta <= vsync;
            vsync_cpu <= vsync_meta;
        end
    end

    cpu u_cpu (
        .clk(cpu_clk),
        .rst_n(cpu_rst_n),
        .pc_enable(pc_enable),
        .memory_hold(memory_hold),
        .address_bus(cpu_address_bus),
        .data_in(cpu_data_in),
        .data_out(cpu_data_out),
        .write_en(cpu_write_en),
        .vsync(vsync_cpu),
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
        S_WRITE_MEM_LOOP,
        S_DRAIN
    } debug_state_t;
    debug_state_t        debug_state;

    logic         [11:0] debug_counter;
    logic         [15:0] debug_addr;
    logic         [ 3:0] sub_state;
    logic                clear_only;
    logic [15:0] snapshot_pc;
    logic [7:0] snapshot_a, snapshot_x, snapshot_y, snapshot_p, snapshot_s;
    logic [7:0] debug_byte;

    always_ff @(posedge cpu_clk or negedge mem_rst_n) begin
        if (!mem_rst_n) begin
            vram_cea <= 1'b0;
            vram_ada <= 10'd0;
            vram_din <= 8'h20;
            debug_state <= S_IDLE;
            debug_counter <= 12'd0;
            debug_addr <= 16'h0000;
            sub_state <= 4'd0;
            clear_only <= 0;
            snapshot_pc <= 0;
            snapshot_a <= 0; snapshot_x <= 0; snapshot_y <= 0;
            snapshot_p <= 0; snapshot_s <= 0;
            debug_byte <= 0;
        end else begin
            vram_cea <= 1'b0;
            case (debug_state)
                S_IDLE: begin
                    if (!boot_active && (cpu_show_info || cpu_vram_clear)) begin
                        clear_only <= !cpu_show_info;
                        snapshot_pc <= cpu_debug_pc;
                        snapshot_a <= cpu_debug_a; snapshot_x <= cpu_debug_x;
                        snapshot_y <= cpu_debug_y; snapshot_p <= cpu_debug_p;
                        snapshot_s <= cpu_debug_s;
`ifdef VERILATOR
                        assert (!cpu_write_en) else $fatal(1, "Debug request overlaps CPU write");
`endif
                        debug_state   <= S_CLEAR;
                        debug_counter <= 12'd0;
                    end
                end

                S_CLEAR: begin
                    vram_cea <= 1;
                    vram_ada <= debug_counter[9:0];
                    vram_din <= 8'h20;
                    if (debug_counter == 1023) begin
                        debug_counter <= 0;
                        debug_state   <= clear_only ? S_DRAIN : S_WRITE_REGS;
                    end else begin
                        debug_counter <= debug_counter + 1'b1;
                    end
                end

                S_WRITE_REGS: begin
                    vram_cea <= 1;
                    case (debug_counter)
                        0: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd0;
                            vram_din <= "R";
                        end
                        1: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd1;
                            vram_din <= "e";
                        end
                        2: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd2;
                            vram_din <= "g";
                        end
                        3: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd3;
                            vram_din <= "i";
                        end
                        4: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd4;
                            vram_din <= "s";
                        end
                        5: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd5;
                            vram_din <= "t";
                        end
                        6: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd6;
                            vram_din <= "e";
                        end
                        7: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd7;
                            vram_din <= "r";
                        end
                        8: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd8;
                            vram_din <= "s";
                        end
                        9: begin
                            vram_ada <= 10'd0 * COLUMNS + 10'd9;
                            vram_din <= ")";
                        end
                        10: begin
                            vram_ada <= 10'd1 * COLUMNS + 10'd0;
                            vram_din <= "A";
                        end
                        11: begin
                            vram_ada <= 10'd1 * COLUMNS + 10'd1;
                            vram_din <= " ";
                        end
                        12: begin
                            vram_ada <= 10'd1 * COLUMNS + 10'd2;
                            vram_din <= ":";
                        end
                        13: begin
                            vram_ada <= 10'd1 * COLUMNS + 10'd3;
                            vram_din <= "0";
                        end
                        14: begin
                            vram_ada <= 10'd1 * COLUMNS + 10'd4;
                            vram_din <= "x";
                        end
                        15: begin
                            vram_ada <= 10'd1 * COLUMNS + 10'd5;
                            vram_din <= to_hex(snapshot_a[7:4]);
                        end
                        16: begin
                            vram_ada <= 10'd1 * COLUMNS + 10'd6;
                            vram_din <= to_hex(snapshot_a[3:0]);
                        end
                        17: begin
                            vram_ada <= 10'd2 * COLUMNS + 10'd0;
                            vram_din <= "X";
                        end
                        18: begin
                            vram_ada <= 10'd2 * COLUMNS + 10'd1;
                            vram_din <= " ";
                        end
                        19: begin
                            vram_ada <= 10'd2 * COLUMNS + 10'd2;
                            vram_din <= ":";
                        end
                        20: begin
                            vram_ada <= 10'd2 * COLUMNS + 10'd3;
                            vram_din <= "0";
                        end
                        21: begin
                            vram_ada <= 10'd2 * COLUMNS + 10'd4;
                            vram_din <= "x";
                        end
                        22: begin
                            vram_ada <= 10'd2 * COLUMNS + 10'd5;
                            vram_din <= to_hex(snapshot_x[7:4]);
                        end
                        23: begin
                            vram_ada <= 10'd2 * COLUMNS + 10'd6;
                            vram_din <= to_hex(snapshot_x[3:0]);
                        end
                        24: begin
                            vram_ada <= 10'd3 * COLUMNS + 10'd0;
                            vram_din <= "Y";
                        end
                        25: begin
                            vram_ada <= 10'd3 * COLUMNS + 10'd1;
                            vram_din <= " ";
                        end
                        26: begin
                            vram_ada <= 10'd3 * COLUMNS + 10'd2;
                            vram_din <= ":";
                        end
                        27: begin
                            vram_ada <= 10'd3 * COLUMNS + 10'd3;
                            vram_din <= "0";
                        end
                        28: begin
                            vram_ada <= 10'd3 * COLUMNS + 10'd4;
                            vram_din <= "x";
                        end
                        29: begin
                            vram_ada <= 10'd3 * COLUMNS + 10'd5;
                            vram_din <= to_hex(snapshot_y[7:4]);
                        end
                        30: begin
                            vram_ada <= 10'd3 * COLUMNS + 10'd6;
                            vram_din <= to_hex(snapshot_y[3:0]);
                        end
                        31: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd0;
                            vram_din <= "P";
                        end
                        32: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd1;
                            vram_din <= "C";
                        end
                        33: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd2;
                            vram_din <= ":";
                        end
                        34: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd3;
                            vram_din <= "0";
                        end
                        35: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd4;
                            vram_din <= "x";
                        end
                        36: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd5;
                            vram_din <= to_hex(snapshot_pc[15:12]);
                        end
                        37: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd6;
                            vram_din <= to_hex(snapshot_pc[11:8]);
                        end
                        38: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd7;
                            vram_din <= to_hex(snapshot_pc[7:4]);
                        end
                        39: begin
                            vram_ada <= 10'd4 * COLUMNS + 10'd8;
                            vram_din <= to_hex(snapshot_pc[3:0]);
                        end
                        40: begin
                            vram_ada <= 10'd5 * COLUMNS + 10'd0;
                            vram_din <= "S";
                        end
                        41: begin
                            vram_ada <= 10'd5 * COLUMNS + 10'd1;
                            vram_din <= "P";
                        end
                        42: begin
                            vram_ada <= 10'd5 * COLUMNS + 10'd2;
                            vram_din <= ":";
                        end
                        43: begin
                            vram_ada <= 10'd5 * COLUMNS + 10'd3;
                            vram_din <= "0";
                        end
                        44: begin
                            vram_ada <= 10'd5 * COLUMNS + 10'd4;
                            vram_din <= "x";
                        end
                        45: begin
                            vram_ada <= 10'd5 * COLUMNS + 10'd5;
                            vram_din <= "1";
                        end
                        46: begin
                            vram_ada <= 10'd5 * COLUMNS + 10'd6;
                            vram_din <= to_hex(snapshot_s[7:4]);
                        end
                        47: begin
                            vram_ada <= 10'd5 * COLUMNS + 10'd7;
                            vram_din <= to_hex(snapshot_s[3:0]);
                        end
                        48: begin
                            vram_ada <= 10'd6 * COLUMNS + 10'd0;
                            vram_din <= "P";
                        end
                        49: begin
                            vram_ada <= 10'd6 * COLUMNS + 10'd1;
                            vram_din <= " ";
                        end
                        50: begin
                            vram_ada <= 10'd6 * COLUMNS + 10'd2;
                            vram_din <= ":";
                        end
                        51: begin
                            vram_ada <= 10'd6 * COLUMNS + 10'd3;
                            vram_din <= "0";
                        end
                        52: begin
                            vram_ada <= 10'd6 * COLUMNS + 10'd4;
                            vram_din <= "x";
                        end
                        53: begin
                            vram_ada <= 10'd6 * COLUMNS + 10'd5;
                            vram_din <= to_hex(snapshot_p[7:4]);
                        end
                        54: begin
                            vram_ada <= 10'd6 * COLUMNS + 10'd6;
                            vram_din <= to_hex(snapshot_p[3:0]);
                        end
                        default: vram_cea <= 1'b0;
                    endcase
                    if (debug_counter == 54) begin
                        debug_counter <= 0;
                        debug_state   <= S_WRITE_MEM_HEADER;
                    end else begin
                        debug_counter <= debug_counter + 1'b1;
                    end
                end

                S_WRITE_MEM_HEADER: begin
                    vram_cea <= 1;
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
                        debug_counter <= debug_counter + 1'b1;
                    end
                end

                S_WRITE_MEM_LOOP: begin
                    automatic logic [4:0] row = 5'd9 + debug_addr[6:4];
                    automatic logic [5:0] col;
                    if (debug_addr[3:2] == 0) col = 9 + (debug_addr[1:0] * 2);
                    else if (debug_addr[3:2] == 1) col = 18 + (debug_addr[1:0] * 2);
                    else if (debug_addr[3:2] == 2) col = 28 + (debug_addr[1:0] * 2);
                    else col = 37 + (debug_addr[1:0] * 2);

                    case (sub_state)
                        0: begin  // Row label "0xXX:"
                            vram_cea  <= 1;
                            vram_ada  <= row * COLUMNS + 10'd0;
                            vram_din  <= "0";
                            sub_state <= 1;
                        end
                        1: begin
                            vram_cea  <= 1;
                            vram_ada  <= 10'(row * COLUMNS + 1'b1);
                            vram_din  <= "x";
                            sub_state <= 2;
                        end
                        2: begin
                            vram_cea  <= 1;
                            vram_ada  <= row * COLUMNS + 10'd2;
                            vram_din  <= to_hex(debug_addr[7:4]);
                            sub_state <= 3;
                        end
                        3: begin
                            vram_cea  <= 1;
                            vram_ada  <= row * COLUMNS + 10'd3;
                            vram_din  <= to_hex(debug_addr[3:0]);
                            sub_state <= 4;
                        end
                        4: begin
                            vram_cea  <= 1;
                            vram_ada  <= row * COLUMNS + 10'd4;
                            vram_din  <= ":";
                            sub_state <= 9;
                        end
                        5: begin  // Data High Nibble
                            vram_cea  <= 1;
                            vram_ada  <= row * COLUMNS + col;
                            vram_din  <= to_hex(debug_byte[7:4]);
                            sub_state <= 6;
                        end
                        6: begin  // Data Low Nibble
                            vram_cea  <= 1;
                            vram_ada  <= 10'(row * COLUMNS + col + 1'b1);
                            vram_din  <= to_hex(debug_byte[3:0]);
                            sub_state <= 7;
                        end
                        7: begin
                            vram_cea <= 1'b0;
                            if (debug_addr[3:0] == 4'hF) begin
                                sub_state <= 8;
                                debug_counter <= 0;
                            end else begin
                                debug_addr <= debug_addr + 1'b1;
                                sub_state  <= 9;
                            end
                        end
                        8: begin  // Bit pattern (LED)
                            vram_cea <= 1;
                            vram_ada <= row * COLUMNS + 10'd52 + debug_counter[2:0];
                            vram_din <= debug_byte[7-debug_counter[2:0]] ? "1" : "0";
                            if (debug_counter == 7) begin
                                if (debug_addr == 16'h007F) begin
                                    debug_state <= S_DRAIN;
                                end else begin
                                    debug_addr <= debug_addr + 1'b1;
                                    sub_state  <= 0;
                                end
                            end else begin
                                debug_counter <= debug_counter + 1'b1;
                            end
                        end
                        9: begin  // New debug address sampled by synchronous RAM.
                            vram_cea <= 0;
                            sub_state <= 10;
                        end
                        10: begin
                            debug_byte <= ram_data_out;
                            sub_state <= 5;
                        end
                        default: sub_state <= 0;
                    endcase
                end
                S_DRAIN: begin
                    // The final registered VRAM write retires on this edge.
                    vram_cea <= 0;
                    debug_state <= S_IDLE;
                end
                default: debug_state <= S_IDLE;
            endcase
        end
    end

    assign boot_active = rst_n && !cpu_rst_n;
    assign memory_hold = (debug_state != S_IDLE) || cpu_show_info || cpu_vram_clear;
    // Select the entire memory transaction. Debug must never inherit CPU writes.
    always_comb begin
        ram_addr_final = ram_addr_boot;
        ram_we_final = rst_n && ram_we;
        ram_din_final = ram_din;
        if (!boot_active && memory_hold) begin
            ram_addr_final = debug_addr[14:0];
            ram_we_final = 0;
            ram_din_final = 0;
        end
    end

    // Memory (RAM for $0000-$7FFF)
    ram u_ram (
        .clk(cpu_clk),
        .addr(ram_addr_final),
        .write_en(ram_we_final),
        .din(ram_din_final),
        .dout(ram_data_out)
    );

    rom u_rom (
        .addr(rom_addr),
        .data(rom_data_out)
    );

    boot_loader u_boot (
        .clk(cpu_clk),
        .rst_n(mem_rst_n),
        .cpu_address_bus(cpu_address_bus),
        .cpu_data_out(cpu_data_out),
        .cpu_write_en(cpu_write_en),
        .rom_data_out(rom_data_out),
        .cpu_rst_n(cpu_rst_n),
        .rom_addr(rom_addr),
        .ram_addr(ram_addr_boot),
        .ram_din(ram_din),
        .ram_we(ram_we)
    );

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
