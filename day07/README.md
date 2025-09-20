# Day 07: CPU Implementation Part 2 - Memory Interface

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

-   Design and implement a memory bus interface
-   Detailed implementation of stack operations
-   Implementation of an address generation unit
-   Basic understanding of memory-mapped I/O

## 📚 Theory

### Types of Memory Access

**Instruction Fetch:**

-   Reading an instruction from the PC
-   Variable length of 1-3 bytes

**Data Access:**

-   Reading/writing data with Load/Store instructions
-   Depends on the addressing mode

**Stack Access:**

-   PUSH/POP operations
-   Saving/restoring addresses with JSR/RTS

**Indirect Addressing:**

-   JMP ($nnnn)
-   (zp,X) / (zp),Y addressing

### Stack Operation

**Features of the 6502 Stack:**

-   Fixed area: $0100-$01FF
-   Downward: From high addresses to low addresses
-   8-bit stack pointer: $FF -> $00

## 🛠️ Practice 1: Memory Controller

```systemverilog
module memory_controller (
    input  logic clk,
    input  logic rst_n,

    // CPU-side interface
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  cpu_data_out,
    output logic [7:0]  cpu_data_in,
    input  logic        cpu_read,
    input  logic        cpu_write,
    output logic        cpu_ready,

    // External memory interface
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_read,
    output logic        mem_write,
    output logic        mem_enable,

    // Special area control
    output logic        vram_access,
    output logic        rom_access
);

    // Memory map determination
    always_comb begin
        vram_access = (cpu_addr >= 16'hE000) && (cpu_addr <= 16'hE3FF);
        rom_access  = (cpu_addr >= 16'hF000);

        // Normal memory access
        mem_addr = cpu_addr;
        mem_data_out = cpu_data_out;
        mem_read = cpu_read && !vram_access && !rom_access;
        mem_write = cpu_write && !vram_access && !rom_access;
        mem_enable = cpu_read || cpu_write;
    end

    // Return data to CPU
    always_comb begin
        if (rom_access) begin
            cpu_data_in = 8'h00;  // ROM data (implemented separately)
        end else if (vram_access) begin
            cpu_data_in = 8'h00;  // VRAM data (implemented separately)
        end else begin
            cpu_data_in = mem_data_in;
        end
    end

    // Simple ready control (in reality, wait cycles may be needed)
    assign cpu_ready = 1'b1;

endmodule
```

## 🛠️ Practice 2: Stack Control Unit

```systemverilog
module stack_controller (
    input  logic clk,
    input  logic rst_n,

    // Stack operation control
    input  logic stack_push,
    input  logic stack_pop,
    input  logic [7:0] push_data,
    output logic [7:0] pop_data,

    // Stack pointer
    input  logic sp_write,
    input  logic [7:0] sp_data_in,
    output logic [7:0] stack_pointer,

    // Memory interface
    output logic [15:0] stack_addr,
    output logic [7:0]  stack_data_out,
    input  logic [7:0]  stack_data_in,
    output logic        stack_read,
    output logic        stack_write
);

    logic [7:0] sp_reg;

    // Stack pointer management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sp_reg <= 8'hFF;  // Initial value is the top
        end else begin
            if (sp_write) begin
                sp_reg <= sp_data_in;
            end else if (stack_push) begin
                sp_reg <= sp_reg - 1;  // Decrement after push
            end else if (stack_pop) begin
                sp_reg <= sp_reg + 1;  // Increment before pop
            end
        end
    end

    assign stack_pointer = sp_reg;

    // Stack address generation
    always_comb begin
        if (stack_push) begin
            stack_addr = {8'h01, sp_reg};  // Push: current SP
            stack_data_out = push_data;
            stack_write = 1'b1;
            stack_read = 1'b0;
        end else if (stack_pop) begin
            stack_addr = {8'h01, sp_reg + 1};  // Pop: SP+1
            stack_data_out = 8'h00;
            stack_write = 1'b0;
            stack_read = 1'b1;
        end else begin
            stack_addr = {8'h01, sp_reg};
            stack_data_out = 8'h00;
            stack_write = 1'b0;
            stack_read = 1'b0;
        end
    end

    assign pop_data = stack_data_in;

endmodule
```

## 🛠️ Practice 3: Address Generation Unit

