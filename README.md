# Brian’s Garage 🛠️

**Homelab configurations, scripts, and infrastructure experiments**

Welcome to **Brian’s Garage** — this repository contains the **configurations, scripts, and tooling I use to build, manage, and maintain my homelab**.

Think of this as a working garage: practical, evolving, and occasionally experimental. Some things are polished, others are prototypes, but everything here reflects real-world usage in my environment.

---

## 🧠 What This Repository Is

This repo is a collection of:

- Infrastructure **configuration files** (Docker, Compose, networking, DNS, etc.)
- **Automation scripts** for setup, maintenance, and troubleshooting
- Self‑hosted service configurations (monitoring, security, dev tools, utilities)
- Notes and documentation explaining *why* things are set up the way they are

It’s not meant to be a turnkey product — it’s a **reference implementation of how I run my homelab**.

---

## 🔧 Why “Brian’s Garage”?

Just like a real garage:
- This is where things get built and tuned
- Tools get swapped, upgraded, or replaced
- Experiments happen before they go “production‑ready”

Some projects here eventually stabilize; others are learning exercises. All of them help me better understand systems, reliability, security, and operations.

---

## 📁 Repository Structure

Each directory typically represents a **service, tool, or capability**, for example:

- DNS & networking (e.g., Pi‑hole, sync, local resolution)
- Containers & orchestration (Docker, Compose stacks)
- Observability & monitoring
- Security, identity, and access tooling
- Dev & platform tooling

Most directories include:
- A `README.md` explaining purpose and usage
- Configuration files (`docker-compose.yml`, `.env.example`, etc.)
- Scripts for setup or maintenance

---

## ⚠️ Notes & Caveats

- Configurations are **opinionated** and tailored to my environment
- Secrets are intentionally excluded — use `.env.example` where provided
- Not all setups are production‑hardened
- Breaking changes may occur as tools and approaches evolve

---

## 📌 Usage

You’re welcome to:
- Browse for ideas
- Adapt patterns to your own homelab
- Learn from what worked (and what didn’t)

Just don’t blindly copy‑paste without understanding the implications 😄

---

## 🧭 Guiding Principles

- Prefer **simple, understandable systems**
- Automate repetitive work
- Treat infrastructure as code
- Optimize for reliability and debuggability
- Learn continuously

---

Happy tinkering.
