# ASFRV32I 
ASFRV32I is a small RISC-V RV32I implementation written with under 200 lines for iverilog. 
It is compliant with [RISC-V Unpriviledged ISA 20191213](https://riscv.org//wp-content/uploads/2019/12/riscv-spec-20191213.pdf).

## LICENSE
  ```
Copyright (c) 2020 asfdrwe <asfdrwe@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
IN THE SOFTWARE.
  ```

## require
- [iverlog](http://iverilog.icarus.com/)
	- [Windows version](http://bleyer.org/icarus/)
- [gtkwave](http://gtkwave.sourceforge.net/) (optional)

Checked on Linux only.

## getting started
```
git clone https://github.com/asfdrwe/ASFRV32I.git
```

## synthesis
  ```
iverilog -o RV32I RV32I.v RV32I_test.v
  ```

## run
  ```
./RV32I
  ```

## how to write a program for ASFRV32I (test.hex)
ASFRV32I has 4KB memory(instruction and data).
ASFRV32I runs test.hex which has the opcodes as an 8bit hexadecimal value in each lines, 
so you need a risc-v binary to 8bit hexadecimal values.

### hand assemble
Example "lui x1, 0x20000"
  ```
0b_0010_0000_0000_0000_0000_00001_0110111 (binary)
0x_20_00_00_B7 (hexadecimal)
  ```
Write test.hex as
  ```
B7
00
00
20
  ```
(little endian)

### gcc
Use [RISC-V toolchain](https://github.com/riscv/riscv-gnu-toolchain) .

RETRIEVAL
  ```
$ git clone https://github.com/riscv/riscv-gnu-toolchain
$ cd riscv-gnu-toolchain
$ git submodule update --init --recursive
  ```

BUILD
  ```
$ ./configure --prefix=/opt/riscv
$ make linux
  ```

ASFRV32I is a baremetal.
So need the linker script such as link.ld because ASFRV32I runs from 0 address. 

[link.ld](mytest/link.ld)
  ```
OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x0100);
  .tohost : { *(.tohost) }
  . = ALIGN(0x0100);
  .text : { *(.text) }
  . = ALIGN(0x0100);
  .data : { *(.data) }
  .bss : { *(.bss) }
  _end = .;
}
  ```

#### assembly example
[test.S](mytest/test.S)    
  ```
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
  ```

Assemble
  ```
$ riscv64-unknown-elf-gcc -o test.bin test.S -march=rv32g -mabi=ilp32 -nostdlib -nostartfiles -T ./link.ld
  ```

Convert a binary to hex text  
Use objcopy command and [freedom-bin2hex.py](https://github.com/sifive/elf2hex/blob/master/freedom-bin2hex.py) (require python).

  ```
$ riscv64-unknown-elf-objcopy -O binary test test.bin
$ python freedom-bin2hex.py -w 8 test.bin test.hex
  ```

#### c example
Can't use int main() or printf function etc.
And you need the stack pointer, so you use the startup routing such as start.S .

[start.S](mytest/start.S)  
  ```
.globl _start

_start:
  li sp, 0x0800
  jal _main
  j
  ```

[test2.c](mytest/test2.c)
  ```
void _main()
{
  static int a, b, c;
  a = 1;
  b = 2;
  c = 1 + 2;
  int d, e, f, h;
  d = 10;
  e = 15;
  f = e - d;
  h = a - 10;
  return;
}
  ```

Compile
  ```
$ riscv64-unknown-elf-gcc -o test2.bin start.S test2.c -march=rv32g -mabi=ilp32 -nostdlib -nostartfiles -T ./link.ld
  ```

Convert to hexadecimal text
  ```
$ riscv64-unknown-elf-objcopy test2 -O binary test2.bin
$ freedom-bin2hex.py -w 8 test2.bin test.hex
  ```

#### riscv-tests
Use [riscv-tests](https://github.com/riscv/riscv-tests) .

  ```
$ git clone https://github.com/riscv/riscv-tests
$ cd riscv-tests
$ git submodule update --init --recursive
$ autoconf
  ```

Need [riscv-tests.patch](riscv-tests.patch) for 0 address startup and removal of CSR code 
(NOTE: ASFRV32I's ecall acts as jump instruction to 0 address).

  ```
$ patch -p1 < (ASFRV32I dir)/riscv-tests.patch
  ```

\*.hex in [test](test/)  are hex format riscv-tests for ASFRV32I.
\*.dump in [test](test/) are deassembled riscv-tests programs.

## ASFRV32I Design
![block diagram](images/ASFRV32I_block_diagram.png)

## Reference 
- [RISC-V specification](https://riscv.org/technical/specifications/)
- [oakland Univercity lecture note](https://passlab.github.io/CSE564/notes/lecture08_RISCV_Impl.pdf) 
