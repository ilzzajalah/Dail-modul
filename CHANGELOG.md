# Changelog

## v1.7
- Multi-bahasa: WebUI, tombol Action, dan pesan instalasi otomatis mengikuti bahasa HP (Indonesia / English), bisa diganti manual lewat tile Bahasa

## v1.6
- Action kini memeriksa apakah WebUI benar-benar termuat; jika tidak dalam 10 detik, otomatis pindah ke browser (server lokal)

## v1.5
- Info perangkat (baterai, suhu, RAM, storage)
- Bersihkan RAM, TRIM Storage, dan tampilan log di Status

## v1.4
- Hapus properti `banner=` dari `module.prop` (dibaca manager sebagai URL, memicu `ERR_NAME_NOT_RESOLVED`)
- Diagnosis di Action dan mode browser lewat file `Dail_browser`

## v1.3
- Tampilan WebUI bento grid
- Action memeriksa modul sudah aktif (butuh reboot), nama class WebUI X ditulis lengkap, tambah `config.json`

## v1.2
- Tombol Action membuka WebUI di WebUI X

## v1.1
- Tes jaringan, deteksi aplikasi daily, Boost/Hemat per-aplikasi, Battery Saver
- Action membuka WebUI lewat server lokal ber-token

## v1.0
- Rilis awal: Network Tuning, Private DNS, Data Saver, TikTok Boost, WebUI, boot guard anti-bootloop
