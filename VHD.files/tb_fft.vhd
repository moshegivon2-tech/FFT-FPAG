library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fft is
    -- Testbench is an empty entity
end tb_fft;

architecture behavior of tb_fft is

    -- רכיב לבדיקה (Unit Under Test)
    component top_level is
        port (
            clk : in std_logic;
            reset : in std_logic;
            start : in std_logic;
            done  : out std_logic;
            data_out_real : out std_logic_vector(15 downto 0);
            data_out_imag : out std_logic_vector(15 downto 0)
        );
    end component;

    -- אותות פנימיים לחיבור לרכיב
    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';
    signal start : std_logic := '0';
    signal done  : std_logic;
    signal data_out_real : std_logic_vector(15 downto 0);
    signal data_out_imag : std_logic_vector(15 downto 0);

    -- הגדרת זמן מחזור שעון (100MHz)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 1. יצירת המופע של ה-Top Level
    uut: top_level
    port map (
        clk => clk,
        reset => reset,
        start => start,
        done => done,
        data_out_real => data_out_real,
        data_out_imag => data_out_imag
    );

    -- 2. תהליך יצירת שעון
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 3. תהליך הבדיקה (Stimulus)
    stim_proc: process
    begin
        -- מצב התחלתי
        reset <= '1';
        start <= '0';
        wait for 100 ns;

        -- שחרור Reset
        reset <= '0';
        
        -- הערה חשובה: ב-Top Level הוספנו מנגנון אתחול שלוקח 16 מחזורי שעון.
        -- נמתין שהאתחול הפנימי יסתיים (16 * 10ns = 160ns), ניקח מרווח ביטחון.
        wait for 200 ns; 

        -- שליחת פקודת התחלה (פולס קצר)
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        -- המתנה לסיום החישוב
        -- אנחנו מחכים שהדגל 'done' יעלה ל-'1'
        wait until done = '1';
        
        -- המתנה קצרה לאחר הסיום כדי לראות את התוצאה יציבה
        wait for 100 ns;

        -- סיום הסימולציה
        report "FFT Simulation Completed Successfully!" severity note;
        
        -- עצירת הסימולציה (לרוב הסימולטורים)
        wait;
    end process;

end behavior;