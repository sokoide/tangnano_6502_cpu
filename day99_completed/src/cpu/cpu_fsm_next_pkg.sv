// cpu_fsm_next_pkg.sv - planned 2-process FSM next-state logic
//
// This package is a stepping stone toward the 2-process FSM described in `docs/FSM.md`.
// It provides "next-state only" logic (no side effects) so that:
// - `always_comb` can compute next state/stage deterministically
// - `always_ff` can perform registered side effects and state updates
//
// Note: this is not fully wired into `cpu.sv` yet. We will migrate state-by-state.

`include "consts_pkg.sv"

package cpu_fsm_next_pkg;
  import cpu_pkg::*;
  import consts_pkg::*;

  typedef struct packed {
    cpu_state_e   next_state;
    fetch_stage_e next_fetch_stage;
  } fsm_next_t;

  function automatic fsm_next_t calc_boot_fetch_next(
      input cpu_state_e state, input fetch_stage_e fetch_stage,
      input cpu_state_e fetch_resume_state, input cpu_state_e prev_state, input logic [7:0] dout,
      input logic [14:0] boot_idx, input logic [15:0] boot_program_length, input logic boot_write,
      input logic [9:0] v_ada, input logic [31:0] show_info_counter,
      input show_info_stage_e show_info_stage, input logic show_info_mem_read);
    fsm_next_t r;
    logic [15:0] boot_idx_u16;
    int unsigned v_ada_u32;

    boot_idx_u16 = {1'b0, boot_idx};
    v_ada_u32 = {22'd0, v_ada};

    r.next_state = state;
    r.next_fetch_stage = fetch_stage;

    unique case (state)
      INIT: begin
        r.next_state = INIT_RAM;
      end

      HALT: begin
        r.next_state = HALT;
      end

      INIT_RAM: begin
        if (!boot_write) begin
          if (boot_idx_u16 == boot_program_length) begin
            r.next_state = FETCH_REQ;
            r.next_fetch_stage = FETCH_OPCODE;
          end else begin
            r.next_state = INIT_RAM;
          end
        end else begin
          r.next_state = INIT_RAM;
        end
      end

      FETCH_REQ: begin
        if (fetch_stage == FETCH_OPCODE) begin
          r.next_state = FETCH_RECV;
        end else begin
          r.next_state = FETCH_WAIT;
        end
      end

      FETCH_WAIT: begin
        if (fetch_stage == FETCH_DATA) begin
          r.next_state = fetch_resume_state;
        end else begin
          r.next_state = FETCH_RECV;
        end
      end

      FETCH_RECV: begin
        unique case (fetch_stage)
          FETCH_OPCODE: begin
            unique case (dout)
              // No operand instructions
              8'hEA,
                            8'h60,
                            8'h48,
                            8'h68,
                            8'h08,
                            8'h28,
                            8'hE8,
                            8'hC8,
                            8'hCA,
                            8'h88,
                            8'h0A,
                            8'h4A,
                            8'h2A,
                            8'h6A,
                            8'hAA,
                            8'hA8,
                            8'h8A,
                            8'h98,
                            8'hBA,
                            8'h9A,
                            8'h18,
                            8'hB8,
                            8'h38,
                            8'hCF,
                            8'hEF: begin
                r.next_state = DECODE_EXECUTE;
              end

              // 1-byte operand instructions
              8'hA9,
                            8'hA5,
                            8'hB5,
                            8'hA2,
                            8'hA6,
                            8'hB6,
                            8'hA0,
                            8'hA4,
                            8'hB4,
                            8'h85,
                            8'h95,
                            8'h81,
                            8'h91,
                            8'h86,
                            8'h96,
                            8'h84,
                            8'h94,
                            8'hE6,
                            8'hF6,
                            8'hC6,
                            8'hD6,
                            8'h69,
                            8'h65,
                            8'h75,
                            8'h61,
                            8'h71,
                            8'hE9,
                            8'hE5,
                            8'hF5,
                            8'hE1,
                            8'hF1,
                            8'h29,
                            8'h25,
                            8'h35,
                            8'h21,
                            8'h31,
                            8'h49,
                            8'h45,
                            8'h55,
                            8'h41,
                            8'h51,
                            8'h09,
                            8'h05,
                            8'h15,
                            8'h01,
                            8'h11,
                            8'h06,
                            8'h16,
                            8'h46,
                            8'h56,
                            8'h26,
                            8'h36,
                            8'h66,
                            8'h76,
                            8'h24,
                            8'hC9,
                            8'hC5,
                            8'hD5,
                            8'hC1,
                            8'hD1,
                            8'hE0,
                            8'hE4,
                            8'hC0,
                            8'hC4,
                            8'hF0,
                            8'h30,
                            8'hD0,
                            8'h10,
                            8'h50,
                            8'h70,
                            8'h90,
                            8'hB0,
                            8'hFF: begin
                r.next_fetch_stage = FETCH_OPERAND1;
                r.next_state = FETCH_REQ;
              end

              default: begin
                r.next_fetch_stage = FETCH_OPERAND1OF2;
                r.next_state = FETCH_REQ;
              end
            endcase
          end

          FETCH_OPERAND1: begin
            r.next_state = DECODE_EXECUTE;
          end

          FETCH_OPERAND1OF2: begin
            r.next_fetch_stage = FETCH_OPERAND2;
            r.next_state = FETCH_REQ;
          end

          FETCH_OPERAND2: begin
            r.next_state = DECODE_EXECUTE;
          end

          default: begin
            // Keep defaults.
          end
        endcase
      end

      WRITE_REQ: begin
        r.next_state = DECODE_EXECUTE;
      end

      CLEAR_VRAM: begin
        r.next_state = CLEAR_VRAM2;
      end

      CLEAR_VRAM2: begin
        if (v_ada_u32 <= (COLUMNS * ROWS)) begin
          r.next_state = CLEAR_VRAM2;
        end else begin
          r.next_state = FETCH_REQ;
          r.next_fetch_stage = FETCH_OPCODE;
        end
      end

      SHOW_INFO: begin
        r.next_state = SHOW_INFO2;
      end

      SHOW_INFO2: begin
        if (show_info_stage == SHOW_INFO_EXECUTE) begin
          if (show_info_counter == 1020) begin
            r.next_state = prev_state;
          end else if (show_info_mem_read) begin
            r.next_state = FETCH_REQ;
            r.next_fetch_stage = FETCH_DATA;
          end else begin
            r.next_state = SHOW_INFO2;
          end
        end else begin
          r.next_state = SHOW_INFO2;
        end
      end

      INIT_VRAM: begin
        if (v_ada_u32 <= (COLUMNS * ROWS)) begin
          r.next_state = INIT_VRAM;
        end else begin
          r.next_state = HALT;
        end
      end

      default: begin
        // Keep defaults.
      end
    endcase

    return r;
  endfunction
endpackage
