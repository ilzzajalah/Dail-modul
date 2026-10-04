# Dail Modul

Modul Magisk ringan untuk pengguna harian: tuning jaringan, Data Saver pintar, boost aplikasi pilihan, Battery Saver per-aplikasi, dan pembersih RAM, dengan pengaturan lewat **WebUI bergaya bento grid**.

> **Status: beta.** Belum diuji luas di banyak perangkat. Gunakan dengan risiko sendiri dan pastikan kamu tahu cara masuk safe mode atau recovery.

## Fitur

| Fitur | Keterangan |
|---|---|
| **Network Tuning** | TCP Fast Open, BBR (jika kernel mendukung), mematikan slow-start-after-idle |
| **Private DNS** | Pilihan Cloudflare, Google, atau AdGuard, bisa dikembalikan ke default |
| **Data Saver** | Hemat kuota; aplikasi Boost otomatis dikecualikan agar tidak patah |
| **Tes Jaringan** | Ping, jitter, packet loss, dan tes kecepatan unduh (±5 MB) |
| **Deteksi Aplikasi Daily** | Mengenali puluhan aplikasi populer (TikTok, WhatsApp, Instagram, YouTube, Shopee, game, dll.) |
| **Boost / Hemat per-aplikasi** | *Boost* = selalu aktif, bebas pembatasan baterai dan data. *Hemat* = dibatasi di background saat Battery Saver aktif |
| **Battery Saver** | Mode hemat sistem + pembatasan aplikasi pilihan |
| **Bersihkan RAM** | Menutup proses cache dan mengosongkan cache memori |
| **TRIM Storage** | Menjalankan fstrim di background |
| **Optimasi Dex** | Compile ulang aplikasi Boost (sebaiknya saat charging) |
| **Info perangkat** | Baterai, suhu, RAM bebas, dan sisa storage |
| **Multi-bahasa** | WebUI dan pesan modul otomatis mengikuti bahasa HP (Indonesia / English), bisa diganti manual |

## Persyaratan

- Android 10 (API 29) atau lebih baru
- Magisk (disarankan v28+ untuk tombol Action). KernelSU dan APatch juga bisa membuka WebUI bawaan
- Untuk Magisk: aplikasi **[WebUI X](https://github.com/MMRLApp/WebUI-X-Portable/releases)** untuk menampilkan WebUI

## Instalasi

1. Unduh `Dail_Modul_vX.Y.zip` dari halaman **Releases**.
2. Flash lewat Magisk (Modul → Pasang dari penyimpanan).
3. **Reboot.** WebUI baru bisa dibuka setelah modul aktif.
4. Tekan tombol **Action** pada Dail Modul.

## Cara pakai

- **Action** membuka WebUI di WebUI X. Jika halaman tidak berhasil termuat dalam 10 detik, Action otomatis membuka WebUI yang sama di **browser** lewat server lokal (`127.0.0.1`, dilindungi token acak, berhenti sendiri setelah 10 menit tidak dipakai).
- Untuk langsung memakai browser, buat file kosong bernama `Dail_browser` di penyimpanan internal.
- Atur toggle dan pilihan aplikasi, lalu tekan **Terapkan**. Setting juga diterapkan otomatis setiap boot.

## Keamanan dan anti-bootloop

- Tidak ada tweak di fase `post-fs-data`, hanya penghitung boot. Semua tweak berjalan setelah `boot_completed`.
- Jika boot gagal 3 kali berturut-turut, modul menonaktifkan dirinya sendiri.
- Semua perubahan bersifat runtime dan bisa dikembalikan. Tidak ada partisi atau file sistem yang diubah.
- Tidak ada layanan yang berjalan terus-menerus.
- Server lokal hanya menerima perintah dalam daftar putih dan menolak karakter berbahaya.

## Uninstall

Hapus modul lewat Magisk lalu reboot. `uninstall.sh` mengembalikan DNS, animasi, pembatasan aplikasi, dan nilai sysctl ke semula. Atau tekan **Reset semua** di WebUI sebelum menghapus.

## Troubleshooting

| Masalah | Solusi |
|---|---|
| Action bilang "WebUI belum aktif" | Reboot dulu setelah flash |
| WebUI X menampilkan `ERR_NAME_NOT_RESOLVED` | Action akan pindah ke browser otomatis. Coba juga WebUI X rilis stabil (varian alpha tertentu punya bug yang membuat WebUI modul tidak terbuka) |
| Browser tidak terbuka | Busybox Magisk perlu applet `httpd`. Pakai WebUI X sebagai gantinya |
| Notifikasi aplikasi terlambat | Jangan masukkan aplikasi chat ke daftar *Hemat* |
| Storage tampil `–` | Perintah `df` di perangkatmu tidak memberi hasil; fitur lain tetap jalan |

Modul tidak bisa memperbaiki sinyal buruk atau bandwidth operator. Tweak jaringan paling terasa pada koneksi yang stabil, dan BBR hanya aktif jika kernel menyediakannya.

## Struktur

```
dail_modul/
├── module.prop
├── customize.sh        # cek Android 10+, izin file
├── post-fs-data.sh     # boot guard (ringan)
├── service.sh          # terapkan setting setelah boot selesai
├── action.sh           # buka WebUI (WebUI X -> browser)
├── dail.sh             # logika inti
├── uninstall.sh
├── known.txt           # daftar aplikasi daily yang dikenali
└── webroot/            # WebUI (index.html, config.json, cgi-bin/)
```

## Kredit

- **[Magisk](https://github.com/topjohnwu/Magisk)** oleh John Wu (topjohnwu): installer modul (`update-binary`), GPL-3.0
- **[WebUI X](https://github.com/MMRLApp/WebUI-X-Portable) / [MMRL](https://github.com/MMRLApp/MMRL)** oleh Der_Googler dan MMRLApp: penampil WebUI untuk Magisk
- **[Tricky Addon – Update Target List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List)** oleh KOWX712: referensi cara meluncurkan WebUI X dari tombol Action Magisk
- **KsuWebUIStandalone** oleh a13e300 (fork KOWX712): penampil WebUI alternatif
- **[KernelSU](https://github.com/tiann/KernelSU)** oleh tiann: antarmuka WebUI (`ksu.exec`) yang dipakai halaman pengaturan
- **Banner:** karakter Furina © HoYoverse / Genshin Impact. Ilustrasi oleh **[ISI NAMA ARTIS & LINK SUMBER]**. Gambar tidak termasuk dalam lisensi kode di bawah dan hak ciptanya tetap pada pembuatnya
- Dikembangkan oleh **[ilzzajalah](https://github.com/ilzzajalah)** dengan bantuan Claude (Anthropic)

## Lisensi

Kode modul dirilis di bawah **GPL-3.0** (mengikuti lisensi installer Magisk yang disertakan). Lihat berkas `LICENSE`.

## Disclaimer

Modul ini disediakan apa adanya tanpa jaminan apa pun. Penulis tidak bertanggung jawab atas kerusakan perangkat, bootloop, atau kehilangan data. Lakukan backup dan uji di perangkat yang kamu tahu cara memulihkannya.
