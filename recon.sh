#!/bin/bash

###############################################################################
# recon.sh
#
# Web application recon script
#
# Version 0.1 (Feb 11, 2020)
# Matt Adams
#
###############################################################################


dirsearchThreads=50
dirsearchWordlist=~/tools/dirsearch/db/dicc.txt
massdnsWordlist=~/tools/SecLists/Discovery/DNS/clean-jhaddix-dns.txt
chromiumPath=/usr/bin/chromium

domain=
usage() { echo -e "Usage: ./recon.sh -d domain.com" 1>&2; exit 1; }

while getopts ":d:" o; do
	case "${o}" in
		d)
			domain=${OPTARG}
			;;
	esac
done
shift $((OPTIND - 1))

if [ -z "${domain}" ]; then
	usage; exit 1;
fi

#### Helpers 

createOutputDir() {

	if [ -d "$reportBase" ]
	then
		echo "This is a known target."
	else
		mkdir -p $reportBase
	fi

	mkdir $reportPath
}

#### // Helpers

subdiscovery() {

  echo ""
  echo "******************** Subdomain Discovery ********************"

  echo ""
  echo "[+] Getting subdomains with sublister (sublist3r_out.txt)"
  echo ""
  python ~/tools/Sublist3r/sublist3r.py -d $domain -t 10 -o $reportPath/sublist3r_out.txt 2>/dev/null

  echo ""
  echo "[+] Checking certspotter (certspotter_out.txt)"
  echo ""
  curl -s https://certspotter.com/api/v0/certs\?domain\=$domain | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $domain | tee $reportPath/certspotter_out.txt

  echo ""
  echo "[+] Checking http://crt.sh (crt.sh_out.txt)"
  echo ""
  ~/tools/massdns/scripts/ct.py $domain 2>/dev/null | tee $reportPath/crt.sh_out.txt

  echo ""
  echo "[+] Creating subdomain bruteforce list with subbrute.py (subbrute_list.txt)"
  ~/tools/massdns/scripts/subbrute.py $massdnsWordlist $domain > $reportPath/subbrute_list.txt


  echo ""
  echo "[+] Resolving subdomains (sublist3r_resolved.txt, crt.sh_out.txt, subbrute_resolved.txt)"
  echo "This would be a good time for a coffee. This is going to take a minute"
  echo ""
  [ -s $reportPath/sublist3r_out.txt ] && cat $reportPath/sublist3r_out.txt | ~/tools/massdns/bin/massdns -r ~/tools/massdns/lists/resolvers.txt -t A -q -o S -w $reportPath/sublist3r_resolved.txt

  [ -s $reportPath/crt.sh_out.txt ] && cat $reportPath/crt.sh_out.txt | ~/tools/massdns/bin/massdns -r ~/tools/massdns/lists/resolvers.txt -t A -q -o S -w  $reportPath/crt.sh_resolved.txt

  [ -s $reportPath/subbrute_list.txt ] && cat $reportPath/subbrute_list.txt | ~/tools/massdns/bin/massdns -r ~/tools/massdns/lists/resolvers.txt -t A -q -o S | grep -v 142.54.173.92 > $reportPath/subbrute_resolved.txt

  # Put all resolved subdomains in one file
  [ -s $reportPath/sublist3r_resolved.txt ] && cat $reportPath/sublist3r_resolved.txt > $reportPath/resolved_domains_raw.txt
  [ -s $reportPath/crt.sh_resolved.txt ] && cat $reportPath/crt.sh_resolved.txt >> $reportPath/resolved_domains_raw.txt
  [ -s $reportPath/subbrute_resolved.txt ] && cat $reportPath/subbrute_resolved.txt >> $reportPath/resolved_domains_raw.txt
}

livehosts() {

  echo ""
  echo "******************** Live Host Discovery ********************"
  echo ""

  echo "[+] Parsing unique urls (url_list.txt)"
  cat $reportPath/resolved_domains_raw.txt| awk '{print $3}' | sort -u | while read line; do
    wildcard=$(cat $reportPath/resolved_domains_raw.txt| grep -m 1 $line)
    echo "$wildcard" >> $reportPath/url_temp.txt
  done

  cat $reportPath/url_temp.txt | awk '{print $1}' | while read line; do
    x="$line"
    echo "${x%?}" >> $reportPath/url_list.txt
  done
  cat $reportPath/sublist3r_out.txt >> $reportPath/url_list.txt
  cat $reportPath/certspotter_out.txt >> $reportPath/url_list.txt

  echo ""
  echo "[+] Searching for live hosts (url_live.txt)"
  echo ""
  cat $reportPath/url_list.txt | sort -u | httprobe | tee $reportPath/url_live.txt

  echo ""
  echo "[+] Capturing screenshots of live domains (aquatone_out/)"
  cat $reportPath/url_live.txt | aquatone --out $reportPath/aquatone_out
}


cleanup() {
  echo ""
  echo "******************** Cleanup ********************"
  echo ""

  echo "[+] Performing cleanup"
  rm -rf $reportPath/certspotter_out.txt
  rm -rf $reportPath/crt.sh_out.txt
  rm -rf $reportPath/sublist3r_out.txt
  rm -rf $reportPath/url_temp.txt
}


archive() {

  echo ""
  echo "******************** Archiving Results ********************"
  echo ""

  echo "[+] Creating tar archive ($reportBase/$today.tar.gz)"
  tar -czf "$reportBase/$today.tar.gz" $reportPath
}


main() {

	clear
	echo "Starting recon on $domain"

	createOutputDir

  subdiscovery
  livehosts  
  cleanup
  archive

  # TODO: Add port scan
  # TODO: Add content discovery - disable by default, enable by flag to dodge WAF's

  echo ""
	echo "Scan for $domain finished successfully"
  echo ""
}


today=$(date +"%Y-%m-%d-%H-%M")
startTime=$(date +"%Y-%m-%d %H:%M:%S")
path=$(pwd)
reportBase="$path/recon_out/$domain"
reportPath="$path/recon_out/$domain/$today/"
#reportBase="recon_out/goodrx.com"
#reportPath="recon_out/goodrx.com/2020-02-13-23-22"
main $domain
finishTime=$(date +"%Y-%m-%d %H:%M:%S")
echo "Start Time:  $startTime"
echo "Finish Time: $finishTime"

