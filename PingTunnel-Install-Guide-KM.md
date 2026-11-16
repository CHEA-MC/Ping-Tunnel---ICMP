# មគ្គុទ្ទេសក៍ដំឡើង PingTunnel (ភាសាខ្មែរ)

PingTunnel គឺជាឧបករណ៍ដែលបញ្ជូន traffic TCP/UDP/SOCKS5 តាមរយៈ **ICMP (ping)**។ ឯកសារនេះពន្យល់ពីវិធីដំឡើងផ្សេងៗនៅលើ Ubuntu server និងរបៀបភ្ជាប់ពី client។

> ⚠️ ប្រើសម្រាប់តែការសិក្សា និងគោលបំណងស្របច្បាប់ប៉ុណ្ណោះ។

---

## មាតិកា

1. តម្រូវការជាមុន
2. វិធីទី 1: ដំឡើងដោយ script (installer.sh)
3. វិធីទី 2: ដំឡើងដោយដៃ (Manual)
4. វិធីទី 3: ដំឡើងដោយ Docker
5. ការកំណត់ systemd service (សម្រាប់វិធីទី 2)
6. ការកំណត់ Server បន្ថែម
7. ដំឡើង និងប្រើ Client
8. ពាក្យបញ្ជាសំខាន់ៗ
9. ដោះស្រាយបញ្ហា (Troubleshooting)
10. ដកការដំឡើង (Uninstall)

---

## 1. តម្រូវការជាមុន

- Server Ubuntu/Debian ដែលមាន **Public IP**
- សិទ្ធិ **root** (ឬ `sudo`)
- `curl` និង `unzip`
- **ICMP (ping)** មិនត្រូវបានបិទដោយ firewall របស់ cloud provider
- PingTunnel v3 ប្រើ `-password` (មិនមែន `-key` ទៀតទេ) ត្រូវមានយ៉ាងតិច **8 តួអក្សរ** ហើយដូចគ្នាទាំង server និង client

ដំឡើងឧបករណ៍ចាំបាច់៖

```bash
sudo apt update
sudo apt install -y curl unzip
```

---

## 2. វិធីទី 1: ដំឡើងដោយ script (installer.sh)

វិធីងាយបំផុត។ script នឹងធ្វើការទាំងនេះដោយស្វ័យប្រវត្តិ៖ រកប្រភេទ OS/architecture, ទាញយក, ពន្លា, បង្កើត systemd service និងចាប់ផ្តើម service។

```bash
sudo bash installer.sh
```

បន្ទាប់មកវាយ **Password** យ៉ាងតិច 8 តួអក្សរ (ឧទាហរណ៍ `MyPass1234`)។

ពេលចប់ អ្នកនឹងឃើញ៖

```
✅ PingTunnel Installation Complete
Server IP : x.x.x.x
Password  : 123456
Service   : pingtunnel
Status    : active
```

សូមកត់ត្រា **Server IP** និង **Password** ទុកសម្រាប់ client។

---

## 3. វិធីទី 2: ដំឡើងដោយដៃ (Manual)

### ជំហាន 1: បើក release page

បើក https://github.com/esrrhs/pingtunnel/releases ក្នុង browser ហើយមើលឈ្មោះ file ពិតប្រាកដសម្រាប់ Linux។

ឈ្មោះ file អាចខុសគ្នាតាមកំណែ៖

| ប្រភេទ release | ឧទាហរណ៍ឈ្មោះ file |
|---|---|
| ថ្មី | `pingtunnel_linux_amd64.zip` |
| ចាស់ | `pingtunnel_linux64.zip` |

### ជំហាន 2: ទាញយក និងពន្លា

ប្តូរ `<LINK>` ជាតំណភ្ជាប់ដែលអ្នកចម្លងពី release page៖

```bash
sudo mkdir -p /opt/pingtunnel
cd /opt/pingtunnel
sudo wget -O pingtunnel.zip "<LINK>"
sudo unzip -o pingtunnel.zip
sudo chmod +x pingtunnel
```

ឬប្រើតំណ "latest" ដោយផ្ទាល់ (សម្រាប់ amd64)៖

