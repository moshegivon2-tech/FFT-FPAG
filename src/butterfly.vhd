library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity butterfly is
    generic (
        WIDTH : integer := 16
    );
    port (
        x_real, x_imag  : in std_logic_vector(WIDTH-1 downto 0);
        y_real, y_imag  : in std_logic_vector(WIDTH-1 downto 0);
        tw_real, tw_imag: in std_logic_vector(WIDTH-1 downto 0);

        out_a_real, out_a_imag : out std_logic_vector(WIDTH-1 downto 0);
        out_b_real, out_b_imag : out std_logic_vector(WIDTH-1 downto 0)
    );
end butterfly;

architecture rtl of butterfly is
    signal temp1, temp2, temp3, temp4 : std_logic_vector(WIDTH-1 downto 0);
    
    signal a_plus_wy_r, a_plus_wy_i : signed(WIDTH-1 downto 0);
    signal a_minus_wy_r, a_minus_wy_i : signed(WIDTH-1 downto 0);
    
    component fixed_mult is
        generic (WIDTH : integer := 16);
        port (a, b : in std_logic_vector; result : out std_logic_vector);
    end component;
    
begin
    -- חישוב מכפלות W * Y
    u_mult1: fixed_mult port map(y_real, tw_real, temp1); -- Yr * Tr
    u_mult2: fixed_mult port map(y_imag, tw_imag, temp2); -- Yi * Ti
    u_mult3: fixed_mult port map(y_real, tw_imag, temp3); -- Yr * Ti
    u_mult4: fixed_mult port map(y_imag, tw_real, temp4); -- Yi * Tr

    -- חישובים אריתמטיים
    -- שימוש ב-Shift Right (חלוקה ב-2) למניעת Overflow (Scaling)
    process(x_real, x_imag, temp1, temp2, temp3, temp4)
        variable wy_r, wy_i : signed(WIDTH-1 downto 0);
    begin
        wy_r := signed(temp1) - signed(temp2);
        wy_i := signed(temp3) + signed(temp4);
        
        -- חישוב תוצאה ומיד חלוקה ב-2 (shift right arithmetic)
        out_a_real <= std_logic_vector(shift_right(signed(x_real) + wy_r, 1));
        out_a_imag <= std_logic_vector(shift_right(signed(x_imag) + wy_i, 1));
        
        out_b_real <= std_logic_vector(shift_right(signed(x_real) - wy_r, 1));
        out_b_imag <= std_logic_vector(shift_right(signed(x_imag) - wy_i, 1));
    end process;

end rtl;