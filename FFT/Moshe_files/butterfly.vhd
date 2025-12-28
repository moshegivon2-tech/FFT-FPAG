library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity butterfly is
    generic ( WIDTH : integer := 16 );
    port (
        x_real, x_imag   : in std_logic_vector(WIDTH-1 downto 0);
        y_real, y_imag   : in std_logic_vector(WIDTH-1 downto 0);
        tw_real, tw_imag : in std_logic_vector(WIDTH-1 downto 0);
        out_a_real, out_a_imag : out std_logic_vector(WIDTH-1 downto 0);
        out_b_real, out_b_imag : out std_logic_vector(WIDTH-1 downto 0)
    );
end butterfly;

architecture rtl of butterfly is
    component fixed_mult is
        generic (WIDTH : integer := 16);
        port (
            a, b : in std_logic_vector(WIDTH-1 downto 0);
            result : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    signal sum_r, sum_i, diff_r, diff_i : std_logic_vector(WIDTH-1 downto 0);
    signal m1, m2, m3, m4 : std_logic_vector(WIDTH-1 downto 0);

begin
    -- =================================================================
    -- RADIX-2 DIF BUTTERFLY with STATIC SCALING (divide by 2)
    -- =================================================================
    -- DIF Butterfly equations:
    --   A' = (X + Y) / 2          <- Top output (no twiddle)
    --   B' = [(X - Y) / 2] * W    <- Bottom output (with twiddle)
    --
    -- We divide by 2 (shift right) to prevent overflow accumulation
    -- =================================================================
    
    process(x_real, x_imag, y_real, y_imag)
        variable v_sum_r, v_sum_i   : signed(WIDTH downto 0);  -- 17-bit for overflow
        variable v_diff_r, v_diff_i : signed(WIDTH downto 0);
    begin
        -- Add/Subtract with 17-bit precision
        v_sum_r  := resize(signed(x_real), WIDTH+1) + resize(signed(y_real), WIDTH+1);
        v_sum_i  := resize(signed(x_imag), WIDTH+1) + resize(signed(y_imag), WIDTH+1);
        v_diff_r := resize(signed(x_real), WIDTH+1) - resize(signed(y_real), WIDTH+1);
        v_diff_i := resize(signed(x_imag), WIDTH+1) - resize(signed(y_imag), WIDTH+1);

        -- Divide by 2 (shift right by 1) - STATIC SCALING
        -- This prevents overflow in subsequent stages
        sum_r  <= std_logic_vector(v_sum_r(WIDTH downto 1));
        sum_i  <= std_logic_vector(v_sum_i(WIDTH downto 1));
        diff_r <= std_logic_vector(v_diff_r(WIDTH downto 1));
        diff_i <= std_logic_vector(v_diff_i(WIDTH downto 1));
    end process;

    -- Top output (A path) - no twiddle multiplication needed
    out_a_real <= sum_r;
    out_a_imag <= sum_i;

    -- =================================================================
    -- Complex Multiplication: (diff_r + j*diff_i) * (tw_real + j*tw_imag)
    -- =================================================================
    -- Result_real = (diff_r * tw_real) - (diff_i * tw_imag)
    -- Result_imag = (diff_r * tw_imag) + (diff_i * tw_real)
    -- =================================================================
    
    u_mul1: fixed_mult port map(a => diff_r, b => tw_real, result => m1);
    u_mul2: fixed_mult port map(a => diff_i, b => tw_imag, result => m2);
    u_mul3: fixed_mult port map(a => diff_r, b => tw_imag, result => m3);
    u_mul4: fixed_mult port map(a => diff_i, b => tw_real, result => m4);

    -- Bottom output (B path) - complex result after twiddle multiplication
    out_b_real <= std_logic_vector(signed(m1) - signed(m2));
    out_b_imag <= std_logic_vector(signed(m3) + signed(m4));
    
end rtl;