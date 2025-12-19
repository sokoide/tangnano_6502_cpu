# Day 02: SystemVerilog Basics (Combinational Circuits)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

- Understand the basic syntax of SystemVerilog
- Learn how to design combinational circuits
- Learn the difference between `assign` and `always_comb`
- Understand the basics of testbenches

## 📚 Theory

### For Software Engineers: Combinational Logic is like a Pure Function

Think of the combinational circuits you are building today as **pure functions** in software. Their outputs depend _only_ on their current inputs, with no side effects or memory of past states. `assign` and `always_comb` are the tools you use to describe these "instantaneous" calculations.

### Combinational vs. Sequential (what you’re building today)

In Day 01 you used a **counter**, which is a _sequential_ circuit (it updates on a clock edge and “remembers” state).

Day 02 focuses on **combinational circuits**:

- Output is determined only by the current inputs (no memory).
- In RTL, you describe them with `assign` or `always_comb`.

```mermaid
flowchart LR
  IN[inputs] --> LOGIC[combinational logic] --> OUT[outputs]
```

### SystemVerilog Basic Syntax

**Data Types:**

````systemverilog
logic [7:0] data_bus;   // 8-bit wire, a net for connections
logic [3:0] counter;     // 4-bit variable, can be a register or a wire
logic select;          // 1-bit variable
logic [15:0] address;  // 16-bit variable
````

**Operators:**

```systemverilog
// Logical Operations
a & b    // AND
a | b    // OR
a ^ b    // XOR
~a       // NOT

// Comparison Operations
a == b   // Equal
a != b   // Not equal
a > b    // Greater than

// Bitwise Operations
data[7:4]  // Upper 4 bits
data[0]    // Least significant bit
{a, b}     // Concatenation
```

### How to Describe Combinational Circuits

**Method 1: `assign` statement**

```systemverilog
assign output = input1 & input2;
assign sum = a + b;
```

**Method 2: `always_comb` statement**

```systemverilog
always_comb begin
    if (select)
        output = input1;
    else
        output = input2;
end
```

#### `assign` vs `always_comb`

- `assign` is great for simple expressions (a wire driven by one expression).
- `always_comb` is great when you need `if`/`case` or multiple intermediate values.

```mermaid
flowchart LR
  A[input signals] --> B{assign / always_comb} --> C[output signals]
```

#### Blocking assignment `=` and “why default matters”

Inside `always_comb` you usually use **blocking** assignment `=`. The key rule is:

- Assign _every output_ in _every path_.

If you forget to assign an output in some branch, simulation may infer a “memory” (a latch), which is not what you want for Day 02.

#### Software Engineer Pitfall: The "Implicit Else"

In C/Python, `if (condition) x = 1;` implies "if condition is false, keep x as it is".
In hardware combinational logic, "keep as it is" requires **memory** (a latch).
Since we are building circuits _without_ memory today, you **must** specify what happens in the `else` case (e.g., `else x = 0;`).

## 🏗️ Architecture

A combinational circuit is like a set of pipes; what goes in immediately determines what comes out.

```mermaid
graph LR
    A[Input A] --> ALU
    B[Input B] --> ALU
    OP[Opcode] --> ALU
    ALU --> Result[Result]
    ALU --> Flags[Zero/Carry Flags]
```

## 🛠️ Implementation Steps

1. **4-bit ALU**:
    - Implement the main operations using a `case` statement inside an `always_comb` block.
    - Ensure all outputs are defined to avoid "inferred latches" (accidental memory).
2. **Simulation & Verification**:
    - Write a testbench (`tb_alu_4bit.sv`) to feed values into your ALU.
    - Use `make test` to run the simulation and check for errors.
3. **Hardware Display**:
    - Integrate your ALU into the board and see the results on external LEDs or 7-segment displays.

## 💡 Pure Functions in Hardware

A combinational circuit is basically a **pure function**. Given the same inputs, it will always produce the same outputs immediately. Always remember to provide a `default` case in your logic to ensure your circuit doesn't try to "remember" previous states.

### `wire` vs `logic` (A Simple Rule for Beginners)

You learned about this in Day 01, but here's a recap for the context of combinational logic:

- `logic`: The modern SystemVerilog data type. **For this course, you should use `logic` for almost everything.** It can be used as a simple "variable". The tools are smart enough to figure out if it should become a wire or a register based on how you use it.
  - If you assign to it in an `always_comb` or `always_ff` block, it acts like a variable (a "register").
  - If you assign to it with `assign`, it acts like a `wire`.
- `wire`: Represents a physical wire. It cannot store a value and must be continuously driven by something, for example with an `assign` statement. You'll see it used for module inputs and outputs, which is a common convention.

## 🛠️ Practice: 4-bit ALU

### Specifications

- Two 4-bit inputs (A, B)
- 2-bit operation selection (OP)
- 4-bit output + flags (Zero, Carry)

```mermaid
flowchart LR
  A["a[3:0]"] --> ALU[ALU core]
  B["b[3:0]"] --> ALU
  OP["op[1:0]"] --> ALU
  ALU --> R["result[3:0]"]
  ALU --> Z[zero]
  ALU --> C[carry]
```

### Operations

- 00: A + B (Addition)
- 01: A - B (Subtraction)
- 10: A & B (AND)
- 11: A | B (OR)

### Implementation Template

```systemverilog
module alu_4bit (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [1:0] op,
    output logic [3:0] result,
    output logic zero,
    output logic carry
);

    logic [4:0] temp_result;  // For carry calculation

    always_comb begin
        case (op)
            2'b00: begin  // Addition
                temp_result = a + b;
                result = temp_result[3:0];
                carry = temp_result[4];
            end
            // TODO: Implement other operations
            default: begin
                result = 4'b0000;
                carry = 1'b0;
            end
        endcase

        zero = (result == 4'b0000);
    end

endmodule
```

