# Nebula Sync

**Synchronize Pi-hole configurations across primary and secondary DNS servers**

This directory contains **my Docker Compose and environment configuration for running Nebula Sync**, a community-maintained tool that synchronizes configuration between multiple Pi-hole instances.

I use this setup to keep my **primary and secondary Pi-hole DNS servers** in sync for:
- DNS filtering (ad-blocking, tracking protection)
- Local domain name resolution
- High availability and redundancy

I run the nebula-sync container on my Synology NAS and am notified by email if it has a problem.

---

## 🔍 What Nebula Sync Is

Nebula Sync is an open-source tool that **replicates configuration from a primary Pi-hole instance to one or more secondary (replica) Pi-hole servers** using the Pi-hole API.

It supports:
- **Full configuration syncs** via Pi-hole Teleporter
- **Selective syncs** (e.g., gravity, DNS settings, groups, clients)
- **Scheduled sync execution** via cron-style configuration

> ⚠️ Nebula Sync is **not an official Pi-hole project**. It is a community tool that interacts with Pi-hole through its public APIs.

---

## 🧠 Why I Use It

I run **multiple Pi-hole instances** to provide resilient DNS for my network. Manually maintaining identical configuration across instances is tedious and error-prone.

Nebula Sync allows me to:

- ✅ Treat one Pi-hole as the **source of truth**
- 🔁 Automatically propagate configuration changes
- 📊 Ensure consistent DNS filtering behavior
- 🛡 Maintain redundancy if one DNS server goes offline

This approach is especially useful for homelabs, multi-site networks, or environments where DNS reliability matters.

---

## 📁 Repository / Directory Layout

This directory contains:

- **`docker-compose.yml`**  
  Runs Nebula Sync as a containerized service

- **`.env` (or environment files)**  
  Stores Pi-hole endpoints, API tokens, schedules, and sync options

- **`README.md` (this file)**  
  Documents how and why Nebula Sync is used in my environment

All configuration in this directory is specific to **how I run Nebula Sync**, not the upstream project itself.

---

## 🧩 How It Works (High Level)

1. **Primary Pi-hole**  
   Acts as the authoritative configuration source

2. **Nebula Sync container**  
   Connects to the primary Pi-hole via API, exports configuration

3. **Secondary Pi-hole(s)**  
   Receive updates and apply changes automatically

4. **Scheduled sync**  
   Keeps all replicas aligned over time

---

## 🔗 Source Material & References

Upstream project and documentation:

- **Nebula Sync (GitHub)**  
  https://github.com/lovelaze/nebula-sync

Additional community resources:

- Pi-hole community discussions and examples  
  https://www.reddit.com/r/pihole/search?q=nebula-sync

- Docker-based setup walkthroughs  
  https://wiki.hakedev.com/docs/proxmox/nebula-sync

- Video guides and demos  
  Search YouTube for *“Nebula Sync Pi-hole”*

---

## 📌 Notes

- This repository **does not re-implement Nebula Sync** — it only contains configuration.
- Pi-hole v6.x is recommended.
- API tokens must be kept secret and should never be committed.
