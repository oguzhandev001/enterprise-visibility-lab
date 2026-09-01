# Findings

Bu doküman, her görünürlük bileşeni için yapılan işi, karşılaşılan gerçek sorunları ve bunlardan çıkarılan sonuçları anlatır.

## 1. Network Traffic Analysis

**Araç:** Wireshark (capture filtreleri: `tcp`, `udp`) · **Kaynak:** Kali (10.10.10.101) üzerinde `python3 -m http.server` · **Test istemcisi:** Windows client (10.10.10.100), `Invoke-WebRequest` ve `nslookup`

### İlk deneme — başarısız (troubleshooting)

İlk bağlantı denemesinde:
- **TCP:** 5 adet SYN paketine karşılık, Kali her seferinde `RST,ACK` ile cevap verdi.
- **DNS/UDP:** `nslookup <isim> 10.10.10.101` sorgularına karşılık ICMP **Port Unreachable** döndü.

**Yorum:** Bir SYN'e `RST,ACK` gelmesi — sessiz kalmak (paketin bir firewall tarafından drop edilmesi) değil, hedefin **aktif olarak reddetmesi** anlamına gelir; bu da o portta dinleyen bir servis olmadığını gösterir. Aynı mantık UDP tarafında ICMP Port Unreachable için de geçerli.

**Kök neden:** `python3 -m http.server 8080` komutu doğru arayüze/adrese bind olmamıştı.

**Çözüm:**
```bash
python3 -m http.server -b 10.10.10.101 8080
```

### İkinci deneme — başarılı

