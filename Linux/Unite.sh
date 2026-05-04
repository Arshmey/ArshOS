#!/bin/bash

# Создаем пустой образ диска (5 МБ = 5242880 байт)
dd if=/dev/zero of=os.iso bs=5242880 count=1

# Копируем загрузчик (BOOT.bin) в начало образа
dd if=BOOT.bin of=os.iso conv=notrunc

# Копируем ядро (KernelASM.bin) по смещению 512 байт
dd if=KernelASM.bin of=os.iso bs=512 seek=1 conv=notrunc

qemu-system-i386 -m 128 -hda /test/os.iso
