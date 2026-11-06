#!/bin/bash
# Descr: tlshunter.sh, ETL-wrapper for tlstest.sh by using nmap to generate a tlstest.sh configuration file, and sqlite3 to create a database based on tlstest.sh's output.
# Author: B.J. van Buuren -- https://github.com/j4cc0
# License: BSD 3-clause

# -- Globals

TESTSSL="testssl" # On some platforms it's called testssl.sh
export DEBUG="" # Disabled when empty. Any other value will switch debugging on, NOTE: testssl itself uses this too (values 1-3)!

SCRIPT="$(basename ${0%.sh})"
TLSHUNTERDIR=$(dirname $(readlink -f "$0"))
SQLFILE="${TLSHUNTERDIR}/${SCRIPT}.sql"

RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
PURPLE="\e[0;35m"
EOC="\e[0m"

COLOR=("$RED" "$GREEN" "$YELLOW" "$BLUE" "$PURPLE")

ONTTY="$(tty -s && echo 'YES' || echo '')"

# -- Parameter parsing

if [ "x${1}x" = "x-nx" -o "x{$1}x" = "x--no-colorx" ]; then
	# Pretend that you're not on a tty if you don't want colors in output.
	ONTTY=""
	shift
fi

if [ "x${ONTTY}x" = "xx" ]; then
	# Disable all colors if you're not on a tty.
	COLOR=()
	RED=""
	GREEN=""
	YELLOW=""
	BLUE=""
	PURPLE=""
	EOC=""
fi

if [ "x${ONTTY}x" != "xx" ]; then
	# We're on a tty
	echo -e "$(cat <<-___EOF___
	${GREEN}┌──────────────────────────────────────┐${EOC}
	${YELLOW}│░▀█▀░█░░░█▀▀░█░█░█░█░█▀█░▀█▀░█▀▀░█▀▄░░│${EOC}
	${RED}│░░█░░█░░░▀▀█░█▀█░█░█░█░█░░█░░█▀▀░█▀▄░░│${EOC}
	${YELLOW}│░░▀░░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀░▀░░│${EOC}
	${GREEN}└──────────────────────────────────────┘${EOC}
	${EOC}
	___EOF___
	)"
fi

if [ "x${1}x" = "x-hx" -o "x${1}x" = "x--helpx" ]; then
	echo -e "$(cat <<-___EOF___
	${GREEN}${SCRIPT}${EOC} [-n|--no-color] [-h|--help] ${YELLOW}<file-containing-hostnames> <file-containing-port-numbers> [output-directory]${EOC}

	Scan all hosts from ${YELLOW}file-containing-hostnames${EOC} on ports as specified in ${YELLOW}file-containing-port-numbers${EOC}
	for TLS details using ${RED}nmap${EOC} and ${RED}testssl.sh${EOC}. Resulting output is stored in ${YELLOW}output-directory${EOC}.

	The CSV file from testssl is used to build a ${RED}sqlite3${EOC} database, containing all TLS details.
	Final result is an overview of TLS versions used per host,ip and port-number, as well as indicators for
	which hosts are capable of post quantum secure communication and which are not.
	${EOC}
	___EOF___
	)"
	exit 0
fi

NETFILE="${1:-${SCRIPT}-net.conf}"
PORTFILE="${2:-${SCRIPT}-port.conf}"
MYOUTDIR="${3:-${SCRIPT}-$(date '+%Y%m%d')}"

# -- Global constants

CSVFILE="${MYOUTDIR}/${SCRIPT}.csv"
DBFILE="${MYOUTDIR}/${SCRIPT}.db"
DBLATEST="latest-${SCRIPT}.db"
TESTSSLFILE="${MYOUTDIR}/${SCRIPT}-testssl"
NMAPBASEFN="${MYOUTDIR}/${SCRIPT}-nmap"
NMAPRESULTFILE="${NMAPBASEFN}.nmap"

# -- Functions

warn() {
	echo -e "[${RED}!${EOC}] $@" >&2
	return 0
}

die() {
	warn "$@ Aborted."
	exit 1
}

mustread() {
	for i in $@
	do
		if [ ! -r "$i" ]; then
			die "$i is not readable. Does it exist?"
		fi
	done
	return 0
}

required() {
	for prog in $@
	do
		which -a "$prog" &>/dev/null || \
			die "$prog is not in PATH or not installed."
	done
	return 0
}

debug() {
	if [ "x${DEBUG}x" != "xx" ]; then
		echo -e "[${YELLOW}D${EOC}] $@"
	fi
	return 0
}

