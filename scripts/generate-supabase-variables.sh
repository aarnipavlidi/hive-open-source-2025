#!/bin/bash
set -euo pipefail

# Helpful function to print errors to stderr and exit
err() {
  echo "❌ $*" >&2
  exit 1
}

# 0. CHECK PREREQUISITES
# ----------------------
# Verify required commands and Python packages are available before proceeding.

# Check openssl
if ! command -v openssl >/dev/null 2>&1; then
  err "Required command 'openssl' not found. Install it (e.g. on macOS: 'brew install openssl', on Debian/Ubuntu: 'sudo apt-get install openssl')."
fi

# Check python3
if ! command -v python3 >/dev/null 2>&1; then
  err "Required command 'python3' not found. Install Python 3 (e.g. on macOS: 'brew install python', on Debian/Ubuntu: 'sudo apt-get install python3')."
fi

# Check PyJWT module availability using python3
if ! python3 - <<'PY' >/dev/null 2>&1
try:
    import importlib.util
    spec = importlib.util.find_spec("jwt")
    if spec is None:
        raise ImportError
except Exception:
    raise SystemExit(1)
else:
    raise SystemExit(0)
PY
then
  err "Python module 'PyJWT' (import name 'jwt') is not installed for python3. Install it with: 'pip3 install pyjwt' or in your virtualenv."
fi

# 1. GENERATE RANDOM SECRETS
# --------------------------
# Generates secure random strings for passwords and keys
POSTGRES_PASSWORD=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)

DASHBOARD_USERNAME=supabase
DASHBOARD_PASSWORD=$(openssl rand -hex 16)
SECRET_KEY_BASE=$(openssl rand -hex 32)
# Generates exactly 32 character hex strings for encryption keys
VAULT_ENC_KEY=$(openssl rand -hex 16)
PG_META_CRYPTO_KEY=$(openssl rand -hex 16)
LOGFLARE_PUBLIC_ACCESS_TOKEN=$(openssl rand -hex 16)
LOGFLARE_PRIVATE_ACCESS_TOKEN=$(openssl rand -hex 16)

# 2. DEFINE PROJECT SETTINGS
# --------------------------
# You can change these defaults or pass them as arguments later
PROJECT_ID="hive-open-source-2025"
DOMAIN="supabase-stg.usko.lol"
SITE_URL="http//localhost:3000"
STUDIO_DEFAULT_ORGANIZATION="Hive Open Source 2025"
STUDIO_DEFAULT_PROJECT="Database for Hive Open Source 2025"

# 3. GENERATE JWT TOKENS (ANON & SERVICE_ROLE)
# --------------------------------------------
# Use python to sign the tokens using the JWT_SECRET generated above.
# This ensures your API keys actually work with your Database.
ANON_PAYLOAD='{"role":"anon","iss":"supabase","iat":1764453600,"exp":1922220000}'
SERVICE_PAYLOAD='{"role":"service_role","iss":"supabase","iat":1764453600,"exp":1922220000}'

# Export variables so the python heredoc can read them from the environment
export ANON_PAYLOAD SERVICE_PAYLOAD JWT_SECRET

# Create ANON_KEY robustly handling PyJWT returning bytes vs str
ANON_KEY=$(python3 - <<'PY'
import os, json, sys
import jwt

payload = json.loads(os.environ['ANON_PAYLOAD'])
secret = os.environ['JWT_SECRET']
token = jwt.encode(payload, secret, algorithm='HS256')
# PyJWT v1 returns bytes for encode, v2 returns str
if isinstance(token, bytes):
    token = token.decode('utf-8')
print(token)
PY
)

SERVICE_ROLE_KEY=$(python3 - <<'PY'
import os, json, sys
import jwt

payload = json.loads(os.environ['SERVICE_PAYLOAD'])
secret = os.environ['JWT_SECRET']
token = jwt.encode(payload, secret, algorithm='HS256')
if isinstance(token, bytes):
    token = token.decode('utf-8')
print(token)
PY
)

# Validate generated secrets
if [ -z "${JWT_SECRET:-}" ]; then
  err "Generated JWT_SECRET is empty. Random generation failed or 'openssl' returned no data."
fi

if [ -z "${ANON_KEY:-}" ] || [ -z "${SERVICE_ROLE_KEY:-}" ]; then
  err "Failed to generate ANON_KEY or SERVICE_ROLE_KEY. Verify PyJWT is installed and working for python3 (try: 'python3 -c \"import jwt; print(jwt.__version__)\"' and install with 'pip3 install pyjwt')."
fi

# Unset exported vars we no longer need in the environment for safety
unset ANON_PAYLOAD SERVICE_PAYLOAD

