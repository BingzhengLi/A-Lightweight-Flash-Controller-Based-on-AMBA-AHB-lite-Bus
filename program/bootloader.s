/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
.section .reset,  "ax"
.global	__start 
.global __reset 
__reset:


#enable btb & bht
#  csrr x3, mhcr
#  ori x3, x3, 0x20
#  csrw mhcr, x3
#
#  li x3, 0x1000
#  csrrs x0, mhcr, x3

#reset all regs written by Li Bingzheng 20240328.
#  li x1, 0
#  li x2, 0
#  li x3, 0
#  li x4, 0
#  li x5, 0
#  li x6, 0
#  li x7, 0
#  li x8, 0
#  li x9, 0
#  li x10, 0
#  li x11, 0
#  li x12, 0
#  li x13, 0
#  li x14, 0
#  li x15, 0
#  li x16, 0
#  li x17, 0
#  li x18, 0
#  li x19, 0
#  li x20, 0
#  li x21, 0
#  li x22, 0
#  li x23, 0
#  li x24, 0
#  li x25, 0
#  li x26, 0
#  li x27, 0
#  li x28, 0 
#  li x29, 0
#  li x30, 0
#  li x31, 0   
__stack_init:
#la x3, 0x20000
  la  x2, __kernel_stack
#Init_Stack:
#
#  sw x0, 0(x2)
#  addi x2, x2, -4
#  addi x3, x3, -4
#  bnez x3, Init_Stack
# Copy from Flash to IRAM/DRAM written by Li Bingzheng 20240328.
# Copy prog from Flash to IRAM.
_GPIO_display_current_state:
  lui x28, 0x40019
  lui x29, 0x40019
  addi x29, x29, 0x4
  addi x30, x0, 0x80
  sw x30, 0(x28)
  sw x30, 0(x29)
#Added by @Li Bingzheng 20240423.
  #lui x3, 0x10006
  #sw x5, 0(x3)
__prog_copy:
  la x3, __lma_user_pat
  la x4, __user_pat_start
  la x5, __user_pat_end
  sub x5, x5, x4 #Calculate user text size.
  beqz x5, L_loop1_done

#  lui x28, 0x40019
#  lui x29, 0x40019
#  addi x29, x29, 0x4
#  addi x30, x0, 0x40
#  sw x30, 0(x28)
#  sw x30, 0(x29)

__loop_user_pat_copy:
  lw x6, 0(x3) #x6 work as a temp storing prog's 1 word.
  sw x6, 0(x4) #Word stroing in x6 move x4, VMA in IRAM.
  
#  lui x28, 0x40019
#  lui x29, 0x40019
#  addi x29, x29, 0x4
#  addi x30, x0, 0x60
#  sw x30, 0(x28)
#  sw x30, 0(x29)

  addi x3, x3, 0x4 #LMA +4 for next text LMA.
  addi x4, x4, 0x4 #VMA +4 for next text VMA.
  addi x5, x5, -4  #Check whether finish copying user text. 
  bnez x5, __loop_user_pat_copy
#  lui x3, 0x40019
#  lui x4, 0x40019
#  addi x4, x4, 0x4
#  addi x5, x0, 0x40
#  sw x5, 0(x3)
#  sw x5, 0(x3)  
# lui t1,0x10000
# jalr x0,0(t1)
#  sub x5, x5, x4
#  beqz x5, L_loop0_done
#L_loop0:
#   lw x6, 0(x3)
#   sw x6, 0(x4)
#   addi x3, x3, 0x4
#   addi x4, x4, 0x4
#   addi x5, x5, -4
#   bnez x5, L_loop0

#L_loop0_done:
#   la x3, __data_end__
#   la x4, __bss_end__

#   li x5, 0
#   sub x4, x4, x3
#   beqz x4, L_loop1_done

#L_loop1:
#   sw x5, 0(x3)
#   addi x3, x3, 0x4
#   addi x4, x4, -4
#   bnez x4, L_loop1  

#Vectors addr initial written by Li Bingzheng 20240328.
L_loop1_done:
  #lui x28, 0x40019
  #lui x29, 0x40019
  #addi x29, x29, 0x4
  #addi x30, x0, 0x20
  #sw x30, 0(x28)
  #sw x30, 0(x29)

 

#Jump to use prog's main when finish copying and reg initialing @Li Bingzheng 20240328.  
#_to_main:
#  jal main
#  la x3, __user_pat_start
  #lui x3, 0x0
  #jalr x1, x3
#  jalr x1, x3
 



  la x3, trap_handler
  csrw mtvec, x3

  la x3, vector_table
  addi x3, x3, 64
  csrw mtvt, x3


  li a5, 0xeffff000
  li a6, 0x20000
  sw a6, 0(a5)
  li a7, 0xc
  sw a7, 4(a5)

  li a6, 0x40000
  li a7, 0xc
  sw a6, 8(a5)
  sw a7, 12(a5)
  
  li a6, 0x50000
  li a7, 0x10
  sw a6, 16(a5)
  sw a7, 20(a5)

  li a5, 0x40011000
  li a6, 0xff
  sw a6, 0(a5)
  li a6, 0x3
  sw a6, 8(a5)
  lw a6, 4(a5)


# enable mie
  li   x3,0x88 
  csrw mstatus,x3

# enable fpu
  li x3, 0x2000
  csrs mstatus,x3

  li   x3,0x103f
  csrw mhcr,x3
  li   x3,0x400c
  csrw mhint,x3
 
#Jump to use prog's main when finish copying and reg initialing @Li Bingzheng 20240328.  
_to_main:
  #jal main
  la x3, __user_pat_start
  #lui x3, 0x0
  jalr x1, x3
  #jalr x1, x3
  .global __exit
__exit:
  fence.i
  fence
  li    x4, 0x6000fff8
  addi  x3, x0,0xFF
  slli  x3, x3,0x4
  addi  x3, x3, 0xf #0xFFF
  sw	x3, 0(x4)

  .global __fail
__fail:
  fence.i
  fence
  li    x4, 0x6000fff8
  addi  x3, x0,0xEE
  slli  x3, x3,0x4
  addi  x3, x3,0xe #0xEEE
  sw	x3, 0(x4)

  .align 6  
  .global trap_handler
trap_handler:
  j __synchronous_exception
  .align 2  
  j __fail
 
__synchronous_exception:
  sw   x13,-4(x2)
  sw   x14,-8(x2)
  sw   x15,-12(x2)
  csrr x14,mcause
  andi x15,x14,0xff  #cause
  srli x14,x14,0x1b   #int
  andi x14,x14,0x10   #mask bit
  add  x14,x14,x15    #{int,cause}

  slli x14,x14,0x2  #offset
  la   x15,vector_table
  add  x15,x14,x15  #target pc
  lw   x14, 0(x15)  #get exception addr
  lw   x13, -4(x2)  #recover x16
  lw   x15, -12(x2) #recover x15
#addi x14,x14,-4
  jr   x14


  .global vector_table
  .align  6
vector_table:	#totally 256 entries
	.rept   256
	.long   __dummy
	.endr

  .global __dummy
__dummy:  
  j __fail
  
  .data
  .long 0

  #.section .usertext, "a"
  #.incbin "user_inst.bin"
  
  #.section .userdata, "a"
  #.incbin "user_data.bin"
  .section .userpat, "a"
  .incbin "user.bin"
