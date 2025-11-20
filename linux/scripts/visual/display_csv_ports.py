#!/usr/bin/env python3
import csv
import sys

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'


def grep_ip_in_ports(csv_file, port):
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            data = list(reader)
        
        if not data:
            print("Файл пуст!")
            return
        
        headers = data[0]
        rows = data[1:]
        
        # Находим индекс порта в заголовках
        try:
            port_index = headers.index(port)
        except ValueError:
            print(f"Порт {port} не найден в файле")
            return
        
        print(f"IP-адреса с открытым портом {port}:")
        found = False
        
        for row in rows:
            if not row:
                continue
            
            # Проверяем, что в строке достаточно элементов
            if len(row) > port_index:
                ip = row[0]
                port_status = row[port_index]
                
                if port_status == '1':  # Порт открыт
                    print(ip)
                    found = True
        
        if not found:
            print(f"Нет IP-адресов с открытым портом {port}")
    
    except FileNotFoundError:
        print(f"Файл {csv_file} не найден!")
    except Exception as e:
        print(f"Ошибка: {e}")





    except FileNotFoundError:
        print(f"Файл {csv_file} не найден!")
    except Exception as e:
        print(f"Ошибка: {e}")


def display_port_matrix(csv_file):
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            data = list(reader)
        
        if not data:
            print("Файл пуст!")
            return
        
        headers = data[0]
        rows = data[1:]

        # Определяем ширину колонок
        
        ips_widths = max([len(item[0]) for item in rows])
        col_widths = [max(len(str(item))  for item in col) for col in zip(*data)]
        line_widths = (len(data[0][1:]) + 1) + sum(len(s) for s in data[0][1:])


        print(f"\n{Colors.BOLD}{Colors.BLUE}╔{'═' * (line_widths + ips_widths + 3 )  }╗{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}║ {'МАТРИЦА ПОРТОВ':^{(line_widths + ips_widths + 1 )}} ║{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}╠{'═' * (ips_widths + 2)  }╦{'═' * line_widths }╣{Colors.END}")


        header_line = f"{Colors.BOLD}{Colors.BLUE}║ {Colors.END}{'IP':<{ips_widths}}{Colors.CYAN} │ {Colors.END}"
        for i, header in enumerate(headers[1:], 1):
            header_line += f"{Colors.BOLD}{Colors.YELLOW}{header:^{col_widths[i]}} {Colors.END}"
        print(header_line + f"{Colors.BOLD}{Colors.BLUE}║{Colors.END}")

        print(f"{Colors.BOLD}{Colors.BLUE}╠{'═' * (ips_widths + 2) }╬{'═' * line_widths }╣{Colors.END}")

        #Данные
        for row in rows:
            if not row:
                continue
                
            ip = row[0]
            len_ip = len(ip)
            line = f"{Colors.BOLD}{Colors.BLUE}║ {Colors.END}{ip:<{ips_widths}}{Colors.BOLD}{Colors.CYAN} │ {Colors.END}"

            for i, cell in enumerate(row[1:], 1):
                if cell == '1':  # Открыт
                    line += f"■".center(col_widths[i] + 1)
                elif cell == '2':  # Фильтуется
                    line += f"~".center(col_widths[i] + 1)
                else:  # Закрыт
                    line += f" ".center(col_widths[i] + 1)
            
            line += f"{Colors.BOLD}{Colors.BLUE}║{Colors.END}"
            print(line)

        print(f"{Colors.BOLD}{Colors.BLUE}╚{'═' * (ips_widths + 2) }╩{'═' * line_widths }╝{Colors.END}")

        # Легенда
        print(f"\nЛегенда:{Colors.END}")
        print(f"  ■ - Открыт")
        print(f"  ~ - Фильтруется\n")


    
    except FileNotFoundError:
        print(f"Файл {csv_file} не найден!")
    except Exception as e:
        print(f"Ошибка: {e}")


if __name__ == "__main__":
    if len(sys.argv) == 2:
        # Один аргумент: matrix.csv
        display_port_matrix(sys.argv[1])
    elif len(sys.argv) == 3:
        # Два аргумента: matrix.csv и порт
        grep_ip_in_ports(sys.argv[1], sys.argv[2])
    else:
        print("Использование:")
        print("  python3 display_ports.py matrix.csv          # показать всю матрицу")
        print("  python3 display_ports.py matrix.csv порт     # найти IP с открытым портом")
        sys.exit(1)