```bash
sudo wget -O pingtunnel.zip \
  https://github.com/esrrhs/pingtunnel/releases/latest/download/pingtunnel_linux_amd64.zip
```

### ជំហាន 3: សាកល្បងរត់

```bash
sudo ./pingtunnel -type server -password MyPass1234
```

ប្រសិនបើដំណើរការ សូមចុច `Ctrl+C` ដើម្បីឈប់ ហើយបន្តទៅផ្នែកទី 5 ដើម្បីឱ្យវារត់ជា service។

---

## 4. វិធីទី 3: ដំឡើងដោយ Docker

ដំឡើង Docker ជាមុនសិន (ប្រសិនបើមិនទាន់មាន)៖

```bash
sudo apt install -y docker.io
sudo systemctl enable --now docker
```

រត់ Server៖

```bash
docker run --name pingtunnel-server -d --privileged --network host \
  --restart=always esrrhs/pingtunnel \
  ./pingtunnel -type server -password MyPass1234
```

ពិនិត្យ log៖

```bash
docker logs -f pingtunnel-server
```

---

## 5. ការកំណត់ systemd service (សម្រាប់វិធីទី 2)

បង្កើត file service៖

```bash
sudo nano /etc/systemd/system/pingtunnel.service
```

ដាក់មាតិកា៖

```ini
[Unit]
Description=PingTunnel Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/pingtunnel
ExecStart=/opt/pingtunnel/pingtunnel -type server -password MyPass1234
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

ចាប់ផ្តើម service៖

```bash
sudo systemctl daemon-reload
sudo systemctl enable pingtunnel
sudo systemctl restart pingtunnel
sudo systemctl status pingtunnel
```

---

## 6. ការកំណត់ Server បន្ថែម

### 6.1 បិទ ping ដែល kernel ឆ្លើយតបដោយខ្លួនឯង (ណែនាំ)

ដើម្បីកុំឱ្យ kernel ឆ្លើយ ping មុន PingTunnel៖

```bash
echo 1 | sudo tee /proc/sys/net/ipv4/icmp_echo_ignore_all
```

ដើម្បីឱ្យនៅជាប់បន្ទាប់ពី reboot៖

```bash
echo "net.ipv4.icmp_echo_ignore_all=1" | sudo tee /etc/sysctl.d/10-noecho.conf
sudo sysctl -p /etc/sysctl.d/10-noecho.conf
```

### 6.2 Firewall

ត្រូវអនុញ្ញាត **ICMP echo-request/echo-reply** ទាំង firewall លើ server (ufw/iptables) និង Security Group របស់ cloud provider។

---

## 7. ដំឡើង និងប្រើ Client

ទាញ client ពី https://github.com/esrrhs/pingtunnel/releases ដែលត្រូវនឹង OS របស់អ្នក (ឧទាហរណ៍ `pingtunnel_windows_amd64.zip`) ហើយពន្លា។ ត្រូវរត់ដោយសិទ្ធិ **Administrator/root**។

ជំនួស `SERVER_IP` ដោយ IP របស់ server និង `123456` ដោយ key របស់អ្នក។

### 7.1 SOCKS5 proxy (ប្រើច្រើនបំផុត)

```bash
pingtunnel -type client -l :1080 -s SERVER_IP -sock5 1 -password MyPass1234
```

បន្ទាប់មកកំណត់ browser/app ឱ្យប្រើ **SOCKS5 proxy** ត្រង់ `127.0.0.1:1080`។

### 7.2 បញ្ជូន TCP

```bash
pingtunnel -type client -l :4455 -s SERVER_IP -t SERVER_IP:4455 -tcp 1 -password MyPass1234
```

### 7.3 បញ្ជូន UDP

```bash
pingtunnel -type client -l :4455 -s SERVER_IP -t SERVER_IP:4455 -udp -password MyPass1234
```

### 7.4 Client ដោយ Docker

```bash
docker run --name pingtunnel-client -d --restart=always -p 1080:1080 \
  esrrhs/pingtunnel \
  ./pingtunnel -type client -l :1080 -s SERVER_IP -sock5 1 -password MyPass1234
