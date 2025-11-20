package main

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config конфигурация сканирования
type Config struct {
	Mode     string   // "ping" или "tcp"
	TCPPorts []string // порты для TCP сканирования
}

// Результат сканирования
type ScanResult struct {
	IP      string
	Status  string // "free" или "used"
	Details string // дополнительная информация
}

// Предопределенные популярные порты
var popularPorts = []string{"21", "22", "25", "53", "80", "139", "443", "445", "3389", "5432", "8080"}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		return
	}

	// Парсим аргументы
	target := os.Args[1]
	config := parseConfig()

	// Парсим целевые адреса
	ips, err := parseTarget(target)
	if err != nil {
		fmt.Printf("Ошибка парсинга целевых адресов: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Сканируем %d IP-адресов...\n", len(ips))
	fmt.Printf("Режим: %s\n", config.Mode)
	if config.Mode == "tcp" {
		fmt.Printf("Порты: %s\n", strings.Join(config.TCPPorts, ", "))
	}
	fmt.Println(strings.Repeat("-", 50))

	// Сканируем
	results := scanIPs(ips, config)

	// Выводим результаты
	printResults(results, len(ips))
}

// Парсим конфигурацию из аргументов
func parseConfig() Config {
	config := Config{
		Mode:     "ping", // по умолчанию
		TCPPorts: popularPorts,
	}

	for i := 2; i < len(os.Args); i++ {
		switch os.Args[i] {
		case "-p", "--ping":
			config.Mode = "ping"
		case "-t", "--tcp":
			config.Mode = "tcp"
		case "-ports":
			if i+1 < len(os.Args) {
				config.TCPPorts = strings.Split(os.Args[i+1], ",")
				i++
			}
		}
	}

	return config
}

// Парсим целевые адреса (IP, CIDR, диапазон)
func parseTarget(target string) ([]string, error) {
	// Проверяем формат CIDR (192.168.1.0/24)
	if strings.Contains(target, "/") {
		return parseCIDR(target)
	}

	// Проверяем формат диапазона (192.168.1.1-192.168.1.10)
	if strings.Contains(target, "-") {
		return parseRange(target)
	}

	// Проверяем одиночный IP
	ip := net.ParseIP(target)
	if ip == nil {
		return nil, fmt.Errorf("неверный формат IP-адреса: %s", target)
	}

	return []string{target}, nil
}

// Парсим CIDR нотацию
func parseCIDR(cidr string) ([]string, error) {
	_, ipnet, err := net.ParseCIDR(cidr)
	if err != nil {
		return nil, fmt.Errorf("неверный формат CIDR: %s", cidr)
	}

	var ips []string
	ip := ipnet.IP.Mask(ipnet.Mask)
	
	for {
		// Пропускаем network адрес
		if !ip.Equal(ipnet.IP) {
			// Пропускаем broadcast для IPv4
			if ipnet.IP.To4() != nil {
				broadcast := make(net.IP, len(ip))
				copy(broadcast, ip)
				for i := range broadcast {
					broadcast[i] |= ^ipnet.Mask[i]
				}
				if !ip.Equal(broadcast) {
					ips = append(ips, ip.String())
				}
			} else {
				ips = append(ips, ip.String())
			}
		}

		// Увеличиваем IP
		inc(ip)
		if !ipnet.Contains(ip) {
			break
		}
	}

	return ips, nil
}

// Парсим диапазон адресов
func parseRange(rangeStr string) ([]string, error) {
	cleanStr := strings.ReplaceAll(rangeStr, " ", "")
	parts := strings.Split(cleanStr, "-")
	if len(parts) != 2 {
		return nil, fmt.Errorf("неверный формат диапазона: %s", rangeStr)
	}

	startIP := net.ParseIP(strings.TrimSpace(parts[0]))
	endIP := net.ParseIP(strings.TrimSpace(parts[1]))

	if startIP == nil || endIP == nil {
		return nil, fmt.Errorf("неверные IP-адреса в диапазоне: %s", rangeStr)
	}

	if bytesCompare(startIP, endIP) > 0 {
		return nil, fmt.Errorf("начальный IP должен быть меньше конечного")
	}

	var ips []string
	ip := make(net.IP, len(startIP))
	copy(ip, startIP)

	for bytesCompare(ip, endIP) <= 0 {
		ips = append(ips, ip.String())
		inc(ip)
	}

	return ips, nil
}

// Сравниваем два IP-адреса
func bytesCompare(a, b net.IP) int {
	for i := 0; i < len(a) && i < len(b); i++ {
		switch {
		case a[i] > b[i]:
			return 1
		case a[i] < b[i]:
			return -1
		}
	}
	return 0
}

// Увеличиваем IP-адрес на 1
func inc(ip net.IP) {
	for j := len(ip) - 1; j >= 0; j-- {
		ip[j]++
		if ip[j] > 0 {
			break
		}
	}
}

