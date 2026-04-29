----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

    -- components
    component eight_bit_adder is
        port (
            i_op1    : in std_logic_vector(7 downto 0);
            i_op2    : in std_logic_vector(7 downto 0);
            i_Cin  : in std_logic;
            o_S    : out std_logic_vector(7 downto 0);
            o_Cout : out std_logic
            );
        end component eight_bit_adder;

    -- signals
    signal w_B : std_logic_vector(7 downto 0);       -- choosing B or not B
    signal w_S : std_logic_vector(7 downto 0);       -- for sum
    signal w_Cout : std_logic;                       -- for Cout
    signal w_result : std_logic_vector (7 downto 0); -- for result

begin

    -- MUX1: choosing B or not B depending on op
    with i_op(0) select
        w_B <=  i_B when '0',
                (not i_B) when '1',
                i_B when others;     -- default is i_B
    
    -- adder
    eight_bit_adder_0: eight_bit_adder
    port map(
        i_op1     => i_A,
        i_op2     => w_B,
        i_Cin     => i_op(0),
        o_S       => w_S,
        o_Cout    => w_Cout
    );
        
    -- MUX2: choosing operation
    with i_op select
        w_result <= w_S when "000",
                    w_S when "001",
                    (i_A and i_B) when "010",
                    (i_A or i_B) when "011",
                    w_S when others;            -- default is adder
    
    -- Concurrent statements
    o_result <= w_result;
                    
    -- V: Overflow detection
    o_flags(0) <= (w_S(7) xor i_A(7)) and (not i_op(1)) and
                  (not (i_op(0) xor i_A(7) xor i_B(7)));
                  
    -- C: Carry detection
    o_flags(1) <= w_Cout and (not i_op(1));
    
    -- Z: Zero detection (nor gate)
    o_flags(2) <= not (w_result(0) or w_result(1) or w_result(2) or w_result(3)
                  or w_result(4) or w_result(5) or w_result(6) or w_result(7));
                                
    -- N: Negative detection
    o_flags(3) <= w_result(7);
        
end Behavioral;
