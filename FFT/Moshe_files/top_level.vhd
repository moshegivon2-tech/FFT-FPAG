library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    port (
        clk, reset, start : in std_logic;
        wave_sel : in std_logic_vector(1 downto 0);
        display_addr : in std_logic_vector(3 downto 0);
        display_sel : in std_logic;
        done : out std_logic;
        leds : out std_logic_vector(15 downto 0)
    );
end top_level;

architecture rtl of top_level is
    type rom_type is array (0 to 15) of std_logic_vector(15 downto 0);
    -- 1. Square
    constant WAVE_SQUARE : rom_type := (x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000");
    -- 2. Impulse
    constant WAVE_IMPULSE : rom_type := (x"7FFF",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000");
    -- 3. Sine (k=1)
    constant WAVE_SINE : rom_type := (x"0000",x"30F0",x"5A82",x"7641",x"7FFF",x"7641",x"5A82",x"30F0",x"0000",x"CF10",x"A57E",x"89BF",x"8001",x"89BF",x"A57E",x"CF10");
    -- 4. Two-Tone (k=1 + k=5)
    constant WAVE_TWO_TONE : rom_type := (x"0000",x"2A4D",x"2120",x"4C8F",x"4E20",x"15E3",x"3D68",x"F242",x"0000",x"0DBD",x"C298",x"EA1D",x"B1E0",x"B371",x"DEDF",x"D5B3");

    signal ram_we_a, ram_we_b, mux_we_a, internal_done : std_logic;
    signal ram_addr_a, ram_addr_b, twiddle_addr, mux_addr_a, reversed_display_addr : std_logic_vector(3 downto 0);
    signal ram_r_out_a, ram_r_out_b, ram_i_out_a, ram_i_out_b : std_logic_vector(15 downto 0);
    signal bf_out_a_r, bf_out_a_i, bf_out_b_r, bf_out_b_i, tw_r, tw_i : std_logic_vector(15 downto 0);
    signal mux_data_in_a_r, mux_data_in_a_i, selected_wave_sample : std_logic_vector(15 downto 0);
    signal init_counter : integer range 0 to 16 := 0;
    signal is_initializing : boolean := true;
    signal need_init : boolean := true;  -- Flag to track if init is needed

begin
    -- Unscrambler: Bit Reversal for Output
    reversed_display_addr <= display_addr(0) & display_addr(1) & display_addr(2) & display_addr(3);

    -- FIX: Two-stage reset - set flag on reset, then initialize
    process(clk, reset)
    begin
        if reset='1' then 
            need_init <= true;
            init_counter <= 0;
            report "RESET: need_init flag set";
        elsif rising_edge(clk) then
            -- Start initialization if needed
            if need_init then
                is_initializing <= true;
                need_init <= false;
                report "Starting initialization sequence";
            elsif is_initializing then
                if init_counter < 16 then 
                    report "INIT: Writing sample " & integer'image(init_counter);
                    init_counter <= init_counter + 1;
                else
                    -- After 16 clock cycles (wrote samples 0-15), we're done
                    report "INIT: Complete";
                    is_initializing <= false;
                end if;
            end if;
        end if;
    end process;

    process(wave_sel, init_counter)
        variable safe_index : integer range 0 to 15;
    begin
        -- Clamp index to valid range 0-15
        if init_counter < 16 then
            safe_index := init_counter;
        else
            safe_index := 0;  -- Default to 0 when out of range
        end if;
        
        case wave_sel is
            when "00" => selected_wave_sample <= WAVE_SQUARE(safe_index);
            when "01" => selected_wave_sample <= WAVE_IMPULSE(safe_index);
            when "10" => selected_wave_sample <= WAVE_SINE(safe_index);
            when "11" => selected_wave_sample <= WAVE_TWO_TONE(safe_index);
            when others => selected_wave_sample <= (others=>'0');
        end case;
    end process;

    -- MUX Control
    mux_addr_a <= std_logic_vector(to_unsigned(init_counter,4)) when is_initializing else 
                  reversed_display_addr when internal_done='1' else ram_addr_a;
    
    -- Only write during init if counter is valid (0-15)
    mux_we_a <= '1' when (is_initializing and init_counter < 16) else 
                ram_we_a when (internal_done='0' and not is_initializing) else '0';
                
    mux_data_in_a_r <= selected_wave_sample when is_initializing else bf_out_a_r;
    mux_data_in_a_i <= (others=>'0') when is_initializing else bf_out_a_i;

    -- Instantiations
    u_ctrl: entity work.fft_controller port map(clk, reset, start, internal_done, ram_we_a, ram_we_b, ram_addr_a, ram_addr_b, twiddle_addr);
    u_ram_real: entity work.ram_dual_port port map(clk, mux_we_a, ram_we_b, mux_addr_a, ram_addr_b, mux_data_in_a_r, bf_out_b_r, ram_r_out_a, ram_r_out_b);
    u_ram_imag: entity work.ram_dual_port port map(clk, mux_we_a, ram_we_b, mux_addr_a, ram_addr_b, mux_data_in_a_i, bf_out_b_i, ram_i_out_a, ram_i_out_b);
    u_rom: entity work.twiddle_rom port map(twiddle_addr, tw_r, tw_i);
    u_bf: entity work.butterfly port map(ram_r_out_a, ram_i_out_a, ram_r_out_b, ram_i_out_b, tw_r, tw_i, bf_out_a_r, bf_out_a_i, bf_out_b_r, bf_out_b_i);
    
    done <= internal_done;
    leds <= ram_i_out_a when display_sel='1' else ram_r_out_a;
end rtl;