// Independent binary ALU oracle; verifies every A/B/carry combination.
// This tests cpu_alu directly, without assuming it is used by cpu.sv.
`timescale 1ns / 1ps

module tb_alu_regression;
  localparam logic [3:0] ALU_ADC = 4'h1;
  localparam logic [3:0] ALU_SBC = 4'h2;
  localparam logic [3:0] ALU_CMP = 4'h6;
  localparam int VECTORS_PER_OPERATION = 256 * 256 * 2;

  logic [3:0] alu_op;
  logic [7:0] operand_a, operand_b, result;
  logic carry_in, carry_out, zero_flag, negative_flag, overflow_flag;
  int vectors_checked = 0;

  cpu_alu dut (.*);

  task automatic check_operation(input logic [3:0] operation);
    int arithmetic_result;
    int signed_result;
    int signed_a, signed_b;
    logic [7:0] expected_result, flag_result;
    logic expected_carry, expected_zero, expected_negative, expected_overflow;

    for (int a = 0; a < 256; a++) begin
      for (int b = 0; b < 256; b++) begin
        for (int c = 0; c < 2; c++) begin
          alu_op = operation;
          operand_a = 8'(a);
          operand_b = 8'(b);
          carry_in = 1'(c);

          // Compute with mathematical integers, then truncate to eight bits.
          // Signed overflow is range overflow, independent of the DUT formula.
          signed_a = a < 128 ? a : a - 256;
          signed_b = b < 128 ? b : b - 256;
          case (operation)
            ALU_ADC: begin
              arithmetic_result = a + b + c;
              signed_result = signed_a + signed_b + c;
              expected_carry = arithmetic_result > 255;
            end
            ALU_SBC: begin
              arithmetic_result = a - b - (1 - c);
              signed_result = signed_a - signed_b - (1 - c);
              expected_carry = arithmetic_result >= 0;
            end
            ALU_CMP: begin
              // CMP ignores incoming carry and returns A unchanged.
              arithmetic_result = a - b;
              signed_result = 0;
              expected_carry = a >= b;
            end
            default: $fatal(1, "Unsupported regression operation: %h", operation);
          endcase

          flag_result = 8'(arithmetic_result);
          expected_result = operation == ALU_CMP ? 8'(a) : flag_result;
          expected_zero = flag_result == 8'h00;
          expected_negative = flag_result[7];
          // CMP emits zero V at this module boundary; CPU flag masks are separate.
          expected_overflow = signed_result < -128 || signed_result > 127;

          #1;
          assert ({result, carry_out, zero_flag, negative_flag, overflow_flag} ===
                  {expected_result, expected_carry, expected_zero,
                   expected_negative, expected_overflow})
          else $fatal(1,
              "op=%h A=%h B=%h Cin=%b got R/C/Z/N/V=%h/%b/%b/%b/%b expected=%h/%b/%b/%b/%b",
              operation, operand_a, operand_b, carry_in,
              result, carry_out, zero_flag, negative_flag, overflow_flag,
              expected_result, expected_carry, expected_zero,
              expected_negative, expected_overflow);
          vectors_checked++;
        end
      end
    end
  endtask

  initial begin
    check_operation(ALU_CMP);
    check_operation(ALU_ADC);
    check_operation(ALU_SBC);
    assert (vectors_checked == 3 * VECTORS_PER_OPERATION)
    else $fatal(1, "Incomplete regression: %0d vectors", vectors_checked);
    $display("PASS: CMP/ADC/SBC ALU regression (%0d vectors)", vectors_checked);
    $finish;
  end

  initial begin
    #500000;
    $fatal(1, "ALU regression timeout after %0d vectors", vectors_checked);
  end
endmodule
