library ieee;
use ieee.numeric_std.all ;
use ieee.std_logic_1164.all ;

-- *_n or *_N are active low signals
-- yyeeeeessss vhdl is case iNsEnSiTiVe and YES its annoying, but for sanity, lets assume all external facing pins are
-- in caps, and all internal only wires/signals/registers etc... are in lower case; ghdl will still barf if you try
-- and produce a signal that has the same name as a port signal so eh, nice i guess?

entity BANK_DEVICE is
    port ( M1_N      : in  std_logic -- active low
         ; WR_N      : in  std_logic -- active low
         ; RD_N      : in  std_logic -- active low
         ; MREQ_N    : in  std_logic -- active low
         ; IOREQ_N   : in  std_logic -- active low
         ; RESET_N   : in  std_logic -- active low
         ; REFRESH_N : in  std_logic -- active low
         ; ADDRESS   : in  std_logic_vector(15 downto 0) -- active high
         ; DATA      : in  std_logic_vector( 7 downto 0) -- active high
         ; EXTEND    : out std_logic_vector(21 downto 0) -- active high
         ; SYS_DIR_N : out std_logic -- active low
         ; SYS_ACC_N : out std_logic -- active low
         ; RAM_ACC_N : out std_logic -- active low
         ; ROM_ACC_N : out std_logic -- active low
         ; TI0_ACC_N : out std_logic -- active low
         ; TI1_ACC_N : out std_logic -- active low
         ; DMA_ACC_N : out std_logic -- active low
         ) ;
end BANK_DEVICE ;



architecture BEHAVIOR of BANK_DEVICE is
    type   register_bank is array (3 downto 0) of std_logic_vector(7 downto 0) ;
    type   written_flags is array (3 downto 0) of std_logic ;
    
    signal io_acc_n   : std_logic ;
    signal bank_acc_n : std_logic ;
    signal port_F_n   : std_logic ;
    signal tim_acc_n  : std_logic ;
    
    signal flags      : written_flags ;
    signal bank       : register_bank ;
    signal crtl_reg   : std_logic_vector(7 downto 6) ;
    
    signal bank_addr  : std_logic_vector(7 downto 0) ;
    
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
begin
    internal_state : for i in 3 downto 0 generate
        flags(i)<=   '0'  when (RESET_N = '0')
                else '1'  when ((bank_acc_n or WR_N) = '0') and (ADDRESS(15 downto 14) = std_logic_vector(to_unsigned(i, 2)))
                else flags(i) ;
        bank(i) <=   std_logic_vector(to_unsigned(i, 8)) when (RESET_N = '0')
                else DATA when ((bank_acc_n or WR_N) = '0') and (ADDRESS(15 downto 14) = std_logic_vector(to_unsigned(i, 2)))
                else bank(i) ;
    end generate ;
    
    crtl_reg    <=   DATA(7 downto 6) when (not and_reduce(ADDRESS(7 downto 0)) or (io_acc_n or WR_N)) = '0' 
                else crtl_reg ;
    
    bank_addr   <=   bank(0) when (ADDRESS(15 downto 14) = "00") 
                else bank(1) when (ADDRESS(15 downto 14) = "01") 
                else bank(2) when (ADDRESS(15 downto 14) = "10") 
                else bank(3) ;
    
    port_F_n    <=   io_acc_n or not and_reduce(ADDRESS(7 downto 4)) ;
    io_acc_n    <=   IOREQ_N or not M1_N ;
    bank_acc_n  <=   port_F_n or (ADDRESS(3) nand ADDRESS(2)) ;   -- IO:0xFC:4
    tim_acc_n   <=   ((port_F_n or ADDRESS(3)) or RD_N) and ((port_F_n or ADDRESS(3)) or WR_N) ; 
    
    SYS_ACC_N   <=   and_reduce(IOREQ_N & (not or_reduce(bank_addr(7 downto 2)) or MREQ_N) & REFRESH_N) ;
    SYS_DIR_N   <=   '0' when (WR_N = '0') else '1' when (RD_N = '0') else '1';
    RAM_ACC_N   <=   MREQ_N or not bank_addr(7) ;                 -- 128 pages of ram
    ROM_ACC_N   <=   MREQ_N or bank_addr(7) ;                     -- 128 - 4 pages of rom
    TI0_ACC_N   <=   tim_acc_N or ADDRESS(2) ;                    -- IO:0xF0:4
    TI1_ACC_N   <=   tim_acc_N or not ADDRESS(2) ;                -- IO:0xF4:4
    DMA_ACC_N   <=   port_F_n or (ADDRESS(3) or not ADDRESS(2)) ; -- IO:0xF8:4
    
    EXTEND      <=   bank_addr & ADDRESS(13 downto 0) ;
end BEHAVIOR ;