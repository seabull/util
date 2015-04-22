#!/bin/sh

#KEYFILE_DIR=/usr/costing/tmp/migration/v2.0
KEYFILE_DIR=/etc/not-backed-up/costing/v2.0

KEYFILE_FMPUP="${KEYFILE_DIR}/fmp-up"
KEYFILE_FMPDOWN="${KEYFILE_DIR}/fmp-down"
KEYFILE_DOCSDOWN="${KEYFILE_DIR}/docs-down"


./genkey.sh "${KEYFILE_FMPUP}"
./genkey.sh "${KEYFILE_FMPDOWN}"
./genkey.sh "${KEYFILE_DOCSDOWN}"


./mailkey.sh "${KEYFILE_FMPUP}"
./mailkey.sh "${KEYFILE_FMPDOWN}"
./mailkey.sh "${KEYFILE_DOCSDOWN}"
