library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    port (
        clk : in std_logic;
        reset : in std_logic;
        start : in std_logic;
        done  : out std_logic;
        
        -- יציאות לדיבוג
        data_out_real : out std_logic_vector(15 downto 0);
        data_out_imag : out std_logic_vector(15 downto 0)
    );
end top_level;

architecture rtl of top_level is
    signal ram_we_a, ram_we_b : std_logic;
    signal ram_addr_a, ram_addr_b : std_logic_vector(3 downto 0);
    signal twiddle_addr : std_logic_vector(3 downto 0);
    
    signal ram_r_out_a, ram_r_out_b : std_logic_vector(15 downto 0);
    signal ram_i_out_a, ram_i_out_b : std_logic_vector(15 downto 0);
    
    signal bf_out_a_r, bf_out_a_i : std_logic_vector(15 downto 0);
    signal bf_out_b_r, bf_out_b_i : std_logic_vector(15 downto 0);
    
    signal tw_r, tw_i : std_logic_vector(15 downto 0);

    -- סיגנלים לאתחול
    signal init_counter : integer range 0 to 16 := 0;
    signal is_initializing : boolean := true;
    signal mux_we_a : std_logic;
    signal mux_addr_a : std_logic_vector(3 downto 0);
    signal mux_data_in_a_r, mux_data_in_a_i : std_logic_vector(15 downto 0);

begin

    -- תהליך אתחול פשוט לזיכרון (מכניס דופק ריבועי)
    process(clk, reset)
    begin
        if reset = '1' then
            is_initializing <= true;
            init_counter <= 0;
        elsif rising_edge(clk) then
            if is_initializing then
                if init_counter < 16 then
                    init_counter <= init_counter + 1;
                else
                    is_initializing <= false;
                end if;
            end if;
        end if;
    end process;

    -- מרבבים (Multiplexers) לכניסה ל-RAM (או מהבקר או מהאתחול)
    mux_we_a <= '1' when is_initializing else ram_we_a;
    
    mux_addr_a <= std_logic_vector(to_unsigned(init_counter, 4)) when is_initializing 
                  else ram_addr_a;
                  
    -- אתחול: ערך 0x2000 בכתובות 0-7, ו-0 בכתובות 8-15
    mux_data_in_a_r <= x"2000" when (is_initializing and init_counter < 8) else 
                       x"0000" when is_initializing else bf_out_a_r;
                       
    mux_data_in_a_i <= (others => '0') when is_initializing else bf_out_a_i;

    -- רכיבים
    u_ctrl: entity work.fft_controller
    port map(
        clk => clk, reset => reset, start => start, done => done,
        ram_we_a => ram_we_a, ram_we_b => ram_we_b,
        ram_addr_a => ram_addr_a, ram_addr_b => ram_addr_b,
        twiddle_addr => twiddle_addr
    );

    u_ram_real: entity work.ram_dual_port
    port map(
        clk => clk,
        we_a => mux_we_a, addr_a => mux_addr_a, data_in_a => mux_data_in_a_r, data_out_a => ram_r_out_a,
        we_b => ram_we_b, addr_b => ram_addr_b, data_in_b => bf_out_b_r, data_out_b => ram_r_out_b
    );

    u_ram_imag: entity work.ram_dual_port
    port map(
        clk => clk,
        we_a => mux_we_a, addr_a => mux_addr_a, data_in_a => mux_data_in_a_i, data_out_a => ram_i_out_a,
        we_b => ram_we_b, addr_b => ram_addr_b, data_in_b => bf_out_b_i, data_out_b => ram_i_out_b
    );

    u_rom: entity work.twiddle_rom
    port map(
        addr => twiddle_addr,
        twiddle_real => tw_r, twiddle_imag => tw_i
    );

    u_bf: entity work.butterfly
    port map(
        x_real => ram_r_out_a, x_imag => ram_i_out_a,
        y_real => ram_r_out_b, y_imag => ram_i_out_b,
        tw_real => tw_r,       tw_imag => tw_i,
        out_a_real => bf_out_a_r, out_a_imag => bf_out_a_i,
        out_b_real => bf_out_b_r, out_b_imag => bf_out_b_i
    );
    
    -- יציאה לבדיקה
    data_out_real <= ram_r_out_a;
    data_out_imag <= ram_i_out_a;

end rtl;