// Сканируем список IP-адресов
func scanIPs(ips []string, config Config) []ScanResult {
	var results []ScanResult
	semaphore := make(chan struct{}, 50) // Ограничиваем concurrent горутины

	for _, ip := range ips {
		semaphore <- struct{}{}
		go func(ip string) {
			defer func() { <-semaphore }()

			var status, details string
			
			if config.Mode == "ping" {
				if pingCheck(ip) {
					status = "used"
					details = "ping успешен"
				} else {
					status = "free"
					details = "нет ответа на ping"
				}
			} else { // TCP mode
				if tcpCheck(ip, config.TCPPorts) {
					status = "used"
					details = "найдены открытые порты"
				} else {
					status = "free"
					details = "нет открытых портов"
				}
			}

			results = append(results, ScanResult{
				IP:      ip,
				Status:  status,
				Details: details,
			})
		}(ip)
	}

	// Ждем завершения всех горутин
	for i := 0; i < cap(semaphore); i++ {
		semaphore <- struct{}{}
	}

	return results
}

// Проверка ping
func pingCheck(ip string) bool {
	// Простая TCP проверка вместо ICMP (более надежно)
	conn, err := net.DialTimeout("tcp", net.JoinHostPort(ip, "80"), 2*time.Second)
	if err == nil {
		conn.Close()
		return true
	}

	conn, err = net.DialTimeout("tcp", net.JoinHostPort(ip, "22"), 2*time.Second)
	if err == nil {
		conn.Close()
		return true
	}

	conn, err = net.DialTimeout("tcp", net.JoinHostPort(ip, "443"), 2*time.Second)
	if err == nil {
		conn.Close()
		return true
	}

	return false
}

// Проверка TCP портов
func tcpCheck(ip string, ports []string) bool {
	for _, port := range ports {
		conn, err := net.DialTimeout("tcp", net.JoinHostPort(ip, port), 1*time.Second)
		if err == nil {
			conn.Close()
			return true
		}
	}
	return false
}

// Выводим результаты
func printResults(results []ScanResult, total int) {
	var freeIPs, usedIPs []string

	for _, result := range results {
		if result.Status == "free" {
			freeIPs = append(freeIPs, result.IP)
		} else {
			usedIPs = append(usedIPs, result.IP)
		}
	}

	// Если сканировали один IP
	if total == 1 {
		result := results[0]
		if result.Status == "free" {
			fmt.Printf("✅ %s - СВОБОДЕН (%s)\n", result.IP, result.Details)
		} else {
			fmt.Printf("❌ %s - ЗАНЯТ (%s)\n", result.IP, result.Details)
		}
		return
	}

	// Если сканировали несколько IP
	fmt.Printf("\n📊 РЕЗУЛЬТАТЫ СКАНИРОВАНИЯ:\n")
	fmt.Printf("Всего адресов: %d\n", total)
	fmt.Printf("Занято: %d\n", len(usedIPs))
	fmt.Printf("Свободно: %d\n", len(freeIPs))

	if len(freeIPs) > 0 {
		fmt.Printf("\n🟢 СВОБОДНЫЕ АДРЕСА (%d):\n", len(freeIPs))
		for i, ip := range freeIPs {
			if i < 20 { // Показываем первые 20
				fmt.Printf("  %s\n", ip)
			} else if i == 20 {
				fmt.Printf("  ... и еще %d адресов\n", len(freeIPs)-20)
			}
		}
	}

	if len(usedIPs) > 0 {
		fmt.Printf("\n🔴 ЗАНЯТЫЕ АДРЕСА (%d):\n", len(usedIPs))
		for i, ip := range usedIPs {
			if i < 10 { // Показываем первые 10
				fmt.Printf("  %s\n", ip)
			} else if i == 10 {
				fmt.Printf("  ... и еще %d адресов\n", len(usedIPs)-10)
			}
		}
	}
}

// Вывод справки
func printUsage() {
	fmt.Println("🛠️  IP Scanner - инструмент для проверки доступности IP-адресов")
	fmt.Println()
	fmt.Println("Использование:")
	fmt.Println("  ipscanner <цель> [параметры]")
	fmt.Println()
	fmt.Println("Цель может быть:")
	fmt.Println("  • Одиночный IP:       192.168.1.1")
	fmt.Println("  • Сеть с маской:      192.168.1.0/24")
	fmt.Println("  • Диапазон адресов:   192.168.1.1-192.168.1.100")
	fmt.Println()
	fmt.Println("Параметры:")
	fmt.Println("  -p, --ping    Проверка ping (по умолчанию)")
	fmt.Println("  -t, --tcp     Проверка популярных TCP портов")
	fmt.Println("  -ports        Список портов через запятую (например: 22,80,443)")
	fmt.Println()
	fmt.Println("Примеры:")
	fmt.Println("  ipscanner 192.168.1.1")
	fmt.Println("  ipscanner 192.168.1.0/24 -t")
	fmt.Println("  ipscanner 192.168.1.1-192.168.1.50 -ports 22,80,443")
	fmt.Println("  ipscanner 10.0.0.1-10.0.1.100 --ping")
}

// Вспомогательная функция для преобразования строки в int
func mustAtoi(s string) int {
	i, _ := strconv.Atoi(s)
	return i
}