note() {
	echo -e "[${GREEN}+${EOC}] $@"
	return 0
}

waitforpid() {
	if [ "$#" -ne 1 ]; then
		die "Internal error. No pid specified."
	fi
	expr "$1" + 0 &>/dev/null
	if [ "$?" -ne 0 ]; then
		die "Internal error. Pid not numeric."
	fi
	pid="$1"
	FOUNDPID=$(ps ax | awk '{print $1}' | grep "^${pid}$")
	while [ "x${FOUNDPID}x" != "xx" ]; do
		if [ "x${ONTTY}x" != "xx" ]; then
			sec=$(date '+%s')
			dial=$(echo $(($sec % 4)) | sed 's/0/\\\\/;s/1/|/;s/2/\//;s/3/-/')
			#color=$(( $sec % 5 ))
			color=$(( $sec % ${#COLOR[@]} ))
			printf "\r[${COLOR[$color]}${dial}${EOC}] "
		fi
		FOUNDPID=$(ps ax | awk '{print $1}' | grep "^${pid}$")
		sleep 1
	done
	printf "\r"
	return 0
}

# -- Sanity checks

note "$(date) -- $SCRIPT checking prerequisites."

debug "---->[ $SCRIPT debugging is ON ]<----"

required "$TESTSSL" nmap sqlite3
mustread "$NETFILE" "$PORTFILE" "$SQLFILE"

mkdir -p "$MYOUTDIR" && \
	note "Output is in $MYOUTDIR" || \
	die "Failed to create $MYOUTDIR"

PORTS="$(sed 's/#.*$//' $PORTFILE | xargs echo | sed 's/ /,/g')"
if [ "x${PORTS}x" = "xx" ]; then
	warn "No ports were defined. Assuming ALL ports."
	PORTS="-"
fi

# -- Main

note "$(date) -- $SCRIPT has started."

# 1. Make a list of systems that respond to the ports

if [ ! -r "$NMAPRESULTFILE" -o "$NETFILE" -nt "$NMAPRESULTFILE" -o "$PORTFILE" -nt "$NMAPRESULTFILE" ]; then
	# Only scan if there's no scan results, or there's a newer version of either -net or -port configuration
	if [ "x${DEBUG}x" != "xx" ]; then
		nmap -iL "$NETFILE" -p "$PORTS" -sT -oA "$NMAPBASEFN"
	else
		note "Running nmap to verify open ports and host availability. This may take a while...."
		nmap -iL "$NETFILE" -p "$PORTS" -sT -oA "$NMAPBASEFN" &>/dev/null &
		waitforpid "$!"
	fi
else
	warn "$NMAPRESULTFILE already exists. Skipping scan."
fi

# 2. Write a testssl.sh "iL" file for testssl.sh to devour

mustread "$NMAPRESULTFILE"

if [ ! -r "$TESTSSLFILE" -o "$NMAPRESULTFILE" -nt "$TESTSSLFILE" ]; then
	note "Constructing testssl configuration..."
	host=""
	cat "$NMAPRESULTFILE" | grep -vE 'filtered|closed|^MAC|^PORT|^rDNS|^#.*|^ *$|^Host is|(not scanned)' | sed 's#^Nmap.*for ##;s#/.*$##' | while read line
	do
		debug "Parsing: $line"
		ishost="$(echo $line | grep '\.' | sed 's/ .*$//')"
		if [ "x${ishost}x" != "xx" ]; then
			debug "Found host: $ishost"
			host="$ishost"
			continue
		fi
		isport="$(echo $line | grep '^[0-9]*$')"
		if [ "x${isport}x" != "xx" -a "x${host}x" != "xx" ]; then
			debug "Found port: $isport"
			case $isport in
			25)
				echo "-t smtp $host:$isport" >> "$TESTSSLFILE"
				;;
			*)
				echo "$host:$isport" >> "$TESTSSLFILE"
				;;
			esac
		else
			warn "$isport is missing a host!"
		fi
	done
else
	warn "$TESTSSLFILE already exists and is current. Skipping."
fi
	
# 3. Make sure testssl.sh outputs CSV files and runs in batch mode (no interaction)

mustread "$TESTSSLFILE"

if [ ! -r "$CSVFILE" -o "$TESTSSLFILE" -nt "$CSVFILE" ]; then
	touch "$CSVFILE" || \
		die "Failed to write ${CSVFILE}."
	if [ "x${DEBUG}x" != "xx" ]; then
		$TESTSSL -q --openssl-timeout 5 --connect-timeout 5 --parallel --logfile "$MYOUTDIR" --overwrite --csvfile "$CSVFILE" -iL "$TESTSSLFILE"
	else
		note "Running testssl on available hosts and ports. This may take a while...."
		$TESTSSL -q --openssl-timeout 5 --connect-timeout 5 --parallel --logfile "$MYOUTDIR" --overwrite --csvfile "$CSVFILE" -iL "$TESTSSLFILE" &>/dev/null &
		waitforpid "$!"
	fi
else
	warn "$CSVFILE already exists and is current. Skipping."
fi

# 4. Let sqlite3 eat all the CSV files into a single database and table

mustread "$CSVFILE"

if [ ! -r "$DBFILE" -o "$CSVFILE" -nt "$DBFILE" ]; then
	touch "$DBFILE" || \
		die "Failed to write ${DBFILE}."
	if [ "x${DEBUG}x" != "xx" ]; then
		debug "Now generating $DBFILE"
		cat <<-___EOF___ | sqlite3 "$DBFILE"
			.mode csv
			.import "$CSVFILE" testssl
			.quit
			___EOF___
		retv="$?"
	else
		note "Now generating $DBFILE"
		cat <<-___EOF___ | sqlite3 "$DBFILE" &>/dev/null
			.mode csv
			.import "$CSVFILE" testssl
			.quit
			___EOF___
		retv="$?"
	fi
	if [ "$retv" -ne 0 ]; then
		warn "sqlite3 had no clean exit. Please check ${DBFILE}."
	fi
else
	warn "$DBFILE already exists and is current. Skipping."
fi

# 5. Add view(s) to the database, this is where most of the magic (should) happen

mustread "$DBFILE"

ln -sf "${DBFILE}" "${DBLATEST}" &>/dev/null
note "Adding views to the database."
cat "$SQLFILE" | sqlite3 "$DBFILE" &>/dev/null
if [ "$?" -ne 0 ]; then
	warn "sqlite3 had no clean exit. Please check ${DBFILE}."
fi

# 6. Do some queries. Like it's all there

note "[ ${YELLOW}===== ${PURPLE}Just a few demo queries to help you get started${YELLOW} =====${EOC} ]"

note "Total number of hosts queried:"
echo 'select count(distinct `fqdn/ip`) as counted_hosts from tls_details;' | sqlite3 "$DBFILE"

note "Total amount of ports queried:"
echo 'select count(distinct `fqdn/ip:port`) as ports_queried from tls_details;' | sqlite3 "$DBFILE"

note "Potential ${RED}VULNERABLE HOSTS${EOC}:"
echo "select * from testssl where finding like 'VULNERABLE%';" | sqlite3 "$DBFILE"

note "Certificate expiry:"
echo "select \`fqdn/ip\`, port, cert_commonName, cert_subjectAltName, cert_caIssuers, cert_signatureAlgorithm, cert_keySize, cert_notBefore, cert_notAfter, printf('%16.2f', julianday(cert_notAfter) - julianday(cert_notBefore)) as cert_validfordays, printf('%16.2f', julianday(cert_notAfter) - julianday(date())) as cert_expireswithindays from cert_info;" | sqlite3 "$DBFILE"

note "TLS versions found on the following hosts:"
echo "select host,ip,port,tls_ver from all_tls_ver;" | sqlite3 "$DBFILE"

note "TLS versions in use:"
echo 'select tls_ver as "TLS version", count(tls_ver) as Occurence, count(*) * 100.0 / sum(count(*)) over() as Percentage from all_tls_ver group by tls_ver;' | sqlite3 "$DBFILE"

note "ECDHE curves found:"
echo 'select * from ecdhe_curves order by `fqdn/ip`, port;' | sqlite3 "$DBFILE"

note "Post Quantum Secure transport (not certificate) ${GREEN}capable${EOC} hosts:"
echo "select host,ip,port from pqs_capable_hosts;" | sqlite3 "$DBFILE"

note "Post Quantum transport ${RED}UNSAFE${EOC} hosts:"
echo "select host,ip,port from pq_unsafe_hosts;" | sqlite3 "$DBFILE"

note "(PQ) Key Encapsulation Mechanisms:"
echo 'select `fqdn/ip`,port,finding as "KEM" from testssl where id = @FS_KEMs@ and finding <> @No KEMs offered@ order by `fqdn/ip`, port;' | sed "s/@/'/g" | sqlite3 "$DBFILE"

note "$(date) -- $SCRIPT done."

exit 0

###############
# - THE END - #
###############

