PREFIX=$1
HOSTNAME=$2
CA_PASSPHRASE=$3

rm -f ./docker-config/${PREFIX}-*.pem

openssl genrsa -out ./docker-config/${PREFIX}-key.pem 4096

openssl req -subj "/CN=${HOSTNAME}" -sha256 -new -key ./docker-config/${PREFIX}-key.pem -out ./docker-config/${PREFIX}.csr

openssl x509 -req -days 365 -sha256 \
  -in ./docker-config/${PREFIX}.csr \
  -CA ca.pem \
  -CAkey ca-key.pem \
  -CAcreateserial \
  -out ./docker-config/${PREFIX}-cert.pem \
  -passin pass:${CA_PASSPHRASE}

chmod 400 ./docker-config/${PREFIX}-*.pem
