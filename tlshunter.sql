-- Descr: tlshunter.sql used by tlshunter.sh, an ETL-wrapper for tlstest.sh that uses nmap to generate a tlstest.sh configuration file, and sqlite3 to create a database based on tlstest.sh's output.
-- Author: B.J. van Buuren -- https://github.com/j4cc0
-- License: BSD 3-clause

create view if not exists tls_details (`fqdn/ip`, host, ip, port, `fqdn/ip:port`, cipherspec, tls_ver, hexcode, ossl_cipher, kx, enc, strength, tls_cipher) as select
	`fqdn/ip`,
	substr(`fqdn/ip`,1,instr(`fqdn/ip`,'/')- 1) as host,
	substr(`fqdn/ip`,instr(`fqdn/ip`,'/')+1,length(`fqdn/ip`)) as ip,
	port,
	concat(concat(`fqdn/ip`,':'),port) as `fqdn/ip:port`,
	trim(replace(replace(replace(`finding`,' ','| '), ' |', ''), '|', '')) as cipherspec,
	substr(`finding`,1,instr(`finding`,' ')-1) as tls_ver,
	trim(substr(`finding`,instr(`finding`,' ')+1,instr(`finding`,' ')-1)) as hexcode,
	trim(substr(trim(substr(`finding`,17)),1,instr(trim(substr(`finding`,17)),' '))) as ossl_cipher,
	trim(replace(replace(replace(replace(substr(`finding`,51,12),'   3',''),'   A',''),'   C',''),'   R','')) as kx,
	trim(replace(replace(replace(replace(trim(substr(`finding`,62,13)),'M ',''),'A ',''),'   1',''),'   2','')) as enc,
	trim(substr(`finding`,74,6)) as strength,
	trim(substr(`finding`,83)) as tls_cipher
from testssl where
	testssl.`fqdn/ip` = concat(concat(host,'/'),ip) and testssl.port = port and testssl.id like 'cipher-%'
group by `fqdn/ip`, host, ip, port, cipherspec, tls_ver, hexcode, ossl_cipher, kx, enc, strength, tls_cipher
order by `fqdn/ip`;

create view if not exists pq_unsafe_hosts ( `fqdn/ip:port`, `fqdn/ip`, host, ip, port ) as select 
	tls_details.`fqdn/ip:port` as `fqdn/ip:port`,
	tls_details.`fqdn/ip` as `fqdn/ip`,
	tls_details.host as host,
	tls_details.ip as ip,
	tls_details.port as port
from tls_details, testssl where 
	testssl.`fqdn/ip` != '/' and tls_details.`fqdn/ip:port` not in (
	select `fqdn/ip:port` from tls_details, testssl where 
		testssl.`fqdn/ip` = tls_details.`fqdn/ip` and
		testssl.port = tls_details.port and
		testssl.`fqdn/ip` != '/' and 
		id = 'FS_KEMs' and 
		finding like '%MLKEM%'
	group by `fqdn/ip:port` order by `fqdn/ip:port`) 
group by `fqdn/ip:port`
order by `fqdn/ip:port`;

create view if not exists pqs_capable_hosts ( `fqdn/ip:port`, `fqdn/ip`, host, ip, port, fs_kems ) as select 
	tls_details.`fqdn/ip:port` as `fqdn/ip:port`,
	tls_details.`fqdn/ip` as `fqdn/ip`,
	tls_details.host as host,
	tls_details.ip as ip,
	tls_details.port as port,
	testssl.finding as fs_kems
from tls_details, testssl where 
	testssl.`fqdn/ip` = tls_details.`fqdn/ip` and
	testssl.port = tls_details.port and
	testssl.`fqdn/ip` != '/' and 
	testssl.id = 'FS_KEMs' and 
	testssl.finding like '%MLKEM%'
group by tls_details.`fqdn/ip:port`
order by tls_details.`fqdn/ip:port`;

create view if not exists all_tls_ver as select
	`fqdn/ip:port`, `fqdn/ip`, host, ip, port, tls_ver
from tls_details
group by `fqdn/ip:port`, tls_ver 
order by host;

create view if not exists ecdhe_curves as
with recursive split(rn, `fqdn/ip`, port, word, rest) as ( select
	rowid,
	`fqdn/ip`,
	port,
	'',
	finding || ' '
from testssl where id = 'FS_ECDHE_curves' union all select
	rn,
	`fqdn/ip`,
	port,
	substr(rest, 1, instr(rest, ' ') - 1),
	substr(rest, instr(rest, ' ') + 1)
from split where rest <> '' ) select
	`fqdn/ip`,
	port,
	word as curve
from split where word <> '';

create view if not exists cert_details as select 
	`fqdn/ip`,
	port,
	max(case when id like 'cert_signatureAlgorithm%' then finding end) as cert_sigalg,
	max(case when id like 'cert_keySize%' then finding end) as cert_keysize
from ( select 
		`fqdn/ip`,
		port,
		id,
		finding,
		case 
			when instr(id, '<') > 0 then substr(id, instr(id, '<'))
			else 'default'
		end as cert_instance
from testssl where
	id like '%cert_signatureAlgorithm%' or
	id like '%cert_keySize%')
group by `fqdn/ip`, port, cert_instance;

create view if not exists cert_info as
with certs as (
select "fqdn/ip", port, finding,
	case when instr(id,' <hostCert#')>0
		then cast(substr(id, instr(id,'<hostCert#')+10,
			instr(id,'>')-instr(id,'<hostCert#')-10) as integer)
		else 1 end as cert_nr,
	case when instr(id,' <')>0 then substr(id,1,instr(id,' <')-1) else id end as base_id
	from testssl
	where id like 'cert\_%' escape '\'
)
select "fqdn/ip", port, cert_nr,
	max(case when base_id='cert_commonName'         then finding end) as cert_commonName,
	max(case when base_id='cert_subjectAltName'     then finding end) as cert_subjectAltName,
	max(case when base_id='cert_notBefore'          then finding end) as cert_notBefore,
	max(case when base_id='cert_notAfter'           then finding end) as cert_notAfter,
	max(case when base_id='cert_caIssuers'          then finding end) as cert_caIssuers,
	max(case when base_id='cert_signatureAlgorithm' then finding end) as cert_signatureAlgorithm,
	max(case when base_id='cert_keySize'            then finding end) as cert_keySize,
	max(case when base_id='cert_serialNumber'       then finding end) as cert_serialNumber,
	max(case when base_id='cert_fingerprintSHA256'  then finding end) as cert_fingerprintSHA256
from certs
where base_id in ('cert_commonName','cert_subjectAltName','cert_notBefore','cert_notAfter',
		'cert_caIssuers','cert_signatureAlgorithm','cert_keySize',
		'cert_serialNumber','cert_fingerprintSHA256')
group by "fqdn/ip", port, cert_nr;


