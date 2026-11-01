#!/bin/bash
# mainframe_operations.sh

set -e

echo "=== 1. Helyi fájlok és jogosultságok ellenőrzése ==="
# A repóban lévő mappa neve kötőjellel van: cobol-check
if [ -d "cobol-check" ]; then
  cd cobol-check
  chmod +x cobolcheck || true
  if [ -d "scripts" ]; then
    chmod +x scripts/* || true
  fi
  cd ..
fi

LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')
REMOTE_DIR="/z/$LOWERCASE_USERNAME/cobolcheck"

echo "=== 2. COBOL Check futtatása a mainframe USS környezetében ==="

run_cobolcheck() {
  program=$1
  echo "--- COBOL Check futtatása a(z) $program programra ---"

  # SSH / Zowe parancs futtatása a mainframe USS-en
  # Belépünk a USS-en lévő mappába és lefuttatjuk a cobolcheck-et
  zowe zos-uss issue command "cd $REMOTE_DIR && ./cobolcheck -p $program" || true

  # Ellenőrizzük, hogy létrejött-e a CC##99.CBL a mainframe-en
  echo "CC##99.CBL másolása az MVS datasetbe..."
  zowe zos-files copy uss-file "$REMOTE_DIR/CC##99.CBL" "'$ZOWE_USERNAME.CBL($program)'" --overwrite || echo "CC##99.CBL nem található vagy nem sikerült a másolás."

  # JCL fájl másolása az MVS datasetbe (ha létezik a gyökérben)
  if [ -f "${program}.JCL" ]; then
    echo "${program}.JCL feltöltése az MVS-re..."
    zowe zos-files upload file-to-data-set "${program}.JCL" "$ZOWE_USERNAME.JCL($program)" --overwrite
  else
    echo "${program}.JCL nem található a projekt gyökerében."
  fi
}

# Lefuttatjuk a programokra
for program in NUMBERS EMPPAY DEPTPAY; do
  run_cobolcheck $program
done

echo "=== Mainframe műveletek befejeződtek ==="