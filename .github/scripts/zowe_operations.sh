#!/bin/bash
# mainframe_operations.sh

set -e

LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')
REMOTE_DIR="/z/$LOWERCASE_USERNAME/cobolcheck"

echo "=== COBOL Check futtatása a mainframe USS környezetében ==="

run_cobolcheck() {
  program=$1
  echo "--- COBOL Check futtatása a(z) $program programra ---"

  # Parancs kiküldése a z/OSMF REST API-n keresztül a USS felületre
  zowe zos-uss issue command "cd $REMOTE_DIR && chmod +x bin/cobolcheck && ./bin/cobolcheck -p $program" || true

  # Ellenőrizzük a generált kimenetet és felmásoljuk az MVS-re
  if zowe zos-files list uss-files "$REMOTE_DIR/CC##99.CBL" &>/dev/null; then
    echo "CC##99.CBL megtalálva, másolás MVS datasetbe..."
    zowe zos-files copy uss-file "$REMOTE_DIR/CC##99.CBL" "'$ZOWE_USERNAME.CBL($program)'" --overwrite || echo "Másolás sikertelen."
  else
    echo "CC##99.CBL nem jött létre a(z) $program programhoz."
  fi

  # JCL fájl másolása az MVS-re
  if [ -f "${program}.JCL" ]; then
    echo "${program}.JCL feltöltése az MVS-re..."
    zowe zos-files upload file-to-data-set "${program}.JCL" "$ZOWE_USERNAME.JCL($program)" --overwrite || echo "JCL feltöltés sikertelen."
  else
    echo "${program}.JCL nem található a gyökérkönyvtárban."
  fi
}

# Ciklus a programokra
for program in NUMBERS EMPPAY DEPTPAY; do
  run_cobolcheck $program
done

echo "=== Műveletek befejezve ==="