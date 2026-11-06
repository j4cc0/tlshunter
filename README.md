# tlshunter
Wrapper around nmap and testssl to scan for SSL/TLS details and store them in a sqlite3 database

> [!CAUTION]
>  Not fully tested yet. Expect bugs.

## Usage

tlshunter [-n|--no-color] [-h|--help] <file-containing-hostnames> <file-containing-port-numbers> [output-directory]

Scan all hosts from file-containing-hostnames on ports as specified in file-containing-port-numbers
for TLS details using nmap and testssl.sh. Resulting output is stored in output-directory.

The CSV file from testssl is used to build a sqlite3 database, containing all TLS details.
Final result is an overview of TLS versions used per host,ip and port-number, as well as indicators for
which hosts are capable of post quantum secure communication and which are not.

## Example

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


----

> **_NOTE:_**
> More to follow here
