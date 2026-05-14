onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_datapath/clk
add wave -noupdate /tb_datapath/rst
add wave -noupdate /tb_datapath/IRin
add wave -noupdate /tb_datapath/RFout
add wave -noupdate /tb_datapath/RFin
add wave -noupdate /tb_datapath/Ain
add wave -noupdate /tb_datapath/Cin
add wave -noupdate /tb_datapath/Cout
add wave -noupdate /tb_datapath/ALUFN
add wave -noupdate /tb_datapath/RFaddr_wr_sel
add wave -noupdate /tb_datapath/RFaddr_rd_sel
add wave -noupdate /tb_datapath/Imm1_in
add wave -noupdate /tb_datapath/Imm2_in
add wave -noupdate /tb_datapath/PCin
add wave -noupdate /tb_datapath/PCsel
add wave -noupdate /tb_datapath/DTCM_out
add wave -noupdate /tb_datapath/DTCM_addr_in
add wave -noupdate /tb_datapath/DTCM_wr
add wave -noupdate /tb_datapath/TBactive
add wave -noupdate /tb_datapath/ITCM_tb_wr
add wave -noupdate /tb_datapath/ITCM_tb_in
add wave -noupdate /tb_datapath/ITCM_tb_addr_in
add wave -noupdate /tb_datapath/DTCM_tb_wr
add wave -noupdate /tb_datapath/DTCM_tb_in
add wave -noupdate /tb_datapath/DTCM_tb_addr_in
add wave -noupdate /tb_datapath/DTCM_tb_addr_out
add wave -noupdate /tb_datapath/DTCM_tb_out
add wave -noupdate /tb_datapath/add
add wave -noupdate /tb_datapath/sub
add wave -noupdate /tb_datapath/andop
add wave -noupdate /tb_datapath/orop
add wave -noupdate /tb_datapath/xorop
add wave -noupdate /tb_datapath/jmp
add wave -noupdate /tb_datapath/jc
add wave -noupdate /tb_datapath/jnc
add wave -noupdate /tb_datapath/mov
add wave -noupdate /tb_datapath/ld
add wave -noupdate /tb_datapath/st
add wave -noupdate /tb_datapath/done
add wave -noupdate /tb_datapath/Zflag
add wave -noupdate /tb_datapath/Nflag
add wave -noupdate /tb_datapath/Cflag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {505434 ps}
