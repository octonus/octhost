#!/bin/bash

# Módulo de Backup para Script OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

# Diretórios padrão
DIR_BACKUP="/var/backups/ocp"
DIR_BACKUP_TEMP="/tmp/ocp_backup"
ARQUIVO_CONFIG_BACKUP="$DIR_CONFIG/backup_config.json"

# Inicializa diretórios de backup
inicializar_backup() {
    criar_diretorio_seguro "$DIR_BACKUP"
    criar_diretorio_seguro "$DIR_BACKUP_TEMP"
    
    # Cria arquivo de configuração se não existir
    if [ ! -f "$ARQUIVO_CONFIG_BACKUP" ]; then
        cat > "$ARQUIVO_CONFIG_BACKUP" << EOF
{
    "backup_diario": false,
    "backup_semanal": true,
    "backup_mensal": true,
    "retencao_diaria": 7,
    "retencao_semanal": 4,
    "retencao_mensal": 3,
    "hora_backup": "02:00",
    "diretorios": [
        "/etc/ocp",
        "/var/lib/docker/volumes"
    ],
    "notificacao_email": true,
    "email_destino": "suporte@octhost.com.br"
}
EOF
    fi
}

# Criar backup
criar_backup() {
    local tipo_backup=${1:-"manual"}
    local descricao=${2:-"Backup manual"}
    local data_hora=$(date +%Y%m%d_%H%M%S)
    local nome_arquivo="backup_${tipo_backup}_${data_hora}.tar.gz"
    
    registrar_mensagem "INFO" "Iniciando backup: $descricao"
    
    # Verifica espaço em disco
    local espaco_livre=$(df -m "$DIR_BACKUP" | awk 'NR==2 {print $4}')
    if [ "$espaco_livre" -lt 1024 ]; then
        registrar_mensagem "ERRO" "Espaço insuficiente para backup"
        return 1
    fi
    
    # Cria diretório temporário
    rm -rf "$DIR_BACKUP_TEMP"
    mkdir -p "$DIR_BACKUP_TEMP"
    
    # Lista de diretórios para backup
    local diretorios=($(jq -r '.diretorios[]' "$ARQUIVO_CONFIG_BACKUP"))
    
    # Backup dos contêineres Docker
    echo -e "${CIANO}Realizando backup dos contêineres...${SEM_COR}"
    docker ps -a --format "{{.Names}}" > "$DIR_BACKUP_TEMP/containers.txt"
    
    # Backup dos volumes Docker
    echo -e "${CIANO}Realizando backup dos volumes...${SEM_COR}"
    for volume in $(docker volume ls -q); do
        docker run --rm -v $volume:/source:ro -v $DIR_BACKUP_TEMP:/backup alpine tar -czf "/backup/${volume}.tar.gz" -C /source .
    done
    
    # Backup das configurações
    echo -e "${CIANO}Realizando backup das configurações...${SEM_COR}"
    for dir in "${diretorios[@]}"; do
        if [ -d "$dir" ]; then
            tar -czf "$DIR_BACKUP_TEMP/$(basename $dir).tar.gz" -C "$(dirname $dir)" "$(basename $dir)"
        fi
    done
    
    # Compacta todos os arquivos
    cd "$DIR_BACKUP_TEMP"
    tar -czf "$DIR_BACKUP/$nome_arquivo" ./*
    
    # Limpa diretório temporário
    rm -rf "$DIR_BACKUP_TEMP"
    
    # Registra metadados do backup
    cat > "$DIR_BACKUP/${nome_arquivo}.meta" << EOF
{
    "tipo": "$tipo_backup",
    "descricao": "$descricao",
    "data": "$(date +%Y-%m-%d\ %H:%M:%S)",
    "tamanho": "$(du -h "$DIR_BACKUP/$nome_arquivo" | cut -f1)"
}
EOF
    
    registrar_mensagem "SUCESSO" "Backup concluído: $nome_arquivo"
    echo -e "${VERDE}Backup criado com sucesso: $nome_arquivo${SEM_COR}"
    
    # Envia notificação por email se configurado
    if [ "$(jq -r '.notificacao_email' "$ARQUIVO_CONFIG_BACKUP")" = "true" ]; then
        notificar_backup_email "$nome_arquivo"
    fi
    
    return 0
}

# Restaurar backup
restaurar_backup() {
    echo -e "${BRANCO}Backups Disponíveis:${SEM_COR}"
    listar_backups
    
    read -p "Digite o nome do backup para restaurar: " nome_backup
    
    if [ ! -f "$DIR_BACKUP/$nome_backup" ]; then
        registrar_mensagem "ERRO" "Backup não encontrado: $nome_backup"
        return 1
    fi
    
    if ! confirmar_acao "ATENÇÃO: A restauração irá sobrescrever dados existentes. Deseja continuar?"; then
        return 0
    fi
    
    registrar_mensagem "INFO" "Iniciando restauração do backup: $nome_backup"
    
    # Cria diretório temporário
    rm -rf "$DIR_BACKUP_TEMP"
    mkdir -p "$DIR_BACKUP_TEMP"
    
    # Extrai backup
    tar -xzf "$DIR_BACKUP/$nome_backup" -C "$DIR_BACKUP_TEMP"
    
    # Restaura volumes Docker
    echo -e "${CIANO}Restaurando volumes Docker...${SEM_COR}"
    for volume_file in "$DIR_BACKUP_TEMP"/*.tar.gz; do
        if [ -f "$volume_file" ]; then
            volume_name=$(basename "$volume_file" .tar.gz)
            docker volume create "$volume_name" 2>/dev/null
            docker run --rm -v "$volume_name":/dest -v "$DIR_BACKUP_TEMP":/backup alpine sh -c "cd /dest && tar -xzf /backup/$(basename $volume_file)"
        fi
    done
    
    # Restaura configurações
    echo -e "${CIANO}Restaurando configurações...${SEM_COR}"
    for config in $(jq -r '.diretorios[]' "$ARQUIVO_CONFIG_BACKUP"); do
        if [ -f "$DIR_BACKUP_TEMP/$(basename $config).tar.gz" ]; then
            mkdir -p "$(dirname $config)"
            tar -xzf "$DIR_BACKUP_TEMP/$(basename $config).tar.gz" -C "$(dirname $config)"
        fi
    done
    
    # Limpa diretório temporário
    rm -rf "$DIR_BACKUP_TEMP"
    
    registrar_mensagem "SUCESSO" "Restauração concluída: $nome_backup"
    echo -e "${VERDE}Restauração concluída com sucesso${SEM_COR}"
    
    return 0
}

# Configurar agendamento de backup
configurar_agendamento_backup() {
    while true; do
        clear
        echo -e "${BRANCO}Configuração de Agendamento de Backup${SEM_COR}"
        echo "1) Configurar Backup Diário"
        echo "2) Configurar Backup Semanal"
        echo "3) Configurar Backup Mensal"
        echo "4) Configurar Retenção"
        echo "5) Configurar Notificações"
        echo "6) Voltar"
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1) configurar_backup_diario ;;
            2) configurar_backup_semanal ;;
            3) configurar_backup_mensal ;;
            4) configurar_retencao ;;
            5) configurar_notificacoes ;;
            6) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

# Configurar backup diário
configurar_backup_diario() {
    local status_atual=$(jq -r '.backup_diario' "$ARQUIVO_CONFIG_BACKUP")
    local hora_atual=$(jq -r '.hora_backup' "$ARQUIVO_CONFIG_BACKUP")
    
    echo -e "Status atual: $([ "$status_atual" == "true" ] && echo "Ativado" || echo "Desativado")"
    echo -e "Hora atual: $hora_atual"
    
    read -p "Ativar backup diário? (s/n): " ativar
    if [[ ${ativar,,} == "s" ]]; then
        read -p "Digite a hora do backup (HH:MM): " nova_hora
        
        # Atualiza configuração
        jq ".backup_diario = true | .hora_backup = \"$nova_hora\"" "$ARQUIVO_CONFIG_BACKUP" > temp.json && mv temp.json "$ARQUIVO_CONFIG_BACKUP"
        
        # Atualiza crontab
        (crontab -l 2>/dev/null | grep -v "ocp_backup_diario") | crontab -
        echo "0 ${nova_hora%%:*} * * * $DIR_TRABALHO/setup.sh backup diario" | crontab -
        
        registrar_mensagem "SUCESSO" "Backup diário configurado para $nova_hora"
    else
        jq '.backup_diario = false' "$ARQUIVO_CONFIG_BACKUP" > temp.json && mv temp.json "$ARQUIVO_CONFIG_BACKUP"
        (crontab -l 2>/dev/null | grep -v "ocp_backup_diario") | crontab -
        registrar_mensagem "INFO" "Backup diário desativado"
    fi
}

# Listar backups
listar_backups() {
    echo -e "${CIANO}Backups disponíveis:${SEM_COR}"
    echo -e "----------------------------------------"
    printf "%-30s %-20s %-15s %s\n" "ARQUIVO" "DATA" "TAMANHO" "TIPO"
    echo -e "----------------------------------------"
    
    for meta in "$DIR_BACKUP"/*.meta; do
        if [ -f "$meta" ]; then
            local arquivo=$(basename "${meta%.meta}")
            local data=$(jq -r '.data' "$meta")
            local tamanho=$(jq -r '.tamanho' "$meta")
            local tipo=$(jq -r '.tipo' "$meta")
            printf "%-30s %-20s %-15s %s\n" "$arquivo" "$data" "$tamanho" "$tipo"
        fi
    done
    
    echo -e "----------------------------------------"
}

# Limpar backups antigos
limpar_backups_antigos() {
    local retencao_diaria=$(jq -r '.retencao_diaria' "$ARQUIVO_CONFIG_BACKUP")
    local retencao_semanal=$(jq -r '.retencao_semanal' "$ARQUIVO_CONFIG_BACKUP")
    local retencao_mensal=$(jq -r '.retencao_mensal' "$ARQUIVO_CONFIG_BACKUP")
    
    registrar_mensagem "INFO" "Iniciando limpeza de backups antigos"
    
    # Remove backups diários antigos
    find "$DIR_BACKUP" -name "backup_diario_*.tar.gz" -mtime +$retencao_diaria -delete
    find "$DIR_BACKUP" -name "backup_diario_*.meta" -mtime +$retencao_diaria -delete
    
    # Remove backups semanais antigos
    find "$DIR_BACKUP" -name "backup_semanal_*.tar.gz" -mtime +$((retencao_semanal * 7)) -delete
    find "$DIR_BACKUP" -name "backup_semanal_*.meta" -mtime +$((retencao_semanal * 7)) -delete
    
    # Remove backups mensais antigos
    find "$DIR_BACKUP" -name "backup_mensal_*.tar.gz" -mtime +$((retencao_mensal * 30)) -delete
    find "$DIR_BACKUP" -name "backup_mensal_*.meta" -mtime +$((retencao_mensal * 30)) -delete
    
    registrar_mensagem "SUCESSO" "Limpeza de backups antigos concluída"
}

# Notificar backup por email
notificar_backup_email() {
    local arquivo=$1
    local email_destino=$(jq -r '.email_destino' "$ARQUIVO_CONFIG_BACKUP")
    local meta_file="$DIR_BACKUP/${arquivo}.meta"
    
    if [ -f "$meta_file" ]; then
        local data=$(jq -r '.data' "$meta_file")
        local tamanho=$(jq -r '.tamanho' "$meta_file")
        local tipo=$(jq -r '.tipo' "$meta_file")
        
        local mensagem="Backup OCP concluído\n\n"
        mensagem+="Arquivo: $arquivo\n"
        mensagem+="Tipo: $tipo\n"
        mensagem+="Data: $data\n"
        mensagem+="Tamanho: $tamanho\n"
        
        echo -e "$mensagem" | mail -s "Backup OCP Concluído - $tipo" "$email_destino"
    fi
}

# Inicialização do módulo
inicializar_backup_module() {
    inicializar_backup
    registrar_mensagem "INFO" "Módulo de backup inicializado"
}
