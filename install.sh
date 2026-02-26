#!/usr/bin/env bash
set -e

ENV_EXAMPLE=".env.example"
ENV_FILE=".env"

# --------------------------------------------------
# Kontroller
# --------------------------------------------------
if [ ! -f "$ENV_EXAMPLE" ]; then
  echo "❌ $ENV_EXAMPLE bulunamadı."
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "✅ $ENV_EXAMPLE → $ENV_FILE kopyalandı"
else
  echo "ℹ️  $ENV_FILE mevcut, güncellenecek"
fi

# --------------------------------------------------
# Yardımcı Fonksiyonlar
# --------------------------------------------------
gen_password() {
  openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20
}

gen_encryption_key() {
  openssl rand -hex 32
}

set_env() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

set_env_once() {
  local key="$1"
  local value="$2"

  local current
  current=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)

  if [ -z "$current" ]; then
    set_env "$key" "$value"
  fi
}

# --------------------------------------------------
# Kullanıcıdan Gerekli Bilgiler
# --------------------------------------------------
read -rp "N8N_SERVER_HOSTNAME (örn: n8n.example.com): " N8N_SERVER_HOSTNAME

echo
echo "--- SMTP Ayarları ---"
read -rp "N8N_SMTP_HOST (örn: live.smtp.mailtrap.io): " N8N_SMTP_HOST
read -rp "N8N_SMTP_PORT (boş bırakılırsa: 587): " INPUT_SMTP_PORT
N8N_SMTP_PORT="${INPUT_SMTP_PORT:-587}"
read -rp "N8N_SMTP_USER: " N8N_SMTP_USER
read -rsp "N8N_SMTP_PASS: " N8N_SMTP_PASS
echo

echo
echo "--- Veritabanı ---"
read -rp "DB_POSTGRESDB_HOST (boş bırakılırsa: postgres): " INPUT_DB_HOST
DB_POSTGRESDB_HOST="${INPUT_DB_HOST:-postgres}"
read -rp "DB_POSTGRESDB_USER (boş bırakılırsa: n8n): " INPUT_DB_USER
DB_POSTGRESDB_USER="${INPUT_DB_USER:-n8n}"
read -rsp "DB_POSTGRESDB_PASSWORD: " DB_POSTGRESDB_PASSWORD
echo

# --------------------------------------------------
# .env Güncelle
# --------------------------------------------------
set_env N8N_SERVER_HOSTNAME "$N8N_SERVER_HOSTNAME"

set_env N8N_SMTP_HOST "$N8N_SMTP_HOST"
set_env N8N_SMTP_PORT "$N8N_SMTP_PORT"
set_env N8N_SMTP_USER "$N8N_SMTP_USER"
set_env N8N_SMTP_PASS "$N8N_SMTP_PASS"

set_env DB_POSTGRESDB_HOST     "$DB_POSTGRESDB_HOST"
set_env DB_POSTGRESDB_USER     "$DB_POSTGRESDB_USER"
set_env DB_POSTGRESDB_PASSWORD "$DB_POSTGRESDB_PASSWORD"

# Secret'lar — mevcut değerlerin üzerine yazılmaz
set_env_once N8N_ENCRYPTION_KEY "$(gen_encryption_key)"

# --------------------------------------------------
# Sonuçları Göster
# --------------------------------------------------
echo
echo "==============================================="
echo "✅ n8n .env başarıyla hazırlandı"
echo "-----------------------------------------------"
echo "🌐 Hostname      : $N8N_SERVER_HOSTNAME"
echo "📧 SMTP Host     : $N8N_SMTP_HOST:$N8N_SMTP_PORT"
echo "📧 SMTP Password : $N8N_SMTP_USER"
echo "🗄️ DB Host       : $DB_POSTGRESDB_HOST"
echo "👤 DB Password   : $DB_POSTGRESDB_USER"
echo "-----------------------------------------------"
echo "⚠️ Şifreyi güvenli bir yerde saklayın!"
echo "==============================================="