## 🧪 What is a Testbench? (Your First "Unit Test" in Hardware)

If you're a software engineer, think of a **testbench** as a **unit test for your hardware module**.

It's a separate SystemVerilog file that exists **only for simulation**. Its job is to "wrap around" your design, feed it inputs, and check if the outputs are correct. This code is **never synthesized** into an actual FPGA circuit.

A testbench typically does three things:

1. **Instantiate the DUT**: "DUT" stands for "Design Under Test". In your testbench, you create an instance of the module you want to test (e.g., `alu_4bit`).
2. **Provide Stimulus**: You drive the input ports of your DUT with various values to simulate different scenarios (e.g., `a = 5; b = 3;`). The `#10` is a **simulation-only delay** to give the circuit time to react to the new inputs.
3. **Check Results**: You use `assert` or `$display` to verify that the DUT's output ports produce the expected values. If an `assert` fails, the simulation stops and reports an error.

```systemverilog
// This is a testbench module, not for synthesis!
module tb_alu_4bit;

    // 1. Create signals to connect to the DUT
    logic [3:0] a, b;
    logic [1:0] op;
    logic [3:0] result;
    logic zero, carry;

    // 2. Instantiate the Design Under Test (DUT)
    //    Think of this as: alu_4bit uut = new alu_4bit();
    alu_4bit uut (
        .a(a), .b(b), .op(op),         // Provide inputs
        .result(result), .zero(zero), .carry(carry) // Observe outputs
    );

    // 3. Provide stimulus and check results
    initial begin
        // Test case 1: 5 + 3 = 8
        a = 4'd5;
        b = 4'd3;
        op = 2'b00;
        #10; // Wait for the combinational logic to settle

        // Check the result. If not correct, show an error.
        assert (result == 4'd8) else $error("Test failed: 5+3 != 8");

        // TODO: Add more test cases here...

        $display("All tests completed successfully!");
        $finish; // End the simulation
    end

endmodule
```

```mermaid
sequenceDiagram
  participant TB as Testbench
  participant UUT as ALU (Your Design)
  TB->>UUT: Set inputs a=5, b=3, op=0
  Note over TB,UUT: Wait for a short time (#10)
  UUT->>TB: Produces 'result' and 'flags'
  TB->>TB: Check if 'result' is 8
  TB->>TB: $finish (end simulation)
```

## 🔬 What is Verilator? (The Hardware "Transpiler")

So, how do you run a testbench? You can't just "execute" SystemVerilog. You need a **simulator**. **Verilator** is a popular, high-performance, open-source simulator.

Think of Verilator as a **transpiler**. It converts your SystemVerilog code into a C++ model that behaves exactly like your hardware design. This C++ code is then compiled into a normal executable program that you can run.

The `make test` command automates this entire flow for you:

```mermaid
flowchart LR
    subgraph Your Code
        A["alu_4bit.sv (Your Design)"]
        B["tb_alu_4bit.sv (Your Testbench)"]
    end

    subgraph "make test" Automation
        direction LR
        C(Verilator Tool)
        D{"C++ Compiler<br/>(like g++)"}
        E[Executable<br/>Sim-Program]
        F[Run Program]
    end

    subgraph Result
        G["'Test Passed!' or<br/>'Test Failed!'"]
    end

    A -- feeds --> C
    B -- feeds --> C
    C -- generates --> D
    D -- compiles --> E
    E -- is run by --> F
    F -- produces --> G
```

### How to Run Tests and Debug

1. **Run the Simulation:**

    ```bash
    make test
    ```

    This command will run the Verilator flow described above. You will see output from the `$display` and `assert` statements in your testbench.

2. **View Waveforms (Optional but Recommended):**
   Sometimes, just seeing "pass" or "fail" isn't enough. You need to see _how_ the signals are changing over time. A waveform is a graph of your circuit's signals.

    To generate a waveform, you need to add these two lines to your `initial begin` block in the testbench:

    ```systemverilog
    $dumpfile("tb_alu_4bit.vcd");
    $dumpvars(0, tb_alu_4bit);
    ```

    After running `make test`, a file named `tb_alu_4bit.vcd` will be created. You can open it with a waveform viewer like **GTKWave**.

    ```bash
    gtkwave tb_alu_4bit.vcd
    ```

    `a`, `b`, `carry`, `zero`, and `result` will be displayed as waveforms over time.
    ![Wave](../docs/day02_wave.png)

    This is incredibly useful for debugging why a value is not what you expect.

## 🔧 Debugging Tips

1. **Synthesis Error Countermeasures**

    - Check for missing semicolons
    - Check for matching `begin`-`end` pairs
    - Check for duplicate signal names

2. **Logic Error Countermeasures**
    - Compare with a truth table
    - Test step-by-step from simple cases
    - Verify operation using waveforms

## 📚 What I Learned Today

- [ ] Basic syntax of SystemVerilog
- [ ] How to design combinational circuits
- [ ] The difference between `assign` and `always_comb`
- [ ] Use of `case` and `if-else` statements
- [ ] Basic structure of a testbench

## 🎯 Preview for Tomorrow

In Day 03, we will learn about sequential circuits:

- Clock-synchronous circuits
- Flip-flops and latches
- Finite State Machines (FSM)
- Counters and timers

**Preparation task**: Review the basics of digital circuits (flip-flops, clocks, setup time).