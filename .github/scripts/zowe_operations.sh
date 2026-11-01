#!/bin/bash
# zowe_operations.sh

set -e

# 1. Telemetria es interaktiv kerdesek kikapcsolasa
export CI=true
export ZOWE_DISABLE_TELEMETRY=true

# 2. Zowe zOSMF profil letrehozasa az uj (V2/V3) szintaxissal
echo "Zowe profil letrehozasa..."
zowe profiles create zosmf-profile ibmteam \
  --host "204.90.115.200" \
  --port 10443 \
  --user "$ZOWE_USERNAME" \
  --pass "$ZOWE_PASSWORD" \
  --reject-unauthorized false \
  --overwrite || true

# HA a fenti parancs lefutott, kenyszeritsuk a projekt-konfiguracio letrehozasat:
zowe config init --force || true

# 3. Mappa ellenorzes es feltoltes
LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')

echo "Mappa ellenorze..."
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