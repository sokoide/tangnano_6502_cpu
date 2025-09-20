# Day 03: SystemVerilog Basics (Sequential Circuits)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

-   Understand the concept of clock-synchronous circuits
-   Learn the difference between flip-flops and latches
-   Master register design using `always_ff`
-   Understand the basics of Finite State Machines (FSM)

## 📚 Theory

### Basics of Clock-Synchronous Circuits

**Clock Edges:**

```systemverilog
always_ff @(posedge clk) begin
    // Execute on the rising edge
end

always_ff @(negedge clk) begin
    // Execute on the falling edge
end
```

**Register with Reset:**

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter <= 8'b0;
    else
        counter <= counter + 1;
end
```

### Basics of Finite State Machines (FSM)

**State Definition:**

```systemverilog
typedef enum logic [1:0] {
    IDLE  = 2'b00,
    START = 2'b01,
    WORK  = 2'b10,
    DONE  = 2'b11
} state_t;

state_t current_state, next_state;
```

## 🛠️ Practice 1: Counter Circuit

### 8-bit Up Counter

```systemverilog
module counter_8bit (
    input  logic clk,
    input  logic rst_n,
    input  logic enable,
    output logic [7:0] count,
    output logic overflow
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'b0;
        end else if (enable) begin
            count <= count + 1;
        end
    end

    assign overflow = (count == 8'hFF) && enable;

endmodule
```

## 🛠️ Practice 2: PWM Generator

### Specifications

-   8-bit duty cycle control
-   Supports variable frequency

```systemverilog
module pwm_generator (
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] duty_cycle,  // 0-255
    output logic pwm_out
);

    logic [7:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'b0;
        end else begin
            counter <= counter + 1;
        end
    end

    assign pwm_out = (counter < duty_cycle);

endmodule
```

## 🛠️ Practice 3: Traffic Light Controller

### Signal Control with a State Machine

```systemverilog
module traffic_light (
    input  logic clk,
    input  logic rst_n,
    output logic red,
    output logic yellow,
    output logic green
);

    typedef enum logic [1:0] {
        RED_STATE    = 2'b00,
        GREEN_STATE  = 2'b01,
        YELLOW_STATE = 2'b10
    } state_t;

    state_t current_state, next_state;
    logic [25:0] timer;

    // State transition logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RED_STATE;
            timer <= 26'b0;
        end else begin
            current_state <= next_state;
            timer <= timer + 1;
        end
    end

    // Next state decision logic
    always_comb begin
        case (current_state)
            RED_STATE: begin
                if (timer >= 26'd50_000_000)  // Approx. 2 seconds
                    next_state = GREEN_STATE;
                else
                    next_state = RED_STATE;
            end
            // TODO: Implement other states
            default: next_state = RED_STATE;
        endcase
    end

    // Output logic
    assign red    = (current_state == RED_STATE);
    assign green  = (current_state == GREEN_STATE);
    assign yellow = (current_state == YELLOW_STATE);

endmodule
```

## 📝 Assignments

### Basic Assignments

1.  Implement an up/down counter
2.  Control LED brightness with PWM
3.  Complete the traffic light controller

### Advanced Assignments

1.  State machine for a UART transmitter
2.  Variable-length shift register
3.  Implement a clock divider

## 📚 What I Learned Today

-   [ ] Basics of clock-synchronous circuits
-   [ ] How to use `always_ff`
-   [ ] State machine design methods
-   [ ] Implementation of timers and counters

## 🎯 Preview for Tomorrow

In Day 04, we will learn about the 6502 CPU architecture:

-   Basic components of a CPU
-   Relationship between registers and memory
-   Instruction execution cycle
