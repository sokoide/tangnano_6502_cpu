# SystemVerilog Cheatsheet for Software Engineers

This guide summarizes the essential SystemVerilog syntax and concepts needed for this course, tailored for those with a software background.

---

🌐 Available languages:
[English](./SYSTEMVERILOG_CHEATSHEET.md) | [日本語](./SYSTEMVERILOG_CHEATSHEET_ja.md)

## 1. Data Types: Just use `logic`

In older Verilog, you had to choose between `wire` and `reg`. In SystemVerilog, you can use **`logic`** for almost everything.

| Type | Description | Usage Rule |
| :--- | :--- | :--- |
| **`logic`** | **The modern standard.** Can be a wire or a register depending on context. | **Use this by default.** |
| `wire` | A physical wire. Can have multiple drivers (e.g., I2C bus). | Only used for tri-state buffers (rare in this course). |
| `reg` | Older Verilog type for storage. | Legacy. Use `logic` instead. |

**Example:**

```systemverilog
logic [7:0] data;  // 8-bit signal (0 to 255)
logic       flag;  // 1-bit signal (0 or 1)
```

## 2. Assignments: `=` vs `<=`

This is the most confusing part for software engineers. The assignment operator depends on the **type of circuit** you are describing.

| Circuit Type | Block | Operator | Meaning | Analogy |
| :--- | :--- | :---: | :--- | :--- |
| **Combinational** | `always_comb` | **`=`** | **Blocking Assignment**<br>Updates immediately, order matters. | Normal variable assignment in C/Python. |
| **Sequential** | `always_ff` | **`<=`** | **Non-Blocking Assignment**<br>Scheduled to update at the *end* of the clock cycle. All happen in parallel. | "Snapshot" update. `a <= b` and `b <= a` swaps values. |

### ✅ Combinational Logic (Logic Gates) -> Use `=`

```systemverilog
// Describes: y = a AND b
always_comb begin
    y = a & b; 
end
```

### ✅ Sequential Logic (Registers/Flip-Flops) -> Use `<=`

```systemverilog
// Describes: On clock tick, copy d to q
always_ff @(posedge clk) begin
    q <= d;
end
```

> **⚠️ CRITICAL RULE:**
> NEVER mix `=` and `<=` in the same block.

## 3. Circuit Blocks

### `assign` (Continuous Assignment)

Used for simple connections. Think of it as soldering a wire permanently.

```systemverilog
assign led = switch & enable; // LED is ON when both switch AND enable are 1
```

### `always_comb` (Combinational Block)

Used for complex logic (if-else, case). Describes a circuit with **no memory**. Output depends *only* on current inputs.

```systemverilog
always_comb begin
    if (enable)
        result = a + b;
    else
        result = 0;
end
```

### `always_ff @(posedge clk)` (Sequential Block)

Used for registers, counters, state machines. Describes a circuit **with memory**. Updates only on the rising edge of the clock.

```systemverilog
always_ff @(posedge clk) begin
    if (reset)
        count <= 0;
    else
        count <= count + 1;
end
```

## 4. Common Pitfalls

### ❌ The "Inferring Latch" Trap

In software, `if (x) y = 1;` implies "if not x, keep y as is".
In hardware combinational logic, "keep as is" requires memory (a latch), which is usually unintended and causes timing bugs.

**Rule:** In `always_comb`, you must assign a value in **all possible branches**.

**Bad:**

```systemverilog
always_comb begin
    if (valid) data = input_val; 
    // Implicit "else keep data" -> LATCH GENERATED!
end
```

**Good (Default value strategy):**

```systemverilog
always_comb begin
    data = 0; // Default value
    if (valid) data = input_val; 
end
```

**Good (Full if-else):**

```systemverilog
always_comb begin
    if (valid)
        data = input_val;
    else
        data = 0;
end
```

### ❌ Multiple Drivers

You cannot assign to the same signal from two different `always` blocks or `assign` statements. This is like connecting two output pins together—it causes a short circuit.

**Bad:**

```systemverilog
assign led = a;
assign led = b; // Error: led has multiple drivers
```

**Solution:** Use a multiplexer (selector) logic.

```systemverilog
assign led = select ? a : b;
```
