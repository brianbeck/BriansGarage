# Fail2ban Setup for Caddy (LXC / Proxmox)

This guide shows how to:

1. Install **fail2ban** and verify firewall support works
2. Install **5 Caddy fail2ban filters + jails** from a GitHub repo
3. Understand what each filter/jail does
4. Validate matching, banning, and troubleshooting

> Assumptions:
> - Caddy is already logging JSON access logs to: `/var/log/caddy/access.log`
> - Caddy runs inside an **LXC container** (Debian/Ubuntu style)
> - You are using **nftables** (modern default)
> - Your LAN is `192.168.20.0/24` (adjust as needed)

---

## 1) Install fail2ban and verify firewall support

### 1.1 Install fail2ban

```bash
sudo apt update
sudo apt install -y fail2ban
```

Enable and start:

```bash
sudo systemctl enable --now fail2ban
sudo systemctl status fail2ban --no-pager
```

---

### 1.2 Ensure nftables exists (recommended)

Check if nft is available:

```bash
which nft && nft --version
```

If missing:

```bash
sudo apt install -y nftables
sudo systemctl enable --now nftables
```

---

### 1.3 Verify the LXC can access firewall rules

This confirms the container has sufficient capabilities:

```bash
sudo nft list ruleset >/dev/null && echo "OK: nft list ruleset works"
```

If this fails with permission errors, you likely need Proxmox LXC capability changes (NET_ADMIN / apparmor / nesting).

---

### 1.4 Verify fail2ban can create firewall rules (forced test)

After jails are installed (later in this guide), run:

```bash
sudo fail2ban-client set caddy-exploit banip 1.2.3.4
sudo fail2ban-client status caddy-exploit
sudo nft list ruleset | grep -inE 'fail2ban|f2b|caddy' || true
sudo fail2ban-client set caddy-exploit unbanip 1.2.3.4
```

If you see rules/chains appear, fail2ban ↔ nftables is working.

---

## 2) Install the 5 Caddy filters + jails from GitHub

### 2.1 Expected repo layout

This guide assumes your repo looks like:

```
repo-root/
  fail2ban/
    filter.d/
      caddy-exploit.conf
      caddy-404.conf
      caddy-badhost.conf
      caddy-badagent.conf
      caddy-bad-requests.conf
    jail.d/
      caddy-exploit.local
      caddy-404-scanner.local
      caddy-badhost.local
      caddy-badagent.local
      caddy-bad-requests.local
```

Adjust paths if your layout differs.

---

### 2.2 Copy filters into fail2ban

From the repo root:

```bash
sudo cp -v fail2ban/filter.d/caddy-*.conf /etc/fail2ban/filter.d/
sudo chmod 644 /etc/fail2ban/filter.d/caddy-*.conf
```

---

### 2.3 Copy jails into fail2ban

```bash
sudo cp -v fail2ban/jail.d/caddy-*.local /etc/fail2ban/jail.d/
sudo chmod 644 /etc/fail2ban/jail.d/caddy-*.local
```

---

### 2.4 Confirm jails use nftables actions

Check:

```bash
grep -R "action" /etc/fail2ban/jail.d/caddy-*.local
```

Recommended action:

```ini
action = nftables-allports
```

---

### 2.5 Ensure filters include Caddy epoch timestamp parsing

Caddy JSON logs use an epoch timestamp like:

```json
"ts":1771466037.168971
```

Each filter should include:

```ini
datepattern = "ts":{EPOCH}
```

Without this, fail2ban may match in `fail2ban-regex` but never count live failures.

---

