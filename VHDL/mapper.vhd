-- VHDL CODE OF THE NABU Z80 CPU INTERPOSER
-- Copyright (C) 2022  LISTOFOPTIONS, PURDEAANDREI
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.



library ieee;
use ieee.numeric_std.all ;
use ieee.std_logic_1164.all ;



package mapper is

function or_reduce(arg : std_logic_vector) return std_logic ;
    
function and_reduce(arg : std_logic_vector) return std_logic ;

end package mapper ;



package body mapper is

function or_reduce(arg : std_logic_vector) return std_logic is
    variable temp : std_logic := '0' ;
begin
    for i in arg'range loop 
        temp := temp or arg(i) ;
    end loop ;
    return temp ;
end ;
    
function and_reduce(arg : std_logic_vector) return std_logic is
    variable temp : std_logic := '1' ;
begin
    for i in arg'range loop 
        temp := temp and arg(i) ;
    end loop ;
    return temp ;
end ;

end package body mapper ;