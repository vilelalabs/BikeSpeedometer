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

	call verifica_sensor	; verifica valor obtido no sensor: só sai desta 
				; quando o nº de pulsos for diferente (ver cód.)
	movf pulsos,w		; coloca em 'w'

	call math		; converte para m/s
	movf final,w		; coloca valor convertido e arredondado em 'w'

	call get_ascii		; converte em 2 caracteres ASCII

	call atualiza_tela	; atualiza tela já com os valores dec e uni pegos
				; internamente pela função (ver código da função)

	goto LOOP
;================================================================================

	End			; fim do programa
