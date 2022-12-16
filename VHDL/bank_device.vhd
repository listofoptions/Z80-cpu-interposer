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



library work;
use work.mapper.all ;



-- *_n or *_N are active low signals
-- yyeeeeessss vhdl is case iNsEnSiTiVe and YES its annoying, but for sanity, lets assume all external facing pins are
-- in caps, and all internal only wires/signals/registers etc... are in lower case; ghdl will still barf if you try
-- and produce a signal that has the same name as a port signal so eh, nice i guess?
entity BANK_DEVICE is
    port ( M1_N       : in  std_logic -- active low
         ; WR_N       : in  std_logic -- active low
         ; RD_N       : in  std_logic -- active low
         ; MREQ_N     : in  std_logic -- active low
         ; IOREQ_N    : in  std_logic -- active low
         ; RESET_N    : in  std_logic -- active low
         ; REFRESH_N  : in  std_logic -- active low
         ; ADDRESS    : in  std_logic_vector(7 downto 2) -- active high
         ; ADDRESS_15 : in  std_logic -- active high
         ; ADDRESS_14 : in  std_logic -- active high
         ; DATA       : in  std_logic_vector(7 downto 0) -- active high
         ; EXTEND     : out std_logic_vector(7 downto 0) -- active high
         ; SYS_DIR_N  : out std_logic -- active low
         ; SYS_ACC_N  : out std_logic -- active low
         ; RAM_ACC_N  : out std_logic -- active low
         ; ROM_ACC_N  : out std_logic -- active low
         ; TI0_ACC_N  : out std_logic -- active low
         ; TI1_ACC_N  : out std_logic -- active low
         ; DMA_ACC_N  : out std_logic -- active low
         ) ;
end BANK_DEVICE ;



architecture BEHAVIOR of BANK_DEVICE is
    type   register_bank is array (3 downto 0) of std_logic_vector(7 downto 0) ;
    
    signal bank_acc_n : std_logic ;
    signal port_F_n   : std_logic ;
    signal tim_acc_n  : std_logic ;
    
    signal bank       : register_bank ;
    
    signal bank_addr  : std_logic_vector(7 downto 0) ;
begin
    internal_state : for i in 3 downto 0 generate
        -- bank registers get initialized to the first 4 pages of 256, which represent (and are mapped to) the base
        -- hardware, normally wed use the previous hardware design of a series of multiplexers and some latches
        -- but we can reset the bank registers much more sensibly this way
        bank(i) <=   std_logic_vector(to_unsigned(i, 8)) when (RESET_N = '0')
                     -- the above line does the magic (yaaay types!) of taking our iteration index and making it the 
                     -- constant to use in reseting
                else DATA when ((bank_acc_n or WR_N) = '0') 
                           and ((ADDRESS_15 & ADDRESS_14) = std_logic_vector(to_unsigned(i, 2)))
                     -- if we arent currently reseting, we assume we should be writing the databus to the bank
                     -- register of choice (modulo ioreq and wr)
                else bank(i) ;
    end generate ;
    
    -- banks are set up as 256 pages of 2**14 bytes, the bank to be used by the cpu is chosen using the highest 2 bits
    -- of the address bus.
    bank_addr   <=   bank(0) when (ADDRESS_15 = '0') and (ADDRESS_14 = '0')
                else bank(1) when (ADDRESS_15 = '0') and (ADDRESS_14 = '1')
                else bank(2) when (ADDRESS_15 = '1') and (ADDRESS_14 = '0')
                else bank(3) ;
    
    -- most of the peripherals to be added on the interposer are crammed into the nabu memory space at the end of the
    -- io memory map, in ports IO:0xF0:F
    port_F_n    <=   (IOREQ_N or not M1_N) or not and_reduce(ADDRESS(7 downto 4)) ;
    -- IO:0xFC:4 - bank registers, write only
    bank_acc_n  <=   port_F_n or (ADDRESS(3) nand ADDRESS(2)) ; 
    -- IO:0xF8:4 - dma controllers, bidirectional, bus-mastering
    DMA_ACC_N   <=   port_F_n or (ADDRESS(3) or not ADDRESS(2)) ;
    -- IO:0xF4:4 - timer/counter 1, bidirectional, controls timed dma on dma controllers 2 and 3, remainging timers
    --             are configurable as two 8 bit counters/timers or one 16 bit counter/timer
    TI1_ACC_N   <=   tim_acc_N or not ADDRESS(2) ;
    -- IO:0xF0:4 - timer/counter 0, bidirectional, controls timed dma on dma controllers 1 and 2, see timer/counter 1
    TI0_ACC_N   <=   tim_acc_N or ADDRESS(2) ;
    -- remaining timer/counter access logic:
    tim_acc_n   <=   ((port_F_n or ADDRESS(3)) or RD_N) and ((port_F_n or ADDRESS(3)) or WR_N) ; 
    
    -- of the 256 pages of banked memory (*not* IO, we may bank io in the future but we dont now!)
    -- the first four pages (0,1,2,3) are reserved and mapped to the system, as is any IO access.
    -- (the latter implies that another device could knock the interposer off of the cpu bus if it isnt fast enough 
    -- i thinK)
    -- if there is an io operation, or if the bank is 0-3 (and its a memory operation), or if refresh is occuring;
    -- then we need to open access through the interposers buffers to the rest of the system dropping the high Z state
    SYS_ACC_N   <=   and_reduce(IOREQ_N & (not or_reduce(bank_addr(7 downto 2)) or MREQ_N) & REFRESH_N) ;
    -- if we're writing, (or possibly reading and writing!?!?!) then bypass into the interposer bus; otherwise
    -- if we're reading (or we're neither reading or writing) then we bypass the interposer bus to the system
    SYS_DIR_N   <=   '0' when (WR_N = '0') else '1' when (RD_N = '0') else '1' ;
    -- we further subdivide the remaining banks so that the lower 124 (128 - 4) are rom (possibly ram in later revs)
    ROM_ACC_N   <=   MREQ_N or bank_addr(7) ;                     -- 128 - 4 pages of rom
    -- and the remainging 128 pages are all marked ram
    RAM_ACC_N   <=   MREQ_N or not bank_addr(7) ;                 -- 128 pages of ram
    
    EXTEND      <=   bank_addr ;
end BEHAVIOR ;