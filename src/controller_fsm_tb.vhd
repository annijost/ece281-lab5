----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/30/2026 03:03:16 PM
-- Design Name: 
-- Module Name: controller_fsm_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm_tb is
end controller_fsm_tb;

architecture test_bench of controller_fsm_tb is

    component controller_fsm is
		Port ( i_adv 	 : in  STD_LOGIC;
			   i_reset 	 : in  STD_LOGIC; -- synchronous
			   o_cycle 	 : out STD_LOGIC_VECTOR (3 downto 0));
	end component controller_fsm;
	
	-- test signals
	signal w_clk, w_reset, w_adv : std_logic := '0';
	signal w_cycle : std_logic_vector(3 downto 0) := (others => '0');
  
	-- 50 MHz clock
	constant k_clk_period : time := 20 ns;
    
begin
-- PORT MAPS ----------------------------------------

	uut_inst : controller_fsm port map (
		i_reset   => w_reset,
		i_adv    => w_adv,
		o_cycle   => w_cycle
	);
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------
	
	-- Clock Process ------------------------------------
	clk_process : process
	begin
		w_clk <= '0';
		wait for k_clk_period/2;
		
		w_clk <= '1';
		wait for k_clk_period/2;
	end process clk_process;
	
	-- Test Plan Process --------------------------------
	test_process : process 
	begin
	   -- offset to allow for prop delays
	   wait until falling_edge(w_clk);
	   
        -- i_reset into initial state (o_floor 2)
        w_reset <= '1';  wait for k_clk_period; 
        -- clear reset
        w_reset <= '0';
        
		-- active adv signal (should quickly cycle through)
		w_adv <= '1'; 
		
		wait for k_clk_period;
		w_reset <= '1';
		
    end process;	


end test_bench;
