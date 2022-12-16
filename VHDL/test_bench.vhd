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
use work.all ;
use work.mapper.all ;



-- *_n or *_N are active low signals
-- yyeeeeessss vhdl is case iNsEnSiTiVe and YES its annoying, but for sanity, lets assume all external facing pins are
-- in caps, and all internal only wires/signals/registers etc... are in lower case; ghdl will still barf if you try
-- and produce a signal that has the same name as a port signal so eh, nice i guess?
entity TEST_BENCH is
end TEST_BENCH ;

architecture BEHAVIOR of TEST_BENCH is
        -- signals to drive
    signal address_test                            : std_logic_vector(15 downto 0) ;
    signal data_test                               : std_logic_vector( 7 downto 0) ;
    signal m1_test_n, wr_test_n, rd_test_n
         , mreq_test_n, ioreq_test_n, reset_test_n
         , refresh_test_n                          : std_logic ;
    -- signals to be driven
    signal extend_test                             : std_logic_vector( 7 downto 0) ;
    signal sys_test_dir_n, sys_test_acc_n
         , ram_test_acc_n, rom_test_acc_n
         , ti0_test_acc_n, ti1_test_acc_n
         , dma_test_acc_n                          : std_logic ;
begin

    DUT : entity work.BANK_DEVICE(BEHAVIOR)
        port map ( M1_N       => m1_test_n
                 , WR_N       => wr_test_n
                 , RD_N       => rd_test_n
                 , MREQ_N     => mreq_test_n
                 , IOREQ_N    => ioreq_test_n
                 , RESET_N    => reset_test_n
                 , REFRESH_N  => refresh_test_n
                 , ADDRESS    => address_test(7 downto 2)
                 , ADDRESS_15 => address_test(15)
                 , ADDRESS_14 => address_test(14)
                 , DATA       => data_test
                 , EXTEND     => extend_test
                 , SYS_DIR_N  => sys_test_dir_n
                 , SYS_ACC_N  => sys_test_acc_n
                 , RAM_ACC_N  => ram_test_acc_n
                 , ROM_ACC_N  => rom_test_acc_n
                 , TI0_ACC_N  => ti0_test_acc_n
                 , TI1_ACC_N  => ti1_test_acc_n
                 , DMA_ACC_N  => dma_test_acc_n
                 ) ;
    
    stimulus: process
    begin
        -- list of tests performed:
        -- reset test:
        --      extend outputs map to 0-3 on reset
        -- system access test:
        --      access to system on io read
        --      access to system on io write
        --      access to system on mem read
        --      access to system on mem write
        --      access to system on refresh
        -- interposer memory access test:
        --      access to interposer rom read fail
        --      access to interposer ram read fail
        --      access to interposer rom write fail
        --      access to interposer ram write fail
        -- ti0 access test:
        --      io read access
        --      io write access
        -- ti1 access test
        --      same as ti0 access test
        -- dma access test
        --      io read access
        --      io write access
        -- bank write 
        --      write a bank register with a rom page number
        --      write another bank register with a ram page number
        -- system access test:
        --      same as above but all tests must fail on written bank registers
        --      unwritten bank registers pass
        -- bank read test:
        --      previously written banks match when accessed
        --      unwritten bank registers maintain same value
        -- interposer memory access test:
        --      access to interposer rom read pass
        --      access to interposer ram read pass
        --      access to interposer rom write pass
        --      access to interposer ram write pass
        -- ti0 access test:
        --      io read access
        --      io write access
        -- ti1 access test
        --      same as ti0 access test
        -- dma access test
        --      io read access
        --      io write access
        
    end process ;
    
end BEHAVIOR ;