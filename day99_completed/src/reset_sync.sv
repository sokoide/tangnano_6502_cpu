// Assert asynchronously, release after two local clock edges.
module reset_sync (
    input  logic clk,
    ready_n,
    output wire  rst_n
);
    (* ASYNC_REG = "TRUE" *) logic [1:0] release_ff;
    always_ff @(posedge clk or negedge ready_n) begin
        if (!ready_n) release_ff <= 2'b00;
        else release_ff <= {release_ff[0], 1'b1};
    end
    assign rst_n = release_ff[1];
endmodule
