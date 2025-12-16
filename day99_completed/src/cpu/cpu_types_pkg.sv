// cpu_types_pkg.sv - CPU refactor types
//
// This package defines the CPU "context" struct used by the planned refactor:
// - `cpu_ctx_t` represents all CPU internal state and outputs.
// - `cpu_in_t` represents per-cycle inputs observed by the CPU.
//
// The goal is to enable a formatter-friendly split into `package + function`
// units (Go-like namespaces) and a 2-process FSM (`always_comb` next-state,
// `always_ff` state register update).

package cpu_types_pkg;
    import cpu_pkg::*;

    typedef struct packed {
        // Program counter and precomputed increments.
        logic [15:0] pc;
        logic [15:0] pc_plus1;
        logic [15:0] pc_plus2;
        logic [15:0] pc_plus3;

        // 6502 registers.
        logic [7:0] ra;
        logic [7:0] rx;
        logic [7:0] ry;
        logic [7:0] sp;

        // Flags.
        logic flg_c;
        logic flg_z;
        logic flg_i;
        logic flg_d;
        logic flg_b;
        logic flg_v;
        logic flg_n;

        // Memory interface (module outputs).
        logic [7:0] din;
        logic [14:0] ada;
        logic [14:0] adb;
        logic cea;
        logic ceb;

        // VRAM interface (module outputs).
        logic [9:0] v_ada;
        logic v_cea;
        logic [7:0] v_din;

        // Instruction stream and operands.
        logic [7:0]  opcode;
        logic [15:0] operands;

        // Multi-byte read/write bookkeeping.
        logic [2:0]  fetched_data_bytes;
        logic [15:0] fetched_data;
        logic [2:0]  written_data_bytes;

        // Writes to VRAM are conditional in STA helper logic.
        logic write_to_vram;

        // RAM read latch.
        logic [7:0] dout_r;

        // Boot/diagnostic helpers.
        logic [7:0] char_code;
        logic [31:0] counter;
        logic [14:0] boot_idx;
        logic boot_write;

        logic vsync_meta;
        logic vsync_sync;
        logic [1:0] vsync_stage;

        logic [31:0] show_info_counter;
        show_info_cmd_t show_info_cmd;

        // FSM state.
        cpu_state_e state;
        cpu_state_e prev_state;
        cpu_state_e fetch_resume_state;
        cpu_state_e next_state;
        fetch_stage_e fetch_stage;
        fetch_stage_e next_fetch_stage;
        show_info_stage_e show_info_stage;
    } cpu_ctx_t;

    typedef struct packed {
        logic [7:0] dout;
        logic vsync;
        logic [15:0] boot_program_length;
        logic [7:0] boot_byte;
    } cpu_in_t;
endpackage
