task automatic state_machine_step();
    begin : STATE_MACHINE_STEP
        /* verilator lint_off BLKSEQ */
        /* verilator lint_off CASEOVERLAP */
        case (state)
            INIT: state_boot_init();
            INIT_VRAM: state_boot_init_vram();
            INIT_RAM: state_boot_init_ram();
            HALT: state_boot_halt();

            FETCH_REQ: state_fetch_req();
            FETCH_WAIT: state_fetch_wait();
            FETCH_RECV: state_fetch_recv();
            FETCH_OPERAND1: state_fetch_operand1();
            FETCH_OPERAND1OF2: state_fetch_operand1of2();
            FETCH_OPERAND2: state_fetch_operand2();

            DECODE_EXECUTE: state_decode_execute();

            WRITE_REQ: state_write_req_handler();

            SHOW_INFO:  state_show_info_init();
            SHOW_INFO2: state_show_info_step();

            CLEAR_VRAM:  state_clear_vram_init();
            CLEAR_VRAM2: state_clear_vram_loop();

            default: begin
                // Intentional no-op
            end
        endcase
        /* verilator lint_on CASEOVERLAP */
        /* verilator lint_on BLKSEQ */
    end
endtask
