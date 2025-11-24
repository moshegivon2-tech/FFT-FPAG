library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity twiddle_rom is
    generic (
        WIDTH : integer := 16;
        ADDR_WIDTH : integer := 4
    );
    port (
        addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        twiddle_real : out std_logic_vector(WIDTH-1 downto 0);
        twiddle_imag : out std_logic_vector(WIDTH-1 downto 0)
    );
end twiddle_rom;

architecture rtl of twiddle_rom is
    type rom_arr is array (0 to 15) of std_logic_vector(WIDTH-1 downto 0);
    
    -- ערכים מחושבים עבור N=16, פורמט Q1.15 Fixed Point
    -- W^k = cos(2pi*k/16) - j*sin(2pi*k/16)
    
    constant ROM_REAL : rom_arr := (
        x"7FFF", -- k=0:  1.000
        x"7641", -- k=1:  0.923
        x"5A82", -- k=2:  0.707
        x"30FB", -- k=3:  0.382
        x"0000", -- k=4:  0.000
        x"CF05", -- k=5: -0.382
        x"A57E", -- k=6: -0.707
        x"89BF", -- k=7: -0.923
        x"8000", -- k=8: -1.000 (Min value)
        x"89BF", -- k=9: -0.923
        x"A57E", -- k=10: -0.707
        x"CF05", -- k=11: -0.382
        x"0000", -- k=12:  0.000
        x"30FB", -- k=13:  0.382
        x"5A82", -- k=14:  0.707
        x"7641"  -- k=15:  0.923
    );
    
    constant ROM_IMAG : rom_arr := (
        x"0000", -- k=0:  0.000
        x"CF05", -- k=1: -0.382
        x"A57E", -- k=2: -0.707
        x"89BF", -- k=3: -0.923
        x"8000", -- k=4: -1.000
        x"89BF", -- k=5: -0.923
        x"A57E", -- k=6: -0.707
        x"CF05", -- k=7: -0.382
        x"0000", -- k=8:  0.000
        x"30FB", -- k=9:  0.382
        x"5A82", -- k=10:  0.707
        x"7641", -- k=11:  0.923
        x"7FFF", -- k=12:  1.000
        x"7641", -- k=13:  0.923
        x"5A82", -- k=14:  0.707
        x"30FB"  -- k=15:  0.382
    );
    
begin
    twiddle_real <= ROM_REAL(to_integer(unsigned(addr)));
    twiddle_imag <= ROM_IMAG(to_integer(unsigned(addr)));
end rtl;