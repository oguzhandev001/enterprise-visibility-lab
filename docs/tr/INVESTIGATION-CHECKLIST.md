# Basic Investigation Checklist

ANLA → KARAR VER → DEVRET akışının bu projedeki telemetri türlerine (network capture, Windows event log, PowerShell collection) uyarlanmış hali.

## 1. ANLA

Her bulguyu şu sorularla anlamlandır:

- Ne zaman, hangi host'ta, hangi kullanıcı tarafından gerçekleşti?
- Gerçekten gerçekleşti mi, yoksa bir hata/gürültü mü (örn. yanlış yapılandırılmış bir servis)?
- Planlı bir değişiklik mi — Change Management'ta karşılığı var mı?
- Yetkili bir eylem mi?

**Network capture** için: kaynak ve hedef adresleri/portları kontrol et — olağan dışı bir bağlantı var mı? Paketlerde anomali (beklenmeyen RST, port unreachable, alışılmadık boyut) var mı?

**Event log** için: oluşturulan/silinen/erişilen kaynak Change Management'ta kayıtlı mı, kim tarafından yapılmış?

Gerekirse enrichment yap (TI sorgusu, ilgili diğer log kaynaklarına bakma).

## 2. KARAR VER

Toplanan bulguları karşılaştır: gerçekten yetkili bir eylem mi, yoksa şüpheli mi?

Verdict: **True Positive / False Positive / Benign True Positive**

## 3. DEVRET

- **False Positive** → kapat, gerekiyorsa Detection Engineering'e bir iyileştirme (tuning) önerisi gönder.
- **True Positive** → playbook'ta tanımlı bir containment adımı varsa uygula; yoksa doğrudan bulgularla birlikte L2'ye eskale et.
