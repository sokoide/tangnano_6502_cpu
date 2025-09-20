# Day 06: CPU Implementation Part 1 - Decoder and ALU

## 🎯 Learning Objectives

- Design and implement a complete instruction decoder
- Detailed implementation of a 6502-compatible ALU
- Accurate implementation of flag generation logic
- Understand the concept of micro-instruction control

## 📚 Theory

### Instruction Decoder Design Policy

**Hierarchical Decoding:**
1.  **First Stage**: Determine the instruction type (Load/Store/ALU, etc.)
2.  **Second Stage**: Determine the addressing mode
3.  **Third Stage**: Generate control signals

**Types of Control Signals:**
- ALU operation selection
- Register write control
- Memory access control
- Flag update control

### ALU Design Requirements

**Supported Operations:**
- Arithmetic operations: ADD, SUB (with carry)
- Logical operations: AND, OR, XOR
- Shift operations: ASL, LSR, ROL, ROR
- Compare operations: CMP, CPX, CPY
- Increment/Decrement: INC, DEC

## 🛠️ Practice 1: Complete Instruction Decoder

```systemverilog
module cpu_decoder (
    input  logic [7:0] opcode,
    input  logic [7:0] status_reg,

    // ALU control
    output logic [3:0] alu_op,
    output logic       alu_carry_in,

    // Register control
    output logic reg_a_write,
    output logic reg_x_write,
    output logic reg_y_write,
    output logic reg_sp_write,
    output logic reg_pc_write,

    // Memory control
    output logic mem_read,
    output logic mem_write,

    // Flag control
    output logic update_nz,
    output logic update_c,
    output logic update_v,

    // Datapath control
    output logic [2:0] reg_src_sel,    // Register input selection
    output logic [1:0] alu_a_sel,     // ALU A input selection
    output logic [1:0] alu_b_sel,     // ALU B input selection

    // Addressing
    output logic [2:0] addr_mode,
    output logic [1:0] instruction_length
);

    // ALU operation definitions
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_ASL = 4'b0101;
    localparam ALU_LSR = 4'b0110;
    localparam ALU_ROL = 4'b0111;
    localparam ALU_ROR = 4'b1000;
    localparam ALU_INC = 4'b1001;
    localparam ALU_DEC = 4'b1010;
    localparam ALU_PASS_A = 4'b1011;
    localparam ALU_PASS_B = 4'b1100;

    always_comb begin
        // Default values
        alu_op = ALU_PASS_A;
        alu_carry_in = 1'b0;

        {reg_a_write, reg_x_write, reg_y_write} = 3'b000;
        {reg_sp_write, reg_pc_write} = 2'b00;

        {mem_read, mem_write} = 2'b00;
        {update_nz, update_c, update_v} = 3'b000;

        reg_src_sel = 3'b000;
        alu_a_sel = 2'b00;
        alu_b_sel = 2'b00;

        addr_mode = 3'b000;
        instruction_length = 2'd1;

        case (opcode)
            // LDA Immediate
            8'hA9: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_B;
                reg_src_sel = 3'b001;  // ALU result
                addr_mode = 3'b000;    // Immediate
                instruction_length = 2'd2;
            end

            // ADC Immediate
            8'h69: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                update_c = 1'b1;
                update_v = 1'b1;
                alu_op = ALU_ADD;
                alu_carry_in = status_reg[0];  // C flag
                alu_a_sel = 2'b00;    // A register
                alu_b_sel = 2'b01;    // Memory data
                reg_src_sel = 3'b001; // ALU result
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // STA Zero Page
            8'h85: begin
                mem_write = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = 2'b00;    // A register
                addr_mode = 3'b001;   // Zero Page
                instruction_length = 2'd2;
            end

            // TAX
            8'hAA: begin
                reg_x_write = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = 2'b00;    // A register
                reg_src_sel = 3'b001; // ALU result
                instruction_length = 2'd1;
            end

            // TODO: Implement other important instructions

            default: begin
                // NOP or unimplemented instruction
                instruction_length = 2'd1;
            end
        endcase
    end

endmodule
```

## 🛠️ Practice 2: 6502 ALU Implementation

