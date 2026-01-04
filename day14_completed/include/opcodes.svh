/* verilator lint_off UNUSEDPARAM */
// opcodes.svh
`ifndef OPCODES_SVH
`define OPCODES_SVH

localparam logic [7:0] OP_LDA_IMM = 8'hA9;
localparam logic [7:0] OP_LDX_IMM = 8'hA2;
localparam logic [7:0] OP_LDY_IMM = 8'hA0;
localparam logic [7:0] OP_TAX = 8'hAA;
localparam logic [7:0] OP_TAY = 8'hA8;
localparam logic [7:0] OP_TXA = 8'h8A;
localparam logic [7:0] OP_TYA = 8'h98;
localparam logic [7:0] OP_INX = 8'hE8;
localparam logic [7:0] OP_INY = 8'hC8;
localparam logic [7:0] OP_ADC_IMM = 8'h69;
localparam logic [7:0] OP_SBC_IMM = 8'hE9;
localparam logic [7:0] OP_CLC = 8'h18;
localparam logic [7:0] OP_SEC = 8'h38;
localparam logic [7:0] OP_BNE = 8'hD0;
localparam logic [7:0] OP_BEQ = 8'hF0;
localparam logic [7:0] OP_BPL = 8'h10;
localparam logic [7:0] OP_BMI = 8'h30;
localparam logic [7:0] OP_JSR = 8'h20;
localparam logic [7:0] OP_RTS = 8'h60;
localparam logic [7:0] OP_PHA = 8'h48;
localparam logic [7:0] OP_PLA = 8'h68;
localparam logic [7:0] OP_PHP = 8'h08;
localparam logic [7:0] OP_PLP = 8'h28;
localparam logic [7:0] OP_LDA_ZP = 8'hA5;
localparam logic [7:0] OP_STA_ZP = 8'h85;
localparam logic [7:0] OP_LDX_ZP = 8'hA6;
localparam logic [7:0] OP_STX_ZP = 8'h86;
localparam logic [7:0] OP_LDY_ZP = 8'hA4;
localparam logic [7:0] OP_STY_ZP = 8'h84;
localparam logic [7:0] OP_LDA_ABS = 8'hAD;
localparam logic [7:0] OP_STA_ABS = 8'h8D;
localparam logic [7:0] OP_AND_IMM = 8'h29;
localparam logic [7:0] OP_ORA_IMM = 8'h09;
localparam logic [7:0] OP_EOR_IMM = 8'h49;
localparam logic [7:0] OP_BIT_ZP = 8'h24;
localparam logic [7:0] OP_ASL_A = 8'h0A;
localparam logic [7:0] OP_LSR_A = 8'h4A;
localparam logic [7:0] OP_ROL_A = 8'h2A;
localparam logic [7:0] OP_ROR_A = 8'h6A;
localparam logic [7:0] OP_JMP_ABS = 8'h4C;
localparam logic [7:0] OP_HLT = 8'hEF;
localparam logic [7:0] OP_NOP = 8'hEA;

`endif
