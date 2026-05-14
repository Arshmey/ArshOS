[org 0x8000]
[bits 16]

section .data
codeName db 'Codename: ArshOS', 0Ah, 0Dh, 00h 												;Кодовое имя проекта
loadMsg db 'Arshmey Operation System Loaded', 0Ah, 0Dh, 00h								    ;Привественное сообщение
verKernelMsg db 'Version AK: 0.5.1', 0Ah, 0Dh, 00h 											;Версия ядра
host db 'user>: ', 00h
debugMsg1 db 'debugMsg1', 0Ah, 0Dh, 00h 													;Отладочное сообщение 1
debugMsg2 db 'debugMsg2', 0Ah, 0Dh, 00h 													;Отладочное сообщение 2

unknownCommand db 0Ah, 0Dh, 'Unknown command', 0Ah, 0Dh, 00h								;Сообщение о неизвестной команде
helpCommand	db 'h', 'e', 'l', 'p'															;Команда
helpCommandLen equ $-helpCommand															;Длина команды

;Действие комманды
helpCommandAction db 0Ah, 0Dh, 'Command', 0Ah, 0Dh, 'help - Show commands', 0Ah, 0Dh, 'time - Show time', 0Ah, 0Dh, 'clear - Clear console', 0Ah, 0Dh, 00h
timeCommand db 't', 'i', 'm', 'e'															;Команда
timeCommandLen equ $-timeCommand															;Длина команды

timeCommandAction db 'Current time: 09:41', 0Ah, 0Dh, 0


clearCommand db 'c', 'l', 'e', 'a', 'r'
clearCommandLen equ $-clearCommand

backspaceLine db 08h, ' ', 08h, 00h															;Удаление символа
enterPrint db 0Ah, 0Dh, 00h																	;Перенос на следующую строку

chars times 72 db 0																			;Массив символов
charBufferLen db 0																			;Количество символов в массиве charBuffer
command times 72 db 0																		;Массив из сиволов для команд
commandLen db 0																				;Количество символов в массиве command


section .text
global kernel_hello

kernel_hello:
	mov dl, 0
	call setupScreen
	call clearScreen
	mov bx, codeName
	call print
	mov bx, loadMsg
	call print
	mov bx, verKernelMsg
	call print

kernel:
	cmp dl, 0
	je printHost
	call keyboardDriver
	call lineConsole
	jmp kernel

printHost:
	mov dl, 1
	mov bx, host
	call print
	jmp kernel

lineConsole:
	cmp dh, 0
	jne quite
	mov ah, 0Eh
lineConsoleLoop:
	mov al, [chars + si]
	int 10h
	ret

print:
	mov ah, 0Eh
	mov si, 0
printLoop:
	mov al, [bx + si]
	cmp al, 00h
	je quite
	int 10h
	inc si
	jmp printLoop

keyboardDriver:
	mov ah, 01h
	int 16h
	jz keyNotPress
	mov ah, 00h
	int 16h
	mov dh, 0

	cmp al, 08h
	je backspaceCode
	cmp al, 0Dh
	je enterCode

	cmp byte [charBufferLen], 71
	je keyNotPress

	movzx si, byte [charBufferLen]
	mov byte [chars + si], al
	inc byte [charBufferLen]
	ret

keyNotPress:
	mov dh, 1
	ret

backspaceCode:
	mov dh, 1
	cmp byte [charBufferLen], 0
	je quite

	mov bx, backspaceLine
	call print

	movzx si, byte [charBufferLen]
	mov byte [chars + si], 0
	dec byte [charBufferLen]
	ret

enterCode:
	mov bx, enterPrint
	call print

	mov dl, 0
	mov dh, 1
	mov di, 0
	movzx cx, byte [charBufferLen]

	cmp cx, 0
	je postCopy

	copy:
	mov al, [chars + di]
	mov [command + di], al
	inc di
	inc byte [commandLen]
	loop copy

	postCopy:
	mov di, 0
	movzx cx, byte [charBufferLen]

	cmp cx, 0
	je quite

	clear:
	mov byte [chars + di], 0
    inc di
	loop clear

	mov byte [charBufferLen], 0
	call commandExec
	ret

; ============================================================
; Производит проверку на существование команды, выполняет команду.
; 
;
;                                      
commandExec:
											;Сдлеай ёбанный switch для блятских комманд.
											;Все еще актуально :)


    checkHelp:                                  ; ===============================================
                                                ; Проверка на команду help

        mov si, 0                               ;
    	movzx cx, byte [commandLen]             ; Указатель на строку с командой пользователя
        mov bx, helpCommand                     ; Указатель на команду help

    	checkHelpLoop:                          ; =======

    	    mov al, [command + si]
    	    mov ah, [bx + si]
    	    cmp al, ah
    	    jne checkTime
    	    inc si
    	    loop checkHelpLoop

	call helpExec
	jmp postExec

    checkTime:                                  ; =======================   
                                                ; Проверка на команду time
        mov bx, timeCommand                     ; !! ВНИМАНИЕ !! : на месте time заглушка, эта команда не выдает время (по крайней мере пока)
        movzx cx , byte [ commandLen ]          ; Принцип аналогичен циклу выше.
        mov si, 0
        checkTimeLoop:
    	    mov al, [ command + si ]
            mov ah, [ bx + si ]
            cmp al, ah
            jne checkClear
            inc si
            loop checkTimeLoop

    call timeExec
    jmp postExec


    checkClear:                                     ; =======================
        mov bx, clearCommand                        ; Проверка на команду clear
        movzx cx , byte [ commandLen ]              ; Принцип аналогичен циклу выше и выше.
        mov si, 0
        checkClearLoop:
    	    mov al, [ command + si ]
            mov ah, [ bx + si ]
            cmp al, ah
            jne notExistCommand
            inc si
            loop checkClearLoop

    call clearExec
    jmp postExec

	postExec:                                       ; Выполнение пост-командных операций:
	mov di, 0                                       ; - Задание указателю команды значения 0
	movzx cx, byte [commandLen]                     ; - Очистка commandLen (задание длины 0)
	mov byte [commandLen], 0

	clearCommandBuffer:                             ; - Очистка буфера команды в цикле
	mov byte [command + di], 0
    inc di
	loop clearCommandBuffer
	ret


; ========================================================================
; Секция с командами
; ========================================================================

helpExec:
	mov bx, helpCommandAction
	call print
	ret

timeExec:
    mov bx, timeCommandAction
    call print
    ret

clearExec:
    call clearScreen
    ret


notExistCommand:
	mov bx, unknownCommand
	call print
	jmp postExec




; ===============================================================
; Дебаггинг
; ===============================================================

quiteDebug:
	mov bx, debugMsg1
	call print
	ret

quiteDebug2:
	mov bx, debugMsg2
	call print
	ret

quite:
	ret




; =============================================
; Служебные команды 
; =============================================

setupScreen:
    mov al, 08h
	mov ah, 00h
    int 10h
ret

clearScreen:
	mov al, 0
	mov bh, 07h
	mov ch, 0
	mov cl, 0
	mov dh, 160
	mov dl, 200
	mov ah, 07h
    int 10h

	mov bh, 00h
	mov dh, 0																			;Change Y
	mov dl, 0																			;Change X
	mov ah, 02h
    int 10h
	ret