Bind düzeltildikten sonra:
- 3-way handshake tamamlandı: `SYN` → `SYN,ACK` (seq +1) → `ACK`
- İstemci `GET /` isteği gönderdi (~158 byte, header'larla birlikte)
- Kali `200 OK` cevabı verdi (~1722 byte) — MSS sınırı (~1460 byte) nedeniyle **2 ayrı segmente bölünerek** gönderildi, istemci her segmenti ayrı ACK'ledi
- Bağlantı `FIN,ACK` ile düzgün şekilde kapatıldı

### DNS sorgusu — ek gözlem

`nslookup` çağrısı önce hedef DNS sunucusunun (10.10.10.101) adını göstermek için bir **PTR (reverse) sorgusu** (`101.10.10.10.in-addr.arpa`) gönderdi, ardından asıl sorulan isme geçti — bu `nslookup` aracının kendi varsayılan davranışı. Kali'de DNS servisi çalışmadığı için sorgular yanıtsız kaldı (ICMP Port Unreachable), bu da paketin yapısını (Transaction ID, Query Name) analiz etmek için yeterliydi.

## 2. Windows Event Log Analysis

**Ortam:** Windows Server (10.10.10.10)

### Senaryo

1. `New-LocalUser` ile bir kullanıcı oluşturuldu → **Event 4720**
2. Başarısız bir kimlik doğrulama denemesi tetiklendi → **Event 4625**
3. `Remove-LocalUser` ile kullanıcı silindi → **Event 4726**

### 4625 üretiminde troubleshooting

`runas /user:.\<kullanıcı> cmd` ile yanlış parola denemesi **"Unable to acquire user password"** hatasıyla başarısız oldu — bu, kimlik doğrulamaya hiç ulaşmadan **Secondary Logon servisi** seviyesinde oluşan bir hata, dolayısıyla hiçbir event üretilmedi.

**Çözüm:** `runas` yerine gerçek bir network authentication denemesi kullanıldı:
```powershell
net use \\localhost\c$ /user:.\<kullanıcı> <yanlis_parola>
```
Bu, **Logon Type 3** (Network) olarak başarısız bir authentication denemesi üretti ve 4625'e düştü.

### 4625 alan analizi

| Alan | Değer |
|---|---|
| Logon Type | 3 (Network) |
| TargetUserName | NewUser |
| Failure Reason | `%%2313` — "Unknown user name or bad password" |
| Source Address | `::1` (IPv6 loopback), port 65425 |

**Not:** Windows bu mesajı bilerek belirsiz tutar — kullanıcı adının mı yoksa parolanın mı yanlış olduğunu görünür metinde söylemez (username enumeration'ı zorlaştırmak için). Arka planda daha spesifik bir hex sub-status kodu (`0xC0000064` / `0xC000006A`) bu farkı tutar, ama görünen mesaj kasıtlı olarak genelleştirilmiştir.

### Audit Policy doğrulaması

```powershell
auditpol /get /category:"Logon/Logoff"
```
Logon alt kategorisinde **Success and Failure** açık olduğu doğrulandı — event'in düşmesinin önünde bir audit-policy engeli olmadığı teyit edildi.

### 4726 (silme)

| Alan | Değer |
|---|---|
| SubjectUserName | Windows (silme işlemini yapan hesap) |
| TargetUserName | NewUser (silinen hesap) |

## 3. Linux Log Analysis

**Ortam:** Kali (10.10.10.101), SSH servisi aktif edildi

`/var/log/auth.log` **mevcut değildi**. Sebebi: flat-file syslog kayıtları (`auth.log` gibi) yalnızca `rsyslog` gibi bir syslog daemon kuruluysa oluşur; Kali'de bu kurulu değil, sistem sadece **journald**'e (yapılandırılmış/binary format) yazıyor.

**Çözüm:**
```bash
sudo journalctl -u ssh -e
```

### Gözlemlenen log

Windows client'tan (10.10.10.100) var olmayan bir kullanıcıyla SSH bağlantı denemesi:

```
Invalid user anan from 10.10.10.100 port 65428
pam_unix(sshd:auth): check pass; user unknown
pam_unix(sshd:auth): authentication failure; ... ruser= rhost=10.10.10.100
Failed password for invalid user anan from 10.10.10.100 port 65428 ssh2
... (3 deneme tekrarı)
Connection reset by invalid user anan 10.10.10.100 port 65428 [preauth]
PAM 2 more authentication failures; ...
```

### Windows vs Linux log verbosity karşılaştırması

Linux/PAM, Windows'un aksine kullanıcı adının **var olmadığını açıkça** belirtiyor ("Invalid user", "user unknown"). Bu, saldırgana açık bir kanal değildir — bu log yalnızca sunucudaki analiste görünür, uzaktaki bir saldırgan bu dosyayı okuyamaz. Gerçek username enumeration riski **protokol seviyesinde** olur; modern OpenSSH, geçerli/geçersiz kullanıcı için yanıt süresini (timing) kasıtlı olarak eşitleyerek bu tür bir saldırıyı zaten engeller.

## 4. PowerShell Collection

**Ortam:** Windows client (10.10.10.100)

Aşağıdaki bilgileri tek bir script ile toplayıp `system-report.txt`'ye yazdıran bir collection script'i yazıldı:

- Çalışan process'ler (`Get-Process`)
- Aktif network bağlantıları (`Get-NetTCPConnection`)
- Local user listesi (`Get-LocalUser`)
- Temel sistem bilgisi (`Get-ComputerInfo`)

### Troubleshooting

Script çalıştırılmaya çalışıldığında **"Running scripts is disabled on this system"** hatası alındı — varsayılan Execution Policy (`Restricted`) script çalıştırmayı tamamen engelliyor.

**Çözüm:**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
`RemoteSigned`, yalnızca internetten indirilen script'lerin imzalı olmasını zorunlu kılar; yerelde yazılan script'leri kısıtlamaz — `Unrestricted`'tan daha dar kapsamlı, daha güvenli bir seçim.

**Not:** Execution Policy gerçek bir güvenlik sınırı değildir — `powershell -ExecutionPolicy Bypass` ile trivially aşılabilir. Bu yüzden detection bu ayara değil, process davranışına dayanmalıdır.

## Öğrenilen Dersler

- **Bir event'in üretilmesi, görülebilir olması anlamına gelmez.** Windows'ta bu Audit Policy'nin (Logon/Logoff kategorisi) açık olup olmamasına, Linux'ta ise bir syslog daemon'ın (rsyslog) kurulu olup olmamasına bağlı — ikisinde de varsayılan durum garanti değil.
- **Execution Policy bir güvenlik kontrolü değil, bir kaza-önleyicidir** — `RemoteSigned` ile `Unrestricted` arasındaki fark gerçek, ama ikisi de kararlı bir saldırgana karşı bir engel değil.
- **Aktif red (RST/Port Unreachable) ile sessiz drop farklı sinyallerdir** — biri "port kapalı", diğeri "bir yerde filtreleniyor" der; troubleshooting'de bu ayrımı yapabilmek doğrudan zaman kazandırıyor.
- **Log verbosity'si güvenlik açığı değildir** — sunucu tarafı bir log ne kadar ayrıntılı olursa olsun, bu bilgi sadece o loga erişebilene (analiste) açıktır; asıl risk protokolün kendisinin uzaktaki saldırgana ne söylediğidir.
