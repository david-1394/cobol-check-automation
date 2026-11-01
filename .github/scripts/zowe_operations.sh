#!/bin/bash
# zowe_operations.sh

set -e

# Interaktív mód és telemetria tiltása
export CI=true
export ZOWE_DISABLE_TELEMETRY=true

echo "Zowe projekt konfiguráció inicializálása..."
zowe config init --global-config || true

# Beállítjuk a profil tulajdonságait
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

echo "Fájlok feltöltése bináris módban a JAR fájlokra..."
zowe zos-files upload dir-to-uss "./cobol-check" "/z/$LOWERCASE_USERNAME/cobolcheck" --recursive --binary-files "*.jar"

echo "Feltöltés ellenőrzése:"
zowe zos-files list uss-files "/z/$LOWERCASE_USERNAME/cobolcheck"