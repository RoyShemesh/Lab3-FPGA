onerror {resume}
add list -width 17 /tb_control/clk
add list /tb_control/rst
add list /tb_control/ena
add list /tb_control/add
add list /tb_control/sub
add list /tb_control/andop
add list /tb_control/orop
add list /tb_control/xorop
add list /tb_control/jmp
add list /tb_control/jc
add list /tb_control/jnc
add list /tb_control/mov
add list /tb_control/ld
add list /tb_control/st
add list /tb_control/done
add list /tb_control/Zflag
add list /tb_control/Nflag
add list /tb_control/Cflag
add list /tb_control/IRin
add list /tb_control/RFout
add list /tb_control/RFin
add list /tb_control/Ain
add list /tb_control/Cin
add list /tb_control/Cout
add list /tb_control/ALUFN
add list /tb_control/RFaddr_wr_sel
add list /tb_control/RFaddr_rd_sel
add list /tb_control/Imm1_in
add list /tb_control/Imm2_in
add list /tb_control/PCin
add list /tb_control/PCsel
add list /tb_control/DTCM_out
add list /tb_control/DTCM_addr_in
add list /tb_control/DTCM_wr
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta collapse
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
