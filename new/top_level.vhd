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
    -- 1. Square Wave
    constant WAVE_SQUARE : rom_type := (
        x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"7FFF",x"7FFF",
        x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000"
    );
    -- 2. Impulse
    constant WAVE_IMPULSE : rom_type := (
        x"7FFF",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",
        x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000"
    );
    -- 3. Sine Wave (k=1)
    constant WAVE_SINE : rom_type := (
        x"0000",x"30F0",x"5A82",x"7641",x"7FFF",x"7641",x"5A82",x"30F0",
        x"0000",x"CF10",x"A57E",x"89BF",x"8001",x"89BF",x"A57E",x"CF10"
    );
    -- 4. Two-Tone (k=1 + k=5)
    constant WAVE_TWO_TONE : rom_type := (
        x"0000",x"2A4D",x"2120",x"4C8F",x"4E20",x"15E3",x"3D68",x"F242",
        x"0000",x"0DBD",x"C298",x"EA1D",x"B1E0",x"B371",x"DEDF",x"D5B3"
    );

    -- Internal signals
    signal ram_we_a, ram_we_b, mux_we_a, internal_done : std_logic;
    signal ram_addr_a, ram_addr_b, twiddle_addr, mux_addr_a : std_logic_vector(3 downto 0);
    signal reversed_display_addr : std_logic_vector(3 downto 0);
    signal ram_r_out_a, ram_r_out_b, ram_i_out_a, ram_i_out_b : std_logic_vector(15 downto 0);
    signal bf_out_a_r, bf_out_a_i, bf_out_b_r, bf_out_b_i : std_logic_vector(15 downto 0);
    signal tw_r, tw_i : std_logic_vector(15 downto 0);
    signal mux_data_in_a_r, mux_data_in_a_i, selected_wave_sample : std_logic_vector(15 downto 0);
    
    -- Initialization FSM
    type init_state_type is (INIT_WAIT, INIT_LOAD, INIT_DONE);
    signal init_state : init_state_type := INIT_WAIT;
    signal init_counter : integer range 0 to 16 := 0;

begin
    -- ============================================
    -- Bit Reversal for Output Display
    -- ============================================
    reversed_display_addr <= display_addr(0) & display_addr(1) & 
                             display_addr(2) & display_addr(3);

    -- ============================================
    -- Initialization FSM
    -- ============================================
    process(clk, reset)
    begin
        if reset = '1' then
            init_state <= INIT_WAIT;
            init_counter <= 0;
        elsif rising_edge(clk) then
            case init_state is
                when INIT_WAIT =>
                    -- Wait one cycle after reset before loading
                    init_state <= INIT_LOAD;
                    init_counter <= 0;
                    
                when INIT_LOAD =>
                    if init_counter < 15 then
                        init_counter <= init_counter + 1;
                    else
                        init_state <= INIT_DONE;
                    end if;
                    
                when INIT_DONE =>
                    -- Stay here forever after initialization
                    null;
            end case;
        end if;
    end process;

    -- ============================================
    -- Waveform Selection
    -- ============================================
    process(wave_sel, init_counter)
    begin
        case wave_sel is
            when "00"   => selected_wave_sample <= WAVE_SQUARE(init_counter);
            when "01"   => selected_wave_sample <= WAVE_IMPULSE(init_counter);
            when "10"   => selected_wave_sample <= WAVE_SINE(init_counter);
            when "11"   => selected_wave_sample <= WAVE_TWO_TONE(init_counter);
            when others => selected_wave_sample <= (others => '0');
        end case;
    end process;

    -- ============================================
    -- MUX Control Logic
    -- ============================================
    -- Address MUX
    mux_addr_a <= std_logic_vector(to_unsigned(init_counter, 4)) when init_state = INIT_LOAD else 
                  reversed_display_addr when internal_done = '1' else 
                  ram_addr_a;
    
    -- Write Enable MUX
    mux_we_a <= '1' when init_state = INIT_LOAD else 
                ram_we_a when init_state = INIT_DONE else 
                '0';
                
    -- Data Input MUX
    mux_data_in_a_r <= selected_wave_sample when init_state = INIT_LOAD else bf_out_a_r;
    mux_data_in_a_i <= (others => '0') when init_state = INIT_LOAD else bf_out_a_i;

    -- ============================================
    -- Component Instantiations
    -- ============================================
    
    -- FFT Controller
    u_ctrl: entity work.fft_controller 
        port map(
            clk => clk,
            reset => reset,
            start => start,
            done => internal_done,
            ram_we_a => ram_we_a,
            ram_we_b => ram_we_b,
            ram_addr_a => ram_addr_a,
            ram_addr_b => ram_addr_b,
            twiddle_addr => twiddle_addr
        );
    
    -- RAM for Real Part (Dual Port)
    u_ram_real: entity work.ram_dual_port 
        port map(
            clk => clk,
            we_a => mux_we_a,
            we_b => ram_we_b,
            addr_a => mux_addr_a,
            addr_b => ram_addr_b,
            data_in_a => mux_data_in_a_r,
            data_in_b => bf_out_b_r,
            data_out_a => ram_r_out_a,
            data_out_b => ram_r_out_b
        );
    
    -- RAM for Imaginary Part (Dual Port)
    u_ram_imag: entity work.ram_dual_port 
        port map(
            clk => clk,
            we_a => mux_we_a,
            we_b => ram_we_b,
            addr_a => mux_addr_a,
            addr_b => ram_addr_b,
            data_in_a => mux_data_in_a_i,
            data_in_b => bf_out_b_i,
            data_out_a => ram_i_out_a,
            data_out_b => ram_i_out_b
        );
    
    -- Twiddle Factor ROM
    u_rom: entity work.twiddle_rom 
        port map(
            addr => twiddle_addr,
            twiddle_real => tw_r,
            twiddle_imag => tw_i
        );
    
    -- Butterfly Unit
    u_bf: entity work.butterfly 
        port map(
            x_real => ram_r_out_a,
            x_imag => ram_i_out_a,
            y_real => ram_r_out_b,
            y_imag => ram_i_out_b,
            tw_real => tw_r,
            tw_imag => tw_i,
            out_a_real => bf_out_a_r,
            out_a_imag => bf_out_a_i,
            out_b_real => bf_out_b_r,
            out_b_imag => bf_out_b_i
        );
    
    -- ============================================
    -- Output Assignments
    -- ============================================
    done <= internal_done;
    leds <= ram_i_out_a when display_sel = '1' else ram_r_out_a;
    
end rtl;