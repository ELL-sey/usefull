#!/bin/bash

CONFIG_DIR="/home/username/Шаблоны/nmcli/conf_data/.network_profiles"
CONFIG_FILE="$CONFIG_DIR/profiles.conf"
mkdir -p "$CONFIG_DIR"

wofi_dmenu() {
    wofi --dmenu --prompt "$1" 2>/dev/null
}

wofi_msg() {
    notify-send "Сетевые профили" "$1"
}

# Сохранение текущих настроек
save_profile() {
    local profile_name=$(echo "" | wofi_dmenu "Имя профиля:")
    [[ -z "$profile_name" ]] && exit 0

    local interface_name=$(nmcli -t -f NAME,TYPE connection show | grep ethernet | cut -d: -f1 | head -n1)
    [[ -z "$interface_name" ]] && { wofi_msg "Не найдено ethernet-подключение"; exit 1; }

    local ip_addr=$(nmcli -g ip4.address connection show "$interface_name")
    local gateway=$(nmcli -g ip4.gateway connection show "$interface_name")

    if [[ -n "$ip_addr" && -n "$gateway" ]]; then
        echo "$profile_name|$interface_name|$ip_addr|$gateway|" >> "$CONFIG_FILE"
        wofi_msg "$profile_name сохранён"
    else
        wofi_msg "Не удалось получить текущие сетевые настройки"
    fi
}

# Создание нового профиля вручную
create_profile() {
    local profile_name=$(echo "" | wofi_dmenu "Имя профиля:")
    [[ -z "$profile_name" ]] && return

    local interface_name=$(nmcli -t -f NAME,TYPE connection show | grep ethernet | cut -d: -f1 | head -n1)
    [[ -z "$interface_name" ]] && { wofi_msg "Не найдено ethernet-подключение"; return; }

    local ip_addr=$(echo "" | wofi_dmenu "IP адрес/маска (X.X.X.X/Y):")
    [[ -z "$ip_addr" ]] && return

    local gateway=$(echo "" | wofi_dmenu "Шлюз:")
    [[ -z "$gateway" ]] && return

    echo "$profile_name|$interface_name|$ip_addr|$gateway|" >> "$CONFIG_FILE"
    wofi_msg "$profile_name создан"

    nmcli connection modify "$interface_name" ipv4.gateway ""
    nmcli connection modify "$interface_name" ipv4.addresses ""
    nmcli connection modify "$interface_name" ipv4.addresses "$ip_addr"
    nmcli connection modify "$interface_name" ipv4.gateway "$gateway"
    nmcli connection modify "$interface_name" ipv4.method manual
    nmcli connection down "$interface_name"
    nmcli connection up "$interface_name"

    wofi_msg "$profile_name применён ($ip_addr)"

}

# Применение профиля

apply_profile() {
    [[ ! -s "$CONFIG_FILE" ]] && { wofi_msg "Нет сохранённых профилей"; exit 1; }

    # создаём красивый список: "Имя — IP"
    local selection=$(awk -F'|' '{printf "%s — %s\n", $1, $3}' "$CONFIG_FILE" | wofi_dmenu "Выберите профиль:")
    [[ -z "$selection" ]] && exit 0

    # получаем исходную строку из файла по имени профиля
    local profile_name=$(echo "$selection" | awk -F' — ' '{print $1}')
    local profile=$(grep "^$profile_name|" "$CONFIG_FILE")
    [[ -z "$profile" ]] && { wofi_msg "Профиль не найден"; exit 1; }

    IFS='|' read -r profile_name interface_name ip_addr gateway <<< "$profile"

    nmcli connection modify "$interface_name" ipv4.gateway ""
    nmcli connection modify "$interface_name" ipv4.addresses ""
    nmcli connection modify "$interface_name" ipv4.addresses "$ip_addr"
    nmcli connection modify "$interface_name" ipv4.gateway "$gateway"
    nmcli connection modify "$interface_name" ipv4.method manual
    nmcli connection down "$interface_name"
    nmcli connection up "$interface_name"

    wofi_msg "$profile_name применён ($ip_addr)"
}



# Включение DHCP
apply_dhcp() {
    local interface_name=$(nmcli -t -f NAME,TYPE connection show | grep ethernet | cut -d: -f1 | head -n1)
    [[ -z "$interface_name" ]] && { wofi_msg "Не найдено ethernet-подключение"; exit 1; }

    nmcli connection modify "$interface_name" ipv4.method auto
    nmcli connection modify "$interface_name" ipv4.gateway ""
    nmcli connection modify "$interface_name" ipv4.addresses ""
    nmcli connection down "$interface_name"
    nmcli connection up "$interface_name"

    wofi_msg "Профиль переведён в режим DHCP"
}

restart_eth() {
    local interface_name=$(nmcli -t -f NAME,TYPE connection show | grep ethernet | cut -d: -f1 | head -n1)
    nmcli connection down "$interface_name"
    nmcli connection up "$interface_name"
    wofi_msg "Профиль перезапущен"

}

# Удаление профиля
delete_profile() {
    [[ ! -s "$CONFIG_FILE" ]] && { wofi_msg "Нет сохранённых профилей"; exit 1; }

    local profile=$(cat "$CONFIG_FILE" | wofi_dmenu "Удалить профиль:")
    [[ -z "$profile" ]] && exit 0

    grep -vF "$profile" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    wofi_msg "Профиль удалён"
}

# Главное меню
main_menu() {
    local options=(
        "🔧 Применить профиль"
        "📶 DHCP"
        "Рестарт"
        "➕ Создать профиль"
        "🗑️ Удалить профиль"
        "📋 Список профилей"
    )

    local choice=$(printf '%s\n' "${options[@]}" | wofi_dmenu "Управление сетевыми профилями:")

    case "$choice" in
         "💾 Сохранить текущие настройки") save_profile ;;
        "🔧 Применить профиль") apply_profile ;;
        "📶 DHCP") apply_dhcp ;;
        "Рестарт") restart_eth ;;
        "➕ Создать профиль") create_profile ;;
        "🗑️ Удалить профиль") delete_profile ;;
        "📋 Список профилей")
            [[ -s "$CONFIG_FILE" ]] && \
                notify-send "Список профилей" "$(sed 's/|/ - /g' "$CONFIG_FILE")" || \
                wofi_msg "Нет сохранённых профилей"
            ;;
    esac
}

main_menu
