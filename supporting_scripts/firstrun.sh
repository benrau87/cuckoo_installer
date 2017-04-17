#!/bin/bash
cp ~/.mitmproxy/mitmproxy-ca-cert.p12 ~/.cuckoo/analyzer/windows/bin/cert.p12
cp ~/conf/* ~/.cuckoo/conf/
cuckoo community
cuckoo migrate