```

> បើឃើញ log ថា "ping pong" មានន័យថាការភ្ជាប់ដំណើរការធម្មតា។

---

## 8. ពាក្យបញ្ជាសំខាន់ៗ

| ការងារ | ពាក្យបញ្ជា |
|---|---|
| មើលស្ថានភាព | `systemctl status pingtunnel` |
| ចាប់ផ្តើមឡើងវិញ | `systemctl restart pingtunnel` |
| បញ្ឈប់ | `systemctl stop pingtunnel` |
| មើល log ផ្ទាល់ | `journalctl -u pingtunnel -f` |
| ផ្លាស់ប្តូរ password | កែ `ExecStart` ក្នុង `/etc/systemd/system/pingtunnel.service` បន្ទាប់មក `daemon-reload` និង `restart` |

---

## 9. ដោះស្រាយបញ្ហា (Troubleshooting)

### ❌ `curl: (22) The requested URL returned error: 404`

URL ទាញយកខុស (tag ឬឈ្មោះ file មិនមាន)។
- បើក https://github.com/esrrhs/pingtunnel/releases ហើយមើលឈ្មោះ file ពិតប្រាកដ
- ឬប្រើ `releases/latest/download/<ឈ្មោះ file>`
- `installer.sh` កំណែថ្មីសាកល្បង URL ច្រើនដោយស្វ័យប្រវត្តិ

### ❌ `PingTunnel binary not found after extraction`

ឈ្មោះ binary ក្នុង zip ខុសពីការរំពឹង។ ពិនិត្យ៖

```bash
cd /opt/pingtunnel && ls -la
```

### ❌ Service មិនចាប់ផ្តើម

```bash
journalctl -u pingtunnel -n 50 --no-pager
```

- ពិនិត្យថា password មានយ៉ាងតិច 8 តួអក្សរ
- ពិនិត្យថា binary មានសិទ្ធិ execute (`chmod +x`)

### ❌ `flag provided but not defined: -key` (service exit status=2)

PingTunnel v3 បានប្តូរ parameter៖ `-key` → `-password` (យ៉ាងតិច 8 តួអក្សរ), `-sock5 1` → `-socks5`, `-tcp 1` ត្រូវបានលុប (TCP ជា default), ហើយ UDP ប្រើ `-udp`។ កែ `ExecStart` ក្នុង service file ហើយ `daemon-reload` + `restart`។

### ❌ Client ភ្ជាប់មិនបាន

- Password នៅ client និង server ត្រូវដូចគ្នា
- ពិនិត្យថា ping ទៅ server បាន៖ `ping SERVER_IP`
- ពិនិត្យ Security Group/Firewall ថាអនុញ្ញាត ICMP
- ប្រើ client ដោយសិទ្ធិ Administrator/root
- បើ browser ប្រើ proxy ហើយបង្ហាញ `socks version not supported` សូមប្រាកដថាជា **SOCKS5** មិនមែន HTTP proxy
- បើ DNS មានបញ្ហា សូមបើកជម្រើស "Proxy DNS when using SOCKS5" ក្នុង browser

### ❌ `Unsupported architecture` ឬ `Unsupported OS`

OS/CPU របស់ server មិនស្ថិតក្នុងបញ្ជីដែល script គាំទ្រ។ ទាញ file ត្រឹមត្រូវដោយដៃពី release page (ផ្នែកទី 3)។

---

## 10. ដកការដំឡើង (Uninstall)

### ការដំឡើងដោយ script/manual

```bash
sudo systemctl stop pingtunnel
sudo systemctl disable pingtunnel
sudo rm -f /etc/systemd/system/pingtunnel.service
sudo systemctl daemon-reload
sudo rm -rf /opt/pingtunnel
```

### ការដំឡើងដោយ Docker

```bash
docker rm -f pingtunnel-server
```

---

## ឯកសារយោង

- GitHub: https://github.com/esrrhs/pingtunnel
- Releases: https://github.com/esrrhs/pingtunnel/releases
