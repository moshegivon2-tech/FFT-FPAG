library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_dual_port is
    generic ( DATA_WIDTH : integer := 16; ADDR_WIDTH : integer := 4 );
    port (
        clk : in std_logic;
        we_a, we_b : in std_logic;
        addr_a, addr_b : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in_a, data_in_b : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_a, data_out_b : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end ram_dual_port;

architecture rtl of ram_dual_port is
    type ram_type is array (0 to 15) of std_logic_vector(15 downto 0);
    signal ram : ram_type := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we_a = '1' then ram(to_integer(unsigned(addr_a))) <= data_in_a; end if;
            data_out_a <= ram(to_integer(unsigned(addr_a)));
            
            if we_b = '1' then ram(to_integer(unsigned(addr_b))) <= data_in_b; end if;
            data_out_b <= ram(to_integer(unsigned(addr_b)));
        end if;
    end process;
end rtl;
