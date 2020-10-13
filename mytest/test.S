.globl _start

_start:
  lui x1, 0x50000
  addi x1, x1, 0xca
_loop:
  jal x2, _loop

.data
        .align 4
testdata:
        .dword 41

