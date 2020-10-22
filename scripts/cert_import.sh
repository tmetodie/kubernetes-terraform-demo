#!/bin/bash
set -e

ENVIRONMENT="$1"

openssl genrsa -out "toptal-${ENVIRONMENT}.tmetodieCA.key" 4096
openssl req -x509 -new -nodes -key "toptal-${ENVIRONMENT}.tmetodieCA.key" -sha256 -days 1024 -out "toptal-${ENVIRONMENT}.tmetodieCA.crt"
openssl genrsa -out "toptal-${ENVIRONMENT}.tmetodie.com.key" 4096
openssl req -new -sha256 -key "toptal-${ENVIRONMENT}.tmetodie.com.key" -subj "/C=US/ST=CA/O=MyOrg, Inc./CN=toptal-${ENVIRONMENT}.tmetodie.com" -out "toptal-${ENVIRONMENT}.tmetodie.com.csr"
openssl x509 -req -in "toptal-${ENVIRONMENT}.tmetodie.com.csr" -CA "toptal-${ENVIRONMENT}.tmetodieCA.crt" -CAkey "toptal-${ENVIRONMENT}.tmetodieCA.key" -CAcreateserial -out "toptal-${ENVIRONMENT}.tmetodie.com.crt" -days 500 -sha256

cat "toptal-${ENVIRONMENT}.tmetodieCA.crt" "toptal-${ENVIRONMENT}.tmetodie.com.crt" > "toptal-${ENVIRONMENT}.tmetodie.com-chain.crt"