# 4. WRITE TO .ENV.LOCAL FILE
# ---------------------------
cat > .env.local <<EOF
############################
# --- Supabase Secrets --- #
############################

POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
JWT_SECRET=${JWT_SECRET}
ANON_KEY=${ANON_KEY}
SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}
DASHBOARD_USERNAME=${DASHBOARD_USERNAME}
DASHBOARD_PASSWORD=${DASHBOARD_PASSWORD}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
VAULT_ENC_KEY=${VAULT_ENC_KEY}
PG_META_CRYPTO_KEY=${PG_META_CRYPTO_KEY}

#############################
# --- Supabase Database --- #
#############################

POSTGRES_HOST=db
POSTGRES_DB=postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres

##############################
# --- Supabase Supavisor --- #
##############################

# Port Supavisor listens on for transaction pooling connections
POOLER_PROXY_PORT_TRANSACTION=6543
# Maximum number of PostgreSQL connections Supavisor opens per pool
POOLER_DEFAULT_POOL_SIZE=20
# Maximum number of client connections Supavisor accepts per pool
POOLER_MAX_CLIENT_CONN=100
# Unique tenant identifier
POOLER_TENANT_ID=${PROJECT_ID}
# Pool size for internal metadata storage used by Supavisor
# This is separate from client connections and used only by Supavisor itself
POOLER_DB_POOL_SIZE=5

##############################
# --- Supabase API Proxy --- #
##############################

KONG_HTTP_PORT=8000
KONG_HTTPS_PORT=8443

########################
# --- Supabase API --- #
########################

PGRST_DB_SCHEMAS=public,storage,graphql_public

#########################
# --- Supabase Auth --- #
#########################

## General ##
SITE_URL=${SITE_URL}
ADDITIONAL_REDIRECT_URLS=
JWT_EXPIRY=3600
DISABLE_SIGNUP=false
API_EXTERNAL_URL=http://localhost:8000

## Mailer Config ##
MAILER_URLPATHS_CONFIRMATION="/auth/v1/verify"
MAILER_URLPATHS_INVITE="/auth/v1/verify"
MAILER_URLPATHS_RECOVERY="/auth/v1/verify"
MAILER_URLPATHS_EMAIL_CHANGE="/auth/v1/verify"

## Email auth ##
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false
SMTP_ADMIN_EMAIL=admin@example.com
SMTP_HOST=supabase-mail
SMTP_PORT=2500
SMTP_USER=fake_mail_user
SMTP_PASS=fake_mail_password
SMTP_SENDER_NAME=fake_sender
ENABLE_ANONYMOUS_USERS=false

## Phone auth ##
ENABLE_PHONE_SIGNUP=true
ENABLE_PHONE_AUTOCONFIRM=true

###########################
# --- Supabase Studio --- #
###########################

STUDIO_DEFAULT_ORGANIZATION=${STUDIO_DEFAULT_ORGANIZATION}
STUDIO_DEFAULT_PROJECT=${STUDIO_DEFAULT_PROJECT}

# replace if you intend to use Studio outside of localhost
SUPABASE_HOST=${DOMAIN}
STUDIO_PORT=3000

# Enable webp support
IMGPROXY_ENABLE_WEBP_DETECTION=true

# Add your OpenAI API key to enable SQL Editor Assistant
OPENAI_API_KEY=

##############################
# --- Supabase Functions --- #
##############################

# NOTE: VERIFY_JWT applies to all functions. Per-function VERIFY_JWT is not supported yet.
FUNCTIONS_VERIFY_JWT=false

#########################
# --- Supabase Logs --- #
#########################

# Change vector.toml sinks to reflect this change
# these cannot be the same value
LOGFLARE_PUBLIC_ACCESS_TOKEN=${LOGFLARE_PUBLIC_ACCESS_TOKEN}
LOGFLARE_PRIVATE_ACCESS_TOKEN=${LOGFLARE_PRIVATE_ACCESS_TOKEN}

# Docker socket location - this value will differ depending on your OS
DOCKER_SOCKET_LOCATION=/var/run/docker.sock

# Google Cloud Project details
GOOGLE_PROJECT_ID=GOOGLE_PROJECT_ID
GOOGLE_PROJECT_NUMBER=GOOGLE_PROJECT_NUMBER
EOF

echo "✅ .env.local file created successfully!"
echo "🔑 Dashboard User: ${DASHBOARD_USERNAME}"
echo "🔑 Dashboard Pass: ${DASHBOARD_PASSWORD}"
echo "🔑 JWT Secret: ${JWT_SECRET}"
echo "🚀 Once Supabase is deployed, use the above credentials to log in to the Supabase Dashboard!"
echo "🚀 Dashboard can be accessed from following address ➡️ https://${DOMAIN}"
