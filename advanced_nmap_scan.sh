#!/bin/bash

# ============================================
# Advanced Nmap Scanner + Enumeration Tool
# Author: Sagar
# Purpose: Scanning, OS Detection, Enumeration, HTML Report
# ============================================

echo "============================================"
echo "           Created By Nautiyal G "
echo "        ADVANCED NMAP SCANNER TOOL"
echo "============================================"

# --------- USER INPUT ----------
read -p "Enter target IP: " target
read -p "Enter port range (e.g., 1-1000 or 80,443): " ports

echo ""
echo "Select scanning technique:"
echo "1) TCP Connect Scan (-sT)"
echo "2) SYN Stealth Scan (-sS)"
echo "3) UDP Scan (-sU)"
echo "4) Service Version Detection (-sV)"
echo "5) Aggressive Scan (-A)"
echo "6) Custom Nmap Command"
read -p "Choose option [1-6]: " choice

# --------- SCAN SELECTION ----------
case $choice in
    1) scan="nmap -sT -p $ports $target" ;;
    2) scan="nmap -sS -p $ports $target" ;;
    3) scan="nmap -sU -p $ports $target" ;;
    4) scan="nmap -sV -p $ports $target" ;;
    5) scan="nmap -A -p $ports $target" ;;
    6)
        echo "Enter your custom Nmap command"
        echo "Use {IP} for target and {PORTS} for ports"
        read custom_cmd
        scan=$(echo "$custom_cmd" | sed "s/{IP}/$target/g; s/{PORTS}/$ports/g")
        ;;
    *)
        echo "Invalid choice! Exiting."
        exit 1
        ;;
esac

# --------- OUTPUT FILES ----------
outfile="scan_result.txt"
openfile="open_ports.txt"
enumfile="enum_results.txt"
htmlfile="scan_report.html"

# --------- RUN SCAN ----------
echo ""
echo "[+] Running Scan:"
echo "$scan"
$scan -oN "$outfile"

# --------- OS DETECTION ----------
echo ""
echo "[+] Running OS Detection..."
nmap -O "$target" >> "$outfile"

# --------- EXTRACT OPEN PORTS ----------
echo ""
echo "[+] Extracting open ports and services..."
grep "open" "$outfile" | awk '{print $1, $3}' > "$openfile"

if [ ! -s "$openfile" ]; then
    echo "[-] No open ports found."
    exit
fi

echo ""
echo "================ OPEN PORTS ================"
cat "$openfile"
echo "==========================================="

# --------- ENUMERATION MENU ----------
read -p "Do you want to perform ENUMERATION? (y/n): " enum

if [[ "$enum" == "y" || "$enum" == "Y" ]]; then

    echo ""
    echo "Select Enumeration Type:"
    echo "1) FTP"
    echo "2) SSH"
    echo "3) HTTP"
    echo "4) SMB"
    echo "5) All Services"
    read -p "Choose option [1-5]: " enum_choice

    > "$enumfile"

    while read -r line; do
        port=$(echo "$line" | awk -F/ '{print $1}')
        service=$(echo "$line" | awk '{print $2}')

        case $enum_choice in
            1)
                if [[ "$service" == "ftp" ]]; then
                    echo "[+] Enumerating FTP on port $port"
                    nmap --script=ftp* -p "$port" "$target" >> "$enumfile"
                fi
                ;;
            2)
                if [[ "$service" == "ssh" ]]; then
                    echo "[+] Enumerating SSH on port $port"
                    nmap --script=ssh* -p "$port" "$target" >> "$enumfile"
                fi
                ;;
            3)
                if [[ "$service" == "http" || "$service" == "https" ]]; then
                    echo "[+] Enumerating HTTP on port $port"
                    nmap --script=http* -p "$port" "$target" >> "$enumfile"
                fi
                ;;
            4)
                if [[ "$service" == "smb" || "$service" == "microsoft-ds" ]]; then
                    echo "[+] Enumerating SMB on port $port"
                    nmap --script=smb* -p "$port" "$target" >> "$enumfile"
                fi
                ;;
            5)
                echo "[+] Enumerating $service on port $port"
                nmap --script="${service}*" -p "$port" "$target" >> "$enumfile"
                ;;
        esac

    done < "$openfile"

    echo ""
    echo "============= ENUMERATION RESULTS ==========="
    cat "$enumfile"
    echo "============================================"

else
    echo "[-] Enumeration skipped."
fi

# --------- HTML REPORT ----------
echo ""
read -p "Do you want to generate HTML report? (y/n): " html

if [[ "$html" == "y" || "$html" == "Y" ]]; then
    echo "[+] Generating HTML report..."
    nmap -p "$ports" "$target" -oX scan.xml
    xsltproc scan.xml -o "$htmlfile"
    echo "[+] HTML report saved as: $htmlfile"
fi

echo ""
echo "=========== SCAN COMPLETED ==========="
echo "Text Report : $outfile"
echo "Open Ports  : $openfile"
echo "Enum Result : $enumfile"
echo "HTML Report : $htmlfile"
echo "====================================="
