# Normal vs Suspicious Activity Comparison

| Telemetri | Normal | Şüpheli | Neden şüpheli etiketlerim |
|---|---|---|---|
| **Network** | Kapalı bir porta yalnızca kendi başlattığımız istekler dışında bağlantı gelmez. | Kapalı/beklenmeyen bir porta dışarıdan rastgele bir istek gelmesi. | Beklenmeyen bir kaynağın port taraması veya hatalı yapılandırılmış bir servise erişim denemesi olabileceğini gösterir. |
| **Windows Event** | Kullanıcı oluşturma/silme gibi işlemler Change Management dahilinde, önceden haber verilerek yapılır. | Change Management'ta karşılığı olmayan bir kullanıcı oluşturma event'i (4720). | Yetkisiz veya kayıt dışı bir hesap oluşturma girişimi olabilir — persistence amaçlı olabilir. |
| **Linux Log** | SSH erişimi genelde key-based authentication ile sağlanır; bir yazım hatası dışında rastgele bir kullanıcı adıyla kimse giriş denemez. | Var olmayan/rastgele bir kullanıcı adıyla veya geçerli bir kullanıcıya art arda hatalı parolayla giriş denemesi. | Yetkisiz erişim denemesi işareti — IoC olarak SSH auth logları (invalid user, failed password) kullanılabilir. |
