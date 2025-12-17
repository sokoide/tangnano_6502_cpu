module font_rom (
    input logic clk,
    input logic [11:0] addr,
    output logic [7:0] data
);

    logic [7:0] next_data;
    logic [7:0] data_reg;
    assign data = data_reg;

    always_comb begin
        logic [3:0] row = addr[3:0];
        unique case (addr[11:4])
            8'h41: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h18;
                    4'd2: next_data = 8'h24;
                    4'd3: next_data = 8'h24;
                    4'd4: next_data = 8'h42;
                    4'd5: next_data = 8'h42;
                    4'd6: next_data = 8'h7E;
                    4'd7: next_data = 8'h42;
                    4'd8: next_data = 8'h42;
                    4'd9: next_data = 8'h42;
                    4'd10: next_data = 8'h42;
                    4'd11: next_data = 8'h42;
                    4'd12: next_data = 8'h42;
                    4'd13: next_data = 8'h42;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h43: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h1E;
                    4'd2: next_data = 8'h21;
                    4'd3: next_data = 8'h40;
                    4'd4: next_data = 8'h40;
                    4'd5: next_data = 8'h40;
                    4'd6: next_data = 8'h40;
                    4'd7: next_data = 8'h40;
                    4'd8: next_data = 8'h40;
                    4'd9: next_data = 8'h40;
                    4'd10: next_data = 8'h21;
                    4'd11: next_data = 8'h1E;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h44: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h7E;
                    4'd2: next_data = 8'h42;
                    4'd3: next_data = 8'h41;
                    4'd4: next_data = 8'h41;
                    4'd5: next_data = 8'h41;
                    4'd6: next_data = 8'h41;
                    4'd7: next_data = 8'h41;
                    4'd8: next_data = 8'h41;
                    4'd9: next_data = 8'h41;
                    4'd10: next_data = 8'h42;
                    4'd11: next_data = 8'h7E;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h45: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h7F;
                    4'd2: next_data = 8'h40;
                    4'd3: next_data = 8'h40;
                    4'd4: next_data = 8'h40;
                    4'd5: next_data = 8'h7C;
                    4'd6: next_data = 8'h40;
                    4'd7: next_data = 8'h40;
                    4'd8: next_data = 8'h40;
                    4'd9: next_data = 8'h40;
                    4'd10: next_data = 8'h40;
                    4'd11: next_data = 8'h7F;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h46: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h7F;
                    4'd2: next_data = 8'h40;
                    4'd3: next_data = 8'h40;
                    4'd4: next_data = 8'h40;
                    4'd5: next_data = 8'h7C;
                    4'd6: next_data = 8'h40;
                    4'd7: next_data = 8'h40;
                    4'd8: next_data = 8'h40;
                    4'd9: next_data = 8'h40;
                    4'd10: next_data = 8'h40;
                    4'd11: next_data = 8'h40;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h47: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h3E;
                    4'd2: next_data = 8'h41;
                    4'd3: next_data = 8'h80;
                    4'd4: next_data = 8'h80;
                    4'd5: next_data = 8'h80;
                    4'd6: next_data = 8'h9E;
                    4'd7: next_data = 8'h82;
                    4'd8: next_data = 8'h82;
                    4'd9: next_data = 8'h82;
                    4'd10: next_data = 8'h42;
                    4'd11: next_data = 8'h3C;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h48: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h42;
                    4'd2: next_data = 8'h42;
                    4'd3: next_data = 8'h42;
                    4'd4: next_data = 8'h42;
                    4'd5: next_data = 8'h7E;
                    4'd6: next_data = 8'h42;
                    4'd7: next_data = 8'h42;
                    4'd8: next_data = 8'h42;
                    4'd9: next_data = 8'h42;
                    4'd10: next_data = 8'h42;
                    4'd11: next_data = 8'h42;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h4C: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h40;
                    4'd2: next_data = 8'h40;
                    4'd3: next_data = 8'h40;
                    4'd4: next_data = 8'h40;
                    4'd5: next_data = 8'h40;
                    4'd6: next_data = 8'h40;
                    4'd7: next_data = 8'h40;
                    4'd8: next_data = 8'h40;
                    4'd9: next_data = 8'h40;
                    4'd10: next_data = 8'h40;
                    4'd11: next_data = 8'h7F;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h4D: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h42;
                    4'd2: next_data = 8'h66;
                    4'd3: next_data = 8'h66;
                    4'd4: next_data = 8'h54;
                    4'd5: next_data = 8'h54;
                    4'd6: next_data = 8'h48;
                    4'd7: next_data = 8'h48;
                    4'd8: next_data = 8'h48;
                    4'd9: next_data = 8'h48;
                    4'd10: next_data = 8'h48;
                    4'd11: next_data = 8'h48;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h4F: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h3E;
                    4'd2: next_data = 8'h41;
                    4'd3: next_data = 8'h41;
                    4'd4: next_data = 8'h41;
                    4'd5: next_data = 8'h41;
                    4'd6: next_data = 8'h41;
                    4'd7: next_data = 8'h41;
                    4'd8: next_data = 8'h41;
                    4'd9: next_data = 8'h41;
                    4'd10: next_data = 8'h41;
                    4'd11: next_data = 8'h3E;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h50: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h7E;
                    4'd2: next_data = 8'h42;
                    4'd3: next_data = 8'h42;
                    4'd4: next_data = 8'h42;
                    4'd5: next_data = 8'h7E;
                    4'd6: next_data = 8'h40;
                    4'd7: next_data = 8'h40;
                    4'd8: next_data = 8'h40;
                    4'd9: next_data = 8'h40;
                    4'd10: next_data = 8'h40;
                    4'd11: next_data = 8'h40;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h52: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h7E;
                    4'd2: next_data = 8'h42;
                    4'd3: next_data = 8'h42;
                    4'd4: next_data = 8'h42;
                    4'd5: next_data = 8'h7E;
                    4'd6: next_data = 8'h48;
                    4'd7: next_data = 8'h44;
                    4'd8: next_data = 8'h44;
                    4'd9: next_data = 8'h42;
                    4'd10: next_data = 8'h41;
                    4'd11: next_data = 8'h40;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h53: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h3E;
                    4'd2: next_data = 8'h41;
                    4'd3: next_data = 8'h40;
                    4'd4: next_data = 8'h40;
                    4'd5: next_data = 8'h3E;
                    4'd6: next_data = 8'h02;
                    4'd7: next_data = 8'h02;
                    4'd8: next_data = 8'h02;
                    4'd9: next_data = 8'h41;
                    4'd10: next_data = 8'h41;
                    4'd11: next_data = 8'h3E;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h54: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h7F;
                    4'd2: next_data = 8'h10;
                    4'd3: next_data = 8'h10;
                    4'd4: next_data = 8'h10;
                    4'd5: next_data = 8'h10;
                    4'd6: next_data = 8'h10;
                    4'd7: next_data = 8'h10;
                    4'd8: next_data = 8'h10;
                    4'd9: next_data = 8'h10;
                    4'd10: next_data = 8'h10;
                    4'd11: next_data = 8'h10;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h56: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h42;
                    4'd2: next_data = 8'h42;
                    4'd3: next_data = 8'h42;
                    4'd4: next_data = 8'h42;
                    4'd5: next_data = 8'h42;
                    4'd6: next_data = 8'h42;
                    4'd7: next_data = 8'h42;
                    4'd8: next_data = 8'h42;
                    4'd9: next_data = 8'h42;
                    4'd10: next_data = 8'h42;
                    4'd11: next_data = 8'h24;
                    4'd12: next_data = 8'h18;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h57: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h42;
                    4'd2: next_data = 8'h42;
                    4'd3: next_data = 8'h42;
                    4'd4: next_data = 8'h42;
                    4'd5: next_data = 8'h42;
                    4'd6: next_data = 8'h4A;
                    4'd7: next_data = 8'h4A;
                    4'd8: next_data = 8'h5A;
                    4'd9: next_data = 8'h5A;
                    4'd10: next_data = 8'h5A;
                    4'd11: next_data = 8'h42;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            8'h58: begin
                unique case (row)
                    4'd0: next_data = 8'h00;
                    4'd1: next_data = 8'h42;
                    4'd2: next_data = 8'h42;
                    4'd3: next_data = 8'h24;
                    4'd4: next_data = 8'h24;
                    4'd5: next_data = 8'h18;
                    4'd6: next_data = 8'h18;
                    4'd7: next_data = 8'h24;
                    4'd8: next_data = 8'h24;
                    4'd9: next_data = 8'h42;
                    4'd10: next_data = 8'h42;
                    4'd11: next_data = 8'h42;
                    4'd12: next_data = 8'h00;
                    4'd13: next_data = 8'h00;
                    4'd14: next_data = 8'h00;
                    4'd15: next_data = 8'h00;
                    default: next_data = 8'h00;
                endcase
            end
            default: next_data = 8'h00;
        endcase
    end

    always_ff @(posedge clk) begin
        data_reg <= next_data;
    end

endmodule
