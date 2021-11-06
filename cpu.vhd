-- cpu.vhd: Simple 8-bit CPU (BrainLove interpreter)
-- Copyright (C) 2021 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): Martin Pech (xpechm00)
-- E-mail: xpechm00@stud.vutbr.cz
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

 signal pc_addr: std_logic_vector(11 downto 0);
 signal pc_inc : std_logic;
 signal pc_dec : std_logic;

 --

 signal ptr_addr: std_logic_vector(9 downto 0);
 signal ptr_inc : std_logic;
 signal ptr_dec : std_logic;

 --

 signal cnt_addr: std_logic_vector(11 downto 0);
 signal cnt_inc : std_logic;
 signal cnt_dec : std_logic;
 
 -- Muxy
-- ----------------------------------------------------------------------------

 signal sel : std_logic_vector(1 downto 0); 

 -- Stavy FSM
-- ----------------------------------------------------------------------------

 type fsm_state is (
   sidle, sfetch, sdecode, 																-- výchozí, načítací a dekódovací state
   state_inc_val, state_inc_val2, state_inc_val3,										-- odpovídá inc_val, značí +
   state_dec_val, state_dec_val2, state_dec_val3,  										-- odpovídá dec_val, značí -
   state_po_inc, state_po_dec,   														-- odpovídá po_inc a po_dec, značí > & <
   state_while_s, state_while_s2, state_while_s3, state_while_s_loop,					-- odpovídá while_s a značí začátek cyklu
   state_while_e, state_while_e2, state_while_e3, state_while_e_loop, state_while_e4, 	-- odpovídá while_e a značí konec cyklu
   state_putchar, state_putchar2, state_getchar, state_getchar2, 						-- odpovídá putchar a getchar, značí . a ,
   state_break, state_break2, state_break3, state_return,								-- značí tildu a null
   state_none																			-- značí ostatní stavy
 );
 signal pstate : fsm_state := sidle;													-- aktuální stav
 signal nstate : fsm_state;																-- další stav

 -- Instrukce
