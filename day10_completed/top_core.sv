module top_core (
    input  logic       rst_n,
    input  logic       XTAL_IN,
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B
);

    // Clock generation: 27MHz -> 9MHz
    Gowin_rPLL9 pll_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    // CPU wires
    logic [15:0] cpu_mem_addr;
    logic [ 7:0] cpu_mem_data_out;
    logic [ 7:0] cpu_mem_data_in;
    logic        cpu_mem_read;
    logic        cpu_mem_write;
    logic        cpu_mem_ready;

    // Memory controller wires
    logic [15:0] ext_addr;
    logic [ 7:0] ext_data_out;
    logic [ 7:0] ext_data_in;
    logic        ext_oe;
    logic        ext_we;
    logic        ram_select;
    logic        rom_select;
    logic        io_select;
    logic        vram_select;

    logic [ 7:0] ram_data_out;
    logic [ 7:0] rom_data_out;

    logic [ 7:0] mem_stack_data_in;
    logic [ 7:0] mem_stack_pointer;

    // VRAM pipeline
    logic [ 9:0] vram_addr;
    logic [ 7:0] vram_data;

    logic [11:0] font_addr;
    logic [ 7:0] font_data;

    /* verilator lint_off UNUSEDSIGNAL */
    logic vsync;
    /* verilator lint_on UNUSEDSIGNAL */

    // 6502 CPU Core
    cpu_core cpu (
        .clk             (LCD_CLK),
        .rst_n           (rst_n),
        .mem_addr        (cpu_mem_addr),
        .mem_data_out    (cpu_mem_data_out),
        .mem_data_in     (cpu_mem_data_in),
        .mem_read        (cpu_mem_read),
        .mem_write       (cpu_mem_write),
        .mem_ready       (cpu_mem_ready),
        .irq_n           (1'b1),
        .nmi_n           (1'b1),
        .debug_reg_a     (),
        .debug_reg_x     (),
        .debug_reg_y     (),
        .debug_reg_sp    (),
        .debug_reg_pc    (),
        .debug_status_reg(),
        .debug_opcode    (),
        .debug_cpu_state (),
        .debug_alu_result()
    );

    memory_controller mem_ctrl (
        .clk           (LCD_CLK),
        .rst_n         (rst_n),
        .cpu_addr      (cpu_mem_addr),
        .cpu_data_out  (cpu_mem_data_out),
        .cpu_data_in   (cpu_mem_data_in),
        .cpu_mem_read  (cpu_mem_read),
        .cpu_mem_write (cpu_mem_write),
        .cpu_ready     (cpu_mem_ready),
        .stack_push    (1'b0),
        .stack_pop     (1'b0),
        .stack_data_out(8'h00),
        .stack_data_in (mem_stack_data_in),
        .stack_pointer (mem_stack_pointer),
        .ext_addr      (ext_addr),
        .ext_data_out  (ext_data_out),
        .ext_data_in   (ext_data_in),
        .ext_oe        (ext_oe),
        .ext_we        (ext_we),
        .ram_select    (ram_select),
        .rom_select    (rom_select),
        .io_select     (io_select),
        .vram_select   (vram_select)
    );

`ifdef VERILATOR
    simple_ram #(
        .ADDR_WIDTH(15),
        .DATA_WIDTH(8)
    ) ram_inst (
        .clk(LCD_CLK),
        .rst_n(rst_n),
        .addr(ext_addr[14:0]),
        .data_in(ext_data_out),
        .data_out(ram_data_out),
        .we(ext_we && ram_select),
        .oe(ext_oe && ram_select),
        .cs(ram_select)
    );
`else
    Gowin_SDPB ram_inst (
        .dout  (ram_data_out),
        .clka  (LCD_CLK),
        .cea   (ext_we && ram_select),
        .reseta(1'b0),
        .clkb  (LCD_CLK),
        .ceb   (ext_oe && ram_select),
        .resetb(1'b0),
        .oce   (1'b1),
        .ada   (ext_addr[14:0]),
        .din   (ext_data_out),
        .adb   (ext_addr[14:0])
    );
`endif

    boot_rom rom_inst (
        .clk(LCD_CLK),
        .rst_n(rst_n),
        .addr(ext_addr),
        .data_out(rom_data_out),
        .oe(ext_oe && rom_select),
        .cs(rom_select)
    );

    vram vram_inst (
        .clk(LCD_CLK),
        .rst_n(rst_n),
        .cpu_we(ext_we && vram_select),
        .cpu_addr(ext_addr[9:0]),
        .cpu_data(ext_data_out),
        .lcd_addr(vram_addr),
        .lcd_data(vram_data)
    );

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

    font_rom font_inst (
        .clk(LCD_CLK),
        .addr(font_addr),
        .data(font_data)
    );

    always_comb begin
        if (ram_select) begin
            ext_data_in = ram_data_out;
        end else if (rom_select) begin
            ext_data_in = rom_data_out;
        end else begin
            ext_data_in = 8'h00;
        end
    end

endmodule
