.globl _start

_start:
  li sp, 0x0800
  jal _main
  j