-- ----------------------------------------------------------------------------
-- UNUSED!
 --type instruction_type is (
 --inc_val, dec_val, -- inkrementace a dekrementace buňky (hodnoty)
 --po_inc, po_dec,   -- inkrementace a dekrementace ukazatele
 --while_s, while_e,
 --putchar, getchar,
 --break, ret,
 --none
 --);
 -- UNUSED!   signal instruction : instruction_type;


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
pc_process: process(RESET, CLK, pc_inc, pc_dec)
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
CODE_ADDR <= pc_addr; --?
-- ----------------------------------------------------------------------------
--                               Register CNT
-- ----------------------------------------------------------------------------
cnt_process: process(RESET, CLK, cnt_inc, cnt_dec)
begin
	if (RESET = '1') then
	  cnt_addr <= (others => '0');
	elsif(CLK'event) and (CLK = '1') then
	  if(cnt_inc = '1') then
	    cnt_addr <= cnt_addr + 1;
	  elsif(cnt_dec = '1') then
	    cnt_addr <= cnt_addr - 1;
	  end if;
	end if;
end process;

-- ----------------------------------------------------------------------------
--                               Register PTR
-- ----------------------------------------------------------------------------
ptr_process: process(RESET, CLK, ptr_inc, ptr_dec)
begin
	if (RESET = '1') then
	  ptr_addr <= (others => '0');
	elsif(CLK'event) and (CLK = '1') then
	  if(ptr_inc = '1') then
	    ptr_addr <= ptr_addr + 1;
	  elsif(ptr_dec = '1') then
	    ptr_addr <= ptr_addr - 1;
	  end if;
	end if;
end process;
DATA_ADDR <= ptr_addr;
-- ----------------------------------------------------------------------------
--                             Multiplexor 3 na 1
-- ----------------------------------------------------------------------------
mux: process(CLK, sel, RESET)
begin
    if RESET = '1' then
        DATA_WDATA <= (others => '0'); 
    elsif CLK'event and CLK = '1' then
	case sel is
	  when "00" => DATA_WDATA <= IN_DATA;
	  when "01" => DATA_WDATA <= DATA_RDATA - 1;
	  when "10" => DATA_WDATA <= DATA_RDATA + 1;
	  when others =>
            DATA_WDATA <= (others => '0');
	end case;
    end if;
end process;
-- ----------------------------------------------------------------------------
--                             Dekoder - UNUSED!
--		   Nebyl použit z důvodu chyb výpisu a zbytečné implementaci
-- ----------------------------------------------------------------------------
--decoder: process(instruction, CLK, RESET)
--begin
	--case(DATA_RDATA) is
	  --when X"3E" => instruction <= inc_val; -- Instrukce:  >
	  --when X"3C" => instruction <= dec_val; -- Instrukce:  <
	  --when X"2B" => instruction <= po_inc;  -- Instrukce:  +
	  --when X"2D" => instruction <= po_dec;  -- Instrukce:  -
	  --when X"5B" => instruction <= while_s; -- Instrukce:  [
	  --when X"5D" => instruction <= while_e; -- Instrukce:  ]
	  --when X"2E" => instruction <= putchar; -- Instrukce:  .
	  --when X"2C" => instruction <= getchar; -- Instrukce:  ,
	  --when X"7E" => instruction <= break;   -- Instrukce:  ~ (Brainlove thing)
	  --when X"00" => instruction <= ret;     -- Instrukce: null
	  --when others => instruction <= none;   -- Instrukce: none
    --end case;
--end process;
-- ----------------------------------------------------------------------------
--                             Aktualizace FSM
-- ----------------------------------------------------------------------------
pstate_fsm: process(RESET, CLK, EN)
begin
	if(RESET = '1') then
		pstate <= sidle;
	elsif CLK'event and CLK = '1' then
		if (EN = '1') then
		  pstate <= nstate;
		end if;
	end if;
end process;
-- ----------------------------------------------------------------------------
--                               Logika FSM
-- ----------------------------------------------------------------------------
nstate_fsm: process(pstate, OUT_BUSY, IN_VLD, CODE_DATA, cnt_addr, DATA_RDATA) --závislosti!!
begin
-- --------------------------Defaultní nastavení-------------------------------
		 pc_inc  	<= '0';
		 pc_dec  	<= '0';
		 ptr_inc 	<= '0';
		 ptr_dec 	<= '0';
		 cnt_inc 	<= '0';
		 cnt_dec 	<= '0';
		 OUT_WREN 	<= '0';
		 IN_REQ  	<= '0';
		 CODE_EN 	<= '0';
		 sel 		<= "00";
		 DATA_WREN 	<= '0';
		 DATA_EN 	<= '0';

case pstate is
-- --------------------------SIDLE-------------------------------
	when sidle =>  
            nstate <= sfetch;
-- -------------------------SFETCH-------------------------------
	when sfetch => 
            CODE_EN <= '1';
            nstate <= sdecode;
-- -------------------------SDECODE------------------------------
    when sdecode =>
		--! Nakonec nepoužito - zbytečné
			--case instruction is
				--when inc_val => nstate <= state_inc_val;
				--when dec_val => nstate <= state_dec_val;
				--when po_inc  => nstate <= state_po_inc;
				--when po_dec  => nstate <= state_po_dec;
				--when while_s => nstate <= state_while_s;
				--when while_e => nstate <= state_while_e;
				--when puthcar => nstate <= state_puthcar;
				--when getchar => nstate <= state_getchar;
				--when break   => nstate <= state_break;
				--when return  => nstate <= state_return;
				--when none    => nstate <= state_none;
				--when others  => nstate <= state_none;
			--end case;

			case CODE_DATA is
					when X"3E" =>
						nstate <= state_po_inc;  -- > - inkrementace hodnoty ukazatele
					when X"3C" =>
						nstate <= state_po_dec;  -- < - dekrementace hodnoty ukazatele
					when X"2B" =>
						nstate <= state_inc_val; -- + - inkrementace hodnoty aktuální buňky
					when X"2D" =>
						nstate <= state_dec_val; -- - - dekrementace hodnoty aktuální buňky
					when X"5B" =>
						nstate <= state_while_s; -- [ - začátek cyklu while
					when X"5D" =>
						nstate <= state_while_e; -- ] - konec cyklu while
					when X"2E" =>
						nstate <= state_putchar; -- . - tisk hodnoty aktuální buňky
					when X"2C" =>
						nstate <= state_getchar; -- , - načtení hodnoty do aktuální buňky
					when X"7E" =>
						nstate <= state_break; 	 -- ~ - ukončení prováděného cyklu while
					when X"00" =>
						nstate <= state_return;  -- null - zastavení vykonávání programu
					when others =>
						nstate <= state_none;
				end case;

-- -------------------------Instrukce: >------------------------------
	when state_po_inc =>
			ptr_inc <= '1';		-- PTR <= PTR + 1
			pc_inc <= '1';		-- PC <= PC + 1
			nstate <= sfetch;

-- -------------------------Instrukce: <------------------------------
	when state_po_dec =>
			ptr_dec <= '1';		-- PTR <= PTR - 1
			pc_inc <= '1';		-- PC <= PC + 1
			nstate <= sfetch;

-- -------------------------Instrukce: +------------------------------          
	when state_inc_val =>
			DATA_EN <= '1';
			DATA_WREN <= '0';	-- DATA RDATA <= ram[PTR]
			nstate <= state_inc_val2; 
	when state_inc_val2 =>
			sel <= "10"; 		-- DATA_WDATA <= DATA_RDATA + 1
			nstate <= state_inc_val3; 
	when state_inc_val3 =>
			DATA_EN <= '1';
			DATA_WREN <= '1';	-- zápis
			pc_inc <= '1';
			nstate <= sfetch;

-- -------------------------Instrukce: -------------------------------  
	when state_dec_val =>
			DATA_EN <= '1';
			DATA_WREN <= '0';	-- DATA RDATA <= ram[PTR]
			nstate <= state_dec_val2;
	when state_dec_val2 => 
			sel <= "01"; 		-- DATA_WDATA <= DATA_RDATA - 1
			nstate <= state_dec_val3;
	when state_dec_val3 =>
			DATA_EN <= '1';
			DATA_WREN <= '1';	-- zápis
			pc_inc <= '1';
			nstate <= sfetch;

-- -------------------------Instrukce: [------------------------------      
	when state_while_s =>
			pc_inc <= '1';		-- PC <- PC + 1
			DATA_EN <= '1';		
			DATA_WREN <= '0';	-- DATA_RDATA = ram[pointer]
			nstate <= state_while_s2;
	when state_while_s2 =>
			if DATA_RDATA = (DATA_RDATA'range => '0') then	-- if ram[pointer] == 0
				cnt_inc <= '1';
				CODE_EN <= '1';				-- CODE_DATA <= RAM[PTR]
				nstate  <= state_while_s3;
			else
				nstate <= sfetch;
 			end if;
	when state_while_s3 =>
			if cnt_addr = (cnt_addr'range => '0') then	-- CNT = 0
				nstate <= sfetch;
			else						-- while CNT != 0
				if CODE_DATA = X"5B" then		-- if c == [ inkrementuj
					cnt_inc <= '1';
				elsif CODE_DATA = X"5D" then		-- if c == ] dekrementuj
					cnt_dec <= '1';
				end if;
				
				pc_inc <= '1';
				nstate <= state_while_s_loop;
			end if;
	when state_while_s_loop =>			
			CODE_EN <= '1';
			nstate <= state_while_s3;	

-- -------------------------Instrukce: ]------------------------------   
	when state_while_e => 
			DATA_EN <= '1';		--DATA_RDATA <= ram[PTR]
			DATA_WREN <= '0';
			nstate <= state_while_e2;
	when state_while_e2 =>
			if DATA_RDATA = (DATA_RDATA'range => '0') then		--if DATA_RDATA == 0, inkrementuj
				pc_inc <= '1';
				nstate <= sfetch;
			else
				cnt_inc <= '1';		--jinak dekrementuj a zvyš counter
				pc_dec <= '1';
				nstate <= state_while_e_loop;
			end if;
	when state_while_e_loop => 
			CODE_EN <= '1';
			nstate <= state_while_e3;
	when state_while_e3 =>
			if cnt_addr = (cnt_addr'range => '0') then		--if counter == 0 -> fetch
				nstate <= sfetch;
			else
				if CODE_DATA = X"5D" then		-- if = ], inkrementuj
					cnt_inc <= '1';
				elsif CODE_DATA = X"5B" then		-- if = [, dekrementuj
					cnt_dec <= '1';
				end if;
				nstate <= state_while_e4;
            end if;
	when state_while_e4 => 
			if cnt_addr = (cnt_addr'range => '0') then		-- if CNT == 0, inkrementuj
				pc_inc <= '1';
			else
				pc_dec <= '1';		-- else dekrementuj
			end if;
			nstate <= state_while_e_loop;

-- -------------------------Instrukce: ,------------------------------    
	when state_getchar => 
			IN_REQ <= '1';
			sel <= "00";		--DATA_WDATA <= IN_DATA
			nstate <= state_getchar2;
	when state_getchar2 =>
			if IN_VLD = '1' then	--RAM[PTR] <= DATA_WDATA
				DATA_EN <= '1';
				DATA_WREN <= '1';
				pc_inc <= '1';
				nstate <= sfetch;
			else
				nstate <= state_getchar;
			end if;

-- -------------------------Instrukce: .------------------------------    
	when state_putchar =>
			DATA_EN <= '1';
			DATA_WREN <= '0';
			nstate <= state_putchar2;
	when state_putchar2 =>
			if OUT_BUSY = '1' then
				DATA_EN <= '1';		--DATA_RDATA <= RAM[PTR]
                		DATA_WREN <= '0';
               			nstate <= state_putchar2;
			else
				OUT_WREN <= '1';	--OUT_DATA <= DATA_RDATA
				pc_inc <= '1';
				OUT_DATA <= DATA_RDATA;
                nstate <= sfetch;
			end if;

-- -------------------------Instrukce: ~------------------------------         
	when state_break =>
			cnt_inc <= '1';
 			pc_inc <= '1';
			nstate <= state_break2;
	when state_break2 =>
			CODE_EN <= '1';
			nstate <= state_break3;
	when state_break3 =>
			if cnt_addr = (cnt_addr'range => '0') then
				nstate <= sfetch;
			else					--Pokud se != 0, tak kontroluj jestli nejde '[', nebo ']'
				if CODE_DATA = X"5B" then
					cnt_inc <= '1';
				elsif CODE_DATA = X"5D" then 
					cnt_dec <= '1';
				end if;
				pc_inc <= '1';
				nstate <= state_break2;
			end if;

-- -------------------------Instrukce: null------------------------------  
	when state_return =>
			nstate <= state_return;

-- -------------------------Instrukce: none------------------------------ 
	when state_none =>
			pc_inc <= '1';
			nstate <= sfetch;
-- -------------------------Else------------------------------ 			
	when others => null;
end case;
end process;			
							
	
end behavioral;
 
