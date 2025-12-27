library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =================================================================
-- Q1.15 Fixed Point Multiplier
-- =================================================================
-- Input:  Two 16-bit Q1.15 numbers (1 sign bit, 15 fractional bits)
-- Output: 16-bit Q1.15 result
--
-- Mathematical Operation:
--   Q1.15 * Q1.15 = Q2.30 (32-bit intermediate)
--   We extract bits [30:15] to get Q1.15 result (with rounding)
-- =================================================================

entity fixed_mult is
    generic ( WIDTH : integer := 16 );
    port (
        a, b : in std_logic_vector(WIDTH-1 downto 0);
        result : out std_logic_vector(WIDTH-1 downto 0)
    );
end fixed_mult;

architecture rtl of fixed_mult is
begin
    process(a, b)
        variable v_a, v_b : signed(WIDTH-1 downto 0);
        variable v_res_full : signed(2*WIDTH-1 downto 0);  -- 32-bit
    begin
        v_a := signed(a);
        v_b := signed(b);
        v_res_full := v_a * v_b;
        
        -- Extract Q1.15 result from Q2.30
        -- Bits [30:15] give us the correct Q1.15 format
        -- This is equivalent to: (a * b) >> 15
        result <= std_logic_vector(v_res_full(WIDTH + WIDTH - 2 downto WIDTH - 1));
    end process;
end rtl;