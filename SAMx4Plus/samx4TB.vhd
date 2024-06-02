--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:42:27 06/02/2024
-- Design Name:   
-- Module Name:   /home/ise/ISE/SAMx4Plus/samx4TB.vhd
-- Project Name:  samx4
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: samx4
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY samx4TB IS
END samx4TB;
 
ARCHITECTURE behavior OF samx4TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT samx4
    PORT(
         OscOut : IN  std_logic;
         E : OUT  std_logic;
         Q : OUT  std_logic;
         A : IN  std_logic_vector(15 downto 0);
         D : IN  std_logic_vector(7 downto 0);
         RnW : IN  std_logic;
         S : OUT  std_logic_vector(2 downto 0);
         Z : OUT  std_logic_vector(21 downto 0);
         nRAS0 : OUT  std_logic;
         nWE : OUT  std_logic;
         nNMI : OUT  std_logic;
         nIRQ : OUT  std_logic;
         nFIRQ : OUT  std_logic;
         nNMIx : IN  std_logic;
         nIRQx : IN  std_logic;
         nFIRQx : IN  std_logic;
         SZ : IN  std_logic_vector(2 downto 0);
         VClk : OUT  std_logic;
         nRST : IN  std_logic;
         DA0 : IN  std_logic;
         nHS : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal OscOut : std_logic := '0';
   signal A : std_logic_vector(15 downto 0) := (others => '0');
   signal D : std_logic_vector(7 downto 0) := (others => '0');
   signal RnW : std_logic := '0';
   signal nNMIx : std_logic := '0';
   signal nIRQx : std_logic := '0';
   signal nFIRQx : std_logic := '0';
   signal SZ : std_logic_vector(2 downto 0) := (others => '0');
   signal nRST : std_logic := '0';
   signal DA0 : std_logic := '0';
   signal nHS : std_logic := '0';

 	--Outputs
   signal E : std_logic;
   signal Q : std_logic;
   signal S : std_logic_vector(2 downto 0);
   signal Z : std_logic_vector(21 downto 0);
   signal nRAS0 : std_logic;
   signal nWE : std_logic;
   signal nNMI : std_logic;
   signal nIRQ : std_logic;
   signal nFIRQ : std_logic;
   signal VClk : std_logic;

   -- Clock period definitions
   constant VClk_period : time := 558.73 ps;
	constant Osc_Period : time := 69.842 ps;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: samx4 PORT MAP (
          OscOut => OscOut,
          E => E,
          Q => Q,
          A => A,
          D => D,
          RnW => RnW,
          S => S,
          Z => Z,
          nRAS0 => nRAS0,
          nWE => nWE,
          nNMI => nNMI,
          nIRQ => nIRQ,
          nFIRQ => nFIRQ,
          nNMIx => nNMIx,
          nIRQx => nIRQx,
          nFIRQx => nFIRQx,
          SZ => SZ,
          VClk => VClk,
          nRST => nRST,
          DA0 => DA0,
          nHS => nHS
        );
	
	OSC_process :process
	begin
		OscOut <= '0';
		wait for Osc_Period/2;
		OscOut <= '1';
		wait for Osc_Period/2;
	end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 50 ns.
		nRST <= '0';
      wait for 50 ns;	
		nRST <= '1';
      wait for Osc_period*20;

      -- insert stimulus here 
		
		-- check A<15..0> translates to appropriate addresses
		-- memory type 0
		-- lower RAM at $4000
		A <= "0100000000000000";
		RnW <= '1';
		wait for Osc_period*8;
		-- expect S==0
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==7
		-- expect Z==$4000
		-- ROM 0 at $8000
		A <= "1000000000000000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==1
		-- expect Z==$0000
		-- ROM 1 at $A000
		A <= "1010000000000000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==1 (rom0 and rom1 combined)
		-- expect Z==$2000
		-- ROM 2 at $C000
		A <= "1100000000000000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==3
		-- expect Z==0
		-- PIA 0 at $FF00
		A <= "1111111100000000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==4
		-- PIA 1 at $FF20
		A <= "1111111100100000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==5
		-- PIA 0 at $FF40
		A <= "1111111101000000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==6
		-- MMU at $FFA0
		A <= "1111111110100000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==7
		-- VDG bits at $FFC0
		A <= "1111111111000000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==7
		-- VDG bits at $FFC6
		A <= "1111111111000110";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==7
		-- VDG bits at $FFD4
		A <= "1111111111010100";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==7
		-- Mem Size bits at $FFDA
		A <= "1111111111011010";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==7
		-- Mem Size bits at $FFDE
		A <= "1111111111011110";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;
		-- expect S==7
		-- CPUQ at $FFE0
		A <= "1111111111100000";
		RnW <= '1';
		wait for Osc_period*8;
		RnW <= '0';
		wait for Osc_period*8;

      wait;
   end process;

END;
