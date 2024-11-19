#
# Openssl
#

ssl_info()
{
  local der=""
  if [[ $1 == *".der"* ]]; then
    der=" -inform der"
  fi

  case "$1" in
    # certificate
    *.crt) ssl_crt_info "$1" "$der" ;;
    *.cer) ssl_crt_info "$1" "$der" ;;
    *.pem) ssl_crt_info "$1" "$der" ;;
    # certification signing request
    *.req) ssl_csr_info "$1" "$der" ;;
    *.csr) ssl_csr_info "$1" "$der" ;;
    *.p10) ssl_csr_info "$1" "$der" ;;
    # pkcs12 (bundle pub+priv)
    *.p12) ssl_p12_info "$1" "$der" ;;
    *.pfx) ssl_p12_info "$1" "$der" ;;
    # pkcs8 (encrypted private)
    *.p8) ssl_p8_info "$1" "$der" ;;
    *.pkcs8) ssl_p8_info "$1" "$der" ;;
    # pkcs7 (public)
    *.p7b) ssl_p7_info "$1" "$der" ;;
    *.p7c) ssl_p7_info "$1" "$der" ;;
    # crl (revoke list)
    *.crl) ssl_crl_info "$1" "$der" ;;
    # unencrypted public key
    *.pub) cat "$1" ;;
    # unencrypted private key
    *.key) cat "$1" ;;
    # probably a certificate ?
    *) ssl_crt_info "$1" "$der" ;;
  esac
}

ssl_encrypt()
{
  local public="${1}"

  if [ -z "$public" ]; then
    public="${BASH_SSL_PUBLIC_PATH}"
  fi

  local args=""
  # if it is a certificate
  if [[ $public == *.pem ]] || [[ $public == *.cer ]] || [[ $public == *.crt ]]; then
    args="$args -certin"
  fi

  openssl pkeyutl -encrypt -pubin -inkey "$public" $args
}

ssl_encrypt64()
{
  local key_path="$1"
  ssl_encrypt "$key_path" | openssl base64
}

ssl_decrypt()
{
  local private="${1}"

  if [ -z "$private" ]; then
    private="${BASH_SSL_PRIVATE_PATH}"
  fi

  openssl pkeyutl -decrypt -inkey "$private"
}

ssl_decrypt64()
{
  openssl base64 -d | ssl_decrypt "$1"
}

# chain

ssl_chain_verify()
{
  local root_crt="$1"
  local intermediate_crt="$2"
  local leaf_crt="$3"

  openssl verify -CAfile "$root_crt" -untrusted "$intermediate_crt" "$leaf_crt"
}

# certificate

ssl_crt_info()
{
  openssl x509 -noout -text -in $@
}

ssl_crt_export_public()
{
  # first arg is a .pem
  openssl x509 -pubkey -noout -in $@
}

ssl_crt_to_der()
{
  openssl x509 -inform pem -in "$1" -outform der -out "$2"
}

# cms

ssl_cms_info()
{
  openssl cms -print -cmsout -in $@
}

ssl_cms_sign()
{
  local infile="$1"
  local outfile="$2"
  local untrusted_signer_chain="$3"
  local trusted_signer_chain="$4"
  local untrusted_key="$5"

  openssl cms -sign -binary \
    -signer "$untrusted_signer_chain" \
    -certfile "$trusted_signer_chain" \
    -inkey "$untrusted_key" \
    -md sha256 \
    -outform der \
    -noattr \
    -in "$infile" \
    -out "$outfile"
}

# pkcs7 public key

ssl_p7_info()
{
  openssl pkcs7 -in -print_certs -in $@
}

# pkcs8 private key

ssl_p8_info()
{
  openssl pkcs8 -in $@
}

ssl_p8_gen()
{
  openssl pkcs8 -topk8 -in $@
}

# pkcs12

ssl_p12_info()
{
  openssl pkcs12 -info -nokeys -in $@
}

ssl_p12_export_private()
{
  openssl pkcs12 -nocerts -in $@
}

ssl_p12_export_public()
{
  openssl pkcs12 -clcerts -nokeys -in $@
}

ssl_p12_export_ca()
{
  openssl pkcs12 -cacerts -nokeys -in $@
}

