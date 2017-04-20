#!/bin/bash
cuckoo &
sleep 20
cuckoo community
cp ~/.mitmproxy/mitmproxy-ca-cert.p12 ~/.cuckoo/analyzer/windows/bin/cert.p12
cp ~/conf/* ~/.cuckoo/conf/


