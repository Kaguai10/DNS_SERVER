<div align="center">
  <img src="https://readme-typing-svg.herokuapp.com?size=33&color=1670ba&center=true&vCenter=true&width=600&lines=Membuat+DNS+Server+Di+Debian">
</div>

## Apa Itu DNS?

Domain Name System (DNS) adalah komponen protokol standar internet yang bertanggung jawab untuk mengubah nama domain yang mudah dipahami manusia menjadi alamat Internet Protocol (IP) yang digunakan komputer untuk mengidentifikasi satu sama lain di jaringan. Dalam dunia jaringan, DNS sering disebut sebagai “buku telepon internet”. Istilah ini muncul karena cara kerjanya mirip seperti daftar kontak: manusia cukup mengingat nama (seperti example.com), sementara DNS akan mencari dan mencocokkan nama tersebut dengan alamat IP yang sesuai, sehingga pengguna tidak perlu menghafal deretan angka yang rumit.

## langkah Konfigurasi

Repository ini menjelaskan langkah-langkah konfigurasi DNS Server menggunakan Bind9 pada Debian. Untuk membangun DNS Server kita wajib menginstall dua paket utama, yaitu bind9 dan dnsutils. Bind9 adalah software DNS server yang paling banyak digunakan di Linux. Fungsinya Menyimpan database domain (zona), Melakukan resolusi domain → IP, Melayani query DNS dari client, Mendukung forward/reverse lookup. dnsutils berisi tools penting seperti: `dig` → untuk melakukan query DNS, `nslookup` → mengecek domain, `host` → mengecek informasi domain

Untuk mengawali, terlebih dahulu kita install packagesnya terlebih dahulu **Jika debian blom diupdate silahkan jalankan command ini terlebih dahulu.** Dan pastikan kalian sudah masuk dengan user root
```bash
apt update
```
jika sudah lanjut menginstall bind9 dan dnsutils
```bash
apt install bind9 bind9utils dnsutil -y
```

Tunggu proses instalasi hingga selesai. Setelah itu, kita akan berpindah ke direktori Bind untuk mulai mengonfigurasi dan mengatur DNS sesuai kebutuhan.
```bash
cd /etc/bind
```
Berikutnya, kita akan membuat dan mengonfigurasi forward zone, yaitu file yang digunakan DNS untuk menerjemahkan nama domain menjadi IP Address. Untuk membuatnya, cukup salin file db.local dan beri nama db.forward. Setelah itu, buka file tersebut dan isi sesuai domain serta IP yang ingin kalian gunakan.
```bash
cp db.local db.forward
nano db.forward
```
pada isi file konfigurasi kalian cukup mengubah localhost menjadi nama domain yang kalian ingin buat. Dan mengubah IP local 127.0.0.1 menjadi alamat IP pada server kalian atau saat ini. **Contoh pada kali ini saya akan memberikan Domain "kaguai.net" dan alamat IP saya "192.168.0.137"** (Pada kali ini saya menggunakan IP Lokal). Berikut hasil db.forward setelah di konfigurasi.
```txt
;
; BIND data file for local loopback interface 
;
$TTL    604800   
@       IN      SOA     kaguai.net. root.kaguai.net. (   
                              2         ; Serial
                         604800         ; Refresh  
                          86400         ; Retry    
                        2419200         ; Expire  
                         604800 )       ; Negative Cache TTL  
;
@       IN      NS      kaguai.net.
@       IN      A       192.168.0.137         
@       IN      AAAA    ::1           
```
Setelah selesai melakukan konfigurasi, simpan perubahan dengan menekan Ctrl+S, kemudian keluar dari editor dengan Ctrl+X.

Selanjutnya, kita akan melakukan konfigurasi pada file db.reverse. File reverse memiliki fungsi kebalikan dari file forward, yaitu memetakan IP Address menjadi nama domain. Untuk membuat file reverse, salin terlebih dahulu file db.127 dan ubah namanya menjadi db.reverse. Konfigurasi file ini sama seperti file forward, yaitu cukup mengubah bagian localhost dan IP sesuai kebutuhan. Perlu diperhatikan bahwa pada konfigurasi reverse, kalian hanya perlu menuliskan oktets terakhir dari IP Address. Sebagai contoh:IP saya adalah 192.168.0.137, maka di file reverse cukup menuliskan 137 saja. Berikut hasil setelah di konfigurasi
```txt
;
; BIND reverse data file for local loopback interface  
;
$TTL    604800 
@       IN      SOA     kaguai.net. root.localhost. (    
                              1         ; Serial 
                         604800         ; Refresh 
                          86400         ; Retry  
                        2419200         ; Expire   
                         604800 )       ; Negative Cache TTL 
;
@       IN      NS      kaguai.net. 
137     IN      PTR     kaguai.net.  
```
Setelah dikonfigurasi kalian dapet menyimpan dengan menekan ctrl+s lalu keluar dengan menekan ctrl+x

