module test_hex;
    function automatic [7:0] to_hex(input [3:0] val);
        case (val)
            4'h0: to_hex = "0";
            4'h1: to_hex = "1";
            4'h2: to_hex = "2";
            4'h3: to_hex = "3";
            4'h4: to_hex = "4";
            4'h5: to_hex = "5";
            4'h6: to_hex = "6";
            4'h7: to_hex = "7";
            4'h8: to_hex = "8";
            4'h9: to_hex = "9";
            4'hA: to_hex = "A";
            4'hB: to_hex = "B";
            4'hC: to_hex = "C";
            4'hD: to_hex = "D";
            4'hE: to_hex = "E";
            4'hF: to_hex = "F";
            default: to_hex = "?";
        endcase
    endfunction

    initial begin
        for (int i = 0; i < 16; i++) begin
            $display("Input: %h, Output: %c (ASCII: %h)", i[3:0], to_hex(i[3:0]), to_hex(i[3:0]));
        end
        $finish;
    end
endmodule
