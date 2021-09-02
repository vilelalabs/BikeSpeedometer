MAIN.ASM
################################################################################
;			     Projeto Bike speedometer						#
;			     	                      							#
; 			 Arquivo com o programa principal					#
;			     	                      							#
;						      Por: Henrique Leal Vilela 			#
;################################################################################

	include <prepara.asm>
	

;============================= PROGRAMA PRINCIPAL ===============================
LOOP

	call verifica_sensor	; verifica valor obtido no sensor: s� sai desta 
				; quando o n� de pulsos for diferente (ver c�d.)
	movf pulsos,w		; coloca em 'w'

	call math		; converte para m/s
	movf final,w		; coloca valor convertido e arredondado em 'w'

	call get_ascii		; converte em 2 caracteres ASCII

	call atualiza_tela	; atualiza tela j� com os valores dec e uni pegos
				; internamente pela fun��o (ver c�digo da fun��o)

	goto LOOP
;================================================================================

	End			; fim do programa