Selanjutnya, kita akan mendefinisikan **Zone Domain**. Pada bagian ini, kita akan menentukan zona-zona yang akan digunakan oleh domain yang kita konfigurasi. File ini memiliki peranan penting karena akan menentukan file **forward** dan **reverse** mana yang akan digunakan serta di-load oleh DNS server.

Kalian dapat melakukan konfigurasi dengan mengedit langsung file `named.conf.default-zones`, atau dapat menyalin Konfigurasi tersebut ke file `named.conf.local` agar lebih rapi dan mudah dikelola.

1.  Ganti `localhost` dengan **nama domain** yang kalian gunakan.
2.  Ubah file tujuan (file zone) menjadi file `db.forward` yang telah
    dibuat sebelumnya.
3.  Untuk zone reverse, tuliskan **tiga oktet awal IP Address dalam
    urutan terbalik**.
    Contoh: jika IP berada di jaringan `192.168.0.x`, maka tuliskan
    `0.168.192`.
4.  Ubah file tujuannya menjadi file `db.reverse` yang telah dibuat.

Berikut hasil setelah dikonfigurasi (kalian dapat menyesuaikan dengan domain dan IP kalian.):
```txt
zone "kaguai.net" {  
        type master;  
        file "/etc/bind/db.forward"; 
};

zone "0.168.192.in-addr.arpa" {  
        type master; 
        file "/etc/bind/db.reverse"; 
};       
```
Setelah kalian konfigurasi silahkan untuk save dengan menekan ctrl+s dan keluar dengan perintah ctrl+x. Jika semua konfigurasi sudah benar dan selesai, kita lakukan restart pada service bind9
```bash
systemctl restart bind9
```
selanjutnya kalian dapat menambahkan nameserver agar domain dapat dikenali didalam jaringan, maka kita perlu mengkonfigurasi IP DNS di file /etc/resolv.conf dengan menambahkan IP address domain dan IP DNS Default dari ISP atau `8.8.8.8` agar server juga tetep terhubung dengan internet. Isi file konfigurasi seperti ini:
```txt
nameserver 192.168.0.137
nameserver 8.8.8.8
```
Selanjutnya kalian dapat memeriksa DNS kalian dengan memakai tools dari dnsutils yang kita install diawal
```bash
# Melihat Host DNS => versi simpel
host kaguai.net #ganti sesuai dengan domain yang dibuat

# Mengecek Domain yang telah dibuat 
nslookup kaguai.net #ganti sesuai dengan domain yang dibuat

# Untuk mendiagnostik query secara lebih lengkap
dig kaguai.net #ganti sesuai dengan domain yang dibuat
```

Jika alamat IP Address yang ditampilkan saat melakukan pengecekan dns sudah sesuai dengan konfigurasi yang kita buat, berarti DNS server telah berhasil dijalankan dengan benar. Setelah itu, kita dapat melakukan pengujian sederhana dengan melakukan ping ke domain yang telah kita konfigurasi.

1. Uji dari Server DNS Gunakan perintah berikut:
```bash
ping kaguai.net #ganti sesuai nama domain kalian
```

Jika DNS bekerja, maka domain akan berhasil di-resolve menjadi alamat IP yang telah kalian tetapkan pada file zona. Jika hasilnya menampilkan alamat IP yang benar, maka konfigurasi DNS berhasil. Contoh:
```txt
PING kaguai.net (192.168.0.137) 56(84) bytes of data.
```

2. Uji dari Perangkat Lain dalam Satu Jaringan
Agar perangkat lain dapat mengakses domain yang sama, kalian perlu:

- Menghubungkan perangkat ke jaringan yang sama (misalnya WiFi atau LAN yang sama).
- Mengubah pengaturan DNS pada perangkat tersebut dengan menambahkan IP Address server DNS kalian.
Contoh IP DNS yang ditambahkan: 192.168.0.137 => sesuai IP Address pada domain .Setelah pengaturan DNS diperbarui, lakukan ping pada domain:
```
ping Kaguai.net
```
Jika perangkat dapat melakukan ping dan mendapatkan IP yang sama seperti hasil di server DNS, maka DNS kalian telah berfungsi dengan baik pada seluruh jaringan lokal.

Kalian juga dapat mencoba tools Otomatis yang saya buat, dengan cara seperti berikut:
```bash
git clone https://github.com/Kaguai10/DNS_SERVER.git

cd DNS_SERVER

chmod +x run.sh

#lalu Jalankan run.sh dan bisa gunakan --help untuk melihat opsi yang tersedia
#contoh menjalankannya

sudo ./run.sh -D kaguai10.net -A 192.168.0.137 -S www
```

