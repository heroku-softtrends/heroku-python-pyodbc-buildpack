#!/bin/bash

for f in ${HOME}/.apt/opt/microsoft/*; do 
	MS_ODBC_VERSION=$(echo "$(basename $f)" | grep -o -E '[0-9]+')
	break;
done

MS_ODBC_DRIVER_FILE=$(find "${HOME}/.apt/usr/lib" \
	-maxdepth 1 -type f -name 'libmsodbcsql-*.so*' \
	-printf '%f\n' | head -n 1)

if [[ -z "$MS_ODBC_DRIVER_FILE" ]]; then
	echo "ERROR: Microsoft ODBC driver library not found." >&2
	return 1
fi

ODBC_CONF_DIR="${HOME}/.apt/usr/lib/odbc/conf"
mkdir -p "${ODBC_CONF_DIR}"

export ODBCINI="${ODBC_CONF_DIR}/odbc.ini"

echo "[ODBC Driver $MS_ODBC_VERSION for SQL Server]
Description=Microsoft ODBC Driver $MS_ODBC_VERSION for SQL Server
Driver=/app/.apt/usr/lib/$MS_ODBC_DRIVER_FILE
UsageCount=1
" > "${ODBCINI}"

export ODBCSYSINI="${ODBC_CONF_DIR}"

echo "[ODBC Driver $MS_ODBC_VERSION for SQL Server]
Description=Microsoft ODBC Driver $MS_ODBC_VERSION for SQL Server
Driver=/app/.apt/usr/lib/$MS_ODBC_DRIVER_FILE
" > "${ODBCSYSINI}/odbcinst.ini"