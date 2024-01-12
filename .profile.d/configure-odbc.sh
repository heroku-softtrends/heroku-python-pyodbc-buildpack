#!/bin/bash

for f in ${HOME}/.apt/opt/microsoft/*; do 
	MS_ODBC_VERSION=$(echo "$(basename $f)" | grep -o -E '[0-9]+')
	break;
done

for f in ${HOME}/.apt/usr/lib/*; do 
	MS_ODBC_DRIVER_FILE=$(echo "$(basename $f)")
	break;
done

export ODBCINI=${HOME}/.apt/usr/lib/odbc/conf/

echo "[ODBC Driver $MS_ODBC_VERSION for SQL Server]
Description=Microsoft ODBC Driver $MS_ODBC_VERSION for SQL Server
Driver=/app/.apt/usr/lib/$MS_ODBC_DRIVER_FILE
UsageCount=1
" > ${ODBCINI}/odbc.ini

export ODBCSYSINI=${HOME}/.apt/usr/lib/odbc/conf/

echo "[ODBC Driver $MS_ODBC_VERSION for SQL Server]
Description=Microsoft ODBC Driver $MS_ODBC_VERSION for SQL Server
Driver=/app/.apt/usr/lib/$MS_ODBC_DRIVER_FILE
" > ${ODBCSYSINI}/odbcinst.ini