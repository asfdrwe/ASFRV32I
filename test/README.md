# riscv-tests prebuilt
These test binaries come from [riscv-test](https://github.com/riscv/riscv-tests) 
and are patched with [riscv-tests.patch](../riscv-tests.patch) for removal of
CSR and exception code.

They are built by [RISC-V toolchain](https://github.com/riscv/riscv-gnu-toolchain)
for rv32ui-p and converted to text hex format by objcopy command and 
[freedom-bin2hex.py](https://github.com/sifive/elf2hex/blob/master/freedom-bin2hex.py) .