```systemverilog
module address_generator (
    input  logic [7:0]  opcode,
    input  logic [7:0]  operand1,
    input  logic [7:0]  operand2,
    input  logic [15:0] pc,
    input  logic [7:0]  reg_x,
    input  logic [7:0]  reg_y,

    // Memory read for indirect addressing
    input  logic [7:0]  indirect_data_low,
    input  logic [7:0]  indirect_data_high,

    output logic [15:0] effective_address,
    output logic [15:0] indirect_read_addr,
    output logic        need_indirect_read,
    output logic        page_crossed
);

    logic [15:0] base_addr;
    logic [15:0] indexed_addr;

    always_comb begin
        // Default values
        effective_address = 16'h0000;
        indirect_read_addr = 16'h0000;
        need_indirect_read = 1'b0;
        page_crossed = 1'b0;

        case (opcode)
            // Immediate - use the next byte directly
            8'hA9, 8'h69: begin
                effective_address = pc + 1;
            end

            // Zero Page
            8'hA5, 8'h85: begin
                effective_address = {8'h00, operand1};
            end

            // Zero Page,X
            8'hB5, 8'h95: begin
                effective_address = {8'h00, operand1 + reg_x};
            end

            // Absolute
            8'hAD, 8'h8D: begin
                effective_address = {operand2, operand1};
            end

            // Absolute,X
            8'hBD, 8'h9D: begin
                base_addr = {operand2, operand1};
                indexed_addr = base_addr + {8'h00, reg_x};
                effective_address = indexed_addr;
                // Page boundary crossing check
                page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
            end

            // Absolute,Y
            8'hB9, 8'h99: begin
                base_addr = {operand2, operand1};
                indexed_addr = base_addr + {8'h00, reg_y};
                effective_address = indexed_addr;
                page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
            end

            // (Zero Page,X) - Indexed Indirect
            8'hA1, 8'h81: begin
                indirect_read_addr = {8'h00, operand1 + reg_x};
                need_indirect_read = 1'b1;
                effective_address = {indirect_data_high, indirect_data_low};
            end

            // (Zero Page),Y - Indirect Indexed
            8'hB1, 8'h91: begin
                indirect_read_addr = {8'h00, operand1};
                need_indirect_read = 1'b1;
                base_addr = {indirect_data_high, indirect_data_low};
                indexed_addr = base_addr + {8'h00, reg_y};
                effective_address = indexed_addr;
                page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
            end

            // Indirect (JMP only)
            8'h6C: begin
                indirect_read_addr = {operand2, operand1};
                need_indirect_read = 1'b1;
                effective_address = {indirect_data_high, indirect_data_low};
            end

            default: begin
                effective_address = pc;
            end
        endcase
    end

endmodule
```

## 🛠️ Practice 4: JSR/RTS Implementation

```systemverilog
module subroutine_controller (
    input  logic clk,
    input  logic rst_n,

    input  logic jsr_execute,  // Execute JSR instruction
    input  logic rts_execute,  // Execute RTS instruction
    input  logic [15:0] jsr_target,
    input  logic [15:0] current_pc,

    // Stack control
    output logic stack_push,
    output logic stack_pop,
    output logic [7:0] push_data,
    input  logic [7:0] pop_data,

    // PC control
    output logic pc_write,
    output logic [15:0] new_pc,

    // State
    output logic operation_complete
);

    typedef enum logic [2:0] {
        IDLE,
        JSR_PUSH_HIGH,
        JSR_PUSH_LOW,
        JSR_JUMP,
        RTS_POP_LOW,
        RTS_POP_HIGH,
        RTS_JUMP
    } state_t;

    state_t current_state, next_state;
    logic [15:0] return_address;
    logic [15:0] target_address;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            return_address <= 16'h0000;
            target_address <= 16'h0000;
        end else begin
            current_state <= next_state;
            if (jsr_execute) begin
                return_address <= current_pc + 2;  // JSR is a 3-byte instruction
                target_address <= jsr_target;
            end
        end
    end

    always_comb begin
        next_state = current_state;
        stack_push = 1'b0;
        stack_pop = 1'b0;
        push_data = 8'h00;
        pc_write = 1'b0;
        new_pc = 16'h0000;
        operation_complete = 1'b0;

        case (current_state)
            IDLE: begin
                if (jsr_execute) begin
                    next_state = JSR_PUSH_HIGH;
                end else if (rts_execute) begin
                    next_state = RTS_POP_LOW;
                end
                operation_complete = 1'b1;
            end

            JSR_PUSH_HIGH: begin
                stack_push = 1'b1;
                push_data = return_address[15:8];  // Upper byte
                next_state = JSR_PUSH_LOW;
            end

            JSR_PUSH_LOW: begin
                stack_push = 1'b1;
                push_data = return_address[7:0];   // Lower byte
                next_state = JSR_JUMP;
            end

            JSR_JUMP: begin
                pc_write = 1'b1;
                new_pc = target_address;
                next_state = IDLE;
            end

            RTS_POP_LOW: begin
                stack_pop = 1'b1;
                next_state = RTS_POP_HIGH;
                return_address[7:0] <= pop_data;
            end

            RTS_POP_HIGH: begin
                stack_pop = 1'b1;
                next_state = RTS_JUMP;
                return_address[15:8] <= pop_data;
            end

            RTS_JUMP: begin
                pc_write = 1'b1;
                new_pc = return_address + 1;  // RTS is return address + 1
                next_state = IDLE;
            end
        endcase
    end

endmodule
```

## 📝 Assignments

### Basic Assignments

1.  Implement PHA/PLA (push/pop register to/from stack)
2.  Reproduce the page boundary bug in indirect addressing
3.  Implement memory access wait cycles

### Advanced Assignments

1.  Coordinated operation with a DMA controller
2.  Implement memory protection features
3.  Basic design of a cache memory

## 📚 What I Learned Today

-   [ ] Memory bus interface design
-   [ ] Detailed implementation of stack operations
-   [ ] The complexity of address generation
-   [ ] State machine implementation of JSR/RTS
-   [ ] Basics of memory-mapped I/O

## 🎯 Preview for Tomorrow

In Day 08, we will integrate and test the CPU core:

-   Combining the various modules
-   Instruction execution cycle control
-   Verifying operation with a basic program
