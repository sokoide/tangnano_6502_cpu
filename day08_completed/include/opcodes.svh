// opcodes.svh
`ifndef OPCODES_SVH
`define OPCODES_SVH

localparam logic [7:0] OP_LDA_IMM = 8'hA9; localparam logic [7:0] OP_LDX_IMM = 8'hA2; localparam logic [7:0] OP_LDY_IMM = 8'hA0;
localparam logic [7:0] OP_TAX     = 8'hAA;
localparam logic [7:0] OP_TAY     = 8'hA8;
localparam logic [7:0] OP_TXA     = 8'h8A;
localparam logic [7:0] OP_TYA     = 8'h98;
localparam logic [7:0] OP_INX     = 8'hE8;
localparam logic [7:0] OP_INY     = 8'hC8;
localparam logic [7:0] OP_ADC_IMM = 8'h69;
localparam logic [7:0] OP_SBC_IMM = 8'hE9;
localparam logic [7:0] OP_CLC     = 8'h18;
localparam logic [7:0] OP_SEC     = 8'h38;
localparam logic [7:0] OP_NOP     = 8'hEA;

`endif
