library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fft is end tb_fft;

architecture behavior of tb_fft is 
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
 
begin
    uut: top_level port map (clk, reset, start, wave_sel, display_addr, display_sel, done, leds);

    clk_process :process begin clk <= '0'; wait for clk_period/2; clk <= '1'; wait for clk_period/2; end process;
 
    stim_proc: process
    begin		
        wait for 100 ns;

        -- 1. Square (????? ?-Sinc)
        wave_sel <= "00"; display_sel <= '0'; -- Real
        reset <= '1'; wait for 50 ns; reset <= '0'; wait for 400 ns; 
        start <= '1'; wait for clk_period; start <= '0';
        wait until done = '1'; wait for 200 ns;

        -- 2. Impulse (????? ?-Flat)
        wave_sel <= "01";
        reset <= '1'; wait for 50 ns; reset <= '0'; wait for 400 ns; 
        start <= '1'; wait for clk_period; start <= '0';
        wait until done = '1'; wait for 200 ns;

        -- 3. Sine (????? ???? ?-1 ??-15 ???? ?-Imaginary)
        wave_sel <= "10"; display_sel <= '1'; -- Imaginary
        reset <= '1'; wait for 50 ns; reset <= '0'; wait for 400 ns; 
        start <= '1'; wait for clk_period; start <= '0';
        wait until done = '1'; wait for 200 ns;

        -- 4. Two-Tone (????? ?????? ?-1,5,11,15 ?-Imaginary)
        wave_sel <= "11";
        reset <= '1'; wait for 50 ns; reset <= '0'; wait for 400 ns; 
        start <= '1'; wait for clk_period; start <= '0';
        wait until done = '1'; 
        
        -- ????? ?????? ???? Two-Tone
        for i in 0 to 15 loop
            display_addr <= std_logic_vector(to_unsigned(i, 4));
            wait for 20 ns;
        end loop;

        wait;
    end process;
end behavior;
