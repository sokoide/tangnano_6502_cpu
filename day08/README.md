# Day 08: CPU Implementation Part 3 - Integration and Testing

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

-   Integration and connection of each CPU module
-   Implementation of the instruction execution cycle control
-   Operational testing with a basic 6502 program
-   Mastering debugging methods and simulation techniques

## 📚 Theory

### Instruction Execution Cycle

**Basic Cycle (minimum 2 clocks):**

1.  **Fetch**: Read opcode from PC
2.  **Decode**: Analyze instruction and read operand
3.  **Execute**: Perform ALU operation and update registers
4.  **Writeback**: Write back the result

**Variable Number of Cycles:**

-   2-7 cycles depending on the addressing mode
-   +1 cycle for page boundary crossing
-   +1 cycle for a successful branch

### CPU State Machine

**Main States:**

-   FETCH: Instruction fetch
-   DECODE: Instruction decode and address calculation
-   EXECUTE: Execute ALU operation
-   MEMORY: Memory access
-   WRITEBACK: Write back result

## 🛠️ Practice 1: CPU Integration Module

```systemverilog
module cpu_6502 (
    input  logic clk,
    input  logic rst_n,

    // Memory interface
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_read,
    output logic        mem_write,
    input  logic        mem_ready,

    // Debug outputs
    output logic [7:0]  debug_reg_a,
    output logic [7:0]  debug_reg_x,
    output logic [7:0]  debug_reg_y,
    output logic [7:0]  debug_reg_sp,
    output logic [15:0] debug_reg_pc,
    output logic [7:0]  debug_status,
    output logic [7:0]  debug_opcode,

    // Control signals
    input  logic        cpu_enable,
    output logic        cpu_halted
);

    // Internal signals
    logic [7:0] current_opcode;
    logic [7:0] operand1, operand2;
    logic [15:0] effective_addr;

    // Register set
    logic [7:0]  reg_a, reg_x, reg_y, reg_sp, status_reg;
    logic [15:0] reg_pc;

    // ALU related
    logic [7:0]  alu_result;
    logic [3:0]  alu_op;
    logic        alu_carry_in, alu_carry_out;
    logic        alu_overflow, alu_negative, alu_zero;

    // Control signals
    logic reg_a_write, reg_x_write, reg_y_write;
    logic reg_sp_write, reg_pc_write;
    logic update_nz, update_c, update_v;

    // State machine
    typedef enum logic [2:0] {
        STATE_FETCH,
        STATE_DECODE,
        STATE_EXECUTE,
        STATE_MEMORY,
        STATE_WRITEBACK,
        STATE_HALT
    } cpu_state_t;

    cpu_state_t current_state, next_state;
    logic [2:0] cycle_counter;

    // State transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_FETCH;
            cycle_counter <= 3'b000;
            reg_pc <= 16'h0200;  // Program start address
        end else if (cpu_enable && mem_ready) begin
            current_state <= next_state;
            if (next_state != current_state) begin
                cycle_counter <= 3'b000;
            end else begin
                cycle_counter <= cycle_counter + 1;
            end
        end
    end

    // Next state determination
    always_comb begin
        next_state = current_state;

        case (current_state)
            STATE_FETCH: begin
                if (mem_ready) begin
                    next_state = STATE_DECODE;
                end
            end

            STATE_DECODE: begin
                // Branch according to instruction type
                case (current_opcode)
                    8'hEF: next_state = STATE_HALT;  // HLT instruction
                    default: next_state = STATE_EXECUTE;
                endcase
            end

            STATE_EXECUTE: begin
                // Execution completion check (differs by instruction)
                next_state = STATE_WRITEBACK;
            end

            STATE_MEMORY: begin
                if (mem_ready) begin
                    next_state = STATE_WRITEBACK;
                end
            end

            STATE_WRITEBACK: begin
                next_state = STATE_FETCH;
            end

            STATE_HALT: begin
                // Maintain halt state
                next_state = STATE_HALT;
            end
        endcase
    end

    // Memory access control
    always_comb begin
        mem_addr = 16'h0000;
        mem_data_out = 8'h00;
        mem_read = 1'b0;
        mem_write = 1'b0;

        case (current_state)
            STATE_FETCH: begin
                mem_addr = reg_pc;
                mem_read = 1'b1;
            end

            STATE_DECODE: begin
                // Read operand
                if (cycle_counter == 0) begin
                    mem_addr = reg_pc + 1;
                    mem_read = 1'b1;
                end else if (cycle_counter == 1) begin
                    mem_addr = reg_pc + 2;
                    mem_read = 1'b1;
                end
            end

            STATE_MEMORY: begin
                mem_addr = effective_addr;
                if (/* store instruction */) begin
                    mem_write = 1'b1;
                    mem_data_out = reg_a;  // e.g., STA instruction
                end else begin
                    mem_read = 1'b1;
                end
            end
        endcase
    end

    // Get opcode and operands
    always_ff @(posedge clk) begin
        if (current_state == STATE_FETCH && mem_ready) begin
            current_opcode <= mem_data_in;
        end else if (current_state == STATE_DECODE && mem_ready) begin
            if (cycle_counter == 0) begin
                operand1 <= mem_data_in;
            end else if (cycle_counter == 1) begin
                operand2 <= mem_data_in;
            end
        end
    end

    // Instantiate CPU modules
    cpu_decoder decoder_inst (
        .opcode(current_opcode),
        .status_reg(status_reg),
        .alu_op(alu_op),
        .alu_carry_in(alu_carry_in),
        .reg_a_write(reg_a_write),
        // ... other control signals
    );

    cpu_alu alu_inst (
        .operand_a(reg_a),
        .operand_b(mem_data_in),  // Simplified
        .operation(alu_op),
        .carry_in(alu_carry_in),
        .result(alu_result),
        .carry_out(alu_carry_out),
        .overflow(alu_overflow),
        .negative(alu_negative),
        .zero(alu_zero)
    );

    // Register update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= 8'h00;
            reg_x <= 8'h00;
            reg_y <= 8'h00;
            reg_sp <= 8'hFF;
            status_reg <= 8'h20;
        end else if (current_state == STATE_WRITEBACK) begin
            if (reg_a_write) reg_a <= alu_result;
            if (reg_x_write) reg_x <= alu_result;
            if (reg_y_write) reg_y <= alu_result;

            // Flag update
            if (update_nz) begin
                status_reg[7] <= alu_negative;
                status_reg[1] <= alu_zero;
            end
            if (update_c) status_reg[0] <= alu_carry_out;
            if (update_v) status_reg[6] <= alu_overflow;

            // PC update
            reg_pc <= reg_pc + instruction_length;
        end
    end

    // Debug outputs
    assign debug_reg_a = reg_a;
    assign debug_reg_x = reg_x;
    assign debug_reg_y = reg_y;
    assign debug_reg_sp = reg_sp;
    assign debug_reg_pc = reg_pc;
    assign debug_status = status_reg;
    assign debug_opcode = current_opcode;
    assign cpu_halted = (current_state == STATE_HALT);

endmodule
```

