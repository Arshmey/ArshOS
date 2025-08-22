:: Создаем пустой образ диска
powershell -command "$emptyImage = New-Object byte[] 5242880; [System.IO.File]::WriteAllBytes('.\test\os.iso', $emptyImage)"

:: Копируем загрузчик (boot.bin) в начало образа
powershell -command "$bootLoader = [System.IO.File]::ReadAllBytes('.\test\BOOT.bin'); $image = [System.IO.File]::ReadAllBytes('.\test\os.iso'); [System.Array]::Copy($bootLoader, 0, $image, 0, $bootLoader.Length); [System.IO.File]::WriteAllBytes('.\test\os.iso', $image)"

:: Копируем ядро (KernelASM.bin) по смещению 512 байт
powershell -command "$kernelASM = [System.IO.File]::ReadAllBytes('.\test\KernelASM.bin'); $image = [System.IO.File]::ReadAllBytes('.\test\os.iso'); [System.Array]::Copy($kernelASM, 0, $image, 512, $kernelASM.Length); [System.IO.File]::WriteAllBytes('.\test\os.iso', $image)"

qemu-system-i386w.exe -m 128 -hda .\test\os.iso