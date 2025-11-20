#!/usr/bin/env python3
import json
import csv
from collections import defaultdict
import re
import sys


def convert_js_csv(js_file, new_csv_file):
    try:

        # Чтение JSON файла
        with open('scan.json', 'r') as f:
            data = json.load(f)

        # Собираем все порты и хосты
        hosts_ports = defaultdict(dict)
        all_ports = set()

        for item in data:
            ip = item['ip']
            for port_info in item['ports']:
                port = port_info['port']
                status = port_info['status']
                all_ports.add(port)
                hosts_ports[ip][port] = status


        def natural_sort_key(s):
            """Ключ для естественной сортировки"""
            return [int(text) if text.isdigit() else text.lower() 
                    for text in re.split(r'(\d+)', s)]

        sorted_ips = sorted(hosts_ports.keys(), key=natural_sort_key)
        # Сортируем порты
        all_ports = sorted(all_ports)
        # Создаем CSV файл
        with open(new_csv_file, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            
            # Заголовок
            header = ['IP'] + [str(port) for port in all_ports]
            writer.writerow(header)
            
            # Данные
            for ip in sorted_ips:
                row = [ip]
                for port in all_ports:
                    status = hosts_ports[ip].get(port)
                    if status == 'open':
                        row.append('1')
                    elif status == 'filtered':
                        row.append('2')
                    else:
                        row.append('3')  

                writer.writerow(row)

    except FileNotFoundError:
        print(f"Файл {js_file} не найден!")
    except Exception as e:
        print(f"Ошибка: {e}")

if __name__ == "__main__":
    if len(sys.argv) == 2:
        print(f"Использование: python3 in_file.js out_file.csv")
        sys.exit(1)
    
    convert_js_csv(sys.argv[1],sys.argv[2])

print(f"Матрица создана: {sys.argv[2]}")