```systemverilog
module cpu_alu (
    input  logic [7:0]  operand_a,
    input  logic [7:0]  operand_b,
    input  logic [3:0]  operation,
    input  logic        carry_in,

    output logic [7:0]  result,
    output logic        carry_out,
    output logic        overflow,
    output logic        negative,
    output logic        zero
);

    logic [8:0] temp_result;

    always_comb begin
        // Default values
        temp_result = 9'b000000000;
        overflow = 1'b0;

        case (operation)
            4'b0000: begin // ADD
                temp_result = {1'b0, operand_a} + {1'b0, operand_b} + {8'b0, carry_in};
                // Overflow detection (signed arithmetic)
                overflow = (operand_a[7] == operand_b[7]) &&
                          (operand_a[7] != temp_result[7]);
            end

            4'b0001: begin // SUB
                temp_result = {1'b0, operand_a} - {1'b0, operand_b} - {8'b0, ~carry_in};
                // Subtraction overflow
                overflow = (operand_a[7] != operand_b[7]) &&
                          (operand_a[7] != temp_result[7]);
            end

            4'b0010: begin // AND
                temp_result = {1'b0, operand_a & operand_b};
            end

            4'b0011: begin // OR
                temp_result = {1'b0, operand_a | operand_b};
            end

            4'b0100: begin // XOR
                temp_result = {1'b0, operand_a ^ operand_b};
            end

            4'b0101: begin // ASL (Arithmetic Shift Left)
                temp_result = {operand_a, 1'b0};
            end

            4'b0110: begin // LSR (Logical Shift Right)
                temp_result = {operand_a[0], 1'b0, operand_a[7:1]};
            end

            4'b0111: begin // ROL (Rotate Left)
                temp_result = {operand_a, carry_in};
            end

            4'b1000: begin // ROR (Rotate Right)
                temp_result = {operand_a[0], carry_in, operand_a[7:1]};
            end

            4'b1001: begin // INC
                temp_result = {1'b0, operand_a} + 9'b000000001;
            end

            4'b1010: begin // DEC
                temp_result = {1'b0, operand_a} - 9'b000000001;
            end

            4'b1011: begin // PASS A
                temp_result = {1'b0, operand_a};
            end

            4'b1100: begin // PASS B
                temp_result = {1'b0, operand_b};
            end

            default: begin
                temp_result = {1'b0, operand_a};
            end
        endcase

        // Generate result and flags
        result = temp_result[7:0];
        carry_out = temp_result[8];
        negative = temp_result[7];
        zero = (temp_result[7:0] == 8'h00);
    end

endmodule
```

## 🛠️ Practice 3: Flag Register Management

```systemverilog
module status_register (
    input  logic clk,
    input  logic rst_n,

    // Flag update control
    input  logic update_n,
    input  logic update_z,
    input  logic update_c,
    input  logic update_v,

    // New flag values
    input  logic new_n,
    input  logic new_z,
    input  logic new_c,
    input  logic new_v,

    // Special flag control
    input  logic set_i,     // Set interrupt disable
    input  logic clear_i,   // Clear interrupt disable
    input  logic set_d,     // Set decimal mode
    input  logic clear_d,   // Clear decimal mode

    // Status register
    output logic [7:0] status_reg
);

    // Flag bit definitions
    // Bit 7: N (Negative)
    // Bit 6: V (Overflow)
    // Bit 5: - (Unused, always 1)
    // Bit 4: B (Break)
    // Bit 3: D (Decimal)
    // Bit 2: I (Interrupt)
    // Bit 1: Z (Zero)
    // Bit 0: C (Carry)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 8'b00100100;  // I=1, unused=1
        end else begin
            // Conditional flag updates
            if (update_n) status_reg[7] <= new_n;
            if (update_v) status_reg[6] <= new_v;
            // Bit 5 is always 1
            status_reg[5] <= 1'b1;
            // Break flag is controlled by instruction
            if (update_z) status_reg[1] <= new_z;
            if (update_c) status_reg[0] <= new_c;

            // Special control
            if (set_i)    status_reg[2] <= 1'b1;
            if (clear_i)  status_reg[2] <= 1'b0;
            if (set_d)    status_reg[3] <= 1'b1;
            if (clear_d)  status_reg[3] <= 1'b0;
        end
    end

endmodule
```

## 📝 Assignments

### Basic Assignments
1.  Implement the remaining arithmetic/logical instructions
2.  Implement all shift/rotate instructions
3.  Implement the compare instructions (CMP, CPX, CPY)

### Advanced Assignments
1.  Implement BCD (Binary Coded Decimal) arithmetic
2.  Define the behavior of unimplemented instructions
3.  Optimize the instruction execution cycle

## 📚 What I Learned Today

- [ ] Design of a hierarchical instruction decoder
- [ ] Complete implementation of the ALU
- [ ] Flag generation logic
- [ ] Systematic design of control signals

## 🎯 Preview for Tomorrow

In Day 07, we will implement the memory interface and stack control:
- Memory bus design
- Implementation of stack operations
- Address generation unit