library ieee;
use ieee.numeric_std.all ;
use ieee.std_logic_1164.all ;

entity BANK_DEVICE is
    port ( WR      : in    std_logic -- active low
         ; RD      : in    std_logic -- active low
         ; MREQ    : in    std_logic -- active low
         ; IOREQ   : in    std_logic -- active low
         ; RESET   : in    std_logic -- active low
         ; REFRESH : in    std_logic -- active low
         ; ADDRESS : in    std_logic_vector(15 downto 0) -- active high
         ; DATA    : inout std_logic_vector( 7 downto 0) -- active high
         ; EXTEND  : out   std_logic_vector(21 downto 0) -- active high
         ; SYS_ACC : out   std_logic -- active low
         ; RAM_ACC : out   std_logic -- active low
         ; ROM_ACC : out   std_logic -- active low
         ; TIM_ACC : out   std_logic -- active low
         ; DMA_ACC : out   std_logic -- active low
         ) ;
end BANK_DEVICE ;

architecture BEHAVIOR of BANK_DEVICE is
    type   register_bank is array (3 downto 0) of std_logic_vector(7 downto 0) ;
    type   written_flags is array (3 downto 0) of std_logic ;
    signal bank_acc_rd    : std_logic ;
    signal bank_acc_wr    : std_logic ;
    signal bank           : register_bank ;
    signal flags          : written_flags ;
    signal bank_addr      : std_logic_vector(7 downto 0) ;
    
    function nand_reduce(arg : std_logic_vector) return std_logic is
        variable temp : std_logic := '0' ;
    begin
        for i in arg'range loop 
            temp := temp nand arg(i) ;
        end loop ;
        return temp ;
    end ;
    
    function nor_reduce(arg : std_logic_vector) return std_logic is
        variable temp : std_logic := '0' ;
    begin
        for i in arg'range loop 
            temp := temp nor arg(i) ;
        end loop ;
        return temp ;
    end ;
    
    function select_as(position : std_logic_vector; value_of : std_logic_vector) return std_logic is
        variable temp : std_logic := '1' ;
        variable mask : std_logic_vector(position'range) ;
    begin
        if position'length = value_of'length then
            mask := position xnor value_of ;
            for i in position'range loop 
                temp := temp and mask(i) ;
            end loop ;
            return temp ;
        else 
            return '0' ;
        end if ;
    end ;
begin
    internal : for i in 3 downto 0 generate
        flags(i)  <=   '0' when (reset = '0')
                  else '1' when ((bank_acc_wr or not select_as(std_logic_vector(to_unsigned(i, 2)), ADDRESS(15 downto 14))) = '0')
                  else flags(i) ;
        bank(i)   <=   std_logic_vector(to_unsigned(i, 8)) when (reset = '0')
                  else DATA when ((bank_acc_wr or not select_as(std_logic_vector(to_unsigned(i, 2)), ADDRESS(15 downto 14))) = '0')
                  else bank(i) ;
    end generate ;

    bank_addr   <=   bank(0) when (select_as("00", ADDRESS(15 downto 14)) = '1') 
                else bank(1) when (select_as("01", ADDRESS(15 downto 14)) = '1') 
                else bank(2) when (select_as("10", ADDRESS(15 downto 14)) = '1') 
                else bank(3) ;
    bank_acc_rd <=   (IOREQ or RD) or nand_reduce(ADDRESS(7 downto 2)) ; -- IO:0xFC:4
    bank_acc_wr <=   (IOREQ or WR) or nand_reduce(ADDRESS(7 downto 2)) ; -- IO:0xFC:4
    EXTEND      <=   bank_addr & ADDRESS(13 downto 0) ;
    SYS_ACC     <=   (nand_reduce(ADDRESS(7 downto 4)) or IOREQ) and (nor_reduce(bank_addr(7 downto 2)) or MREQ) ;
    RAM_ACC     <=   MREQ  or not bank_addr(7) ; -- 128 pages of ram
    ROM_ACC     <=   MREQ  or bank_addr(7) ; -- 128 - 4 pages of rom
    TIM_ACC     <=   (IOREQ or nand_reduce(ADDRESS(7 downto 4))) or ADDRESS(3) ; -- IO:0xF0:8
    DMA_ACC     <=   (IOREQ or nand_reduce(ADDRESS(7 downto 4))) or (ADDRESS(3) or not ADDRESS(2)) ; -- IO:0xF8:4
    DATA        <=   bank_addr when (bank_acc_rd = '0')
                else (others => 'Z') ; 
end BEHAVIOR ;