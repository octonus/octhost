#!/bin/bash

# Módulo de Menu para Script OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

menu_configuracao_sistema() {
    while true; do
        exibir_menu "Configuração do Sistema" \
            "Atualizar Sistema" \
            "Configurar Fuso Horário" \
            "Configurar Nome do Host" \
            "Configurar Rede" \
            "Configurar Firewall" \
            "Voltar ao Menu Principal"
        case $? in
            1) atualizar_sistema ;;
            2) configurar_fuso_horario ;;
            3) configurar_hostname ;;
            4) configurar_rede ;;
            5) configurar_firewall ;;
            6) return ;;
        esac
    done
}

menu_docker() {
    while true; do
        exibir_menu "Gerenciamento Docker" \
            "Instalar Docker" \
            "Configurar Docker" \
            "Gerenciar Contêineres" \
            "Gerenciar Redes" \
            "Gerenciar Volumes" \
            "Atualizar Docker" \
            "Voltar ao Menu Principal"
        case $? in
            1) instalar_docker ;;
            2) configurar_docker ;;
            3) gerenciar_conteineres ;;
            4) gerenciar_redes_docker ;;
            5) gerenciar_volumes_docker ;;
            6) atualizar_docker ;;
            7) return ;;
        esac
    done
}

menu_instalacao_apps() {
    while true; do
        exibir_menu "Instalação de Aplicações" \
            "Instalar Traefik" \
            "Instalar Portainer" \
            "Instalar Stack de Monitoramento" \
            "Instalar Banco de Dados" \
            "Instalar Chatwoot" \
            "Instalar N8N" \
            "Instalar TypeBot" \
            "Voltar ao Menu Principal"
        case $? in
            1) instalar_traefik ;;
            2) instalar_portainer ;;
            3) instalar_monitoramento ;;
            4) menu_banco_dados ;;
            5) instalar_chatwoot ;;
            6) instalar_n8n ;;
            7) instalar_typebot ;;
            8) return ;;
        esac
    done
}

menu_banco_dados() {
    while true; do
        exibir_menu "Instalação de Banco de Dados" \
            "Instalar PostgreSQL" \
            "Instalar MySQL" \
            "Instalar Redis" \
            "Instalar MongoDB" \
            "Voltar ao Menu de Instalação"
        case $? in
            1) instalar_postgresql ;;
            2) instalar_mysql ;;
            3) instalar_redis ;;
            4) instalar_mongodb ;;
            5) return ;;
        esac
    done
}

menu_seguranca() {
    while true; do
        exibir_menu "Configuração de Segurança" \
            "Configurar Firewall" \
            "Gerenciar Certificados SSL" \
            "Configurar Backup Automático" \
            "Auditoria de Segurança" \
            "Gerenciar Senhas" \
            "Voltar ao Menu Principal"
        case $? in
            1) configurar_firewall ;;
            2) gerenciar_ssl ;;
            3) configurar_backup_automatico ;;
            4) auditoria_seguranca ;;
            5) gerenciar_senhas ;;
            6) return ;;
        esac
    done
}

menu_backup() {
    while true; do
        exibir_menu "Backup e Restauração" \
            "Criar Backup" \
            "Restaurar Backup" \
            "Configurar Agendamento" \
            "Listar Backups" \
            "Limpar Backups Antigos" \
            "Voltar ao Menu Principal"
        case $? in
            1) criar_backup ;;
            2) restaurar_backup ;;
            3) configurar_agendamento_backup ;;
            4) listar_backups ;;
            5) limpar_backups_antigos ;;
            6) return ;;
        esac
    done
}

mostrar_status_sistema() {
    clear
    echo -e "${BRANCO}Status do Sistema${SEM_COR}"
    echo -e "${CIANO}----------------------------------------${SEM_COR}"
    echo -e "Uso de CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo -e "Uso de Memória: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
    echo -e "Uso de Disco: $(df -h / | awk 'NR==2{print $5}')"
    echo -e "Status do Docker: $(systemctl is-active docker)"
    echo -e "Contêineres Ativos: $(docker ps -q | wc -l 2>/dev/null || echo 'Docker não instalado')"
    echo -e "${CIANO}----------------------------------------${SEM_COR}"
    
    read -p "Pressione Enter para continuar..."
}
