
filename=$(basename $1)
outdir=$2

riscv32-unknown-elf-objcopy -O binary -j .text.init -j .tohost -j .text -j .data -j .bss $1 $1.data
srec_cat $1.data -binary -fill 0x00 -within $1.data -binary -o $outdir/$filename.vmem -vmem 32 -disable=header -obs=4
rm $1.data