/*
 * Integration main data management for Teragrep
 * Copyright (C) 2021  Suomen Kanuuna Oy
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://github.com/teragrep/teragrep/blob/main/LICENSE>.
 *
 *
 * Additional permission under GNU Affero General Public License version 3
 * section 7
 *
 * If you modify this Program, or any covered work, by linking or combining it
 * with other code, such other code is not for that reason alone subject to any
 * of the requirements of the GNU Affero GPL version 3 as long as this Program
 * is the same Program as licensed from Suomen Kanuuna Oy without any additional
 * modifications.
 *
 * Supplemented terms under GNU Affero General Public License version 3
 * section 7
 *
 * Origin of the software must be attributed to Suomen Kanuuna Oy. Any modified
 * versions must be marked as "Modified version of" The Program.
 *
 * Names of the licensors and authors may not be used for publicity purposes.
 *
 * No rights are granted for use of trade names, trademarks, or service marks
 * which are in The Program if any.
 *
 * Licensee must indemnify licensors and authors for any liability that these
 * contractual assumptions impose on licensors and authors.
 *
 * To the extent this program is licensed as part of the Commercial versions of
 * Teragrep, the applicable Commercial License may apply to this file if you as
 * a licensee so wish it.
 */
use flow;
DELIMITER //
CREATE OR REPLACE PROCEDURE retrieve_sink_by_id(proc_id int,tx_id int)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            RESIGNAL;
        END;
    START TRANSACTION;
            if(tx_id) is null then
             set @time = (select max(transaction_id) from mysql.transaction_registry);
        else
             set @time=tx_id;
        end if;
    if (select id from capture_sink for system_time as of transaction @time where id = proc_id) is null then
        SELECT JSON_OBJECT('id', proc_id, 'message', 'Sink does not exist') into @sink;
        signal sqlstate '45000' set message_text = @sink;
    end if;
    select cs.ip_address  as ip,
           cs.sink_port   as port,
           L.app_protocol as protocol,
           f.name         as flow
    from capture_sink for system_time as of transaction @time cs
             inner join L7 for system_time as of transaction @time L on cs.L7_id = L.id
             inner join flows for system_time as of transaction @time f on cs.flow_id = f.id
    where cs.id = proc_id
      and L.id = cs.L7_id
      and f.id = cs.flow_id;
    COMMIT;
END;
//
DELIMITER ;