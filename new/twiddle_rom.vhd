library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity twiddle_rom is
    generic ( WIDTH : integer := 16; ADDR_WIDTH : integer := 4 );
    port (
        addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        twiddle_real : out std_logic_vector(WIDTH-1 downto 0);
        twiddle_imag : out std_logic_vector(WIDTH-1 downto 0)
    );
end twiddle_rom;

architecture rtl of twiddle_rom is
    type rom_arr is array (0 to 15) of std_logic_vector(WIDTH-1 downto 0);
    
    constant ROM_REAL : rom_arr := (
        x"7FFF", x"7641", x"5A82", x"30FB", x"0000", x"CF05", x"A57E", x"89BF",
        x"8000", x"89BF", x"A57E", x"CF05", x"0000", x"30FB", x"5A82", x"7641"
    );
    constant ROM_IMAG : rom_arr := (
        x"0000", x"CF05", x"A57E", x"89BF", x"8000", x"89BF", x"A57E", x"CF05",
        x"0000", x"30FB", x"5A82", x"7641", x"7FFF", x"7641", x"5A82", x"30FB"
    );
begin
    twiddle_real <= ROM_REAL(to_integer(unsigned(addr)));
    twiddle_imag <= ROM_IMAG(to_integer(unsigned(addr)));
end rtl;