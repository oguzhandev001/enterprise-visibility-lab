cd  C:\Users\Windows\Desktop\
echo "=============== System Report Document =============== " > system-report.txt
echo "=============== PROCESSES ===============" >> system-report.txt
Get-Process >> system-report.txt
echo "=============== CONNECTIONS ===============" >> system-report.txt
Get-NetTCPConnection >> system-report.txt
echo "=============== USERS ===============" >> system-report.txt
Get-LocalUser >> system-report.txt
echo "=============== SYSTEM INFO ===============" >> system-report.txt
Get-ComputerInfo >> system-report.txt
Read-Host -Prompt "Rapor yazildi. Kapatmak icin bir tusa basin."