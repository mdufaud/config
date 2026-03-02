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
  opt_begin "ssl_cms_sign -i <infile> -o <outfile> -s <signer> -c <certfile> -k <key>"
  opt_desc  "CMS sign a file"
  opt_param i infile   "" "Input file to sign"
  opt_param o outfile  "" "Output signed file"
  opt_param s signer   "" "Untrusted signer cert chain"
  opt_param c certfile "" "Trusted signer cert chain"
  opt_param k key      "" "Signer private key"
  opt_parse "$@" || return

  _arg_assert_exists "$opt_infile"   "$opt_usage" || return
  _arg_assert_exists "$opt_outfile"  "$opt_usage" || return
  _arg_assert_exists "$opt_signer"   "$opt_usage" || return
  _arg_assert_exists "$opt_certfile" "$opt_usage" || return
  _arg_assert_exists "$opt_key"      "$opt_usage" || return

  openssl cms -sign -binary \
    -signer "$opt_signer" \
    -certfile "$opt_certfile" \
    -inkey "$opt_key" \
    -md sha256 \
    -outform der \
    -noattr \
    -in "$opt_infile" \
    -out "$opt_outfile"
}

# pkcs7 public key

ssl_p7_info()
{
  openssl pkcs7 -print_certs -in $@
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
  opt_begin "ssl_p12_gen -k <key> -c <cert> [extra-cert ...]"
  opt_desc  "Generate a PKCS#12 from a key, cert, and optional extra certs (root/intermediate)"
  opt_param k key  "" "Private key file"
  opt_param c cert "" "Leaf certificate file"
  opt_parse "$@" || return

  _arg_assert_exists "$opt_key"  "$opt_usage" || return
  _arg_assert_exists "$opt_cert" "$opt_usage" || return

  # Add root and intermediate certs from positional args
  local args=""
  local certfile
  for certfile in "${opt_args[@]}"; do
    args="$args -certfile $certfile"
  done

  openssl pkcs12 -export -inkey "$opt_key" -in "$opt_cert" $args
}

# csr (certificate signing request)

ssl_csr_info()
{
  openssl req -text --noout -in $@
}

ssl_csr_sign()
{
  opt_begin "ssl_csr_sign -o <output> -r <csr> -k <key> -c <cert> [-d days]"
  opt_desc  "Sign a CSR with a CA certificate"
  opt_param o output "" "Output certificate path"
  opt_param r csr    "" "CSR file path"
  opt_param k key    "" "CA private key"
  opt_param c cert   "" "CA certificate"
  opt_param d days   3650 "Validity in days"
  opt_parse "$@" || return

  _arg_assert_exists "$opt_output" "$opt_usage" || return
  _arg_assert_exists "$opt_csr"    "$opt_usage" || return
  _arg_assert_exists "$opt_key"    "$opt_usage" || return
  _arg_assert_exists "$opt_cert"   "$opt_usage" || return

  openssl x509 -req -days "$opt_days" -in "$opt_csr" -CA "$opt_cert" -CAkey "$opt_key" -set_serial "0x$(openssl rand -hex 8)" -out "$opt_output"
}

ssl_csr_verify()
{
  openssl req -noout -text -verify -in $@
}

ssl_csr_gen()
{
  opt_begin "ssl_csr_gen -o <output> -k <key> [-n common-name]"
  opt_desc  "Generate a Certificate Signing Request"
  opt_param o output "" "CSR output path"
  opt_param k key    "" "Private key path"
  opt_param n cn     "" "Common Name"
  opt_parse "$@" || return

  _arg_assert_exists "$opt_output" "$opt_usage" || return
  _arg_assert_exists "$opt_key"    "$opt_usage" || return

  local __cn_opt=""
  if [ -n "$opt_cn" ]; then
    __cn_opt="-subj /CN=$opt_cn"
  fi

  openssl req -new -key "$opt_key" -out "$opt_output" $__cn_opt
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
  opt_begin "ssl_gen_cert -o <output> -k <key> [-n common-name] [-d days]"
  opt_desc  "Generate a self-signed certificate"
  opt_param o output "" "Output certificate path"
  opt_param k key    "" "Private key path"
  opt_param n cn     "" "Common Name"
  opt_param d days   3650 "Validity in days"
  opt_parse "$@" || return

  _arg_assert_exists "$opt_output" "$opt_usage" || return
  _arg_assert_exists "$opt_key"    "$opt_usage" || return

  local __cn_opt=""
  if [ -n "$opt_cn" ]; then
    __cn_opt="-subj /CN=$opt_cn"
  fi

  # nodes omit passphrase
  openssl req -x509 -new -nodes -key "$opt_key" -sha256 -days "$opt_days" -out "$opt_output" -set_serial "0x$(openssl rand -hex 8)" $__cn_opt
}

ssl_gen_new()
{
  opt_begin "ssl_gen_new [-n common-name] [-d days] <key_name>"
  opt_desc  "Generate a new key pair + self-signed certificate"
  opt_param n cn   "" "Common Name"
  opt_param d days 3650 "Validity in days"
  opt_parse "$@" || return

  local name="${opt_args[0]}"
  _arg_assert_exists "$name" "$opt_usage" || return

  ssl_gen_private "${name}.key" \
    && ssl_get_public_from_private "${name}.key" > "${name}.pub" \
    && ssl_gen_cert -o "${name}.crt" -k "${name}.key" ${opt_cn:+-n "$opt_cn"} -d "$opt_days"
}

ssl_revoke()
{
  opt_begin "ssl_revoke -r <cert-to-revoke> -k <ca-key> -c <ca-cert>"
  opt_desc  "Revoke a certificate"
  opt_param r revoke "" "Certificate to revoke"
  opt_param k key    "" "CA private key"
  opt_param c cert   "" "CA certificate"
  opt_parse "$@" || return

  _arg_assert_exists "$opt_revoke" "$opt_usage" || return
  _arg_assert_exists "$opt_key"    "$opt_usage" || return
  _arg_assert_exists "$opt_cert"   "$opt_usage" || return

  openssl ca -revoke "$opt_revoke" -keyfile "$opt_key" -cert "$opt_cert"
}