## 🛠️ Practice 2: Testbench Implementation

```systemverilog
module tb_cpu_integration;

    logic clk;
    logic rst_n;
    logic [7:0] mem_data_in;
    logic [15:0] mem_addr;
    logic [7:0] mem_data_out;
    logic mem_read, mem_write;

    // Memory model (32KB)
    logic [7:0] memory [0:32767];

    // CPU instance
    cpu_6502 cpu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_data_in(mem_data_in),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_ready(1'b1),
        .cpu_enable(1'b1)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Memory access
    always_comb begin
        if (mem_read) begin
            mem_data_in = memory[mem_addr[14:0]];
        end else begin
            mem_data_in = 8'h00;
        end
    end

    always_ff @(posedge clk) begin
        if (mem_write) begin
            memory[mem_addr[14:0]] <= mem_data_out;
        end
    end

    // Execute test program
    initial begin
        // Reset
        rst_n = 0;
        #20 rst_n = 1;

        // Test program 1: LDA #$55
        memory[16'h0200] = 8'hA9;  // LDA Immediate
        memory[16'h0201] = 8'h55;  // Operand

        // Test program 2: STA $80
        memory[16'h0202] = 8'h85;  // STA Zero Page
        memory[16'h0203] = 8'h80;  // Address

        // Test program 3: HLT
        memory[16'h0204] = 8'hEF;  // HLT instruction

        // Run simulation
        #1000;

        // Check results
        assert (cpu_inst.debug_reg_a == 8'h55) else
            $error("Test failed: A register should be 0x55");

        assert (memory[16'h0080] == 8'h55) else
            $error("Test failed: Memory[0x80] should be 0x55");

        $display("All tests passed!");
        $finish;
    end

    // Waveform output
    initial begin
        $dumpfile("cpu_test.vcd");
        $dumpvars(0, tb_cpu_integration);
    end

endmodule
```