### 2.6 Restart fail2ban and verify jails load

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status
```

Expected example:

```
Jail list: caddy-404-scanner, caddy-badagent, caddy-badhost, caddy-exploit, caddy-bad-requests, sshd
```

---

### 2.7 Validate filters against real logs

```bash
sudo fail2ban-regex /var/log/caddy/access.log /etc/fail2ban/filter.d/caddy-exploit.conf
sudo fail2ban-regex /var/log/caddy/access.log /etc/fail2ban/filter.d/caddy-404.conf
```

If matches appear here but jail counters stay at 0, check `datepattern`.

---

## 3) The 5 Caddy filters and what they do

All examples assume JSON logs and:

```ini
datepattern = "ts":{EPOCH}
```

---

### 3.1 caddy-exploit

**Files**
- `/etc/fail2ban/filter.d/caddy-exploit.conf`
- `/etc/fail2ban/jail.d/caddy-exploit.local`

**Purpose**
Blocks obvious exploit probes and sensitive paths:

- `/.env`
- `/.git`
- `/containers`
- `/wp-login`
- `/wp-admin`
- `/phpmyadmin`
- `vendor/phpunit`

**Typical tuning**
- `maxretry = 3`
- `findtime = 600`
- `bantime = 86400`

High signal, low false positives.

---

### 3.2 caddy-404-scanner

**Files**
- `/etc/fail2ban/filter.d/caddy-404.conf`
- `/etc/fail2ban/jail.d/caddy-404-scanner.local`

**Purpose**
Detects path scanners by request rate using HTTP 404 responses.

Bots generate many 404s quickly while probing random paths.

**Typical tuning**
- `maxretry = 20`
- `findtime = 60`
- `bantime = 3600`

This is usually the most effective generic scanner detector.

---

### 3.3 caddy-badhost

**Files**
- `/etc/fail2ban/filter.d/caddy-badhost.conf`
- `/etc/fail2ban/jail.d/caddy-badhost.local`

**Purpose**
Blocks requests using IP-based Host headers, e.g.:

```
Host: 73.231.130.89:80
```

This is typical of automated internet scanning.

**Typical tuning**
- `maxretry = 5`
- `findtime = 300`
- `bantime = 86400`

---

### 3.4 caddy-badagent

**Files**
- `/etc/fail2ban/filter.d/caddy-badagent.conf`
- `/etc/fail2ban/jail.d/caddy-badagent.local`

**Purpose**
Blocks known scanner or automation user agents, e.g.:

- `libredtail-http`
- `sqlmap`
- `masscan`

**Typical tuning**
- `maxretry = 10`
- `findtime = 300`
- `bantime = 7200`

Recommendation:
- Avoid banning on `curl` unless you are sure you will not test from non-ignored IPs.

---

### 3.5 caddy-bad-requests

**Files**
- `/etc/fail2ban/filter.d/caddy-bad-requests.conf`
- `/etc/fail2ban/jail.d/caddy-bad-requests.local`

**Purpose**
Catches specific suspicious URIs you want to block quickly.
Useful when you observe repeated probes in logs.

**Typical tuning**
- `maxretry = 5`
- `findtime = 600`
- `bantime = 3600` to `86400`

---

## 4) Ignore IPs (home lab safety)

Recommended in each jail:

```ini
ignoreip = 127.0.0.1/8 192.168.20.0/24
```

Why:
- Prevents banning your LAN during testing
- Some requests may appear as router IP depending on NAT/protocol

For testing from LAN:
- Temporarily remove `192.168.20.0/24`
- Restart fail2ban
- Restore after testing

---

## 5) Operational checks

### List loaded jails

```bash
sudo fail2ban-client status
```

### Check a specific jail

```bash
sudo fail2ban-client status caddy-exploit
```

### Watch fail2ban live

```bash
sudo journalctl -u fail2ban -f
```

### Watch Caddy logs live

```bash
tail -f /var/log/caddy/access.log
```

---

## 6) Troubleshooting quick reference

### Regex matches but jail shows `Total failed: 0`

Most common causes:

1. Missing `datepattern = "ts":{EPOCH}`
2. Source IP falls under `ignoreip`
3. Backend log reading issue (try `backend = polling` in jail)

Restart after changes:

```bash
sudo systemctl restart fail2ban
```

---

### No nftables rules visible

First, force a ban:

```bash
sudo fail2ban-client set caddy-exploit banip 1.2.3.4
```

Then check:

```bash
sudo nft list ruleset | grep -inE 'fail2ban|f2b|caddy'
```

If fail2ban shows banned IP but nft has no rules, inspect:

```bash
sudo journalctl -u fail2ban --no-pager -n 200
```

Look for permission or nft errors.

---

## 7) Notes on low traffic

It is normal to see little traffic on a home reverse proxy until:

- your IP gets indexed/scanned more widely
- services become discoverable
- bots encounter your DNS

Keeping the exploit + badhost jails enabled gives strong protection with minimal false positives.

---

## 8) Quick sanity checklist

- [ ] fail2ban service running
- [ ] nftables available
- [ ] jails loaded (`fail2ban-client status`)
- [ ] filters include `datepattern`
- [ ] forced ban creates nft rules
- [ ] ignoreip includes LAN (except during testing)
