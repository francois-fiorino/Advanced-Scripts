/* ==========================================================================================================
   Script: monitor_sessions.sql
   Autor: [Francois Fiorino]
   Data: [05/03/2026]
   Descrição:
       Este script exibe informações detalhadas sobre sessões ativas no banco de dados Oracle em ambiente RAC
       ou não-RAC, utilizando as visões gv$session, gv$process e v$sesstat. Ele auxilia na monitoração,
       diagnóstico e análise de sessões de usuários, consumos de CPU, waits e tempo da última ação.

   Funcionalidades:
       - Identifica sessões ativas, inativas e em espera (waits).
       - Mostra detalhes como usuário, máquina cliente, programa, SQL_ID atual e anterior.
       - Inclui informações de CPU, memória UGA/PGA, commits e rollbacks por sessão.
       - Suporta filtros opcionais por variáveis definidas no início (CLIENT_IDENTIFIER, MODULE, MACHINE, etc.)
         sem necessidade de alterar o SQL.

   Instruções de uso:
       1. Execute o script em uma sessão SQL*Plus, SQLcl ou SQL Developer.
       2. Caso queira aplicar filtros, edite as variáveis "define" no início do script.
          Exemplo:
              define STATUS='ACTIVE'
              define MODULE='SQL Developer'
       3. Se deixar os filtros vazios, o script retorna todas as sessões de usuários (excluindo BACKGROUND e SYSTEM).

   Compatibilidade:
       - Oracle Database 12c e superiores.
       - Ambientes RAC (usa gv$ views).
   
   Observação:
       - Este script não realiza alterações, apenas consulta.
       - Certifique-se de ter privilégios de acesso às visões gv$session, gv$process e v$sesstat.

   ========================================================================================================== */


