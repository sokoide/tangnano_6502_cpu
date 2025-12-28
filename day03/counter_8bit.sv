// 8bit Counter
// 8ビット アップカウンタ

// 8-bit Up Counter with Enable and Synchronous Reset

module counter_8bit (

    input  logic clk,

    input  logic rst_n,    // Active Low Reset

    input  logic enable,   // Increment only when enable is high

    output logic [7:0] count,

    output logic overflow  // Set to 1 when count rolls over from FF to 00

);



    // Sequential block using always_ff

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            // Reset state

            count <= 8'b0;

        end else if (enable) begin

            // Non-blocking assignment (<=) is mandatory here

            count <= count + 1;

        end

    end



    // Combinational logic for overflow flag

    assign overflow = (count == 8'hFF) && enable;



endmodule


