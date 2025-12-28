library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fft_selfcheck is 
end tb_fft_selfcheck;

architecture behavior of tb_fft_selfcheck is 

    ---------------------------------------------------------------------------
    -- 1. Component Declaration
    ---------------------------------------------------------------------------
    component top_level
    port(
         clk, reset, start : in  std_logic;
         wave_sel          : in  std_logic_vector(1 downto 0);
         display_addr      : in  std_logic_vector(3 downto 0);
         display_sel       : in  std_logic;
         done              : out std_logic;
         leds              : out std_logic_vector(15 downto 0)
        );
    end component;

    ---------------------------------------------------------------------------
    -- 2. Constants & Signals
    ---------------------------------------------------------------------------
    constant CLK_PERIOD      : time := 10 ns;
    
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal start        : std_logic := '0';
    signal done         : std_logic;
    signal wave_sel     : std_logic_vector(1 downto 0) := "00";
    signal display_addr : std_logic_vector(3 downto 0) := (others => '0');
    signal display_sel  : std_logic := '0';
    signal leds         : std_logic_vector(15 downto 0);
    
    signal test_running : boolean := true;
    signal tests_passed : integer := 0;
    signal tests_failed : integer := 0;

    ---------------------------------------------------------------------------
    -- 3. Utility Function (check_value)
    ---------------------------------------------------------------------------
    function check_value(actual : signed; expected : integer; tolerance : integer; name : string) return boolean is
        variable diff : integer;
    begin
        diff := abs(to_integer(actual) - expected);
        if diff <= tolerance then
            report "  PASS: " & name & " = " & integer'image(to_integer(actual)) & " (expected ~" & integer'image(expected) & ")";
            return true;
        else
            report "  FAIL: " & name & " = " & integer'image(to_integer(actual)) & " (expected ~" & integer'image(expected) & ")" severity error;
            return false;
        end if;
    end function;

begin

    ---------------------------------------------------------------------------
    -- 4. UUT Instantiation
    ---------------------------------------------------------------------------
    uut: top_level port map (
        clk          => clk,
        reset        => reset,
        start        => start,
        wave_sel     => wave_sel,
        display_addr => display_addr,
        display_sel  => display_sel,
        done         => done,
        leds         => leds
    );

    ---------------------------------------------------------------------------
    -- 5. Clock Process
    ---------------------------------------------------------------------------
    clk_process: process 
    begin 
        while test_running loop
            clk <= '0'; wait for CLK_PERIOD/2; 
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    ---------------------------------------------------------------------------
    -- 6. Main Stimulus Process
    ---------------------------------------------------------------------------
    stim_proc: process
        
        -- פרוצדורה להרצה - העתקה מדויקת של התזמון המקורי שלך
        procedure run_fft_flow(
            constant w_code : in std_logic_vector(1 downto 0)
        ) is
        begin
            wave_sel <= w_code;
            reset <= '1'; 
            wait for 50 ns; -- תזמון מקורי
            reset <= '0'; 
            wait for 200 ns; -- תזמון מקורי
            start <= '1'; 
            wait for 10 ns; -- פולס של מחזור אחד
            start <= '0';
            wait until done = '1';
            wait for 50 ns; -- המתנה להתייצבות
        end procedure;

        -- פרוצדורה לבדיקת בינ - המתנה של 2 מחזורי שעון כמו במקור
        procedure check_result(
            constant addr : in integer;
            constant sel  : in std_logic;
            constant exp  : in integer;
            constant tol  : in integer;
            constant msg  : in string
        ) is
        begin
            display_addr <= std_logic_vector(to_unsigned(addr, 4));
            display_sel  <= sel;
            wait for 20 ns; -- שווה ל-clk_period * 2 מהקוד המקורי
            
            if check_value(signed(leds), exp, tol, msg) then
                tests_passed <= tests_passed + 1;
            else
                tests_failed <= tests_failed + 1;
            end if;
        end procedure;

    begin		
        wait for 100 ns;
        report "Starting FFT Self-Check (Original Timing Restore)";

        -- TEST 1: Impulse (Hallem)
        run_fft_flow("01"); -- Impulse code
        check_result(0, '0', 2047, 500, "Impulse Bin 0");

        -- TEST 2: Sine Wave
        run_fft_flow("10"); -- Sine code
        check_result(1,  '1', -16384, 2000, "Sine Bin 1 Imag");
        check_result(15, '1',  16384, 2000, "Sine Bin 15 Imag");
        check_result(2,  '0',  0,      1000, "Sine Bin 2 Real");

        -- TEST 3: Square Wave
        run_fft_flow("00"); -- Square code
        check_result(0, '0', 16384, 2000, "Square Bin 0");

        -- Summary
        report "========================================";
        report "Tests Passed: " & integer'image(tests_passed);
        report "Tests Failed: " & integer'image(tests_failed);
        report "========================================";
        
        test_running <= false;
        wait;
    end process;
    
end behavior;