set define on
set verify off
set feedback on
set pages 200
set lines 300
col STATUS          for a10
col INFO_SESS       for a120
col SESS            for a30
col MACHINE         for a30
col SESSIONWAIT     for a30
col LOGON_TIME      for a17
col LAST_ACAO       for a17
col INST_ID         for 99
define CLIENT_IDENTIFIER=''
define MACHINE=''
define MODULE='SQL Developer'
define OSUSER=''
define PROGRAM=''
define PROGRAM_NOPATH=''
define RCG=''
define STATE=''
define STATUS='ACTIVE'
define SERVER=''
define TYPE=''
define USERNAME=''
define SID=''
define SERIAL=''
define SQL_ID=''
define PID=''
with ps as
     (select inst_id, sid, serial#, qcsid, qcserial#
        from gv$px_session
       where qcserial# is not null)
select
    lpad(nvl(ps.inst_id, s.inst_id), 2,' ') AS INST_ID,
    s.status,
    'SID:'|| s.sid || chr(10) || 
    ' SERIAL:' || s.serial# || chr(10) || 
    ' PID:' || p.spid AS SESS,
    to_char(s.logon_time, 'DD/MM/YY HH24:MI:SS') LOGON_TIME,
    to_char((sysdate - s.last_call_et / 86400),'DD/MM/YY HH24:MI:SS') LAST_ACAO,
    s.machine,
    'OWNER:"' || s.username || 
    '"  USUARIO:"' || s.osuser || 
    '"  PROCESS APL:"' || s.process || '"' || chr(10) ||
    '  PROGRAM:"' || s.program || '"' || chr(10) ||
    '  EVENT:"' || s.event || '"' || chr(10) ||
    '  SQL_ID ATUAL:"' || s.sql_id || '" SQL_ID ANTERIOR:"' || s.prev_sql_id || '"' AS INFO_SESS,
    -- Tempo em espera
    s.seconds_in_wait as WAIT,
    -- NOVAS COLUNAS DE WAIT
 decode(
        s.state,
        'WAITING',
        substr(
           trim(
             replace(
               replace(substr(s.event,1,100),'SQL*Net',''),
             'Streams','')
           ),1,24),
        'ON CPU'
    ) as SESSIONWAIT
from gv$session s
join (
  select ss.sid stat_sid,
         sum(decode(sn.name, 'CPU used when call started', ss.value, 0)) CPU_this_call_start,
         sum(decode(sn.name, 'CPU used by this session', ss.value, 0)) CPU,
         sum(decode(sn.name, 'session uga memory', ss.value, 0)) uga_memory,
         sum(decode(sn.name, 'session pga memory', ss.value, 0)) pga_memory,
         sum(decode(sn.name, 'user commits', ss.value, 0)) commits,
         sum(decode(sn.name, 'user rollbacks', ss.value, 0)) rollbacks
    from   v$sesstat ss
    join   v$statname sn on ss.statistic# = sn.statistic#
   where   sn.name in (
             'CPU used when call started',
             'CPU used by this session',
             'session uga memory',
             'session pga memory',
             'user commits',
             'user rollbacks'
           )
   group by ss.sid
) stat
  on stat.stat_sid = s.sid
left join ps
  on ps.sid = s.sid
 and ps.serial# = s.serial#
 and ps.inst_id = s.inst_id
left join gv$process p
  on p.addr = s.paddr
 and p.inst_id = s.inst_id
where s.username is not null
  and nvl(s.osuser,'x') <> 'SYSTEM'
  and s.type <> 'BACKGROUND'
AND (
  COALESCE(TRIM(UPPER('&CLIENT_IDENTIFIER')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.client_identifier, '')) = TRIM(UPPER('&CLIENT_IDENTIFIER'))
)
AND (
  COALESCE(TRIM(UPPER('&MACHINE')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.machine, '')) = TRIM(UPPER('&MACHINE'))
)
AND (
  COALESCE(TRIM(UPPER('&MODULE')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.module, '')) = TRIM(UPPER('&MODULE'))
)
AND (
  COALESCE(TRIM(UPPER('&OSUSER')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.osuser, '')) = TRIM(UPPER('&OSUSER'))
)
AND (
  COALESCE(TRIM(UPPER('&PROGRAM')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.program, '')) = TRIM(UPPER('&PROGRAM'))
)
AND (
  COALESCE(TRIM(UPPER('&RCG')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.resource_consumer_group, '')) = TRIM(UPPER('&RCG'))
)
AND (
  COALESCE(TRIM(UPPER('&STATE')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.state, '')) = TRIM(UPPER('&STATE'))
)
AND (
  COALESCE(TRIM(UPPER('&SERVER')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.server, '')) = TRIM(UPPER('&SERVER'))
)
AND (
  COALESCE(TRIM(UPPER('&TYPE')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.type, '')) = TRIM(UPPER('&TYPE'))
)
AND (
  COALESCE(TRIM(UPPER('&USERNAME')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.username, '')) = TRIM(UPPER('&USERNAME'))
)
AND (
  COALESCE(TRIM('&SID'), 'ALL') = 'ALL'
  OR TO_CHAR(s.sid) = TRIM('&SID')
)
AND (
  COALESCE(TRIM('&SERIAL'), 'ALL') = 'ALL'
  OR TO_CHAR(s.serial#) = TRIM('&SERIAL')
)
AND (
  COALESCE(TRIM(UPPER('&SQL_ID')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.sql_id, '')) = TRIM(UPPER('&SQL_ID'))
)
AND (
  COALESCE(TRIM('&PID'), 'ALL') = 'ALL'
  OR TO_CHAR(p.pid) = TRIM('&PID')
)
AND (
  COALESCE(TRIM(UPPER('&STATUS')), 'ALL') = 'ALL'
  OR UPPER(NVL(s.status, '')) = TRIM(UPPER('&STATUS'))
)
AND (
  COALESCE(TRIM(UPPER('&PROGRAM_NOPATH')), 'ALL') = 'ALL'
  OR UPPER(
        CASE
          WHEN INSTR(s.program, '\') > 0 THEN SUBSTR(s.program, INSTR(s.program, '\', -1) + 1)
          WHEN INSTR(s.program,  '/') > 0 THEN SUBSTR(s.program,  INSTR(s.program,  '/', -1) + 1)
          ELSE s.program
        END
      ) = TRIM(UPPER('&PROGRAM_NOPATH'))
)
order by s.status desc,
         to_char((sysdate - s.last_call_et / 86400),'DD/MM/YY HH24:MI:SS') asc;
