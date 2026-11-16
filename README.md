# Ping Tunnel - ICMP

ស្គ្រីបដំឡើង **PingTunnel Server** ដោយស្វ័យប្រវត្តិលើ Linux។ PingTunnel បញ្ជូន traffic TCP/UDP/SOCKS5 តាមរយៈ **ICMP (ping)**។

> ⚠️ សម្រាប់តែការសិក្សា និងគោលបំណងស្របច្បាប់ប៉ុណ្ណោះ។

---

## ✨ លក្ខណៈពិសេស

- ដំឡើងដោយពាក្យបញ្ជាតែមួយ
- រក OS និង architecture ដោយស្វ័យប្រវត្តិ (amd64, 386, arm, arm64, riscv64, ppc64)
- សាកល្បង URL ទាញយកច្រើនដោយស្វ័យប្រវត្តិ (latest release មុន)
- បង្កើត និងបើក **systemd service** (`pingtunnel`) ដោយស្វ័យប្រវត្តិ
- ពិនិត្យ Password (យ៉ាងតិច 8 តួអក្សរ; ប្រើបាន `a-z A-Z 0-9 . _ -`)
- បង្ហាញ Server IP និង Password នៅពេលដំឡើងចប់

---

## 📋 តម្រូវការ

- Linux ដែលប្រើ **systemd** (Ubuntu / Debian / CentOS ...)
- សិទ្ធិ **root** (ឬ `sudo`)
- `curl` (script នឹងដំឡើង `unzip` ឱ្យដោយខ្លួនឯង)
- Server មាន **Public IP** ហើយអនុញ្ញាត **ICMP** ក្នុង firewall / Security Group

---

## 🚀 ដំឡើង

```bash
curl -fsSL https://raw.githubusercontent.com/CHEA-MC/Ping-Tunnel---ICMP/main/installer.sh -o installer.sh

sudo bash installer.sh
```

បន្ទាប់មកវាយ **Password** យ៉ាងតិច 8 តួអក្សរ (ឧទាហរណ៍ `MyPass1234`)៖

```
Enter a Password for PingTunnel (-password, min 8 chars, allowed: a-z A-Z 0-9 . _ -): MyPass1234
```

ពេលចប់ អ្នកនឹងឃើញ៖

```
================================
✅ PingTunnel Installation Complete
================================
Server IP : x.x.x.x
Password  : MyPass1234
Service   : pingtunnel
Status    : active
================================
```

សូមកត់ត្រា **Server IP** និង **Password** សម្រាប់ប្រើនៅ client។

---

## 🖥️ ការគ្រប់គ្រង Service

| ការងារ | ពាក្យបញ្ជា |
|---|---|
| មើលស្ថានភាព | `sudo systemctl status pingtunnel` |
| ចាប់ផ្តើមឡើងវិញ | `sudo systemctl restart pingtunnel` |
| បញ្ឈប់ | `sudo systemctl stop pingtunnel` |
| មើល log ផ្ទាល់ | `sudo journalctl -u pingtunnel -f` |

---

## 💻 ប្រើ Client

ទាញ client ពី [PingTunnel Releases](https://github.com/esrrhs/pingtunnel/releases) ហើយរត់ដោយសិទ្ធិ Administrator/root។ ជំនួស `SERVER_IP` និង `MyPass1234` តាមតម្លៃរបស់អ្នក។

**SOCKS5 proxy**

```bash
pingtunnel -type client -l :1080 -s SERVER_IP -socks5 -password MyPass1234
```

បន្ទាប់មកកំណត់ browser/app ឱ្យប្រើ **SOCKS5** ត្រង់ `127.0.0.1:1080`។

**បញ្ជូន TCP**

```bash
pingtunnel -type client -l :4455 -s SERVER_IP -t SERVER_IP:4455 -password MyPass1234
```

**បញ្ជូន UDP**

```bash
pingtunnel -type client -l :4455 -s SERVER_IP -t SERVER_IP:4455 -udp -password MyPass1234
```

---

## ⚙️ ការកំណត់បន្ថែម (ណែនាំ)

បិទការឆ្លើយ ping របស់ kernel ដើម្បីកុំឱ្យជាន់ PingTunnel៖

```bash
echo "net.ipv4.icmp_echo_ignore_all=1" | sudo tee /etc/sysctl.d/10-noecho.conf
sudo sysctl -p /etc/sysctl.d/10-noecho.conf
```

---

## 🛠️ ដោះស្រាយបញ្ហា

| បញ្ហា | ដំណោះស្រាយ |
|---|---|
| `curl: (22) ... 404` | ឈ្មោះ file ក្នុង release ប្រែប្រួល។ ពិនិត្យ [Releases](https://github.com/esrrhs/pingtunnel/releases) |
| `flag provided but not defined: -key` | PingTunnel v3 ប្រើ `-password` (យ៉ាងតិច 8 តួអក្សរ) ជំនួស `-key` |
| Service មិនចាប់ផ្តើម | `sudo journalctl -u pingtunnel -n 50 --no-pager` |
| Client ភ្ជាប់មិនបាន | ពិនិត្យ Password ដូចគ្នា, `ping SERVER_IP`, និង firewall អនុញ្ញាត ICMP |
| `Please run this script as root` | ប្រើ `sudo bash installer.sh` |
| `requires systemd` | OS របស់អ្នកមិនប្រើ systemd។ រត់ដោយដៃ ឬប្រើ Docker |

---

## 🗑️ ដកការដំឡើង

```bash
sudo systemctl stop pingtunnel
sudo systemctl disable pingtunnel
sudo rm -f /etc/systemd/system/pingtunnel.service
sudo systemctl daemon-reload
sudo rm -rf /opt/pingtunnel
```

---

## 🔗 ឯកសារយោង

- PingTunnel (ដើម): https://github.com/esrrhs/pingtunnel
- Releases: https://github.com/esrrhs/pingtunnel/releases
