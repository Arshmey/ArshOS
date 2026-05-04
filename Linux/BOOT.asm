[org 0x7C00]
[bits 16]

global boot

boot:
	xor ah, ah
	
	mov ah, 02h
	mov al, 2
	mov ch, 0
	mov dh, 0
	mov cl, 2
	mov bx, 0x8000
	int 13h
	jc chkdsk
	
	jmp 0x8000
	
print:
	lodsb
	or al, al
	jz exit
	mov ah, 0Eh
	int 10h
	jmp print
	
chkdsk:
	mov si, err_msg
	jmp print
	ret

exit:
	ret
	
err_msg db 'Corrupted data', 13, 10, 0	;Error message
times 510-($-$$) db 0
dw 0xAA55