#include<stdio.h>
#include<stdlib.h>
#include<stdbool.h>
#include<stdint.h>
//this is the golden reference model or instruction set simulator for my risc-v core
//this core is a part of a larger crypto core which i am going to create
//function prototypes here
// void* 
// int argc, char* argv[]
int main() {
    //testing instruction decode first
    //declaring the array for the register file
    uint32_t registerfile[32];
    uint32_t program_counter = 0x000000000; //program counter initialised to zero in the starting of the game
    uint32_t inst_curr;
    //using malloc fxn to denote memory
    // uint8_t* mem_arr = (uint8_t*)malloc(80*sizeof(uint8_t));
    // uint8_t* inst_arr = (uint8_t*)malloc(80*sizeof(uint8_t));
    //using static arrays for testing
    uint8_t inst_arr[80]; // this can store like 4 instructions enough for verification
    uint8_t mem_arr[80];
    //a simple for loop which does the part of reading every instruction over and over
    while (program_counter <= 80) {
        // //copying over the instruction into a temporary current instruction array because well i need to bitshift to hell
        inst_curr = (inst_arr[program_counter + 3] << 24 | inst_arr[program_counter + 2] << 16 | inst_arr[program_counter + 1] << 8 | inst_arr[program_counter]);
        //filtering the opcodes first
        int32_t rs1, rs2;
        uint32_t index;
        switch (inst_curr & 0x7f) {
        case 0x37: {
            //load upper intermediate lui
            registerfile[(inst_curr & 0xf80) >> 7] = inst_curr & 0xfffff000;
            //incrementing pc by 4
            program_counter += 4;
            break;
        }
        case 0x17: {
            //adding upper intermediate to current p
            registerfile[(inst_curr & 0xf80) >> 7] = inst_curr & 0xfffff000 + program_counter;
            program_counter += 4;
            break;
        }
        case 0x6f: {
            //jal jump and link
            registerfile[(inst_curr & 0xf80) >> 7] = program_counter += 4;
            program_counter += ((inst_curr & 0x80000000 | (inst_curr & 0xff000) << 11 | (inst_curr & 0x100000) << 2 | (inst_curr & 0x7fe00000) >> 9) >> 11) | ((inst_curr & 0x80000000) ? (0xffe00000) : (0x00000000));
            break;
        }
        case 0x67: {
            //jump and link register jalr
            if ((inst_curr & 0x7000) >> 12 == 0) {
                registerfile[(inst_curr & 0xf80) >> 7] = program_counter += 4;
                program_counter = registerfile[(inst_curr & 0xf8000) >> 15] + (((inst_curr >> 20) & ~0x1) | ((inst_curr & 0x80000000) ? (0xfff00000) : (0x00000000)));
            }
            else {
                program_counter += 4;
            }
            break;
        }
        case 0x63: {
            //branch cases
            rs2 = registerfile[(inst_curr & 0x1f00000) >> 20];
            rs1 = registerfile[(inst_curr & 0xf8000) >> 15];
            switch ((inst_curr & 0x7000) >> 12) {
                //beq -> branch if equal by offset
            case 0x0: {
                if (rs1 == rs2) {
                    program_counter += ((inst_curr & 0x80000000 | (inst_curr & 0x7e000000) >> 1 | (inst_curr & 0x80) << 22 | (inst_curr & 0xf00) << 11) >> 19) | ((inst_curr & 0x80000000) ? (0xffffe000) : (0x00000000));
                }
                else {
                    program_counter += 4;
                }
                break;
            }
            case 0x1: {
                //bne -> branch if not equal by offset
                if (rs1 != rs2) {
                    program_counter += ((inst_curr & 0x80000000 | (inst_curr & 0x7e000000) >> 1 | (inst_curr & 0x80) << 22 | (inst_curr & 0xf00) << 11) >> 19) | ((inst_curr & 0x80000000) ? (0xffffe000) : (0x00000000));
                }
                else {
                    program_counter += 4;
                }
                break;
            }
            case 0x4: {
                //blt ->branch if less than by offse
                if (rs1 < rs2) {
                    program_counter += ((inst_curr & 0x80000000 | (inst_curr & 0x7e000000) >> 1 | (inst_curr & 0x80) << 22 | (inst_curr & 0xf00) << 11) >> 19) | ((inst_curr & 0x80000000) ? (0xffffe000) : (0x00000000));
                }
                else {
                    program_counter += 4;
                }
                break;
            }
            case 0x5: {
                //bge -> branch if greater than or equal to 
                if (rs1 >= rs2) {
                    program_counter += ((inst_curr & 0x80000000 | (inst_curr & 0x7e000000) >> 1 | (inst_curr & 0x80) << 22 | (inst_curr & 0xf00) << 11) >> 19) | ((inst_curr & 0x80000000) ? (0xffffe000) : (0x00000000));
                }
                else {
                    program_counter += 4;
                }
                break;
            }
            case 0x6: {
                //bltu -> branch less than unsigned
                if (registerfile[(inst_curr & 0xf8000) >> 15] < registerfile[(inst_curr & 0x1f00000) >> 20]) {
                    program_counter += ((inst_curr & 0x80000000 | (inst_curr & 0x7e000000) >> 1 | (inst_curr & 0x80) << 22 | (inst_curr & 0xf00) << 11) >> 19) | ((inst_curr & 0x80000000) ? (0xffffe000) : (0x00000000));
                }
                else {
                    program_counter += 4;
                }
                break;
            }
            case 0x7: {
                //bgeu -> branch greater than unsigned
                if (registerfile[(inst_curr & 0xf8000) >> 15] >= registerfile[(inst_curr & 0x1f00000) >> 20]) {
                    program_counter += ((inst_curr & 0x80000000 | (inst_curr & 0x7e000000) >> 1 | (inst_curr & 0x80) << 22 | (inst_curr & 0xf00) << 11) >> 19) | ((inst_curr & 0x80000000) ? (0xffffe000) : (0x00000000));
                }
                else {
                    program_counter += 4;
                }
                break;
            }
            default: {
                program_counter += 4;
                break;
            }
            }
            break;
        }
        case 0x03: {
            index = registerfile[(inst_curr & 0xf8000) >> 15] + (inst_curr >> 20) | ((inst_curr & 0x80000000) ? (0xfffff000) : (0x00000000));
            //memory operations -> lb load byte, lh load halfword ,lw load word lbu -> load byte unsigned lhu -> load halfword unsigned
            switch ((inst_curr & 0x7000) >> 12) {
            case 0x00: {
                //load byte and sign extend to 32 bites
                registerfile[(inst_curr & 0xf80) >> 7] = (mem_arr[index]) | ((mem_arr[index] & 0x80) ? (0xffffff00) : (0x0));
                program_counter += 4;
                break;
            }
            case 0x01: {
                //load halfword and sign extend by
                registerfile[(inst_curr & 0xf80) >> 7] = (mem_arr[index + 1] << 8 | mem_arr[index]) | ((mem_arr[index + 1] & 0x80) ? (0xffff0000) : (0x0));
                program_counter += 4;
                break;
            }
            case 0x02: {
                //load entire 32 bit word
                registerfile[(inst_curr & 0xf80) >> 7] = mem_arr[index + 3] << 24 | mem_arr[index + 2] << 16 | mem_arr[index + 1] << 8 | mem_arr[index];
                program_counter += 4;
                break;
            }
            case 0x04: {
                //load byte unsigned
                registerfile[(inst_curr & 0xf80) >> 7] = (mem_arr[index]);
                program_counter += 4;
                break;
            }
            case 0x05: {
                //load halfword unsigned
                registerfile[(inst_curr & 0xf80) >> 7] = (mem_arr[index + 1] << 8 | mem_arr[index]);
                program_counter += 4;
                break;
            }
            default: {
                program_counter += 4;
                break;
            }
            }
            break;
        }
        case 0x23: {
            //memory store operations sb-> store byte, stores byte  sh-> stores half word , sw -> stores entire 32 bit word
            index = registerfile[(inst_curr & 0xf8000) >> 15] + ((inst_curr & 0xfe000000) >> 20 | (inst_curr & 0xf80) << 13) | ((inst_curr & 0x80000000) ? (0xfffff000) : (0x00000000));
            switch ((inst_curr & 0x7000) >> 12) {
            case 0x01: {
                //sb -> stores byte
                mem_arr[index] = registerfile[(inst_curr & 0x1f00000) >> 20] & 0xff;
                break;
            }
            case 0x02: {
                //sh -> stores halfword
                mem_arr[index + 1] = (registerfile[(inst_curr & 0x1f00000) >> 20] & 0xff00) >> 8;
                mem_arr[index] = registerfile[(inst_curr & 0x1f00000) >> 20] & 0xff;
                break;
            }
            case 0x04: {
                //sw -> stores word
                mem_arr[index + 3] = (registerfile[(inst_curr & 0x1f00000) >> 20] & 0xff000000) >> 24;
                mem_arr[index + 2] = (registerfile[(inst_curr & 0x1f00000) >> 20] & 0xff0000) >> 16;
                mem_arr[index + 1] = (registerfile[(inst_curr & 0x1f00000) >> 20] & 0xff00) >> 8;
                mem_arr[index] = registerfile[(inst_curr & 0x1f00000) >> 20] & 0xff;
                break;
            }
            }
            break;
        }
        case 0x13: {
            //immediate arithmetic instructions -> addi, slti, sltiu, xori, ori, andi, slli, srli, srai,
            switch ((inst_curr & 0x7000) >> 12) {
            case 0x00: {
                //addi -> add intermediate i.e take 12 bit thing sign extend and add
                break;
            }
            case:
            case:
            case:
            case:
            case:
            case:
            case:
            }
            break;
        }
        case 0x33: {
            break;
        }
        case 0x0f: {
            break;
        }
        case 0x73: {
            break;
        }
        default: {
            program_counter += 4;
        }
        }

    }

    //or instruction cache
}