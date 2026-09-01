# Lab Setup Guide

## Ortam

- Hypervisor: VMware
- Ağ modu: Host-Only, `10.10.10.0/24`, izole (internet erişimi yok)
- Gateway: `10.10.10.1` (host makine)

| Rol              | Hostname        | IP           | Subnet          | Gateway     |
|-------------------|-----------------|--------------|-----------------|-------------|
| Gateway (host)     | —               | 10.10.10.1   | 255.255.255.0   | —           |
| DC (Windows Srv)   | WIN-3GTJDFSUSVD | 10.10.10.10  | 255.255.255.0   | 10.10.10.1  |
| Linux (Ubuntu)     | ubuntu          | 10.10.10.20  | 255.255.255.0   | 10.10.10.1  |
| Client (Win 11)    | —               | 10.10.10.100 | 255.255.255.0   | 10.10.10.1  |
| Kali               | kali            | 10.10.10.101 | 255.255.255.0   | 10.10.10.1  |

Ubuntu netplan yapılandırması (`/etc/netplan/*.yaml`):

```yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses:
      - "10.10.10.20/24"
      nameservers:
        addresses:
        - 10.10.10.10
      routes:
      - to: "default"
        via: "10.10.10.1"
```

## Kurulum Sırasında Karşılaşılan Sorunlar

### 1. Windows Server 2022 Evaluation — lisans hatası

Kurulum sırasında lisans doğrulama hatası alındı.

**Çözüm:** VMware ayarlarından Floppy Disk'i devre dışı bırakmak. Floppy Disk sürücüsü Windows kurulumunun lisans/aktivasyon akışının kafasının karışmasına neden oluyor.

### 2. VM'ler birbirine ping atamıyor

IP ataması sonrası cihazlar aynı subnette olmasına rağmen birbirine ulaşamadı.

**Kök neden:** Windows VM'de Subnet Mask ve Default Gateway atanmamıştı — sadece IP adresi verilmişti.

**Çözüm:**
```powershell
Remove-NetIPAddress -InterfaceIndex 15
New-NetIPAddress -InterfaceIndex 15 -IPAddress 10.10.10.10 -PrefixLength 24 -DefaultGateway 10.10.10.1
```
Interface'i önce temizlemek gerekti — aksi halde aynı interface'de birden fazla IP kalıyordu.

### 3. Windows 11 kurulumu başarısız oluyor

**Kök neden:** Windows 11 kurulumu Secure Boot'un aktif olmasını zorunlu kılıyor.

**Çözüm:** VM ayarlarından Secure Boot'u aktif hale getirmek.

### 4. Windows 11 kurulum sonrası ping alınamıyor

**Kök neden:** Windows Defender Firewall varsayılan olarak inbound/outbound ICMPv4 isteklerini bloklar.

**Çözüm:** Firewall kurallarında ICMPv4 echo request/reply için izin verilmesi.
