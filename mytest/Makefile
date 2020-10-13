all:
	riscv64-unknown-elf-gcc -o test test.S -march=rv32g -mabi=ilp32 -nostdlib -nostartfiles -T ./link.ld
	riscv64-unknown-elf-gcc -o test2 start.S test2.c -march=rv32g -mabi=ilp32 -nostdlib -nostartfiles -T ./link.ld
