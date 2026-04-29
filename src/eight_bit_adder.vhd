----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/28/2026 07:29:14 PM
-- Design Name: 
-- Module Name: eight_bit_adder - Behavioral
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

entity eight_bit_adder is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_Cin : in STD_LOGIC;
           o_S : out STD_LOGIC_VECTOR (7 downto 0);
           o_Cout : out STD_LOGIC);
end eight_bit_adder;

architecture Behavioral of eight_bit_adder is

    component ripple_adder is
        port (
            A    : in std_logic_vector(3 downto 0);
            B    : in std_logic_vector(3 downto 0);
            Cin  : in std_logic;
            S    : out std_logic_vector(3 downto 0);
            Cout : out std_logic
            );
        end component ripple_adder;
    
    signal w_carry : std_logic; -- for ripple between ripple adders

begin

    -- Port maps
    ripple_adder_1: ripple_adder
    port map(
        A     => i_A(3 downto 0),
        B     => i_B(3 downto 0),
        Cin   => i_Cin,             -- Direct to ALUControl0
        S     => o_S(3 downto 0),
        Cout  => w_carry
    );
    
    ripple_adder_2: ripple_adder
    port map(
        A     => i_A(7 downto 4),
        B     => i_B(7 downto 4),
        Cin   => w_carry,             -- From ripple adder 1
        S     => o_S(7 downto 4),
        Cout  => o_Cout
    );

end Behavioral;
