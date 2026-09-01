# Enterprise Endpoint and Network Visibility Lab

🇬🇧 [English](README.md) | 🇹🇷 Türkçe

Küçük ölçekli bir kurumsal ortamı simüle eden, Windows ve Linux sistemlerinden uçtan uca **görünürlük** (visibility) verisi toplayıp analiz eden bir Blue Team lab projesi. Amaç sadece log/trafik üretmek değil — üretilen her sinyali gerçekten okuyup yorumlayabilmek ve görünürlükteki (audit policy, log altyapısı gibi) gerçek boşlukları tespit edebilmek.

## Lab Topolojisi

Ağ modu: **Host-Only** (izole, internet erişimi yok), subnet `10.10.10.0/24`.

```
                        10.10.10.0/24
                      VLAN 1 (Host-Only)
                             |
        +-----------+-----------+-----------+
        |           |           |           |
   10.10.10.10  10.10.10.20 10.10.10.100 10.10.10.101
   DC (Win Srv) Ubuntu Srv  Win 11 Client    Kali
```

| Rol              | Hostname        | IP           | Gateway     |
|-------------------|-----------------|--------------|-------------|
| Gateway (host)     | —               | 10.10.10.1   | —           |
| DC (Windows Srv)   | WIN-3GTJDFSUSVD | 10.10.10.10  | 10.10.10.1  |
| Linux (Ubuntu)     | ubuntu          | 10.10.10.20  | 10.10.10.1  |
| Client (Win 11)    | —               | 10.10.10.100 | 10.10.10.1  |
| Kali               | kali            | 10.10.10.101 | 10.10.10.1  |

Kurulum detayları ve altyapı sorun/çözümleri: [`docs/tr/LAB-SETUP.md`](docs/tr/LAB-SETUP.md)

## Kapsam

| Bileşen | Ne yapıldı |
|---|---|
| **Network Traffic Analysis** | Wireshark ile TCP handshake, HTTP trafiği ve DNS sorgusu analizi — hem başarısız (troubleshooting) hem başarılı senaryo |
| **Windows Event Log Analysis** | Kullanıcı oluşturma/silme ve başarısız logon event'lerinin (4720/4625/4726) üretilmesi ve alan bazında incelenmesi |
| **Linux Log Analysis** | SSH servisine karşı başarısız kimlik doğrulama denemesi, journald üzerinden inceleme |
| **PowerShell Collection** | Process, network connection, local user ve sistem bilgisini tek script'te toplayan otomasyon |
| **Investigation Checklist** | ANLA / KARAR VER / DEVRET akışına dayanan, bu projenin telemetri türlerine uyarlanmış triage rehberi |
| **Normal vs Suspicious** | Her telemetri türü için normal davranışla şüpheli davranışın karşılaştırması |

Detaylı bulgular ve troubleshooting anlatısı: [`docs/tr/FINDINGS.md`](docs/tr/FINDINGS.md)
Investigation checklist: [`docs/tr/INVESTIGATION-CHECKLIST.md`](docs/tr/INVESTIGATION-CHECKLIST.md)
Normal vs Suspicious karşılaştırması: [`docs/tr/NORMAL-VS-SUSPICIOUS.md`](docs/tr/NORMAL-VS-SUSPICIOUS.md)

## Öne Çıkan Bulgular

- Kapalı bir porta gelen TCP SYN'e sistemin **aktif** `RST,ACK` ile cevap verdiğini, bunun bir firewall'ın sessiz paket düşürmesinden (drop) farklı bir davranış olduğunu doğrudan gözlemleyerek ayırt ettim.
- Windows'un başarısız logon event'lerinde (`%%2313`) kullanıcı adı/parola hatasını **bilerek belirsiz bıraktığını**, buna karşın Linux/PAM'ın "invalid user" ile bunu açıkça belirttiğini karşılaştırdım — ve bunun bir güvenlik açığı değil, görünürlük/log-erişim meselesi olduğunu ayırt ettim.
- Bir event'in **üretilmesi** ile o event'in **görülebilir olması** arasındaki farkı — Windows'ta Audit Policy, Linux'ta rsyslog/journald ayrımı üzerinden — pratik olarak yaşadım.

## Kullanılan Araçlar

VMware · Wireshark · Windows Event Viewer · `journalctl` / systemd-journald · PowerShell · OpenSSH

## Evidence

Ham kanıt dosyaları [`evidence/`](evidence/) klasöründe:

| Dosya | İçerik |
|---|---|
| `network-capture.pcapng` | Wireshark ile alınan network capture (RST/ACK troubleshooting + başarılı handshake) |
| `system-report-script.ps1` | PowerShell collection script'inin kendisi |
| `system-report.txt` | Script'in ürettiği tam çıktı (process/connection/user/sistem bilgisi) |
| `ssh_logs.txt` | Kali'de `journalctl -u ssh` çıktısı — başarısız SSH denemesi |
