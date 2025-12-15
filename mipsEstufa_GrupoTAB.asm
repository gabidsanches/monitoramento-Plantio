.data

    historico_umid: .word 50, 50, 50, 50, 50
    indice_atual:   .word 0
    tam_vetor:      .word 5
    LIMITE_SECO:    .word 40
    LIMITE_TEMP:    .word 30
    PH_MIN:         .word 6
    PH_MAX:         .word 8

    MSG_INICIO:     .asciiz "\n=== ESTUFA INTELIGENTE ===\n"

    # --- STRINGS PARA FORMATACAO ---
    STR_CICLO:       .asciiz "\n--------------------------\nCiclo "
    STR_HORARIO:     .asciiz ", Horario : "
    STR_DOIS_PONTOS: .asciiz ":"
    STR_H:           .asciiz "h\n"
    # -------------------------------

    MSG_MEDIA:      .asciiz "   [INFO] Media Movel UMID: "
    PULA_LINHA:     .asciiz "\n"

    ASK_UMID:       .asciiz "Digite a UMIDADE do solo (0-100): "
    ASK_TEMP:       .asciiz "Digite a TEMPERATURA (C): "
    ASK_PH:         .asciiz "Digite o pH do solo (0-14): "
    ASK_CICLOS:     .asciiz "Digite quantos ciclos de leitura: "

    # --- FASE E STATUS DA LUZ ---
    ASK_FASE:       .asciiz "digite 0  para fase vegetativa ou 1 para fase de floracao: "
    MSG_LUZ:        .asciiz "   [LUZ] "
    MSG_LUZ_ON:     .asciiz "LIGADA\n"
    MSG_LUZ_OFF:    .asciiz "DESLIGADA\n"
    # -------------------------------

    ALERTA_SECO:    .asciiz "   [ACAO] BOMBA LIGADA\n"
    ALERTA_QUENTE:  .asciiz "   [ACAO] VENTOINHA LIGADA\n"
    ALERTA_ACIDO:   .asciiz "   [ALERTA] CORRETOR DE pH (Acido)\n"
    ALERTA_BASICO:  .asciiz "   [ALERTA] CORRETOR DE pH (Basico)\n"
    STATUS_OK:      .asciiz "   [STATUS] Parametros Normais. Standby.\n"
    MSG_FIM:        .asciiz "\n=== FIM DO MONITORAMENTO ===\n"

.text
.globl main

main:
    li $v0, 4
    la $a0, MSG_INICIO
    syscall

    # === INICIALIZACAO DO CONTADOR ===
    li $s7, 0              # $s7 é o contador (i)

    # === LEITURA DE CICLOS ===
    li $v0, 4
    la $a0, ASK_CICLOS
    syscall

    li $v0, 5
    syscall
    move $s6, $v0           # $s6 = TOTAL DE CICLOS

    # === NOVO: LER FASE (0 vegetativa, 1 floracao) ===
    li $v0, 4
    la $a0, ASK_FASE
    syscall

    li $v0, 5
    syscall
    move $s4, $v0           # $s4 = fase (0 ou 1)

    # === NOVO: DEFINIR HORAS DE LUZ (em minutos) ===
    # Vegetativa: 18h luz = 1080 min
    # Floracao:   12h luz =  720 min
    beq $s4, $zero, fase_veg

fase_flor:
    li $s5, 720             # $s5 = minutos_luz
    j fase_ok

fase_veg:
    li $s5, 1080            # $s5 = minutos_luz

fase_ok:
    li $v0, 4
    la $a0, PULA_LINHA
    syscall

# Loop Principal
main_loop:
    bne $s7, $s6, continue_loop
    j encerrar_programa

continue_loop:

    # === IMPRESSAO DO CICLO E HORARIO (ROBUSTO) ===

    # 1) "Ciclo "
    li $v0, 4
    la $a0, STR_CICLO
    syscall

    # 2) numero do ciclo (i + 1)
    addi $t0, $s7, 1        # t0 = cicloAtual
    li $v0, 1
    move $a0, $t0
    syscall

    # 3) ", Horario : "
    li $v0, 4
    la $a0, STR_HORARIO
    syscall

    # 4) tempo_min = ((cicloAtual) * 1440) / total_ciclos
    li  $t1, 1440
    mul $t2, $t0, $t1       # t2 = cicloAtual * 1440
    div $t2, $s6
    mflo $t2                # t2 = tempo_atual_em_minutos (0..1440)

    # horas = t2 / 60, minutos = t2 % 60
    li  $t3, 60
    div $t2, $t3
    mflo $t4                # t4 = horas
    mfhi $t5                # t5 = minutos

    # imprime horas
    li $v0, 1
    move $a0, $t4
    syscall

    # imprime ":"
    li $v0, 4
    la $a0, STR_DOIS_PONTOS
    syscall

    # imprime minutos com zero à esquerda
    li  $t6, 10
    blt $t5, $t6, print_zero
    j   print_min

print_zero:
    li $v0, 1
    li $a0, 0
    syscall

print_min:
    li $v0, 1
    move $a0, $t5
    syscall

    # imprime "h\n"
    li $v0, 4
    la $a0, STR_H
    syscall

    # === EXIBIR SE A LUZ ESTA LIGADA OU DESLIGADA ===
    li $v0, 4
    la $a0, MSG_LUZ
    syscall

    ble $t2, $s5, luz_on

luz_off:
    li $v0, 4
    la $a0, MSG_LUZ_OFF
    syscall
    j sensores

luz_on:
    li $v0, 4
    la $a0, MSG_LUZ_ON
    syscall

sensores:
    # --- 1. LEITURA DOS SENSORES ---
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

    # --- 2. ATUALIZAR VETOR ---
    lw $t0, indice_atual
    sll $t1, $t0, 2

    la  $t2, historico_umid
    add $t2, $t2, $t1
    sw  $s0, 0($t2)

    # Atualiza Indice Circular
    addi $t0, $t0, 1
    lw   $t3, tam_vetor
    div $t0, $t3
    mfhi $t0
    sw  $t0, indice_atual

    # --- 3. CALCULAR MEDIA ---
    la $a0, historico_umid
    lw $a1, tam_vetor
    jal calcular_media
    move $s3, $v0

    # === IMPRIMIR A MEDIA ===
    li $v0, 4
    la $a0, MSG_MEDIA
    syscall

    li $v0, 1
    move $a0, $s3
    syscall

    li $v0, 4
    la $a0, PULA_LINHA
    syscall

    # --- 4. LOGICA DE DECISAO ---
    li $t9, 0

    lw $t0, LIMITE_SECO
    bge $s3, $t0, check_temp

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
    bne $t9, $zero, proxima_iteracao
    li $v0, 4
    la $a0, STATUS_OK
    syscall

proxima_iteracao:
    addi $s7, $s7, 1
    j main_loop
    

calcular_media:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $t0, 12($sp)

    move $s0, $zero
    move $s1, $zero

loop_soma:
    bge $s1, $a1, fim_media

    sll $t0, $s1, 2
    add $t1, $a0, $t0
    lw  $t2, 0($t1)

    add $s0, $s0, $t2
    addi $s1, $s1, 1
    j loop_soma

fim_media:
    div $s0, $a1
    mflo $v0

    lw $t0, 12($sp)
    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra

encerrar_programa:
    li $v0, 4
    la $a0, MSG_FIM
    syscall
    li $v0, 10
    syscall
