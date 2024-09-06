     HCOPYRIGHT('2020 Patrik Schindler <poc@pocnet.net>, v. 2020-11-06')
     H* 
     H* This is free software; you can redistribute it and/or modify it
     H*  under the terms of the GNU General Public License as published by the
     H*  Free Software Foundation; either version 2 of the License, or (at your
     H*  option) any later version.
     H*
     H* It is distributed in the hope that it will be useful, but WITHOUT
     H*  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
     H*  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
     H*  for more details.
     H*
     H* You should have received a copy of the GNU General Public License along
     H*  with it; if not, write to the Free Software Foundation, Inc., 59
     H*  Temple Place, Suite 330, Boston, MA 02111-1307 USA or get it at
     H*  http://www.gnu.org/licenses/gpl.html
     H*
     H* Compiler flags.
     HDFTACTGRP(*NO) ACTGRP(*NEW) ALWNULL(*INPUTONLY)
     H*
     H* Tweak default compiler output: Don't be too verbose.
     HOPTION(*NOXREF : *NOSECLVL : *NOSHOWCPY : *NOEXT : *NOSHOWSKP)
     H*
     H* When going prod, enable this for more speed/less CPU load.
     HOPTIMIZE(*FULL)
     H*************************************************************************
     D* Global Variables (additional to autocreated ones by referenced files).
     DALLREC           S             10I 0
     DEXPREC           S             10I 0
     D*
     D* Call prototypes -------------------------------------------------------
     D* printf() like thing to add entries to the job log.
     D* https://www.mcpressonline.com/programming/rpg/
     D*  job-logging-from-rpg-ivthe-easy-way
     DQp0zLprintf      PR             5I 0 ExtProc('Qp0zLprintf')
     D szOutputStr                     *   Value OPTIONS(*STRING)
     D                                 *   Value OPTIONS(*STRING:*NOPASS)
     D                                 *   Value OPTIONS(*STRING:*NOPASS)
     D**************************************************************************
     C* Get the count of all records.
     C/EXEC SQL DECLARE SLT1 CURSOR FOR
     C+ SELECT COUNT(*) FROM spamassass/txrep FOR READ ONLY
     C/END-EXEC
     C*
     C* Get the count of expirable records.
     C/EXEC SQL DECLARE SLT2 CURSOR FOR
     C+ SELECT COUNT(*) FROM spamassass/txrep WHERE (
     C+  count=1 AND TIMESTAMP(last_hit) < (CURRENT_TIMESTAMP - 7 DAYS)
     C+ ) or (
     C+  TIMESTAMP(last_hit) < (CURRENT_TIMESTAMP - 2 MONTHS)
     C+ ) FOR READ ONLY
     C/END-EXEC
     C*
     C* Output statistics to job log.
     C                   EXSR      PRTDSTATS
     C*
     C* Expire records.
     C/EXEC SQL
     C+ DELETE FROM spamassass/txrep WHERE (
     C+  count=1 AND TIMESTAMP(last_hit) < (CURRENT_TIMESTAMP - 7 DAYS)
     C+ ) or (
     C+  TIMESTAMP(last_hit) < (CURRENT_TIMESTAMP - 2 MONTHS)
     C+ )
     C/END-EXEC
     C*
     C/EXEC SQL
     C+ COMMIT
     C/END-EXEC
     C*
     C                   MOVE      *ON           *INLR
     C                   RETURN
     C**************************************************************************
     C     PRTDSTATS     BEGSR
     C*
     C/EXEC SQL
     C+ OPEN SLT1
     C/END-EXEC
     C*
     C/EXEC SQL
     C+ FETCH NEXT FROM SLT1 INTO :ALLREC
     C/END-EXEC
     C*
     C/EXEC SQL
     C+ OPEN SLT2
     C/END-EXEC
     C*
     C/EXEC SQL
     C+ FETCH NEXT FROM SLT2 INTO :EXPREC
     C/END-EXEC
     C*
     C                   CALLP     Qp0zLprintf('TXREP-cleanup: %s entries, +
     C                             %s to expire.' +X'25'+X'00' : %CHAR(ALLREC)
     C                             : %CHAR(EXPREC))
     C*
     C                   ENDSR
     C**************************************************************************
     C* vim: syntax=rpgle colorcolumn=81 autoindent noignorecase
