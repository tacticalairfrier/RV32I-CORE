.section .text
.global _main

_main: 
    li x1, 0x124f80 
    li x2, 0x1000 
    li x3, 0x0 
    li x4, 0xff
    beq x3, x1, 0x24
    addi x3, x3, 1
    jal x0, 0x14
    sb x4, 4(x2)
    li x3, 0x0
    beq x3, x1, 0x3c
    addi x3, x3, 1
    jal x0, 0x2c
    li x4, 0x00
    sb x4, 4(x2)
    jal x0, 0x00
