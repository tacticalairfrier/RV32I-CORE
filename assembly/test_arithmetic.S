.section .text
.global _main

_main:
    # testing using an expression which generates a hash which can be verified
    # using 20 testcases and checking the dumped values
    # (a+b)^(a-b)^(a<<shamt)^(b>>shamt) = hash 
    # testcase 1
    li x3, 0x12345678 # a
    li x4, 0xffffeeee # b
    add x5, x3, x4
    sub x6, x3, x4
    xor x1, x5, x4
    slli x5, x3, 0
    srli x6, x4, 31
    xor x2, x5, x6
    xor x1, x1, x2
    sw x1 ,0(x0) # store in the first memory address
    # testcase 2
    li x3, 0xD27931CA
    li x4, 0xD4209771
    add x5, x3, x4
    sub x6, x3, x4
    xor x1, x5, x4
    slli x5, x3, 0x1B
    srli x6, x4, 0x1D
    xor x2, x5, x6
    xor x1, x1, x2
    sw x1, 4(x0)
    #testcase 3
    li x3, 0x2F8D3F89
    li x4, 0xF85DA539
    add x5, x3, x4
    sub x6, x3, x4
    xor x1, x5, x4
    slli x5, x3, 0x0D
    srli x6, x4, 0x0F
    xor x2, x5, x6
    xor x1, x1, x2
    sw x1, 8(x0)
    # testcase 3 
    li x3, 0x49942DA5
    li x4, 0x23AF8CD3
    add x5, x3, x4
    sub x6, x3, x4
    xor x1, x5, x4
    slli x5, x3, 0x0C
    srli x6, x4, 0x02
    xor x2, x5, x6
    xor x1, x1, x2
    sw x1, 12(x0)
    # testcase 4
    li x3, 0x5A040557
    li x4, 0xA841CBE9
    add x5, x3, x4
    sub x6, x3, x4
    xor x1, x5, x4
    slli x5, x3, 0x04
    srli x6, x4, 0x0F
    xor x2, x5, x6
    xor x1, x1, x2
    sw x1, 16(x0)
    # testcase 5
    li x3, 0x4518E713
    li x4, 0x392F245D
    add x5, x3, x4
    sub x6, x3, x4
    xor x1, x5, x4
    slli x5, x3, 0x11
    srli x6, x4, 0x04
    xor x2, x5, x6
    xor x1, x1, x2
    sw x1, 20(x0)
    # testing the load instructionsets
    lw x5, 0(x0);
    lh x6, 4(x0)
    lhu x7, 8(x0)
    lb x8, 12(x0)
    lbu x9, 16(x0)
    xor x1, x5, x6
    xor x1, x1, x7
    xor x1, x1, x8
    xor x1, x1, x9
    sw x1, 24(x0)
    sh x1, 28(x0)
    sb x1, 32(x0)
    # tests for immediate instructions
    lw x5, 0(x0)
    lw x6, 4(x0)
    lw x7, 8(x0)
    lw x8, 12(x0)
    xori x11, x5, 0x6fb
    ori x12, x6, 0x542
    andi x13, x7, 0x431
    sw x11, 36(x0)
    sw x12, 40(x0)
    sw x13, 44(x0)
    #testing 1 branch with the 0 output and 1 with a 0
    sra x14, x11, x12
    srl x15, x11, x12
    sll x16, x11, x12
    xor x14, x14, x15
    xor x14, x14, x15
    xor x14, x14, x16
    sw x14, 48(x0)
    #testing branch statements
    li x5, 10
    li x6, 0
    beq x5, x6, 0x1ac
    addi x6, x6, 1
    jal x0, 0x19c
    sw x6, 52(x0)