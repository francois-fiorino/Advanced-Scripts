
--Problema:
[oracle@srv1 ~]$ ./menudba
: No such file or directory

--Ao copiar script de um windows para linux ou linux para unix.


[oracle@srv1 ~]$ bash -x menudba
+ $'\r'
menudba: line 2: $'\r': command not found
+++ dirname menudba
++ cat ./config.txt
+ config='USERNAME: menudba
PASSWORD: agestado
EMAIL: francois.fiorino@gmail.com
'
+ $'\r'
menudba: line 4: $'\r': command not found
+ readonly $'database=\r'
+ database=$'\r'
+ readonly $'passwd=\r'
+ passwd=$'\r'
' readonly 'TNS_ADMIN='\''/u01/app/oracle/product/19.0.0/db_1/network/admin/tnsnames.ora'\''
' TNS_ADMIN=''\''/u01/app/oracle/product/19.0.0/db_1/network/admin/tnsnames.ora'\''
++ echo 'USERNAME: menudba
PASSWORD: agestado
EMAIL: francois.fiorino@gmail.com
'
++ awk '{print $NF}'
++ grep USERNAME:
+ user=$'menudba\r\r'
++ echo 'USERNAME: menudba
PASSWORD: agestado
EMAIL: francois.fiorino@gmail.com
'
++ grep EMAIL:
++ awk '{print $NF}'
+ dbamail=$'francois.fiorino@gmail.com\r\r'
+ user=$'menudba\r\r'
+ dbamail=$'francois.fiorino@gmail.com\r\r'
+ $'\r'
menudba: line 14: $'\r': command not found
menudba: line 15: syntax error in conditional expression
'enudba: line 15: syntax error near `]]
'enudba: line 15: `if [ -z "$dbamail" ] || [[ "$dbamail" = "EMAIL:" ]]

--Valida
Isso aí é 100% problema de fim-de-linha Windows (CRLF) no script (e possivelmente no config.txt). 
O bash -x já entregou: +$'\r' e command not found. Ou seja: tem caractere \r (CR) no final das linhas.

[oracle@srv1 ~]$ file menudba
menudba: Bourne-Again shell script, UTF-8 Unicode text executable, with very long lines, with CRLF line terminators


--Resolver:
dos2unix menudba



