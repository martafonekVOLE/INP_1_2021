-- cpu.vhd: Simple 8-bit CPU (BrainLove interpreter)
-- Copyright (C) 2021 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): DOPLNIT
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity cpu is
 port (
   CLK   : in std_logic;  -- hodinovy signal
   RESET : in std_logic;  -- asynchronni reset procesoru
   EN    : in std_logic;  -- povoleni cinnosti procesoru
 
   -- synchronni pamet ROM
   CODE_ADDR : out std_logic_vector(11 downto 0); -- adresa do pameti
   CODE_DATA : in std_logic_vector(7 downto 0);   -- CODE_DATA <- rom[CODE_ADDR] pokud CODE_EN='1'
   CODE_EN   : out std_logic;                     -- povoleni cinnosti
   
   -- synchronni pamet RAM
   DATA_ADDR  : out std_logic_vector(9 downto 0); -- adresa do pameti
   DATA_WDATA : out std_logic_vector(7 downto 0); -- ram[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
   DATA_RDATA : in std_logic_vector(7 downto 0);  -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
   DATA_WREN  : out std_logic;                    -- cteni z pameti (DATA_WREN='0') / zapis do pameti (DATA_WREN='1')
   DATA_EN    : out std_logic;                    -- povoleni cinnosti
   
   -- vstupni port
   IN_DATA   : in std_logic_vector(7 downto 0);   -- IN_DATA obsahuje stisknuty znak klavesnice pokud IN_VLD='1' a IN_REQ='1'
   IN_VLD    : in std_logic;                      -- data platna pokud IN_VLD='1'
   IN_REQ    : out std_logic;                     -- pozadavek na vstup dat z klavesnice
   
   -- vystupni port
   OUT_DATA : out  std_logic_vector(7 downto 0);  -- zapisovana data
   OUT_BUSY : in std_logic;                       -- pokud OUT_BUSY='1', LCD je zaneprazdnen, nelze zapisovat,  OUT_WREN musi byt '0'
   OUT_WREN : out std_logic                       -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
 );
end cpu;


-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is

 -- Registry
-- ----------------------------------------------------------------------------

 signal pc_addr: std_logic_vector(9 downto 0)
 signal pc_inc : std_logic;
 signal pc_dec : std_logic;

 --

 signal ptr_addr: std_logic_vector(9 downto 0)
 signal ptr_inc : std_logic;
 signal ptr_dec : std_logic;

 --

 signal cnt_addr: std_logic_vector(9 downto 0)
 signal cnt_inc : std_logic;
 signal cnt_dec : std_logic;
 
 -- Muxy
-- ----------------------------------------------------------------------------

 signal sel : std_logic_vector(1 downto 0); 

 -- Stavy FSM
-- ----------------------------------------------------------------------------

 type fsm_state is (
   sidle, sfetch, sdecode, --výchozí, načítací a dekódovací state
   state_inc_val, state_inc_val2, state_inc_val3,
   state_dec_val, state_dec_val2, state_dec_val3,  -- odpovídá inc_val a dec_val
   state_po_inc, state_po_dec,   -- odpovídá po_inc a po_dec
   state_while_s, state_while_s2, state_while_s3, 
   state_while_p, state_while_p2, state_while_p3,-- odpovídá while_s a while_p
   state_putchar, state_getchar, -- odpovídá putchar a getchar
   state_break, state_return,
   state_none
-- další stavy
 );
 --signal 2x 

 -- Instrukce
-- ----------------------------------------------------------------------------

 type instruction_type is (
 inc_val, dec_val, -- inkrementace a dekrementace buňky (hodnoty)
 po_inc, po_dec,   -- inkrementace a dekrementace ukazatele
 while_s, while_p,
 putchar, getchar,
 break, return,
 none
 );
 signal instruction : instruction_type;


begin

 -- zde dopiste vlastni VHDL kod

 -- pri tvorbe kodu reflektujte rady ze cviceni INP, zejmena mejte na pameti, ze 
 --   - nelze z vice procesu ovladat stejny signal,
 --   - je vhodne mit jeden proces pro popis jedne hardwarove komponenty, protoze pak
 --      - u synchronnich komponent obsahuje sensitivity list pouze CLK a RESET a 
 --      - u kombinacnich komponent obsahuje sensitivity list vsechny ctene signaly.


-- ----------------------------------------------------------------------------
--                               Register PC
-- ----------------------------------------------------------------------------
pc_process: process(RESET, CLK)
begin
	if (RESET = '1') then
	  pc_addr <= (others => '0');
	elsif(CLK'event) and (CLK='1') then
	  if(pc_inc = '1') then
	    pc_addr <= pc_addr + 1;
	  elsif(pc_dec = '1') then
	    pc_addr <= pc_addr - 1;
	  end if;
	end if;
end process;
-- ----------------------------------------------------------------------------
--                               Register PTR
-- ----------------------------------------------------------------------------
ptr_process: process(RESET, CLK)
begin
	if (RESET = '1') then
	  ptr_addr <= '100000000";
	elsif(CLK'event) and (CLK = '1') then
	  if(ptr_inc = '1') then
	    ptr_addr <= ptr_addr + 1;
	  elsif(ptr_dec = '1') then
	    ptr_addr <= ptr_addr - 1;
	  endif;
	endif;
end process;
-- ----------------------------------------------------------------------------
--                               Register CNT
-- ----------------------------------------------------------------------------
ptr_process: process(RESET, CLK)
begin
	if (RESET = '1') then
	  ptr_addr <= '100000000";
	elsif(CLK'event) and (CLK = '1') then
	  if(ptr_inc = '1') then
	    ptr_addr <= ptr_addr + 1;
	  elsif(ptr_dec = '1') then
	    ptr_addr <= ptr_addr - 1;
	  endif;
	endif;
end process;
-- ----------------------------------------------------------------------------
--                             Multiplexor 3 na 1
-- ----------------------------------------------------------------------------
mux: process(CLK, sel, DATA_RDATA, IN_DATA)
begin
	case sel is
	  when "00" => DATA_WDATA <= IN_DATA;
	  when "01" => DATA_WDATA <= DATA_RDATA - 1;
	  when "10" => DATA_WDATA <= DATA_RDATA + 1;
	  when others =>
	end case;
end process;
-- ----------------------------------------------------------------------------
--                                 Dekoder
-- ----------------------------------------------------------------------------
decoder: process(DATA_RDATA)
begin
	case(DATA_RDATA) is
	  when X"3E" => instruction <= inc_val; -- Instrukce:  >
	  when X"3C" => instruction <= dec_val; -- Instrukce:  <
	  when X"2B" => instruction <= po_inc;  -- Instrukce:  +
	  when X"2D" => instruction <= po_dec;  -- Instrukce:  -
	  when X"5B" => instruction <= while_s; -- Instrukce:  [
	  when X"5D" => instruction <= while_p; -- Instrukce:  ]
	  when X"2E" => instruction <= putchar;	-- Instrukce:  .
	  when X"2C" => instruction <= getchat; -- Instrukce:  ,
	  when X"7E" => instruction <= break;   -- Instrukce:  ~ (Brainlove thing)
	  when X"00" => instruction <= return;  -- Instrukce: null
	  when others => instruction <= none;   -- Instrukce: none
-- ----------------------------------------------------------------------------
--                             Aktualizace FSM
-- ----------------------------------------------------------------------------
pstate_fsm: process(RESET, CLK)
begin
	if(RESET = '1') then
		pstate <= sidle;
	elsif (CLK'event) and (CLK = 1) then
		if (EN = '1') then
		  pstate <= nstate;
		endif;
	endif;
end process;
-- ----------------------------------------------------------------------------
--                               Logika FSM
-- ----------------------------------------------------------------------------
nstate_fsm: process() --závislosti!!
begin
	-----Default-----
	pc_addr = '0';
	pc_inc  = '0';
	pc_dec  = '0';
	ptr_addr= '0';
	ptr_inc = '0';
	ptr_dec = '0';
	cnt_addr= '0';
	cnt_inc = '0';
	cnt_dec = '0';

case pstate is
	-----SIDLE-----
	when sidle =>  nstate <= sfetch;
	-----SFETCH-----
	when sfetch => nstate <= sdecode;
	-----SDECODE-----
		case instruction is
			when inc_val => nstate <= state_inc_val;
			when dec_val => nstate <= state_dec_val;
			when po_inc  => nstate <= state_po_inc;
			when po_dec  => nstate <= state_po_dec;
			when while_s => nstate <= state_while_s;
			when while_p => nstate <= state_while_p;
			when puthcar => nstate <= state_puthcar;
			when getchar => nstate <= state_getchar;
			when break   => nstate <= state_break;
			when return  => nstate <= state_return;
			when none    => nstate <= state_none;
			when others  => nstate <= state_none;
	-----Instrukce:  >-----
	when state_po_inc =>
			po_inc <= '1';
			pc_inc <= '1';
			nstate <= sfetch;
	when state_po_dec =>
			po_dec <= '1';
			pc_dec <= '1';
			nstate <= sfetch;
	when state_inc_val =>
			DATA_EN <= '1';
			DATA_RDWR <= '0';
			nstate <= state_inc_val2; 
	when state_inc_val2 =>
			sel <= "10"; 		--Inkrementace
			nstate <= state_inc_val3; 
	when state_inc_val3 =>
			DATA_EN <= '1';
			DATA_RDWR <= '1';
			pc_inc <= '1';
			nstate <= sfetch;
	when state_dec_val =>
			DATA_EN <= '1';
			DATA_RDWR <= '0';
			nstate <= state_dec_val2;
	when state_dec_val2 => 
			sel <= "01" 		--Dekrementace
			nstate <= state_dec_val3;
	when state_dec_val3 =>
			DATA_EN <= '1';
			DATA_RDWR <= '1';
			pc_dec <= '1';
			nstate <= sfetch;
	when state_while_s =>
			pc_dec <= '1';		-- PC <- PC + 1
			DATA_EN <= '1';		
			DATA_RDWR <= '0';	-- DATA_RDATA = ram[pointer]
			nstate <= state_while_s2;
	when state_while_s2 =>
			if DATA_RDATA = (DATA_RDATA'range => '0') then	-- if ram[pointer] == 0
				cnt_inc <= '1';
				CODE_EN <= '1';				-- povolí zápis 
				nstate  <= state_while_s3;
			else
				nstate <= sfetch;
 			endif;
	when state_while_s3 =>
			if cnt_addr = (cnt_addr'range => '0'); then	-- CNT = 0
				nstate <= sfetch;
			else						-- while CNT != 0
				if CODE_DATA = X"5B" then		-- if c == [ inkrementuj
					cnt_inc <= '1';
				elsif CODE_DATA = X"5D" then		-- if c == ] dekrementuj
					cnt_dec <= '0';
				endif;
				
				pc_dec <= '1';
				nstate <= 'state_while_p';
			endif;	
	when state_while_p => 
				
				
			
			
	

	
end behavioral;
 
