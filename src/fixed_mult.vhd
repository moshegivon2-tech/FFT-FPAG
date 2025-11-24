library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_mult is
    generic (
        WIDTH : integer := 16
    );
    port (
        a : in std_logic_vector(WIDTH-1 downto 0);
        b : in std_logic_vector(WIDTH-1 downto 0);
        result : out std_logic_vector(WIDTH-1 downto 0)
    );
end fixed_mult;

architecture rtl of fixed_mult is
    signal a_s, b_s : signed(WIDTH-1 downto 0);
    signal temp : signed(2*WIDTH-1 downto 0);
begin
    a_s <= signed(a);
    b_s <= signed(b);
    temp <= a_s * b_s;
    
    -- חיתוך לפורמט Q1.15 (שומרים על הביט העליון ו-15 שאחריו)
    -- שים לב: זה מניח שהמספרים הם בטווח -1 ל-1
    result <= std_logic_vector(temp(2*WIDTH-2 downto WIDTH-1)); 
end rtl;