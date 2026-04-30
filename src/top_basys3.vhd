--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnL    :   in std_logic; -- clock divider reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- Components declartions
	
    component button_debounce is
        port (
            clk: in  STD_LOGIC;
			reset : in  STD_LOGIC;
			button: in STD_LOGIC;
			action: out STD_LOGIC
		);
    end component button_debounce;
    
    component controller_fsm is
        port ( 
            i_reset : in STD_LOGIC;
            i_adv : in STD_LOGIC;
            o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component controller_fsm;
        
    component clock_divider is
        generic ( constant k_DIV : natural := 2	); 
        port ( 	
            i_clk    : in STD_LOGIC;
            i_reset  : in STD_LOGIC;    -- asynchronous
            o_clk    : out STD_LOGIC	-- divided (slow) clock for TDM
        );
    end component clock_divider;
    
    component ALU is
        port ( 
            i_A : in STD_LOGIC_VECTOR (7 downto 0);
            i_B : in STD_LOGIC_VECTOR (7 downto 0);
            i_op : in STD_LOGIC_VECTOR (2 downto 0);
            o_result : out STD_LOGIC_VECTOR (7 downto 0);
            o_flags : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component ALU;
    
    component twos_comp is
        port (
            i_bin: in STD_LOGIC_VECTOR(7 downto 0);
            o_sign: out STD_LOGIC;
            o_hund: out STD_LOGIC_VECTOR(3 downto 0);
            o_tens: out STD_LOGIC_VECTOR(3 downto 0);
            o_ones: out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component twos_comp;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural := 4 ); 
        port (
            i_clk		: in  STD_LOGIC;
            i_reset		: in  STD_LOGIC; -- asynchronous
            i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		    i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		    i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		    i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		    o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		    o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
    
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    -- Signal declarations
    
    signal w_clk_TDM, w_adv, w_sign: std_logic;
    signal w_cycle, w_flags, w_hund, w_tens, w_ones, w_data, w_sel, w_an: std_logic_vector(3 downto 0);
    signal w_result, w_mux1_out: std_logic_vector(7 downto 0);
    signal w_seg_n, w_sign_seg, w_seg_out: std_logic_vector(6 downto 0);
    
    -- creating register signals with default ZERO
	signal w_A: std_logic_vector(7 downto 0):=x"00";
	signal w_B: std_logic_vector(7 downto 0):=x"00"; 
  
begin
	-- PORT MAPS ----------------------------------------

    clkdiv_inst_fsm: clock_divider 	   -- Clock divider for TDM4
        generic map ( k_DIV => 50000 ) -- 1000 Hz clock (1ms) from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => btnL,
            o_clk   => w_clk_TDM
        );
        
    button_debounce_inst: button_debounce
        port map (
            clk     => clk,     -- IS THIS THE MASTER CLOCK
            reset   => '0',     -- MAYBE CHANGE TO BTNU (syn reset)
            button  => btnC,
            action  => w_adv
        );
	
	controller_fsm_inst: controller_fsm
	    port map (
	        i_reset    => btnU,
	        i_adv      => w_adv,
	        o_cycle    => w_cycle
	    );
	    
	ALU_inst: ALU
	    port map (
	        i_A      => w_A,
	        i_B      => w_B,
	        i_op     => sw(2 downto 0),
	        o_result => w_result,
	        o_flags  => w_flags
	    );
	    
	twos_comp_inst: twos_comp
	    port map (
	        i_bin  => w_mux1_out,
	        o_sign => w_sign,
	        o_hund => w_hund,
	        o_tens => w_tens,
	        o_ones => w_ones
	    );
	    
	TDM4_inst: TDM4
	    port map (
	        i_D3    => x"0",  --this doesn't matter
	        i_D2    => w_hund,
	        i_D1    => w_tens,
	        i_D0    => w_ones,
	        i_clk   => w_clk_TDM,
	        i_reset => '0',        -- MAYBE BTNL (asyn reset)
	        o_data  => w_data,
	        o_sel   => w_sel
	    );
	
	sevenseg_decoder_inst: sevenseg_decoder
	    port map (
	        i_hex      => w_data,
	        o_seg_n    => w_seg_n
	    );
	    
	-- MUX LOGIC -------------------------------------
	
	-- Mux 1: determine what displays based on current cycle
	with w_cycle select
	    w_mux1_out <= x"00"    when "0001",
	                  w_A      when "0010",
	                  w_B      when "0100",
	                  w_result when "1000",
	                  x"00"    when others;
	                  
	-- Mux 2: determines negative sign or blank on display
	with w_sign select
	    w_sign_seg <= "1111111" when '0',  -- blank
	                  "0111111" when '1',  -- negative sign
	                  "1111111" when others;
	                  
    -- Mux 3: anode control
    with w_cycle select
        w_an    <= "1111" when "0001",  -- all anodes off
                   w_sel when others;
    
    -- Mux 4: segment control
    with w_sel select
        w_seg_out <= w_sign_seg when "0111",    -- first display is sign
                     w_seg_n when others;
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	led(3 downto 0)   <= w_cycle;
	led(15 downto 12) <= w_flags;
	led(11 downto 4)  <= (others => '0');  -- unused LEDs grounded
	
	seg(6 downto 0)   <= w_seg_out;
	
	-- REGISTER PROCESSES -------------------------------
	
	register_A_proc : process (w_cycle(1))
	begin
	    if rising_edge(w_cycle(1)) then
	        w_A <= sw(7 downto 0);
	    end if;
	end process register_A_proc;
	
	register_B_proc : process (w_cycle(2))
	begin
	    if rising_edge(w_cycle(2)) then
	        w_B <= sw(7 downto 0);
	    end if;
    end process register_B_proc;
	
end top_basys3_arch;
