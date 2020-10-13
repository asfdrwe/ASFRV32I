# ASFRV32I 
ASFRV32I シンプルなRISC-V RV32I実装

Verilog 200行以下で実装したRISC-V RV32IのCPUです。
[RISC-V Unpriviledged ISA 20191213](https://riscv.org//wp-content/uploads/2019/12/riscv-spec-20191213.pdf) に準拠しています。
コードが短い分理解しやすいと思うのでCPUの学習の参考にしてみてください。
ASFRV32Iの実装の詳細の解説は [ASFRV32I\_detail\_jp.md](ASFRV32I_detail_jp.md) です。

## ライセンス
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

## 必要なもの
- [iverlog](http://iverilog.icarus.com/)
	- [iverlog Windows版](http://bleyer.org/icarus/)
- [gtkwave](http://gtkwave.sourceforge.net/) (なくてもいい)  

Linuxで動作確認しています。iverlogもgtkwaveもLinuxなら大抵のディストリビューションで
バイナリが用意されていると思います。

## ファイル取得
```
git clone https://github.com/asfdrwe/ASFRV32I.git
```

## 論理合成
  ```
iverilog -o RV32I RV32I.v RV32I_test.v
  ```

## シミュレーション実行
  ```
./RV32I
  ```

### プログラム(test.hex)の書き方
ASFRV32Iのメモリは命令データ兼用で4KBです。1行が8bit16進数で書かれた
test.hexを読み込み実行します。バイナリは1行8bit16進数のテキストに変換する
必要があります。

#### ハンドアセンブル
RV32Iは4バイト固定長です。ASFRV32Iではリトルエンディアンで書きます。
lui x1, 0x20000ならば
  ```
0b_0010_0000_0000_0000_0000_00001_0110111(2進数)
0x_20_00_00_B7(16進数)
  ```
なのでtest.hexは次のようになります。  
  ```
B7
00
00
20
  ```

#### gcc
[RISC-Vのツールチェイン](https://github.com/riscv/riscv-gnu-toolchain) を
取得してビルドしてください。

ファイル取得  
  ```
$ git clone https://github.com/riscv/riscv-gnu-toolchain
$ cd riscv-gnu-toolchain
$ git submodule update --init --recursive
  ```

Linuxでのビルド  
  ```
$ ./configure --prefix=/opt/riscv
$ make linux
  ```

ASFRV32IはOSなしのベアメタルなのでそのままではコンパイルしても動きません。
0番地から実行するので下記のlink.ldのようなリンカスクリプトで実行コード
(.textセクション)を0番地に配置します。 なお0x100単位でalignしています。

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

##### アセンブリ
アセンブリで記述する場合は次のようなコードです。  
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

コンパイルは次のように行います。  
  ```
$ riscv64-unknown-elf-gcc -o test.bin test.S -march=rv32g -mabi=ilp32 -nostdlib -nostartfiles -T ./link.ld
  ```

##### バイナリの変換
elf形式のバイナリを1行8bit16進数のテキストファイルに変換します。
[freedom-bin2hex.py](https://github.com/sifive/elf2hex/blob/master/freedom-bin2hex.py) を
ダウンロードしてください。実行にはpythonが必要です。

objcopyでbinaryをダンプしてfreedom-bin2hex.pyで1行8bit16進数のテキストファイルに変換します。
  ```
$ riscv64-unknown-elf-objcopy -O binary test test.bin
$ freedom-bin2hex.py -w 8 test.bin test.hex
  ```

##### c言語
ベアメタルなのでint main()は使えません。printf等も使えません。
スタックポインタを設定するスタートアップルーチンがないとほとんど
意味がないのでstart.Sをスタートアップルーチンとします。

[start.S](mytest/start.S)  
  ```
.globl _start

_start:
  li sp, 0x0800
  jal _main
  j
  ```

Cでのコード例  
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

コンパイルは次のようにstart.Sも一緒にアセンブル＆リンクして-nostdlib -nostartfilesを指定してください。
ASFRV32Iでは未対応命令はNOP扱いなので掛け算等はNOPになるはずです(未確認)。
  ```
$ riscv64-unknown-elf-gcc -o test2.bin start.S test2.c -march=rv32g -mabi=ilp32 -nostdlib -nostartfiles -T ./link.ld
  ```

バイナリからtest.hexへの変換はアセンブリのときと同じです。  
  ```
$ riscv64-unknown-elf-objcopy test2 -O binary test2.bin
$ freedom-bin2hex.py -w 8 test2.bin test.hex
  ```

#### riscv-tests
[riscv-tests](https://github.com/riscv/riscv-tests) を使うことでRV32Iに正しく
準拠しているか確認できます。

ファイル取得  
  ```
$ git clone https://github.com/riscv/riscv-tests
$ cd riscv-tests
$ git submodule update --init --recursive
$ autoconf
  ```

ASFRV32Iはメモリが4KBで割り込みやCSR関係を実装していないので、0番地から実行するように修正しCSR命令と割り込み関連を削除します。
risc-testsのトップディレクトリで [riscv-tests.patch](riscv-tests.patch) を当ててください。

  ```
$ patch -p1 < ASFRV32Iの場所/riscv-tests.patch
  ```

hex形式にしたものとコンパイル後に逆アセンブルしたもの(*.dump)を[test](test/)以下に用意
してあります。ASFRV32Iではecallが0番地への無条件分岐なのことに気をつけて動作確認して
みてください。

## ASFRV32Iの設計と実装
### ASFRV32Iのブロックダイアグラム  
![block diagram](images/ASFRV32I_block_diagram.png)

### ASFRV32Iの設計と実装の詳細
RISC-Vの仕様書を読み解きながらRV32Iに必要なマイクロアーキテクチャをどのように設計したか
具体的なアプローチと、設計したブロックダイアグラムに基づきどのように実装したか実装の詳細を
[ASFRV32I\_detail\_jp.md](ASFRV32I_detail_jp.md)で解説しています。

CPUの専門家でないのでおかしな点があれば指摘お願いします。
