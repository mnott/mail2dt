#!/bin/bash

openssl genrsa -out dovecot_key_file.pem 2048
openssl req -new -x509 -key dovecot_key_file.pem -out dovecot_cert_file.pem -subj "/C=US" -days 1095
