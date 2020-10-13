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

