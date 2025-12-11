.data
    MSG_INICIO:     .asciiz "\n=== ESTUFA INTELIGENTE ===\n"
    ASK_UMID:       .asciiz "\nDigite a UMIDADE do solo (0-100): "
    ASK_TEMP:       .asciiz "Digite a TEMPERATURA (C): "
    ASK_PH:         .asciiz "Digite o pH do solo (0-14): "
    MSG_VALORES:    .asciiz "\n[DADOS LIDOS] Umidade: "
    SEPARADOR:      .asciiz " | Temp: "
    SEPARADOR_PH:   .asciiz " | pH: "
    QUEBRA_LINHA:   .asciiz "\n"
    ALERTA_SECO:    .asciiz "   [ALERTA] Solo Seco! (Bomba Ligada)\n"
    ALERTA_QUENTE:  .asciiz "   [ALERTA] Temperatura Alta! (Ventoinha Ligada)\n"
    ALERTA_ACIDO:   .asciiz "   [ALERTA] pH muito Acido!\n"
    ALERTA_BASICO:  .asciiz "   [ALERTA] pH muito Basico!\n"
    STATUS_OK:      .asciiz "   [STATUS] Sistema Estavel!\n"
    MSG_VETOR:      .asciiz "\n[MEMORIA VETOR] Historico Umidade: "
    SPACE:          .asciiz "  "
    historico_umid: .word 50, 50, 50, 50, 50
    indice_atual:   .word 0
    tam_vetor:      .word 5
    LIMITE_SECO:    .word 40
    LIMITE_TEMP:    .word 30
    PH_MIN:         .word 6
    PH_MAX:         .word 8

.text
.globl main

main:
    li $v0, 4
    la $a0, MSG_INICIO
    syscall

    li $v0, 4
    la $a0, ASK_UMID
    syscall
    
    li $v0, 5
    syscall
    move $s0, $v0

    li $v0, 4
    la $a0, ASK_TEMP
    syscall
    
    li $v0, 5
    syscall
    move $s1, $v0

    li $v0, 4
    la $a0, ASK_PH
    syscall
    
    li $v0, 5
    syscall
    move $s2, $v0

    li $v0, 4
    la $a0, MSG_VALORES
    syscall
    
    li $v0, 1
    move $a0, $s0
    syscall
    
    li $v0, 4
    la $a0, SEPARADOR
    syscall
    
    li $v0, 1
    move $a0, $s1
    syscall
    
    li $v0, 4
    la $a0, SEPARADOR_PH
    syscall
    
    li $v0, 1
    move $a0, $s2
    syscall
    
    lw $t0, indice_atual
    mul $t1, $t0, 4
    la $t2, historico_umid
    add $t2, $t2, $t1
    sw $s0, 0($t2)

    addi $t0, $t0, 1
    lw $t3, tam_vetor
    div $t0, $t3
    mfhi $t0
    sw $t0, indice_atual

    li $v0, 4
    la $a0, MSG_VETOR
    syscall

    li $t5, 0
    lw $t6, tam_vetor

loop_print:
    beq $t5, $t6, fim_print
    
    mul $t7, $t5, 4
    la $t8, historico_umid
    add $t8, $t8, $t7
    lw $a0, 0($t8)
    
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, SPACE
    syscall

    addi $t5, $t5, 1
    j loop_print

fim_print:
    li $v0, 4
    la $a0, QUEBRA_LINHA
    syscall
    li $v0, 4
    la $a0, QUEBRA_LINHA
    syscall

    li $t9, 0

    lw $t0, LIMITE_SECO
    bge $s0, $t0, check_temp
    
    li $v0, 4
    la $a0, ALERTA_SECO
    syscall
    li $t9, 1

check_temp:
    lw $t0, LIMITE_TEMP
    ble $s1, $t0, check_ph
    
    li $v0, 4
    la $a0, ALERTA_QUENTE
    syscall
    li $t9, 1

check_ph:
    lw $t0, PH_MIN
    lw $t1, PH_MAX
    
    blt $s2, $t0, aviso_acido
    bgt $s2, $t1, aviso_basico
    j fim_analise

aviso_acido:
    li $v0, 4
    la $a0, ALERTA_ACIDO
    syscall
    li $t9, 1
    j fim_analise

aviso_basico:
    li $v0, 4
    la $a0, ALERTA_BASICO
    syscall
    li $t9, 1

fim_analise:
    bne $t9, $zero, encerrar_programa
    
    li $v0, 4
    la $a0, STATUS_OK
    syscall

encerrar_programa:
    li $v0, 10
    syscall
