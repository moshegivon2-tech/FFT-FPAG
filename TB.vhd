library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_fft_selfcheck is 
end tb_fft_selfcheck;

architecture behavior of tb_fft_selfcheck is 
    component top_level
    port(
         clk, reset, start : in std_logic;
         wave_sel : in std_logic_vector(1 downto 0);
         display_addr : in std_logic_vector(3 downto 0);
         display_sel : in std_logic;
         done : out std_logic;
         leds : out std_logic_vector(15 downto 0)
        );
    end component;

    signal clk : std_logic := '0';
    signal reset, start, done, display_sel : std_logic := '0';
    signal wave_sel : std_logic_vector(1 downto 0) := "00";
    signal display_addr : std_logic_vector(3 downto 0) := (others => '0');
    signal leds : std_logic_vector(15 downto 0);
    
    constant clk_period : time := 10 ns;
    signal test_running : boolean := true;
    
    -- Test result tracking
    signal tests_passed : integer := 0;
    signal tests_failed : integer := 0;
 
begin
    uut: top_level port map (
        clk => clk,
        reset => reset,
        start => start,
        wave_sel => wave_sel,
        display_addr => display_addr,
        display_sel => display_sel,
        done => done,
        leds => leds
    );

    clk_process: process 
    begin 
        while test_running loop
            clk <= '0'; wait for clk_period/2; 
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;
 
    stim_proc: process
        type result_array is array (0 to 15) of integer;
        variable real_results : result_array;
        variable imag_results : result_array;
        
        -- Check if value is within tolerance
        function check_value(
            actual : signed;
            expected : integer;
            tolerance : integer;
            name : string
        ) return boolean is
            variable diff : integer;
        begin
            diff := abs(to_integer(actual) - expected);
            if diff <= tolerance then
                report "  PASS: " & name & " = " & integer'image(to_integer(actual)) & 
                       " (expected ~" & integer'image(expected) & ")";
                return true;
            else
                report "  FAIL: " & name & " = " & integer'image(to_integer(actual)) & 
                       " (expected ~" & integer'image(expected) & ", diff=" & integer'image(diff) & ")" 
                       severity error;
                return false;
            end if;
        end function;
        
        procedure run_and_check_fft(
            constant wave_name : in string;
            constant wave_code : in std_logic_vector(1 downto 0);
            constant check_bin : in integer;
            constant check_real : in boolean;
            constant expected_val : in integer;
            constant tolerance : in integer
        ) is
            variable pass : boolean := false;
        begin
            report "================================================";
            report "TEST: " & wave_name;
            report "================================================";
            
            wave_sel <= wave_code;
            reset <= '1'; wait for 50 ns; reset <= '0'; wait for 200 ns;
            start <= '1'; wait for clk_period; start <= '0';
            wait until done = '1';
            wait for 50 ns;
            
            -- Read the specific bin we want to check
            display_addr <= std_logic_vector(to_unsigned(check_bin, 4));
            
            if check_real then
                display_sel <= '0';  -- Real
            else
                display_sel <= '1';  -- Imaginary
            end if;
            
            wait for clk_period * 2;
            
            -- Check result
            pass := check_value(
                signed(leds),
                expected_val,
                tolerance,
                "FFT[" & integer'image(check_bin) & "]"
            );
            
            if pass then
                tests_passed <= tests_passed + 1;
                report "? Test PASSED: " & wave_name;
            else
                tests_failed <= tests_failed + 1;
                report "? Test FAILED: " & wave_name severity error;
            end if;
            
            report "";
            wait for 100 ns;
        end procedure;
        
    begin		
        wait for 100 ns;
        report "========================================";
        report "Starting Self-Checking FFT Testbench";
        report "========================================";
        report "";

        -- ===========================================
        -- TEST 1: Impulse Response
        -- Expected: All bins should have similar magnitude (flat spectrum)
        -- ===========================================
        run_and_check_fft(
            wave_name => "Impulse - DC Component",
            wave_code => "01",
            check_bin => 0,
            check_real => true,
            expected_val => 2047,    -- TIKUN: Changed from 8192 to 2047 (32767 / 16)
            tolerance => 500         -- Allow 500 units tolerance
        );

        -- ===========================================
        -- TEST 2: Sine Wave k=1
        -- Expected: Large imaginary component at bin 1
        -- ===========================================
        run_and_check_fft(
            wave_name => "Sine k=1 - Bin 1 Imaginary",
            wave_code => "10",
            check_bin => 1,
            check_real => false,     -- Check imaginary
            expected_val => -16384,  -- Expected large negative value
            tolerance => 2000
        );

        -- ===========================================
        -- TEST 3: Sine Wave k=1 - Check bin 15 (mirror)
        -- Expected: Large positive imaginary at bin 15 (conjugate symmetry)
        -- ===========================================
        run_and_check_fft(
            wave_name => "Sine k=1 - Bin 15 Imaginary (mirror)",
            wave_code => "10",
            check_bin => 15,
            check_real => false,
            expected_val => 16384,   -- Positive (conjugate of bin 1)
            tolerance => 2000
        );

        -- ===========================================
        -- TEST 4: DC Component (Square Wave)
        -- Expected: Large DC component at bin 0
        -- ===========================================
        run_and_check_fft(
            wave_name => "Square Wave - DC Component",
            wave_code => "00",
            check_bin => 0,
            check_real => true,
            expected_val => 16384,   -- Half of samples are high
            tolerance => 2000
        );

        -- ===========================================
        -- TEST 5: Check that bin 2 is near zero for sine k=1
        -- ===========================================
        run_and_check_fft(
            wave_name => "Sine k=1 - Bin 2 should be ~0",
            wave_code => "10",
            check_bin => 2,
            check_real => true,
            expected_val => 0,
            tolerance => 1000
        );

        -- ===========================================
        -- End of simulation
        -- ===========================================
        report "========================================";
        report "Test Summary:";
        report "  Passed: " & integer'image(tests_passed);
        report "  Failed: " & integer'image(tests_failed);
        
        if tests_failed = 0 then
            report "ALL TESTS PASSED! ?" severity note;
        else
            report "SOME TESTS FAILED! ?" severity error;
        end if;
        report "========================================";
        
        test_running <= false;
        wait;
    end process;
    
end behavior;