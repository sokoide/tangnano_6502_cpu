// cpu.sv - 6502 CPU Core Implementation
//
// This module implements a complete 6502 microprocessor with custom extensions
// for FPGA-based LCD display systems. The CPU includes:
//
// Standard 6502 Features:
// - All standard addressing modes (immediate, zero page, absolute, indexed, etc.)
// - Complete instruction set except interrupt-related instructions
// - Standard registers: A, X, Y, SP, PC, and status flags (C, Z, V, N, etc.)
// - 64KB addressable memory space with configurable memory map
//
// Custom Extensions:
// - CVR (0xCF): Clear VRAM - Hardware-accelerated VRAM clearing
// - IFO (0xDF): Info/Debug - Display registers and memory for debugging
// - HLT (0xEF): Halt - Stop CPU execution while preserving LCD operation
// - WVS (0xFF): Wait VSync - Synchronize with LCD vertical refresh
//
// Memory Map Integration:
// - 0x0000-0x00FF: Zero Page (256B)
// - 0x0100-0x01FF: Stack (256B)
// - 0x0200-0x7BFF: Program RAM (30.5KB)
// - 0x7C00-0x7FFF: Shadow VRAM (1KB, read-only)
// - 0xE000-0xE3FF: Text VRAM (1KB, write-only)
//
// State Machine Architecture:
// - Multi-stage fetch/decode/execute pipeline
// - Separate states for memory operations and custom instructions
// - Proper handling of different instruction lengths and addressing modes
//
`include "../include/consts.svh"
`include "../include/cpu_pkg.sv"
`include "cpu/cpu_types_pkg.sv"
`include "cpu/cpu_fsm_next_pkg.sv"
`include "cpu/cpu_exec_transfers_pkg.sv"
`include "cpu/cpu_exec_flags_custom_pkg.sv"
`include "cpu/cpu_exec_branches_pkg.sv"
`include "cpu/cpu_exec_compare_pkg.sv"
`include "cpu/cpu_exec_logic_pkg.sv"
`include "cpu/cpu_exec_shifts_pkg.sv"
`include "cpu/cpu_exec_store_pkg.sv"
`include "cpu/cpu_exec_inc_dec_pkg.sv"
`include "cpu/cpu_exec_control_flow_pkg.sv"
`include "cpu/cpu_exec_load_store_pkg.sv"
`include "cpu/cpu_exec_adc_sbc_pkg.sv"
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
module cpu (
    // Clock and Reset
    input logic rst_n,  // Active-low asynchronous reset
    input logic clk,    // System clock (40.5MHz)

    // Memory Interface
    input  logic [ 7:0] dout,  // RAM read data
    output logic [ 7:0] din,   // RAM write data
    output logic [14:0] ada,   // RAM write address (32KB space)
    output logic [14:0] adb,   // RAM read address (32KB space)
    output logic        cea,   // RAM write enable
    output logic        ceb,   // RAM read enable

    // Video Memory Interface
    output logic [9:0] v_ada,  // VRAM write address (1KB space)
    output logic       v_cea,  // VRAM write enable
    output logic [7:0] v_din,  // VRAM write data (character codes)

    // System Integration
    input logic        vsync,                      // LCD vertical sync (for WVS instruction)
    input logic [ 7:0] boot_program       [7680],  // Boot program ROM (max 30KB)
    input logic [15:0] boot_program_length         // Actual boot program size
);

    import cpu_pkg::*;
    import cpu_types_pkg::*;
    import cpu_fsm_next_pkg::*;

    /* verilator lint_off UNUSEDSIGNAL */
    // 6502 CPU Registers
    // Program Counter and addressing
    logic        [15:0] pc;  // Program Counter (16-bit)
    logic        [15:0] pc_plus1;  // PC + 1 for instruction fetch
    logic        [15:0] pc_plus2;  // PC + 2 for instruction fetch
    logic        [15:0] pc_plus3;  // PC + 3 for instruction fetch

    // Data Registers
    logic        [ 7:0] ra;  // Accumulator (A Register)
    logic        [ 7:0] rx;  // X Index Register
    logic        [ 7:0] ry;  // Y Index Register
    logic        [ 7:0] sp;  // Stack Pointer (points into 0x0100-0x01FF)

    // Status Flags (Processor Status Register)
    logic               flg_c;  // Carry flag
    logic               flg_z;  // Zero flag
    logic               flg_i;  // Interrupt disable (not implemented)
    logic               flg_d;  // Decimal mode flag (not implemented)
    logic               flg_b;  // Break command flag (not implemented)
    logic               flg_v;  // Overflow flag
    logic               flg_n;  // Negative flag
    logic        [15:0] addr;
    logic signed [15:0] s_offset;
    logic signed [ 7:0] s_imm8;
    logic        [ 7:0] dout_r;  // RAM read latch
    logic               write_to_vram;  // Flag set by sta_write

    // Internal states
    logic        [ 7:0] opcode;
    logic        [15:0] operands;
    logic        [ 2:0] fetched_data_bytes;
    logic        [15:0] fetched_data;
    logic        [ 2:0] written_data_bytes;
    logic        [ 7:0] char_code;
    logic        [31:0] counter;
    logic        [14:0] boot_idx;
    logic               boot_write;
    logic vsync_meta, vsync_sync;
    logic [1:0] vsync_stage;
    logic [31:0] show_info_counter;
    cpu_state_e state;
    cpu_state_e prev_state;
    cpu_state_e fetch_resume_state;
    cpu_state_e next_state;
    fetch_stage_e fetch_stage;
    fetch_stage_e next_fetch_stage;
    show_info_stage_e show_info_stage;
    cpu_ctx_t cur;
    cpu_ctx_t next_ctx;
    cpu_in_t cpu_inputs;
    fsm_next_t boot_fetch_next;
    /* verilator lint_on UNUSEDSIGNAL */

    `include "../include/cpu_tasks.svh"
    `include "cpu/state_boot_tasks.sv"
    `include "cpu/state_fetch_tasks.sv"
    `include "cpu/state_write_req_tasks.sv"
    `include "cpu/state_show_info_tasks.sv"
    `include "cpu/state_clear_vram_tasks.sv"
    `include "cpu/state_decode_tasks.sv"
    `include "cpu/state_machine.svh"

    // din ratch
    always_ff @(posedge clk) dout_r <= dout;

    always_comb begin
        cur = '{
            pc: pc,
            pc_plus1: pc_plus1,
            pc_plus2: pc_plus2,
            pc_plus3: pc_plus3,

            ra: ra,
            rx: rx,
            ry: ry,
            sp: sp,

            flg_c: flg_c,
            flg_z: flg_z,
            flg_i: flg_i,
            flg_d: flg_d,
            flg_b: flg_b,
            flg_v: flg_v,
            flg_n: flg_n,

            din: din,
            ada: ada,
            adb: adb,
            cea: cea,
            ceb: ceb,

            v_ada: v_ada,
            v_cea: v_cea,
            v_din: v_din,

            opcode: opcode,
            operands: operands,

            fetched_data_bytes: fetched_data_bytes,
            fetched_data: fetched_data,
            written_data_bytes: written_data_bytes,

            write_to_vram: write_to_vram,

            dout_r: dout_r,

            char_code: char_code,
            counter: counter,
            boot_idx: boot_idx,
            boot_write: boot_write,

            vsync_meta: vsync_meta,
            vsync_sync: vsync_sync,
            vsync_stage: vsync_stage,

            show_info_counter: show_info_counter,
            show_info_cmd: show_info_cmd,

            state: state,
            prev_state: prev_state,
            fetch_resume_state: fetch_resume_state,
            next_state: next_state,
            fetch_stage: fetch_stage,
            next_fetch_stage: next_fetch_stage,
            show_info_stage: show_info_stage
        };

        cpu_inputs = '{
            dout: dout,
            vsync: vsync,
            boot_program_length: boot_program_length,
            boot_byte: boot_program[cur.boot_idx]
        };
        next_ctx = cpu_fsm_next_pkg::calc_cpu_next(cur, cpu_inputs);

        boot_fetch_next = cpu_fsm_next_pkg::calc_boot_fetch_next(
            state,
            fetch_stage,
            fetch_resume_state,
            prev_state,
            dout,
            boot_idx,
            boot_program_length,
            boot_write,
            v_ada,
            show_info_counter,
            show_info_stage,
            show_info_cmd.mem_read
        );
    end

    // Sequential logic: use an asynchronous active-low rst_n.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // rst_n: clear selected registers and the flag.
            {ra, rx, ry}                                      <= 8'd0;
            {flg_c, flg_z, flg_i, flg_d, flg_b, flg_v, flg_n} <= 1'b0;
            pc                                                <= 16'h0200;
            pc_plus1                                          <= 16'h0000;
            pc_plus2                                          <= 16'h0000;
            pc_plus3                                          <= 16'h0000;
            sp                                                <= 8'hFF;
            ada                                               <= 15'h0000;
            ceb                                               <= 1'b1;
            din                                               <= 8'h0;
            adb                                               <= PROGRAM_START;
            v_ada                                             <= 10'h0000;
            v_cea                                             <= 0;
            v_din                                             <= 8'h0;
            opcode                                            <= 8'h0;
            operands                                          <= 16'h0000;
            fetched_data_bytes                                <= 0;
            written_data_bytes                                <= 0;
            fetched_data                                      <= 16'h0000;
            state                                             <= INIT;
            prev_state                                        <= INIT;
            fetch_resume_state                                <= INIT;
            next_state                                        <= INIT;
            next_fetch_stage                                  <= FETCH_OPCODE;
            fetch_stage                                       <= FETCH_OPCODE;
            char_code                                         <= 8'h20;  // ' '
            counter                                           <= 32'h0;
            boot_idx                                          <= 0;
            boot_write                                        <= 0;
            vsync_meta                                        <= 1'b0;
            vsync_sync                                        <= 1'b0;
            vsync_stage                                       <= 0;
            show_info_counter                                 <= 0;
        end else begin
            vsync_meta <= vsync;
            vsync_sync <= vsync_meta;
            begin
                counter <= (counter + 1) & 32'hFFFFFFFF;

                state_machine_step();
                if (cpu_fsm_next_pkg::uses_pure_next(state)) begin
                    begin
                        state <= boot_fetch_next.next_state;
                        fetch_stage <= boot_fetch_next.next_fetch_stage;
                    end
                end else begin
                    state <= next_state;
                    fetch_stage <= next_fetch_stage;
                end
            end
        end
    end

    /* verilator lint_on WIDTHTRUNC */
    /* verilator lint_on WIDTHEXPAND */
endmodule
