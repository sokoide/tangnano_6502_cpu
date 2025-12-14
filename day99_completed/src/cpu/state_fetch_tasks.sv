task automatic state_fetch_req();
  begin
    if (fetch_stage == FETCH_OPCODE) begin
      next_state = FETCH_RECV;
    end else begin
      next_state = FETCH_WAIT;
    end
    // timing improvement to avoid redundant pc calculations elsewhere.
    pc_plus1 <= (pc + 16'd1) & RAMW;
    pc_plus2 <= (pc + 16'd2) & RAMW;
    pc_plus3 <= (pc + 16'd3) & RAMW;
  end
endtask

task automatic state_fetch_wait();
  begin
    if (fetch_stage == FETCH_DATA) begin
      fetched_data_bytes <= fetched_data_bytes + 1'd1;
      next_state = fetch_resume_state;
    end else begin
      next_state = FETCH_RECV;
    end
  end
endtask

task automatic state_fetch_recv();
  begin
    unique case (fetch_stage)
      FETCH_OPCODE: begin
        opcode <= dout;
        fetched_data_bytes <= 0;
        written_data_bytes <= 0;
        cea <= 0;
        v_cea <= 0;

        case (dout)
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
            next_state = DECODE_EXECUTE;
          end

          // Instructions with 1-byte operand
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
            adb <= pc_plus1 & RAMW;
            next_fetch_stage = FETCH_OPERAND1;
            next_state = FETCH_REQ;
          end

          default: begin
            adb <= pc_plus1 & RAMW;
            next_fetch_stage = FETCH_OPERAND1OF2;
            next_state = FETCH_REQ;
          end
        endcase
      end

      FETCH_OPERAND1: begin
        operands[7:0] <= dout;
        next_state = DECODE_EXECUTE;
      end

      FETCH_OPERAND1OF2: begin
        operands[7:0] <= dout;
        adb <= pc_plus2 & RAMW;
        next_fetch_stage = FETCH_OPERAND2;
        next_state = FETCH_REQ;
      end

      FETCH_OPERAND2: begin
        operands[15:8] <= dout;
        next_state = DECODE_EXECUTE;
      end

      default: begin
        // Should not reach here.
      end
    endcase
  end
endtask

task automatic state_fetch_operand1();
  begin
    operands[7:0] <= dout;
    next_state = DECODE_EXECUTE;
  end
endtask

task automatic state_fetch_operand1of2();
  begin
    operands[7:0] <= dout;
    adb <= pc_plus2 & RAMW;
    next_fetch_stage = FETCH_OPERAND2;
    next_state = FETCH_REQ;
  end
endtask

task automatic state_fetch_operand2();
  begin
    operands[15:8] <= dout;
    next_state = DECODE_EXECUTE;
  end
endtask
