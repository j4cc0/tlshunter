# tlshunter
Wrapper around nmap and testssl to scan for SSL/TLS details and store them in a sqlite3 database

> [!CAUTION]
>  Not fully tested yet. Expect bugs.

## Usage

`tlshunter [-n|--no-color] [-h|--help] <file-containing-hostnames> <file-containing-port-numbers> [output-directory]`

Scan all hosts from `file-containing-hostnames` on ports as specified in `file-containing-port-numbers`
for TLS details using [`nmap`](https://nmap.org/) and [`testssl.sh`](https://testssl.sh/). Resulting output is stored in `output-directory`, or `tlshunter-<date>` if omitted.

The CSV file from testssl is used to build a [sqlite3](https://www.sqlite.org/) database, containing all TLS details.
Final result is an overview of TLS versions used per host,ip and port-number, as well as indicators for
which hosts are capable of post quantum secure communication and which are not.

## Example 1

Below is the scan-output of a single host.

```
 $ ~/tlshunter/tlshunter.sh ~/tlshunter/tlshunter-net.conf ~/tlshunter/tlshunter-port.conf
┌──────────────────────────────────────┐
│░▀█▀░█░░░█▀▀░█░█░█░█░█▀█░▀█▀░█▀▀░█▀▄░░│
│░░█░░█░░░▀▀█░█▀█░█░█░█░█░░█░░█▀▀░█▀▄░░│
│░░▀░░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀░▀░░│
└──────────────────────────────────────┘

[+] Fri Nov  6 05:33:31 PM CET 2026 -- tlshunter checking prerequisites.
[+] Output is in tlshunter-20261106
[+] Fri Nov  6 05:33:31 PM CET 2026 -- tlshunter has started.
[+] Running nmap to verify open ports and host availability. This may take a while....
[+] Constructing testssl configuration...
[+] Running testssl on available hosts and ports. This may take a while....
[+] Now generating tlshunter-20261106/tlshunter.db
[+] Adding views to the database.
[+] [ ===== Just a few demo queries to help you get started ===== ]
[+] Total number of hosts queried:
╭───────────────╮
│ counted_hosts │
╞═══════════════╡
│             1 │
╰───────────────╯
[+] Total amount of ports queried:
╭───────────────╮
│ ports_queried │
╞═══════════════╡
│             1 │
╰───────────────╯
[+] Potential VULNERABLE HOSTS:
╭───────┬───────────────────────────┬───────┬──────────┬──────────────────────────────────────────────────────────────────────────────────────┬───────────────┬────────╮
│  id   │          fqdn/ip          │ port  │ severity │                                       finding                                        │      cve      │  cwe   │
╞═══════╪═══════════════════════════╪═══════╪══════════╪══════════════════════════════════════════════════════════════════════════════════════╪═══════════════╪════════╡
│ BEAST │ badssl.com/104.154.89.105 │ '443' │ LOW      │ VULNERABLE -- but also supports higher protocols  TLSv1.1 TLSv1.2 (likely mitigated) │ CVE-2011-3389 │ CWE-20 │
╰───────┴───────────────────────────┴───────┴──────────┴──────────────────────────────────────────────────────────────────────────────────────┴───────────────┴────────╯
[+] Certificate expiry:
╭────────────────┬─────┬───────────────┬───────────────────────┬──────────────┬────────────────────┬─────────────────┬────────────────┬────────────────┬──────────────────┬────────────────────╮
│    fqdn/ip     │port │cert_commonName│  cert_subjectAltName  │cert_caIssuers│cert_signatureAlg...│  cert_keySize   │ cert_notBefore │ cert_notAfter  │cert_validfordays │cert_expireswithi...│
╞════════════════╪═════╪═══════════════╪═══════════════════════╪══════════════╪════════════════════╪═════════════════╪════════════════╪════════════════╪══════════════════╪════════════════════╡
│badssl.com/104. │'443'│*.badssl.com   │*.badssl.com badssl.com│YR1 (Let's    │SHA256 with RSA     │RSA 2048 bits    │2026-09-29 20:02│2026-12-28 20:02│'           90.00'│'           52.83'  │
│154.89.105      │     │               │                       │Encrypt from  │                    │(exponent is     │                │                │                  │                    │
│                │     │               │                       │US)           │                    │65537)           │                │                │                  │                    │
╰────────────────┴─────┴───────────────┴───────────────────────┴──────────────┴────────────────────┴─────────────────┴────────────────┴────────────────┴──────────────────┴────────────────────╯
[+] TLS versions found on the following hosts:
╭────────────┬────────────────┬───────┬─────────╮
│    host    │       ip       │ port  │ tls_ver │
╞════════════╪════════════════╪═══════╪═════════╡
│ badssl.com │ 104.154.89.105 │ '443' │ TLSv1   │
│ badssl.com │ 104.154.89.105 │ '443' │ TLSv1.1 │
│ badssl.com │ 104.154.89.105 │ '443' │ TLSv1.2 │
╰────────────┴────────────────┴───────┴─────────╯
[+] TLS versions in use:
╭─────────────┬───────────┬────────────────────╮
│ TLS version │ Occurence │     Percentage     │
╞═════════════╪═══════════╪════════════════════╡
│ TLSv1       │         1 │ 33.333333333333336 │
│ TLSv1.1     │         1 │ 33.333333333333336 │
│ TLSv1.2     │         1 │ 33.333333333333336 │
╰─────────────┴───────────┴────────────────────╯
[+] ECDHE curves found:
╭───────────────────────────┬───────┬────────────╮
│          fqdn/ip          │ port  │   curve    │
╞═══════════════════════════╪═══════╪════════════╡
│ badssl.com/104.154.89.105 │ '443' │ prime256v1 │
╰───────────────────────────┴───────┴────────────╯
[+] Post Quantum Secure transport (not certificate) capable hosts:
[+] Post Quantum transport UNSAFE hosts:
╭────────────┬────────────────┬───────╮
│    host    │       ip       │ port  │
╞════════════╪════════════════╪═══════╡
│ badssl.com │ 104.154.89.105 │ '443' │
╰────────────┴────────────────┴───────╯
[+] (PQ) Key Encapsulation Mechanisms:
[+] Fri Nov  6 05:37:47 PM CET 2026 -- tlshunter done.
```

---

## Example 2

Below is the scan-output of a mix of multiple hosts:

```
$ ~/tlshunter/tlshunter.sh ~/tlshunter/tlshunter-net.conf ~/tlshunter/tlshunter-port.conf
┌──────────────────────────────────────┐
│░▀█▀░█░░░█▀▀░█░█░█░█░█▀█░▀█▀░█▀▀░█▀▄░░│
│░░█░░█░░░▀▀█░█▀█░█░█░█░█░░█░░█▀▀░█▀▄░░│
│░░▀░░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀░▀░░│
└──────────────────────────────────────┘

[+] Fri Nov  6 09:45:03 PM CET 2026 -- tlshunter checking prerequisites.
[+] Output is in tlshunter-20261106
[+] Fri Nov  6 09:45:04 PM CET 2026 -- tlshunter has started.
[!] tlshunter-20261106/tlshunter-nmap.nmap already exists. Skipping scan.
[!] tlshunter-20261106/tlshunter-testssl already exists and is current. Skipping.
[!] tlshunter-20261106/tlshunter.csv already exists and is current. Skipping.
[!] tlshunter-20261106/tlshunter.db already exists and is current. Skipping.
[+] Adding views to the database.
[+] [ ===== Just a few demo queries to help you get started ===== ]
[+] Total number of hosts queried:
╭───────────────╮
│ counted_hosts │
╞═══════════════╡
│             5 │
╰───────────────╯
[+] Total amount of ports queried:
╭───────────────╮
│ ports_queried │
╞═══════════════╡
│             6 │
╰───────────────╯
[+] Potential VULNERABLE HOSTS:
╭──────────────────────┬─────────────────────────────────────────┬───────┬──────────┬──────────────────────────────────────────────────────────────────────────────────────┬───────────────┬─────────╮
│          id          │                 fqdn/ip                 │ port  │ severity │                                       finding                                        │      cve      │   cwe   │
╞══════════════════════╪═════════════════════════════════════════╪═══════╪══════════╪══════════════════════════════════════════════════════════════════════════════════════╪═══════════════╪═════════╡
│ secure_client_renego │ 192.168.1.52/192.168.1.52               │ '443' │ HIGH     │ VULNERABLE, DoS threat                                                               │ CVE-2011-1473 │ CWE-310 │
│ BEAST                │ pq.cloudflareresearch.com/104.18.31.220 │ '443' │ LOW      │ VULNERABLE -- but also supports higher protocols  TLSv1.1 TLSv1.2 (likely mitigated) │ CVE-2011-3389 │ CWE-20  │
│ BEAST                │ pq.cloudflareresearch.com/104.18.30.220 │ '443' │ LOW      │ VULNERABLE -- but also supports higher protocols  TLSv1.1 TLSv1.2 (likely mitigated) │ CVE-2011-3389 │ CWE-20  │
│ BEAST                │ testssl.sh/81.169.235.32                │ '25'  │ LOW      │ VULNERABLE -- but also supports higher protocols  TLSv1.1 TLSv1.2 (likely mitigated) │ CVE-2011-3389 │ CWE-20  │
╰──────────────────────┴─────────────────────────────────────────┴───────┴──────────┴──────────────────────────────────────────────────────────────────────────────────────┴───────────────┴─────────╯
[+] Certificate expiry:
╭───────────────────────────────────────┬─────┬─────────────────────────┬─────────────────────────────────────────────────────┬───────────────────────────────────┬────────────────────┬─────────────────────────────────┬────────────────┬────────────────┬──────────────────┬────────────────────╮
│                fqdn/ip                │port │     cert_commonName     │                 cert_subjectAltName                 │          cert_caIssuers           │cert_signatureAlg...│          cert_keySize           │ cert_notBefore │ cert_notAfter  │cert_validfordays │cert_expireswithi...│
╞═══════════════════════════════════════╪═════╪═════════════════════════╪═════════════════════════════════════════════════════╪═══════════════════════════════════╪════════════════════╪═════════════════════════════════╪════════════════╪════════════════╪══════════════════╪════════════════════╡
│192.168.1.52/192.168.1.52              │'443'│tplinkdeco.net           │No SAN, browsers are complaining                     │tplinkdeco.net                     │SHA256 with RSA     │RSA 2048 bits (exponent is 65537)│2010-01-01 00:00│2030-12-31 00:00│'         7669.00'│'         1516.00'  │
│pq.cloudflareresearch.com/104.18.30.220│'443'│pq.cloudflareresearch.com│pq.cloudflareresearch.com *.pq.cloudflareresearch.com│WR1 (Google Trust Services from US)│SHA256 with RSA     │RSA 2048 bits (exponent is 65537)│2026-09-24 13:07│2026-12-23 14:05│'           90.04'│'           47.59'  │
│pq.cloudflareresearch.com/104.18.30.220│'443'│pq.cloudflareresearch.com│pq.cloudflareresearch.com *.pq.cloudflareresearch.com│WE1 (Google Trust Services from US)│ECDSA with SHA256   │EC 256 bits (curve P-256)        │2026-09-24 13:08│2026-12-23 14:07│'           90.04'│'           47.59'  │
│pq.cloudflareresearch.com/104.18.31.220│'443'│pq.cloudflareresearch.com│pq.cloudflareresearch.com *.pq.cloudflareresearch.com│WR1 (Google Trust Services from US)│SHA256 with RSA     │RSA 2048 bits (exponent is 65537)│2026-09-24 13:07│2026-12-23 14:05│'           90.04'│'           47.59'  │
│pq.cloudflareresearch.com/104.18.31.220│'443'│pq.cloudflareresearch.com│pq.cloudflareresearch.com *.pq.cloudflareresearch.com│WE1 (Google Trust Services from US)│ECDSA with SHA256   │EC 256 bits (curve P-256)        │2026-09-24 13:08│2026-12-23 14:07│'           90.04'│'           47.59'  │
│rasp-kali-lan/192.168.1.50             │'443'│pi.hole                  │pi.hole                                              │pi.hole (Pi-hole from DE)          │ECDSA with SHA256   │EC 384 bits (curve P-384)        │2025-02-22 09:41│2055-02-22 09:41│'        10957.00'│'        10335.40'  │
│testssl.sh/81.169.235.32               │'25' │testssl.sh               │borken.testssl.sh dev.testssl.sh testssl.sh          │YR2 (Let's Encrypt from US)        │SHA256 with RSA     │RSA 2048 bits (exponent is 65537)│2026-08-15 22:57│2026-11-13 22:57│'           90.00'│'            7.96'  │
│testssl.sh/81.169.235.32               │'443'│testssl.sh               │borken.testssl.sh dev.testssl.sh testssl.sh          │YR2 (Let's Encrypt from US)        │SHA256 with RSA     │RSA 2048 bits (exponent is 65537)│2026-08-15 22:57│2026-11-13 22:57│'           90.00'│'            7.96'  │
╰───────────────────────────────────────┴─────┴─────────────────────────┴─────────────────────────────────────────────────────┴───────────────────────────────────┴────────────────────┴─────────────────────────────────┴────────────────┴────────────────┴──────────────────┴────────────────────╯
[+] TLS versions found on the following hosts:
╭───────────────────────────┬────────────────┬───────┬─────────╮
│           host            │       ip       │ port  │ tls_ver │
╞═══════════════════════════╪════════════════╪═══════╪═════════╡
│ 192.168.1.52              │ 192.168.1.52   │ '443' │ TLSv1.2 │
│ pq.cloudflareresearch.com │ 104.18.30.220  │ '443' │ TLSv1   │
│ pq.cloudflareresearch.com │ 104.18.30.220  │ '443' │ TLSv1.1 │
│ pq.cloudflareresearch.com │ 104.18.30.220  │ '443' │ TLSv1.2 │
│ pq.cloudflareresearch.com │ 104.18.30.220  │ '443' │ TLSv1.3 │
│ pq.cloudflareresearch.com │ 104.18.31.220  │ '443' │ TLSv1   │
│ pq.cloudflareresearch.com │ 104.18.31.220  │ '443' │ TLSv1.1 │
│ pq.cloudflareresearch.com │ 104.18.31.220  │ '443' │ TLSv1.2 │
│ pq.cloudflareresearch.com │ 104.18.31.220  │ '443' │ TLSv1.3 │
│ rasp-kali-lan             │ 192.168.1.50   │ '443' │ TLSv1.2 │
│ rasp-kali-lan             │ 192.168.1.50   │ '443' │ TLSv1.3 │
│ testssl.sh                │ 81.169.235.32  │ '25'  │ TLSv1   │
│ testssl.sh                │ 81.169.235.32  │ '25'  │ TLSv1.1 │
│ testssl.sh                │ 81.169.235.32  │ '25'  │ TLSv1.2 │
│ testssl.sh                │ 81.169.235.32  │ '25'  │ TLSv1.3 │
│ testssl.sh                │ 81.169.235.32  │ '443' │ TLSv1.2 │
│ testssl.sh                │ 81.169.235.32  │ '443' │ TLSv1.3 │
╰───────────────────────────┴────────────────┴───────┴─────────╯
[+] TLS versions in use:
╭─────────────┬───────────┬────────────────────╮
│ TLS version │ Occurence │     Percentage     │
╞═════════════╪═══════════╪════════════════════╡
│ TLSv1       │         3 │ 17.647058823529413 │
│ TLSv1.1     │         3 │ 17.647058823529413 │
│ TLSv1.2     │         6 │ 35.294117647058826 │
│ TLSv1.3     │         5 │ 29.411764705882352 │
╰─────────────┴───────────┴────────────────────╯
[+] ECDHE curves found:
╭─────────────────────────────────────────┬───────┬─────────────────╮
│                 fqdn/ip                 │ port  │      curve      │
╞═════════════════════════════════════════╪═══════╪═════════════════╡
│ 192.168.1.52/192.168.1.52               │ '443' │ secp256k1       │
│ 192.168.1.52/192.168.1.52               │ '443' │ prime256v1      │
│ 192.168.1.52/192.168.1.52               │ '443' │ secp384r1       │
│ 192.168.1.52/192.168.1.52               │ '443' │ secp521r1       │
│ 192.168.1.52/192.168.1.52               │ '443' │ brainpoolP256r1 │
│ 192.168.1.52/192.168.1.52               │ '443' │ brainpoolP384r1 │
│ 192.168.1.52/192.168.1.52               │ '443' │ brainpoolP512r1 │
│ pq.cloudflareresearch.com/104.18.30.220 │ '443' │ prime256v1      │
│ pq.cloudflareresearch.com/104.18.30.220 │ '443' │ secp384r1       │
│ pq.cloudflareresearch.com/104.18.30.220 │ '443' │ secp521r1       │
│ pq.cloudflareresearch.com/104.18.30.220 │ '443' │ X25519          │
│ pq.cloudflareresearch.com/104.18.31.220 │ '443' │ prime256v1      │
│ pq.cloudflareresearch.com/104.18.31.220 │ '443' │ secp384r1       │
│ pq.cloudflareresearch.com/104.18.31.220 │ '443' │ secp521r1       │
│ pq.cloudflareresearch.com/104.18.31.220 │ '443' │ X25519          │
│ rasp-kali-lan/192.168.1.50              │ '443' │ prime256v1      │
│ rasp-kali-lan/192.168.1.50              │ '443' │ secp384r1       │
│ rasp-kali-lan/192.168.1.50              │ '443' │ secp521r1       │
│ rasp-kali-lan/192.168.1.50              │ '443' │ X25519          │
│ rasp-kali-lan/192.168.1.50              │ '443' │ X448            │
│ testssl.sh/81.169.235.32                │ '25'  │ prime256v1      │
│ testssl.sh/81.169.235.32                │ '25'  │ secp384r1       │
│ testssl.sh/81.169.235.32                │ '25'  │ secp521r1       │
│ testssl.sh/81.169.235.32                │ '25'  │ X25519          │
│ testssl.sh/81.169.235.32                │ '25'  │ X448            │
│ testssl.sh/81.169.235.32                │ '443' │ prime256v1      │
│ testssl.sh/81.169.235.32                │ '443' │ secp384r1       │
│ testssl.sh/81.169.235.32                │ '443' │ secp521r1       │
│ testssl.sh/81.169.235.32                │ '443' │ X25519          │
│ testssl.sh/81.169.235.32                │ '443' │ X448            │
╰─────────────────────────────────────────┴───────┴─────────────────╯
[+] Post Quantum Secure transport (not certificate) capable hosts:
╭───────────────────────────┬───────────────┬───────╮
│           host            │      ip       │ port  │
╞═══════════════════════════╪═══════════════╪═══════╡
│ pq.cloudflareresearch.com │ 104.18.30.220 │ '443' │
│ pq.cloudflareresearch.com │ 104.18.31.220 │ '443' │
│ testssl.sh                │ 81.169.235.32 │ '443' │
╰───────────────────────────┴───────────────┴───────╯
[+] Post Quantum transport UNSAFE hosts:
╭────────────────┬────────────────┬───────╮
│      host      │       ip       │ port  │
╞════════════════╪════════════════╪═══════╡
│ 192.168.1.52   │ 192.168.1.52   │ '443' │
│ rasp-kali-lan  │ 192.168.1.50   │ '443' │
│ testssl.sh     │ 81.169.235.32  │ '25'  │
╰────────────────┴────────────────┴───────╯
[+] (PQ) Key Encapsulation Mechanisms:
╭─────────────────────────────────────────┬───────┬────────────────╮
│                 fqdn/ip                 │ port  │      KEM       │
╞═════════════════════════════════════════╪═══════╪════════════════╡
│ pq.cloudflareresearch.com/104.18.30.220 │ '443' │ X25519MLKEM768 │
│ pq.cloudflareresearch.com/104.18.31.220 │ '443' │ X25519MLKEM768 │
│ testssl.sh/81.169.235.32                │ '443' │ X25519MLKEM768 │
╰─────────────────────────────────────────┴───────┴────────────────╯
[+] Fri Nov  6 09:45:04 PM CET 2026 -- tlshunter done.

```


----

> **_NOTE:_**
> More to follow here
