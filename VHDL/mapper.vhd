library ieee;
use ieee.numeric_std.all ;
use ieee.std_logic_1164.all ;

entity BANK_DEVICE is
    port ( WR      : in  std_logic -- active low
         ; RD      : in  std_logic -- active low
         ; MREQ    : in  std_logic -- active low
         ; IOREQ   : in  std_logic -- active low
         ; RESET   : in  std_logic -- active low
         ; REFRESH : in  std_logic -- active low
         ; ADDRESS : in  std_logic_vector(15 downto 0) -- active high
         ; DATA    : in  std_logic_vector( 7 downto 0) -- active high
         ; EXTEND  : out std_logic_vector(21 downto 0) -- active high
         ; SYS_ACC : out std_logic -- active low
         ; RAM_ACC : out std_logic -- active low
         ; ROM_ACC : out std_logic -- active low
         ; TI0_ACC : out std_logic -- active low
         ; TI1_ACC : out std_logic -- active low
         ; DMA_ACC : out std_logic -- active low
         ) ;
end BANK_DEVICE ;

architecture BEHAVIOR of BANK_DEVICE is
    type   register_bank is array (3 downto 0) of std_logic_vector(7 downto 0) ;
    type   written_flags is array (3 downto 0) of std_logic ;
    
    signal io_acc     : std_logic ;
    signal bank_acc   : std_logic ;
    signal port_F     : std_logic ;
    signal tim_acc    : std_logic ;
    
    signal flags      : written_flags ;
    signal bank       : register_bank ;
    signal crtl_reg   : std_logic_vector(7 downto 6) ;
    
    signal bank_addr  : std_logic_vector(7 downto 0) ;
    
    function nor_reduce(arg : std_logic_vector) return std_logic is
        variable temp : std_logic := '0' ;
    begin
        for i in arg'range loop 
            temp := temp nor arg(i) ;
        end loop ;
        return temp ;
    end ;
    
    function nand_reduce(arg : std_logic_vector) return std_logic is
        variable temp : std_logic := '1' ;
    begin
        for i in arg'range loop 
            temp := temp nand arg(i) ;
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
        flags(i)<=   '0'  when (reset = '0')
                else '1'  when ((bank_acc or WR) = '0') and (ADDRESS(15 downto 14) = std_logic_vector(to_unsigned(i, 2)))
                else flags(i) ;
        bank(i) <=   std_logic_vector(to_unsigned(i, 8)) when (reset = '0')
                else DATA when ((bank_acc or WR) = '0') and (ADDRESS(15 downto 14) = std_logic_vector(to_unsigned(i, 2)))
                else bank(i) ;
    end generate ;
    
    crtl_reg    <=   DATA(7 downto 6) when (nand_reduce(ADDRESS(7 downto 0)) or (io_acc or WR)) = '0' 
                else crtl_reg
    
    bank_addr   <=   bank(0) when (ADDRESS(15 downto 14) = "00") 
                else bank(1) when (ADDRESS(15 downto 14) = "01") 
                else bank(2) when (ADDRESS(15 downto 14) = "10") 
                else bank(3) ;
    
    port_F      <=   io_acc or nand_reduce(ADDRESS(7 downto 4)) ;
    io_acc      <=   IOREQ or not M1 ;
    bank_acc    <=   port_F or (ADDRESS(3) nand ADDRESS(2)) ;   -- IO:0xFC:4
    tim_acc     <=   ((port_F or ADDRESS(3)) or rd) and ((port_F or ADDRESS(3)) or wr) ; 
    
    SYS_ACC     <=   and_reduce((IOREQ or M1) & port_F & (nor_reduce(bank_addr(7 downto 2)) or MREQ) & REFRESH);
    RAM_ACC     <=   MREQ or not bank_addr(7) ;                 -- 128 pages of ram
    ROM_ACC     <=   MREQ or bank_addr(7) ;                     -- 128 - 4 pages of rom
    TI0_ACC     <=   tim_acc or ADDRESS(2) ;                    -- IO:0xF0:4
    TI1_ACC     <=   tim_acc or not ADDRESS(2) ;                -- IO:0xF4:4
    DMA_ACC     <=   port_F or (ADDRESS(3) or not ADDRESS(2)) ; -- IO:0xF8:4
    
    EXTEND      <=   bank_addr & ADDRESS(13 downto 0) ;
end BEHAVIOR ;