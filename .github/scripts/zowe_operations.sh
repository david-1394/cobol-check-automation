#!/bin/bash
# zowe_operations.sh

set -e

# Interaktív mód és telemetria tiltása
export CI=true
export ZOWE_DISABLE_TELEMETRY=true

echo "Zowe projekt konfiguráció inicializálása..."
zowe config init --global-config || true

# Profil beállítások
zowe config set "profiles.zosmf.properties.host" "204.90.115.200"
zowe config set "profiles.zosmf.properties.port" 10443
zowe config set "profiles.zosmf.properties.user" "$ZOWE_USERNAME"
zowe config set "profiles.zosmf.properties.password" "$ZOWE_PASSWORD"
zowe config set "profiles.zosmf.properties.rejectUnauthorized" false
zowe config set "defaults.zosmf" "zosmf"

LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')
REMOTE_DIR="/z/$LOWERCASE_USERNAME/cobolcheck"

echo "Mappa ellenőrzése..."
if ! zowe zos-files list uss-files "$REMOTE_DIR" &>/dev/null; then
  echo "A mappa nem létezik, létrehozás..."
  zowe zos-files create uss-directory "$REMOTE_DIR"
  zowe zos-files create uss-directory "$REMOTE_DIR/bin" || true
  zowe zos-files create uss-directory "$REMOTE_DIR/scripts" || true
else
  echo "A mappa már létezik."
fi

echo "Fájlok feltöltése..."
# 1. A rekurzív könyvtárstruktúra feltöltése
zowe zos-files upload dir-to-uss "./cobol-check" "$REMOTE_DIR" --recursive || true

# 2. A JAR fájl kényszerített BINÁRIS feltöltése (X-IBM-Data-Type: binary)
JAR_FILE=$(find ./cobol-check -name "*.jar" | head -n 1)
if [ -n "$JAR_FILE" ]; then
  echo "JAR fájl feltöltése bináris módban: $JAR_FILE"
  zowe zos-files upload file-to-uss "$JAR_FILE" "$REMOTE_DIR/bin/cobol-check-0.2.19.jar" --binary
fi

echo "Feltöltés ellenőrzése:"
zowe zos-files list uss-files "$REMOTE_DIR"