## 🛠️ Practice 3: More Complex Test Program

```assembly
; 6502 Assembly Test Program
; Counter program

.org $0200

START:
    LDA #$00        ; A = 0
    STA $80         ; memory[0x80] = A

LOOP:
    LDA $80         ; A = memory[0x80]
    CLC             ; Clear carry
    ADC #$01        ; A = A + 1
    STA $80         ; memory[0x80] = A
    CMP #$10        ; Compare A with 16
    BNE LOOP        ; If A != 16, go to LOOP

    HLT             ; End program
```

Corresponding SystemVerilog testbench:

```systemverilog
// Write test program to memory
initial begin
    memory[16'h0200] = 8'hA9; memory[16'h0201] = 8'h00; // LDA #$00
    memory[16'h0202] = 8'h85; memory[16'h0203] = 8'h80; // STA $80
    memory[16'h0204] = 8'hA5; memory[16'h0205] = 8'h80; // LDA $80
    memory[16'h0206] = 8'h18;                            // CLC
    memory[16'h0207] = 8'h69; memory[16'h0208] = 8'h01; // ADC #$01
    memory[16'h0209] = 8'h85; memory[16'h020A] = 8'h80; // STA $80
    memory[16'h020B] = 8'hC9; memory[16'h020C] = 8'h10; // CMP #$10
    memory[16'h020D] = 8'hD0; memory[16'h020E] = 8'hF5; // BNE LOOP (-11)
    memory[16'h020F] = 8'hEF;                            // HLT
end
```

## 📝 Assignments

### Basic Assignments

1.  Implement and test branch instructions
2.  Test stack operations (JSR/RTS)
3.  Verify flag behavior of arithmetic operations

### Advanced Assignments

1.  Basic implementation of interrupt handling
2.  Performance optimization
3.  Add error detection features

## 🔧 Debugging Techniques

### 1. Waveform Analysis

-   Verifying operation on a clock-cycle basis
-   Timing relationship of signals
-   Verifying state transitions

### 2. Assertions

-   Comparison with expected values
-   Detection of illegal states
-   Verifying the validity of register values

### 3. Log Output

```systemverilog
always_ff @(posedge clk) begin
    if (current_state == STATE_FETCH) begin
        $display("Time %t: Fetch PC=%04X, Opcode=%02X",
                 $time, reg_pc, mem_data_in);
    end
end
```

## 📚 What I Learned Today

-   [ ] How to integrate each CPU module
-   [ ] Implementation of the instruction execution cycle
-   [ ] Control with a state machine
-   [ ] Design of a testbench
-   [ ] Utilization of debugging techniques

## 🎯 Preview for Tomorrow

In Day 09, we will learn about LCD control and system integration:

-   LCD timing control
-   Character display system
-   Implementation of VRAM
