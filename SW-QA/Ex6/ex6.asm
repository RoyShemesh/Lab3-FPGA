data segment:	;DTCM content
arr dc16 63,542,245,190,91,86,78,64,83,16,24,62,79,19
arr_odds ds16 1
arr_evens ds16 1

code segment:	;ITCM content
mov r1,arr
mov r2,arr_odds
mov r3,arr_evens
mov r4,0
mov r5,1
mov r6,14
ld  r7,0(r1)
add r11,r3,r0
and r9,r7,r5
sub r10,r9,r5
jnc 1
add r11,r2,r0
ld  r8,0(r11)
add r8,r8,r7
st  r8,0(r11)
add r1,r1,r5
add r4,r4,r5
sub r10,r4,r6
jlo -13
done
nop
jmp -2