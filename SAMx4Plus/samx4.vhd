-- SAMx4

-- (C) 2023 Ciaran Anscomb
--
-- Released under the Creative Commons Attribution-ShareAlike 4.0
-- International License (CC BY-SA 4.0).  Full text in the LICENSE file.

-- TODO: Of course, test with 41256 DRAMs and see if we really do get 256K :)

-- Intended to provide the functionality of the SN74LS783 Synchronous Address
-- Multiplexer.

-- Primary references are of course the datasheets for the SN74LS783 and
-- SN74LS785.

-- Research into how SAM VDG mode transitions affect addressing and the various
-- associated "glitches" by Stewart Orchard.

-- While we're here, also add the minor extras required to behave like Stewart
-- Orchard's 256K Banker Board.  Doing it as part of the SAM probably lifts
-- some of the restrictions too.
--
-- https://gitlab.com/sorchard001/dragon-256k-banker-board

-- Interleaves access to memory between VDG and MPU, refreshing DRAM in place
-- of VDG access in bursts of eight rows following the falling edge of HS#.
-- Refreshes eight rows in about 2ms.

-- Supports SLOW, ADDRESS-DEPENDENT and FAST MPU rates.

-- Supports both 32K and 64K RAM map types.

-- Supports the page bit in 32K map type.

-- Supports 4K, 16K and 64K ram sizes.

-- Extra registers in $FF3x allow selection between four banks of 64K for both
-- the lower and upper 32K of RAM as per the Banker Board.

