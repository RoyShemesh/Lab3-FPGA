onerror {resume}
add list -width 13 /tb_top/clk
add list /tb_top/rst
add list /tb_top/ena
add list /tb_top/TBactive
add list /tb_top/ITCM_tb_wr
add list /tb_top/ITCM_tb_in
add list /tb_top/ITCM_tb_addr_in
add list /tb_top/DTCM_tb_wr
add list /tb_top/DTCM_tb_in
add list /tb_top/DTCM_tb_addr_in
add list /tb_top/DTCM_tb_addr_out
add list /tb_top/DTCM_tb_out
add list /tb_top/done
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta collapse
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
