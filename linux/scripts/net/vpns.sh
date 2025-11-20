#!/bin/bash

# Массив VPN
VPNS=(
    "h:home:Дом:"
    "r:...:....:2"
    .......

)


declare -A TAG_EMOJI=(
  [2]="🔐"
  [3]="🏠"
  [4]="🌍"
)

LINE_WIDTH=50

emoji_for_tag() {
  local tag=$1 e=""
  for ((i=0; i<${#tag}; i++)); do
    e+="${TAG_EMOJI[${tag:i:1}]:-❓}"
  done
  echo "$e"
}

mapfile -t ACTIVE < <(nmcli -t -f NAME connection show --active)

vpn_status() {
    nmcli -g GENERAL.STATE connection show "$1" 2>/dev/null | grep -q "activated"
}

is_active() {
  local name=$1
  for v in "${ACTIVE[@]}"; do [[ $v == "$name" ]] && return 0; done
  return 1
}


format_line() {
    local vstatus="$1"
    local vdesc="$2"
    local vkey="$3"
    local vemoji="$4"
    local emoji_len=0
    if [[ -n "$vemoji" ]]; then
        emoji_len=3  # визуальная ширина смайла
    fi

    local sum_len=$(( 
        ${#vstatus} + 1 +
        ${#vdesc} + 2 +
        emoji_len + 
        2 + ${#vkey} + 2
    ))


    local res_tab=$((LINE_WIDTH - sum_len))
    if (( res_tab < 1 )); then
        res_tab=1
    fi

    if [[ -n "$vemoji" ]]; then
        printf "%s %s %s%*s[%s]\n" "$vstatus" "$vdesc" "$vemoji" "$res_tab" "" "$vkey"
    else
        printf "%s %s%*s[%s]\n" "$vstatus" "$vdesc" "$res_tab" "" "$vkey"
    fi
}


# Формирование меню
KEYS_MENU=( "🆇 Отключить все ВПН$(printf '%*s' $((LINE_WIDTH-25)))[0]" )
for vpn in "${VPNS[@]}"; do
  IFS=: read -r key name desc tags <<< "$vpn"
  emoji=$(emoji_for_tag "$tags")
  if is_active "$name"; then
    KEYS_MENU+=( "$(format_line "✅" "$desc" "$key" "$emoji")" )
  else
    KEYS_MENU+=( "$(format_line "❌" "$desc" "$key" "$emoji")" )
  fi
done


SELECTED_LINE=$(printf "%s\n" "${KEYS_MENU[@]}" | wofi --dmenu  --prompt "Выберите VPN" --width 400 --height 450)
[[ -z "$SELECTED_LINE" ]] && exit 0
#  Извлечение ключа из конца строки
SELECTED_KEY=$(echo "$SELECTED_LINE" | grep -o '\[[^]]\]' | tr -d '[]')



# Обработка выбора
if [[ "$SELECTED_KEY" == "0" ]]; then
    echo "Обработка выбора"
    for vpn in "${VPNS[@]}"; do
        IFS=':' read -r key name desc tags <<< "$vpn"
        nmcli connection down "$name" >/dev/null 2>&1
    done
    notify-send "VPN" "Все VPN отключены" -i network-vpn
else
  echo "else not off"
    for vpn in "${VPNS[@]}"; do
        IFS=':' read -r key name desc tags <<< "$vpn"
        if [[ "$key" == "$SELECTED_KEY" ]]; then
            if vpn_status "$name"; then
                echo "down"
                nmcli connection down "$name"
                notify-send "VPN" "Отключено: ${desc}" -i network-vpn-off
            else
                echo "up"
                nmcli connection up "$name"
                notify-send "VPN" "Подключено: ${desc}" -i network-vpn
            fi
            break
        fi
    done
fi