-- Timing outputs occur synchronous with the clock (who'd have thought?), but
-- S[2..0] changes as soon as A[15..13], RnW or map type changes.  Z[8..0] may
-- change during an MPU access in FAST rate, but it should have settled before
-- RAS# fall.

-- Important to operation is the "Address Delay Time" as documented in Figure
-- 1 of the MC6809E datasheet.  The next address from the MPU should be
-- available 3 (2.8) oscillator periods after E falls during a slow cycle or
-- 2 (1.44) periods during a fast cycle.  This means that in address-dependent
-- MPU rate, the decision must be taken at T0 and T8 whether to return from
-- fast to slow cycles.

-- As noted by Stewart Orchard, the transition from slow to actually-fast rate
-- can occur at TA, shortening the slow cycle slightly to allow enough time
-- between falling E and rising Q.

-- Also noted by Stewart is that fast cycles are permitted for the
-- address-dependent rate in map type 1, despite the note on page 16 of the
-- datasheet.

-- Many thanks also to Pedro Peña for testing 4K and 16K ram types in suitable
-- machines.  And Stewart again for testing 2 x 16K bank operation in a Dragon
-- 32.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity samx4 is
	generic (

			-- Enable/disable 256K banker support.
			constant want_256K : boolean := true;

			-- Enable/disable 4K and 16K DRAM support.
			-- constant want_4K : boolean := true;
			-- constant want_16K : boolean := true;

			-- Set to true to change the values for S in map type
			-- 1 to be compatible with the '785.  Also enables 16K
			-- x 4 mode IF want_16K also set to true.
			-- constant want_785 : boolean := false;

			-- Set to true to enable video (and refresh) in fast
			-- mode where possible.  If running mostly from ROM,
			-- you can get a noisy - but better than nothing
			-- picture.  Breaks refresh tester.
			constant want_fast_video : boolean := false;

			-- Set to true to repurpose the Z8 output as a speed
			-- indicator.  Only considered if 256K support is
			-- disabled.
			-- constant want_Z8_speed_LED : boolean := true;

			-- Set to false to disable DRAM refresh.  Those cycles
			-- will become VDG accesses.
			constant want_refresh : boolean := false;
			-- default to false for SRAM only

			-- Enable "for fun" scroll register
			constant want_scroll : boolean := false
		);

	port (
		     -- No OscIn pin: if a crystal is to be used, the circuit
		     -- to present it as a nice square clock should be
		     -- external.
		     OscOut : in std_logic;
		     E : out std_logic;
		     Q : out std_logic;

		     A : in std_logic_vector(15 downto 0);
			  D : in std_logic_vector(7 downto 0);
		     RnW : in std_logic;
		     S : out std_logic_vector(2 downto 0);
			 -- Z expanded for SRAM and larger address space
		     Z : out std_logic_vector(21 downto 0);
		     nRAS0 : out std_logic;
--		     nCAS : out std_logic;
		     nWE : out std_logic;
			  -- artifical interrupt masking for blit operations
			  -- default behaviour is pure pass-through
			  nNMI : out std_logic;
			  nIRQ : out std_logic;
			  nFIRQ : out std_logic;
			  nNMIx : in std_logic;
			  nIRQx : in std_logic;
			  nFIRQx : in std_logic;
			  -- memory size identification
			  SZ : in std_logic_vector(2 downto 0);

		     -- VClk being held low for 8 cycles of OscOut implies
		     -- external reset.
		     VClk : out std_logic;  -- 100Ω to nRST
		     nRST : in std_logic;
		     DA0 : in std_logic;  -- 10K pullup, probably not needed
		     nHS : in std_logic
	     );
end;

architecture rtl of samx4 is

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Shortcuts
    -- needs a rethink, disable for now
	-- constant want_FF3x : boolean := want_256K or want_scroll;

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Address decoding

	-- IO, SAM registers, IRQ vectors
	signal is_FFxx : boolean;
	signal is_IO0 : boolean;
	signal is_IO1 : boolean;
	signal is_IO2 : boolean;
	signal is_FFAx : boolean;
	signal is_SAM_REG : boolean;
	signal is_IRQ_VEC : boolean;

	-- Upper 32K, excluding IO, etc.
	signal is_8xxx : boolean;
	signal is_Axxx : boolean;
	signal is_Cxxx : boolean;
	signal is_upper_32K  : boolean;  -- shorthand for any of the above

	-- RAM, including upper 32K in map type 1
	signal is_RAM : boolean;
	
	-- combined E17/E18 signal to enable rom (R0+R1)
	signal is_ROM : boolean;

	-- Buffer S outputs; on the '785 these are gated with E and Q
	signal S_i : std_logic_vector(2 downto 0);

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Registers

	-- V: VDG addressing mode
	-- Mode		Division	Bits cleared on HS#
	-- V2 V1 V0	    X   Y
	--  0  0  0     1  12           B1-B4
	--  0  0  1     3   1           B1-B3
	--  0  1  0     1   3           B1-B4
	--  0  1  1     2   1           B1-B3
	--  1  0  0     1   2           B1-B4
	--  1  0  1     1   1           B1-B3
	--  1  1  0     1   1           B1-B4
	--  1  1  1     1   1           None (DMA MODE)
	signal V : std_logic_vector(2 downto 0) := (others => '0');
	-- proposed expansion to 4 bits in non-compliance mode
	-- V3 V2 V1 V0  X   Y
	--  1  0  0  0  1  12   B - 40 (reset to last 40 byte boundary)
	--  1  0  0  1  1   8   B1-B4 (8 row high characters, std view)
	--  1  0  1  0  1   1   B - 40
	--  1  0  1  1  1   8   B - 40 (8 row high, wide view)
	--  1  1  0  0  1   1   B - 80 (wide double speed graphics/16 bit data)
	--  1  1  0  1  1   1   B - 64 (std double speed graphics)
	--  1  1  1  0  1   1   B - 80
	--  1  1  1  1  1   1   None (DMA)
	-- signal V : std_logic_vector(3 downto 0) := (others => '0');
	-- can achieve B - 64 by resetting B1-B5
	-- B - 40 and B - 80 are more complex and may be best represented
	-- through DMA unless Y divider is more than 1

	-- F: VDG address offset.  The usual range is 15 downto 9, specifying
	-- offset in multiples of 512 bytes.  If want_scroll is enabled, more
	-- bits are used.
	signal F : std_logic_vector(15 downto 5) := (others => '0');

	-- P: Page bit.  Selects which 32K page from the current bank selected
	-- for region 0 ($0000-$7FFF) is mapped to that region.
	signal P : std_logic := '0';

	-- R: MPU rate.
	signal R : std_logic_vector(1 downto 0) := (others => '0');

	-- M: Memory type.
	signal M : std_logic_vector(1 downto 0) := (others => '0');

	-- TY: Map type.  0 selects 32K RAM, 32K ROM.  1 selects 64K RAM.
	signal TY : std_logic := '0';

	-- 256K related registers

	-- Bank select.  Which of four banks of 64K is mapped for use in the
	-- lower and higher regions of address space.
	type bank_array is array (1 downto 0) of std_logic_vector(1 downto 0);
	constant INIT_BANK : bank_array := (
		"00", "00"
	);
	signal bank : bank_array := INIT_BANK;

	signal vbank_mode : std_logic := '0';

	-- Horizontal scroll register - only used when "for fun" scroll
	-- registers enabled.
	signal Xoff : std_logic_vector(4 downto 0) := (others => '0');

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Timing

	-- Reference time
	type time_ref is (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, TA, TB, TC, TD, TE, TF);
	signal BOSC : std_logic;
	signal T : time_ref := TF;
	signal fast_cycle : boolean := false;

	signal refresh_request : std_logic := '0';
	signal refresh_cycle : boolean := false;

	signal mpu_rate_slow : boolean;
	signal mpu_rate_ad_slow : boolean;
	signal mpu_rate_ad_fast : boolean;
	signal mpu_rate_fast : boolean;

	-- Internal port signals
	signal E_i : std_logic := '0';
	signal Q_i : std_logic := '0';

	-- 8-bit refresh counter
	signal C : std_logic_vector(7 downto 0) := (others => '0');

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Address multiplexer
	-- not required - all dependent code needs to be removed

	-- signal ram_size_16K : boolean;
	-- signal ram_size_16K_1 : boolean;
	-- signal ram_size_16K_4 : boolean;
	-- signal ram_size_4K : boolean;

	-- signal Z7_is_RAS1 : boolean;

	-- Latched from bit 12 or 14 of MPU or VDG address
	-- signal RAS_bank : std_logic;

	type addr_type is (MPU, VDG);
	signal z_source : addr_type := MPU;
	-- type row_or_col is (ROW, COL);
	-- signal z_mux : row_or_col;

	signal nRAS : std_logic;
	-- signal nRAS1 : std_logic;

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Reset

	signal VClk_BOSC_div2_d : std_logic;
	signal VClk_BOSC_div2_q : std_logic;
	signal VClk_BOSC_div4_d : std_logic;
	signal VClk_BOSC_div4_q : std_logic;
	signal IER : std_logic;
	signal HR : std_logic;  -- Horizontal Reset
	signal DA0_nq : std_logic := '0';
	signal IER_or_VP : std_logic;  -- Vertical Pre-load

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- VDG

	-- Video address counter
	signal B : std_logic_vector(15 downto 1) := (others => '0');

	-- Lowest 4 bits of B combined with DA0.  Separated out to make
	-- implementing the optional scroll register easier.
	signal Btmp : std_logic_vector(4 downto 0);

	-- Synchronisation
	signal vdg_da0_window : boolean;
	signal vdg_start : boolean;
	signal vdg_sync_error : boolean := false;

	-- Glitching
	--
	-- Delaying video mode changes for 3 E cycles (Vbuf2 -> 1 -> 0 -> V)
	-- seems to be necessary to line up with divider outputs at the right
	-- time.  Then comparison to Vprev provides the "glitching".

	signal Vbuf2 : std_logic_vector(2 downto 0) := (others => '0');
	signal Vbuf1 : std_logic_vector(2 downto 0) := (others => '0');
	signal Vbuf0 : std_logic_vector(2 downto 0) := (others => '0');
	signal Vprev : std_logic_vector(2 downto 1) := (others => '0');

	-- Counters, dividers

	signal is_DMA       : boolean;

	signal use_xgnd     : std_logic;
	signal use_xdiv3    : std_logic;
	signal use_xdiv2    : std_logic;
	signal use_xdiv1    : std_logic;
	signal xdiv3_out    : std_logic;
	signal xdiv2_out    : std_logic;
	signal clock_b4     : std_logic := '0';

	signal use_ygnd     : std_logic;
	signal use_yb4      : std_logic;
	signal use_ydiv12   : std_logic;
	-- signal use_ydiv8    : std_logic;
	-- needed for 8 row character sets
	signal use_ydiv3    : std_logic;
	signal use_ydiv2    : std_logic;
	signal use_ydiv1    : std_logic;
	signal ydiv12_out   : std_logic;
	-- signal ydiv8_out    : std_logic;
	signal ydiv3_out    : std_logic;
	signal ydiv2_out    : std_logic;
	signal clock_b5     : std_logic := '0';

begin

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Address decoding

	-- IO, SAM registers, IRQ vectors
	-- SAM control bits and CPU vectors
	is_FFxx <= A(15 downto 8) = "11111111";
	-- IO bank 0 (P0)
	is_IO0  <= is_FFxx and A(7 downto 5) = "000";      -- FF0x and FF1x
	-- IO bank 1 (P1)
	-- want to move banking to FFA0 instead of FF3x
	is_IO1  <= is_FFxx and A(7 downto 5) = "001";  -- FF2x and FF3x
	-- assign_FF3x_g : if want_FF3x generate
	-- 	is_FF3x <= is_FFxx and A(7 downto 4) = "0011";  -- FF3x ONLY
	-- end generate;
	-- IO bank 2 (cartidge port P2)
	is_IO2     <= is_FFxx and A(7 downto 5) = "010";   -- FF4x and FF5x
	is_FFAx    <= is_FFxx and A(7 downto 5) = "101";   -- FFAx and FFBx
	is_SAM_REG <= is_FFxx and A(7 downto 5) = "110";   -- FFCx and FFDx
	is_IRQ_VEC <= is_FFxx and A(7 downto 5) = "111";   -- FFEx and FFFx

	-- Upper 32K
	-- ROM 0
	is_8xxx <= A(15 downto 13) = "100";
	-- ROM 1
	is_Axxx <= A(15 downto 13) = "101";
	-- merged rom select
	is_ROM  <= is_8xxx or is_Axxx;
	-- ROM 2 (cartridge port)
	is_Cxxx <= A(15 downto 14) = "11" and not is_FFxx;
	is_upper_32K  <= is_8xxx or is_Axxx or is_Cxxx;

	-- RAM
	is_RAM  <= A(15) = '0' or (TY = '1' and not is_FFxx);

	S_i <= -- IO, SAM registers, IRQ vectors
	       "100" when is_IO0 else
	       "101" when is_IO1 else
	       "110" when is_IO2 else
	       --     the '785 special-cases writes to the IRQ vector area:
	       -- "111" when want_785 and is_IRQ_VEC and RnW = '0' else
	       "010" when is_IRQ_VEC else  -- select ROM1 for IRQ vectors
	       "111" when is_FFxx else
	       -- Upper 32K reads in map type 1:
	       "000" when is_upper_32K and TY = '1' and RnW = '1' else
	       -- Upper 32K writes in map type 1 on the '785:
	       -- "111" when want_785 and is_upper_32K and TY = '1' and RnW = '0' else
	       -- Upper 32K in map type 0 AND writes in map type 1 on the '783:
	       "001" when is_ROM else
		   -- ROM1 is reserved for flashing rom
	       -- "010" when is_Axxx else
	       "011" when is_Cxxx else
	       -- RAM, excluding writes in map type 1 on the '783:
	       "000" when RnW = '1' else
	       "111";

	-- ROM accesses are gated with Q and E on the '785:
	-- S <= "111" when want_785 and Q_i = '1' and E_i = '0' and
	--      (S_i = "001" or S_i = "010" or S_i = "011") else S_i;
	S <= S_i;

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Registers

	process (IER, E_i, RnW, is_FFxx, is_FFAx, is_SAM_REG)
	begin
		-- on reset low
		if IER = '1' then
			Vbuf2 <= (others => '0');
			F <= (others => '0');
			P <= '0';
			R <= (others => '0');
			-- if want_4K and want_16K then
			-- 	M(0) <= '0';
			-- end if;
			-- if want_4K or want_16K then
			-- 	M(1) <= '0';
			-- end if;
			TY <= '0';
			-- if want_256K then
			-- 	bank <= INIT_BANK;
			-- 	vbank_mode <= '0';
			-- end if;
			if want_scroll then
				Xoff <= (others => '0');
			end if;
		elsif rising_edge(E_i) then
			if is_SAM_REG and RnW = '0' then
				-- SAM registers
				case A(4 downto 1) is
					when "0000" => Vbuf2(0) <= A(0);  -- ¹
					-- non compliance mode:
					-- when "0000" => Vbuf2(3 downto 0) <= D(3 downto 0);
					when "0001" => Vbuf2(1) <= A(0);  -- ¹
					when "0010" => Vbuf2(2) <= A(0);  -- ¹
					when "0011" => F(9) <= A(0);
					-- non compliance mode:
					-- when "0011" =< F(16 downto 9) <= D(7 downto 0);
					when "0100" => F(10) <= A(0);
					when "0101" => F(11) <= A(0);
					when "0110" => F(12) <= A(0);
					when "0111" => F(13) <= A(0);
					when "1000" => F(14) <= A(0);
					when "1001" => F(15) <= A(0);
					when "1010" => P <= A(0);
					when "1011" => R(0) <= A(0);
					when "1100" => R(1) <= A(0);
					-- when "1101" =>
					-- 	if want_4K and want_16K then
					-- 		M(0) <= A(0);
					-- 	end if;
					-- when "1110" =>
					-- 	if want_4K or want_16K then
					-- 		M(1) <= A(0);
					-- 	end if;
					when "1111" => TY <= A(0);
					when others => null;
				end case;
			-- elsif is_FF3x and RnW = '0' then
			--	-- 256K banker board registers
			--	if want_256K then
			--		if A(3 downto 2) = "00" then
			--			bank(0) <= A(1 downto 0);
			--		elsif A(3 downto 2) = "01" then
			--			bank(1) <= A(1 downto 0);
			--		elsif A(3 downto 1) = "100" then
			--			vbank_mode <= A(0);
			--		end if;
			--	end if;
			--	-- Scroll registers - non-standard, not enabled
			--	-- by default
			--	if want_scroll then
			--		if A(3 downto 0) = "1010" then
			--			-- Clear X offset
			--			Xoff <= (others => '0');
			--		elsif A(3 downto 0) = "1011" then
			--			-- Clear video base (F)
			--			F <= (others => '0');
			--		elsif A(3 downto 1) = "110" then
			--			-- Shift bit left into X offset
			--			Xoff <= Xoff(3 downto 0) & A(0);
			--		elsif A(3 downto 1) = "111" then
			--			-- Shift bit left into video base (F)
			--			F <= F(14 downto 5) & A(0);
			--		end if;
			--	end if;
			end if;
		end if;
	end process;

	-- ¹ Video mode changes are delayed for three cycles (pipelined in the
	--   main timing state machine below, AFTER the DA0 window).  For some
	--   reason this seems to be necessary to reproduce certain observed
	--   timing behaviour.

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Timing

	-- Buffered Oscillator - used for all internal timing references
	BOSC <= OscOut;

	-- Buffered outputs
	E <= E_i when IER = '0' else '0';
	Q <= Q_i when IER = '0' else '0';

	-- Pass through RnW to RAM (on nWE) when E high (MPU cycle) only for
	-- RAM accesses.
	nWE <= RnW when E_i = '1' and is_RAM else '1';

	-- Refresh timing: HS# going low enables a burst of 8 refresh cycles,
	-- continuing for multiples of 8 if held low longer than that.
	-- not required in sram only system
	-- refresh_request_g : if want_refresh generate
	--	process (nHS, IER, C(2))
	--	begin
	--		if nHS = '0' or IER = '1' then
	--			refresh_request <= '1';
	--		elsif falling_edge(C(2)) then
	--			refresh_request <= '0';
	--		end if;
	--	end process;
	-- end generate;

	-- MPU rate signals
	-- needs modifying for true double and quad speeds
	mpu_rate_slow <= R = "00";
	mpu_rate_ad_slow <= R = "01" and (is_RAM or is_IO0);
	mpu_rate_ad_fast <= R = "01" and not (is_RAM or is_IO0);
	mpu_rate_fast <= R(1) = '1';

	-- ROW vs COLUMN
	-- z_mux <= ROW when T = TF or T = T0 or T = T1 or
	--	 T = T7 or T = T8 or T = T9 else COL;

	-- RAS# timing
	-- needs changing to only trigger nRAS on VDG reads
	-- for double speed needs to be every second VDG clock
	-- for quad speed needs to be every fourth VDG clock
	nRAS <= '0' when T = T1 or T = T2 or T = T3 or T = T4 or T = T5 or
		T = T9 or T = TA or T = TB or T = TC or T = TD else '1';

	-- CAS# timing
	-- nCAS <= '0' when ((T = T3 or T = T4 or T = T5 or T = T6 or T = T7) and not refresh_cycle) or
	--	(T = TB or T = TC or T = TD or T = TE or T = TF) else '1';

	-- VDG DA0 transition window open for these states
	vdg_da0_window <= true when T = TA or T = TB else false;

	-- Restart VDG, if stopped
	vdg_start <= true when T = TB else false;

	-- This is the main state machine, advanced by BOSC falling edge.  It
	-- schedules things (broadly) as specified in the SAM datasheet.
	-- Remember that the NEW state set at each clock transition is what you
	-- should use when cross-referencing with the datasheet.

	process (BOSC)
	begin
		if falling_edge(BOSC) then

			case T is

				when TF =>
					T <= T0;
					-- CAS# rises (see above)

					if fast_cycle then
						if mpu_rate_slow or mpu_rate_ad_slow then
							fast_cycle <= false;
						else
							-- Q rise
							Q_i <= '1';
							if mpu_rate_fast and (not want_fast_video or is_RAM) then
								-- MPU address to RAM
								z_source <= MPU;
								-- if want_refresh then
								--	refresh_cycle <= false;
								-- end if;
							end if;
						end if;
					end if;

				when T0 =>
					T <= T1;
					-- RAS# falls (see above)

				when T1 =>
					T <= T2;

					if not fast_cycle then
						if mpu_rate_fast or mpu_rate_ad_fast then
							fast_cycle <= true;
						end if;
					else
						-- E rise
						E_i <= '1';
					end if;

				when T2 =>
					T <= T3;
					-- CAS# falls if NOT refresh (see above)

					if not fast_cycle then
						-- Q rise
						Q_i <= '1';
					end if;

				when T3 =>
					T <= T4;

					if fast_cycle then
						-- Q fall
						Q_i <= '0';
					end if;

				when T4 =>
					T <= T5;

				when T5 =>
					T <= T6;
					-- RAS# rises (see above)

					if fast_cycle then
						-- E fall
						E_i <= '0';
					end if;

				when T6 =>
					T <= T7;

					-- if want_refresh and refresh_cycle then
					--	-- increment refresh row
					--	C <= std_logic_vector(unsigned(C)+1);
					-- end if;

					if not fast_cycle then
						-- E rise
						E_i <= '1';
					end if;

				when T7 =>
					T <= T8;
					-- CAS# rises (see above)

					-- MPU address to RAM (could have done this at T7)
					z_source <= MPU;
					-- if want_refresh then
					--	refresh_cycle <= false;
					-- end if;

					if fast_cycle then
						if mpu_rate_slow or mpu_rate_ad_slow then
							fast_cycle <= false;
						else
							-- Q rise
							Q_i <= '1';
						end if;
					end if;

				when T8 =>
					T <= T9;
					-- RAS# falls (see above)

				when T9 =>
					T <= TA;

					if not fast_cycle then
						if mpu_rate_fast then
							fast_cycle <= true;
						end if;
					else
						-- E rise
						E_i <= '1';
					end if;

				when TA =>
					T <= TB;
					-- CAS# falls (see above)

					if not fast_cycle then
						-- Q fall
						Q_i <= '0';
					end if;

				when TB =>
					T <= TC;

					if fast_cycle then
						-- Q fall
						Q_i <= '0';
					end if;

				when TC =>
					T <= TD;

				when TD =>
					T <= TE;
					-- RAS# rises (done elsewhere)

					if fast_cycle then
						-- E fall
						E_i <= '0';
					end if;

				when TE =>
					T <= TF;

					-- Pipeline video mode changes.  See
					-- note in Registers section.
					V <= Vbuf0;
					Vbuf0 <= Vbuf1;
					Vbuf1 <= Vbuf2;

					if not fast_cycle then
						-- E fall
						E_i <= '0';
					end if;

					-- Overridden at T0 if FAST
					z_source <= VDG;
					if want_refresh then
						refresh_cycle <= refresh_request = '1';
					end if;

			end case;
		end if;
	end process;

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Address multiplexer

	-- Size     M1 M0   Src     R/C      Z8  Z7  Z6  Z5  Z4  Z3  Z2  Z1  Z0
	-- --------------------------------------------------------------------
	-- 4K        0  0   MPU     ROW     A16   ¹  A6  A5  A4  A3  A2  A1  A0
	--                          COL     A17   ¹ LOW A11 A10  A9  A8  A7  A6
	--                  VDG     ROW       ²   ¹  B6  B5  B4  B3  B2  B1  B0
	--                          COL       ²   ¹ B12 B11 B10  B9  B8  B7  B6
	--                  REF     ROW     LOW   ¹  C6  C5  C4  C3  C2  C1  C0
	--                          COL⁴    LOW   ¹  C6  C5  C4  C3  C2  C1  C0
	-- --------------------------------------------------------------------
	-- 16K x 1   0  1   MPU     ROW     A16   ¹  A6  A5  A4  A3  A2  A1  A0
	--                          COL     A17   ¹ A13 A12 A11 A10  A9  A8  A7
	--                  VDG     ROW       ²   ¹  B6  B5  B4  B3  B2  B1  B0
	--                          COL       ²   ¹ B13 B12 B11 B10  B9  B8  B7
	--                  REF     ROW     LOW   ¹  C6  C5  C4  C3  C2  C1  C0
	--                          COL⁴    LOW   ¹  C6  C5  C4  C3  C2  C1  C0
	-- --------------------------------------------------------------------
	-- 16K x 4   0  1   MPU     ROW     A16  A7  A6  A5  A4  A3  A2  A1  A0
	-- P = 1                    COL     A17   ³ A13 A12 A11 A10  A9  A8  A7
	-- '785 only        VDG     ROW       ²  B7  B6  B5  B4  B3  B2  B1  B0
	--                          COL       ²   ³ B13 B12 B11 B10  B9  B8  B7
	--                  REF     ROW     LOW  C7  C6  C5  C4  C3  C2  C1  C0
	--                          COL⁴    LOW  C7  C6  C5  C4  C3  C2  C1  C0
	-- --------------------------------------------------------------------
	-- 256K      1  X   MPU     ROW     A16  A7  A6  A5  A4  A3  A2  A1  A0
	--                          COL     A17   ³ A14 A13 A12 A11 A10  A9  A8
	--                  VDG     ROW       ²  B7  B6  B5  B4  B3  B2  B1  B0
	--                          COL       ² B15 B14 B13 B12 B11 B10  B9  B8
	--                  REF     ROW     LOW  C7  C6  C5  C4  C3  C2  C1  C0
	--                          COL⁴    LOW  C7  C6  C5  C4  C3  C2  C1  C0
	-- --------------------------------------------------------------------

	-- ¹ In 4K and 16K x 1 modes, two banks of eight ICs are allowed.  Z7
	--   functions as RAS1# in these modes to strobe the second bank.  Both
	--   banks are strobed together for refresh cycles.
	-- ² For VDG addresses, Z8 is either 0 or the configured 32K MPU bank.
	-- ³ If Map TYpe = 0, then page bit "P" is the output (otherwise A15).
	--   This is a "don't care" situation for 16K x 4 MOS RAM inputs.
	-- ⁴ CAS# is not strobed during refresh cycles.

	-- RAM size flags

	-- ram_size_16K <= (want_16K and not want_4K and M(1) = '0') or  -- 4K not supported
	--		(want_16K and want_4K and M = "01");  -- or 16K selected

	-- ram_size_16K_4 <= ram_size_16K and want_785 and P = '1';
	-- ram_size_16K_1 <= ram_size_16K and not ram_size_16K_4;

	-- ram_size_4K <= (want_4K and not want_16K and M(1) = '0') or  -- 16K not supported
	-- 	       (want_4K and want_16K and M = "00");  -- or 4K selected

	-- Z7_is_RAS1 <= ram_size_4K or ram_size_16K_1;

	-- Video address lowest 5 bits.  If the optional non-standard scroll
	-- registers are enabled, they are added in here.

	Btmp <= -- Normal operation
		B(4 downto 1) & DA0 when not want_scroll else
		-- If want_scroll enabled
		std_logic_vector(unsigned(B(4 downto 1) & DA0) + unsigned(Xoff));

	-- Which bank to strobe
	-- not required for sram only system
	-- RAS_bank <= A(12) when (ram_size_4K    and z_source = MPU) else
	--	    B(12) when (ram_size_4K    and z_source = VDG) else
	--	    A(14) when (ram_size_16K_1 and z_source = MPU) else
	--	    B(14) when (ram_size_16K_1 and z_source = VDG) else
	--	    '0';

	-- RAS0# is strobed for refresh, in 64K mode, or for bank 0 in
	-- 4K/16Kx1.
	--
	-- RAS1# is strobed for refresh, or for bank 1 in 4K/16Kx1 (output
	-- shared with Z7 so this signal is routed in the Address Multiplexer
	-- section).
	--
	-- nRAS is generated in the Timing section.

	nRAS0 <= nRAS;
	-- nRAS0 <= nRAS when refresh_cycle or RAS_bank = '0' else '1';

	-- assign_nRAS1_g : if want_4K or want_16K generate
	--	nRAS1 <= nRAS when refresh_cycle or RAS_bank = '1' else '1';
	-- end generate;

	-- Z8 is the most complicated, as it's either used to strobe A16 (ROW)
	-- & A17 (COL) for 256K support or (optionally) repurposed as a speed
	-- indicator LED.

	-- Z(8) <= -- Repurposed as speed indicator:
	--	'1' when not want_256K and fast_cycle and want_Z8_speed_LED else
	--	-- Not used:
	--	'0' when not want_256K else
	--	'0' when refresh_cycle else
	--	-- MPU ROW
	--	bank(to_integer(unsigned'('0'&A(15))))(0) when z_source = MPU and z_mux = ROW else
	--	-- MPU COL
	--	bank(to_integer(unsigned'('0'&A(15))))(1) when z_source = MPU else
	--	-- VDG ROW (use lower 32K bank selection)
	--	bank(0)(0) when z_mux = ROW and vbank_mode = '0' else
	--	-- VDG ROW (0)
	--	'0'        when z_mux = ROW else
	--	-- VDG COL (use lower 32K bank selection)
	--	bank(0)(1) when vbank_mode = '0' else
	--	-- VDG COL (0)
	--	'0';

	-- Z7 is shared with RAS1# in 4K and 16K x 1 modes.

	-- Z(7) <= nRAS1 when Z7_is_RAS1 else
	--	C(7)  when refresh_cycle else
	--	A(7)  when z_source = MPU and z_mux = ROW else  -- MPU ROW
	--	P     when z_source = MPU and TY = '0' else     -- MPU COL, Map Type 0
	--	A(15) when z_source = MPU else                  -- MPU COL, Map Type 1
	--	B(7)  when z_mux = ROW else                     -- VDG ROW
	--	B(15);                                          -- VDG COL

	-- Z6..0 varies by ram size, but is otherwise pretty simple.

	-- Z(6 downto 0) <=
	--	C(6 downto 0)        when refresh_cycle else
	--	A(6 downto 0)        when z_source = MPU and z_mux = ROW else   -- MPU ROW
	--	'0' & A(11 downto 6) when z_source = MPU and ram_size_4K else   -- MPU COL 4K
	--	A(13 downto 7)       when z_source = MPU and ram_size_16K else  -- MPU COL 16K
	--	A(14 downto 8)       when z_source = MPU else                   -- MPU COL
	--	-- VDG ROW, DMA mode
	--	B(6 downto 1) & DA0  when z_mux = ROW and is_DMA else
	--	-- VDG ROW, 16-byte modes
	--	B(6 downto 4) & Btmp(3 downto 0) when z_mux = ROW and V(0) = '1' else
	--	-- VDG ROW, 32-byte modes
	--	B(6 downto 5) & Btmp(4 downto 0) when z_mux = ROW else
	--	'0' & B(11 downto 6) when ram_size_4K else                      -- VDG COL 4K
	--	B(13 downto 7)       when ram_size_16K else                     -- VDG COL 16K
	--	B(14 downto 8);                                                 -- VDG COL

	-- SRAM logic is much simpler!
	-- Z(21 downto 16) is current unused
	-- will need to handle ROM addressing too though once paging is incorporated
	Z(21 downto 16) <= "000000";
	Z(15 downto 0) <=
--		'0' & B(14 downto 4) & Btmp(3 downto 0) when z_source = VDG else
		A(15 downto 0) 			when z_source = MPU and (S_i = "000" or S_i = "111") else
		"00" & A(13 downto 0) 	when z_source = MPU and (S_i = "001" or S_i = "011") else 
		'0' & B(14 downto 4) & Btmp(3 downto 0);

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Reset

	VClk_BOSC_div2_d <= '0' when not vdg_sync_error and BOSC = '1' else '1';

	VClk_BOSC_div2 : entity div2
	port map (
			 clk => VClk_BOSC_div2_d,
			 q => VClk_BOSC_div2_q,
			 rst => IER
		 );

	VClk_BOSC_div4_d <= not VClk_BOSC_div2_q;

	VClk_BOSC_div4 : entity div2
	port map (
			 clk => VClk_BOSC_div4_d,
			 q => VClk_BOSC_div4_q,
			 rst => '0'
		 );

	VClk <= not VClk_BOSC_div4_q;

	IER <= '1' when nRST = '0' and VClk_BOSC_div2_q = '0' and VClk_BOSC_div4_q = '0' else '0';

	-- Horizontal Reset (HR)

	HR <= IER or not nHS;

	-- Vertical Pre-load (VP)

	process (HR)
	begin
		if falling_edge(HR) then
			DA0_nq <= not DA0;
		end if;
	end process;

	IER_or_VP <= IER or (HR nor DA0_nq);

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- VDG

	-- Synchronisation & clock

	process (DA0, vdg_start)
	begin
		if vdg_start then
			vdg_sync_error <= false;
		elsif rising_edge(DA0) then
			if not vdg_da0_window then
				vdg_sync_error <= true;
			end if;
		end if;
	end process;

	-- VDG address modifier

	--  Mode        Division    Bits cleared
	--  V2 V1 V0    X   Y       by HS# (low)
	--  ---------------------------------------
	--   0  0  0    1   12      B1-B4
	--   0  0  1    3    1      B1-B3
	--  ---------------------------------------
	--   0  1  0    1    3      B1-B4
	--   0  1  1    2    1      B1-B3
	--  ---------------------------------------
	--   1  0  0    1    2      B1-B4
	--   1  0  1    1    1      B1-B3
	--  ---------------------------------------
	--   1  1  0    1    1      B1-B4
	--   1  1  1    1    1      None (DMA MODE)

	-- Furthermore, a real SAM "glitches" on certain mode changes, behaving
	-- like the following:
	--
	-- B5 input briefly becomes 0 when switching between Y÷12 and Y÷3, that
	-- is V2 = V0 = 0 and V1 changing.
	--
	-- B5 input briefly becomes B4 when switching between Y÷12 and Y÷2,
	-- that is V1 = V0 = 0 and V2 changing.
	--
	-- B4 input briefly becomes 0 when switching between X÷3 and X÷2, that
	-- is V2 = 0, V0 = 1 and V1 changing.
	--
	-- There are other glitches, but they produce unreliable results, so
	-- I'm not aiming to reproduce them here.

	use_ygnd   <= '1' when V(2) = '0' and V(0) = '0' and Vprev(1) /= V(1) else '0';
	use_yb4    <= '1' when V(1) = '0' and V(0) = '0' and Vprev(2) /= V(2) else '0';
	use_xgnd   <= '1' when V(2) = '0' and V(0) = '1' and Vprev(1) /= V(1) else '0';

	use_ydiv12 <= '1' when use_ygnd = '0' and use_yb4 = '0' and V = "000" else '0';
	use_ydiv3  <= '1' when use_ygnd = '0' and V = "010" else '0';
	use_ydiv2  <= '1' when use_yb4 = '0' and V = "100" else '0';
	use_ydiv1  <= '1' when use_yb4 = '1' or V(2 downto 1) = "11" or V(0) = '1' else '0';

	use_xdiv3  <= '1' when use_xgnd = '0' and V = "001" else '0';
	use_xdiv2  <= '1' when use_xgnd = '0' and V = "011" else '0';
	use_xdiv1  <= '1' when use_xgnd = '1' or V(2) = '1' or V(0) = '0' else '0';

	is_DMA     <= V = "111";

	-- Provides pulse where V /= Vprev, to "glitch" B4/B5 clock inputs.
	process (BOSC)
	begin
		if rising_edge(BOSC) then
			Vprev(2) <= V(2);
			Vprev(1) <= V(1);
			clock_b5 <= (use_ydiv12 and ydiv12_out) or (use_ydiv3 and ydiv3_out) or (use_ydiv2 and ydiv2_out) or (use_ydiv1 and B(4));
			clock_b4 <= (use_xdiv3 and xdiv3_out) or (use_xdiv2 and xdiv2_out) or (use_xdiv1 and B(3));
		end if;
	end process;

	-- VDG X dividers - B3 ÷ X -> B4

	xdiv3 : entity div3
	port map (
			 clk => B(3),
			 q => xdiv3_out,
			 rst => IER_or_VP
		 );

	xdiv2 : entity div2
	port map (
			 clk => B(3),
			 q => xdiv2_out,
			 rst => IER_or_VP
		 );

	-- B3..1 clocked by DA0 falling edge
	--
	-- B4 clocked by B3 or X divider outputs

	process (DA0, IER_or_VP, HR, is_DMA)
	begin
		if IER_or_VP = '1' or (HR = '1' and not is_DMA) then
			B(3 downto 1) <= (others => '0');
		elsif falling_edge(DA0) then
			B(3 downto 1) <= std_logic_vector(unsigned(B(3 downto 1))+1);
		end if;
	end process;

	process (clock_b4, IER_or_VP, HR, V(0))
	begin
		if IER_or_VP = '1' or (HR = '1' and V(0) = '0') then
			B(4) <= '0';
		elsif falling_edge(clock_b4) then
			B(4) <= not B(4);
		end if;
	end process;

	-- VDG Y dividers - B4 ÷ Y -> B15..5

	ydiv12 : entity div4
	port map (
			 clk => ydiv3_out,
			 q => ydiv12_out,
			 rst => IER_or_VP
		 );

	ydiv3 : entity div3
	port map (
			 clk => B(4),
			 q => ydiv3_out,
			 rst => IER_or_VP
		 );

	ydiv2 : entity div2
	port map (
			 clk => B(4),
			 q => ydiv2_out,
			 rst => IER_or_VP
		 );

	-- B15..5 clocked by B4 or Y divider outputs

	process (clock_b5, IER_or_VP, F)
	begin
		if IER_or_VP = '1' then
			B(15 downto 9) <= F(15 downto 9);
			if want_scroll then
				B(8 downto 5) <= F(8 downto 5);
			else
				B(8 downto 5) <= (others => '0');
			end if;
		elsif falling_edge(clock_b5) then
			B(15 downto 5) <= std_logic_vector(unsigned(B(15 downto 5))+1);
		end if;
	end process;
	
	process (nFIRQx, nIRQx, nNMIx)
	begin
		nFIRQ <= nFIRQx;
		nIRQ <= nIRQx;
		nNMI <= nNMIx;
	end process;

end rtl;
