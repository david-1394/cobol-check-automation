#!/bin/bash
# zowe_operations.sh

set -e

# 1. CI környezet és automatikus válaszok beállítása
export CI=true
export ZOWE_DISABLE_TELEMETRY=true

echo "Zowe automatikus konfiguráció inicializálása..."
# Automatikus alapbeállítások létrehozása
zowe config auto-init || true

# Beállítjuk a csatlakozási adatokat a global konfigurációban
zowe config set "profiles.zosmf.properties.host" "204.90.115.200"
zowe config set "profiles.zosmf.properties.port" 10443
zowe config set "profiles.zosmf.properties.user" "$ZOWE_USERNAME"
zowe config set "profiles.zosmf.properties.password" "$ZOWE_PASSWORD"
zowe config set "profiles.zosmf.properties.rejectUnauthorized" false
zowe config set "defaults.zosmf" "zosmf"

# Mappa ellenőrzése és feltöltés
LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')

echo "Mappa ellenőrzése..."
if ! zowe zos-files list uss-files "/z/$LOWERCASE_USERNAME/cobolcheck" &>/dev/null; then
  echo "A mappa nem létezik, létrehozás..."
  zowe zos-files create uss-directory "/z/$LOWERCASE_USERNAME/cobolcheck"
else
  echo "A mappa már létezik."
fi

echo "Fájlok feltöltése..."
zowe zos-files upload dir-to-uss "./cobol-check" "/z/$LOWERCASE_USERNAME/cobolcheck" --recursive --binary-files "cobol-check-0.2.9.jar"

echo "Feltöltés ellenőrzése:"
zowe zos-files list uss-files "/z/$LOWERCASE_USERNAME/cobolcheck"