ssl_p12_gen()
{
  _arg_assert_exists "$1" "usage: ssl_p12_gen <private> <certificate> [+certificate (like root and intermediate)]..."
  _arg_assert_exists "$2" "usage: ssl_p12_gen <private> <certificate> [+certificate (like root and intermediate)]..."

  #use leaf certificate

  local private="$1"
  local crt="$2"
  shift 2

  #add root and intermediate crt

  local args=""
  for certfile in $@; do
    args="$args -certfile $certfile"
  done

  openssl pkcs12 -export -inkey "$private" -in "$crt" $args
}

# csr (certificate signing request)

ssl_csr_info()
{
  openssl req -text --noout -in $@
}

ssl_csr_sign()
{
  _arg_assert_exists "$1" "usage: ssl_csr_sign <certificate_output> <csr> <private> <public> [date(=3650)]"
  _arg_assert_exists "$2" "usage: ssl_csr_sign <certificate_output> <csr> <private> <public> [date(=3650)]"
  _arg_assert_exists "$3" "usage: ssl_csr_sign <certificate_output> <csr> <private> <public> [date(=3650)]"
  _arg_assert_exists "$4" "usage: ssl_csr_sign <certificate_output> <csr> <private> <public> [date(=3650)]"

  local output="$1"
  local csr="$2"
  local private="$3"
  local cert="$4"
  local days="${5:-3650}"

  openssl x509 -req -days "$days" -in "$csr" -CA "$cert" -CAkey "$private" -set_serial "0x$(openssl rand -hex 8)" -out "$output"
}

ssl_csr_verify()
{
  openssl req -noout -text -verify -in $@
}

ssl_csr_gen()
{
  _arg_assert_exists "$1" "usage: ssl_gen_csr <output> <private> [common-name] [date(=3650)]"
  _arg_assert_exists "$2" "usage: ssl_gen_csr <output> <private> [common-name] [date(=3650)]"

  local csr="$1"
  local private="$2"
  local cn="$3"

  if [ -n "$cn" ]; then
    cn="-subj /CN=$cn"
  fi

  openssl req -new -key "$private" -out "$csr" $cn
}

# asn1

ssl_asn1_info()
{
  openssl asn1parse -in $@
}

ssl_asn1_decode()
{
  #use xdd to conver the hex string into a byte array
  xxd -r -p | openssl asn1parse -inform der
}

ssl_asn1_encode()
{
  # may not be an RSA could be openssl ecparam -name prime256v1
  openssl rsa -outform der | xxd -plain
}

# der

ssl_der_to_crt()
{
  openssl x509 -inform pem -in "$1" -outform der -out "$2"
}

# crl (certificate revoke list)

ssl_crl_info()
{
  openssl crl -noout -text -in $@
}

# generate keys

ssl_gen_private()
{
  local output="$1"
  shift
  openssl genrsa -out "$output" 2048 $@
}

ssl_get_public_from_private()
{
  openssl rsa -pubout -in "$1"
}

ssl_gen_cert()
{
  _arg_assert_exists "$1" "usage: ssl_gen_cert <output> <private> [common-name] [date(=3650)]"
  _arg_assert_exists "$2" "usage: ssl_gen_cert <output> <private> [common-name] [date(=3650)]"

  local output="$1"
  local private="$2"
  local cn="$3"
  local days="${4:-3650}"

  if [ -n "$cn" ]; then
    cn="-subj /CN=$cn"
  fi

  # nodes omit passphrase
  openssl req -x509 -new -nodes -key "$private" -sha256 -days "$days" -out "$output" -set_serial "0x$(openssl rand -hex 8)" $cn
}

ssl_gen_new()
{
  _arg_assert_exists "$1" "usage: ssl_gen_new <key_name> [common-name] [date(=3650)]"

  local name="$1"
  local cn="$2"
  local days="${3:-3650}"

  ssl_gen_private "${name}.key" \
    && ssl_get_public "${name}.key" > "${name}.pub" \
    && ssl_gen_cert "${name}.crt" "${name}.key" "$cn" "$days"
}

ssl_revoke()
{
  _arg_assert_exists "$1" "usage: ssl_revoke <to_revoke> <private> <certificate>"
  _arg_assert_exists "$2" "usage: ssl_revoke <to_revoke> <private> <certificate>"
  _arg_assert_exists "$3" "usage: ssl_revoke <to_revoke> <private> <certificate>"

  local torevoke="$1"
  local private="$2"
  local cert="$3"

  openssl ca -revoke "$torevoke" -keyfile "$private" -cert "$cert"
}