library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft_controller is
    port (
        clk, reset, start : in std_logic;
        done : out std_logic;
        ram_we_a, ram_we_b : out std_logic;
        ram_addr_a, ram_addr_b, twiddle_addr : out std_logic_vector(3 downto 0)
    );
end fft_controller;

architecture rtl of fft_controller is
    type state_type is (ST_IDLE, ST_CALC, ST_WAIT);
    signal state : state_type := ST_IDLE;
    signal count : integer range 0 to 31 := 0; 
    signal phase : std_logic := '0'; -- 0=Read, 1=Write
begin
    process(clk, reset)
    begin
        if reset = '1' then
            state <= ST_IDLE;
            count <= 0;
            phase <= '0';
            done <= '0';
            ram_we_a <= '0';
            ram_we_b <= '0';
        elsif rising_edge(clk) then
            case state is
                
                when ST_IDLE =>
                    done <= '0';
                    ram_we_a <= '0';
                    ram_we_b <= '0';
                    if start = '1' then 
                        state <= ST_CALC;
                        count <= 0;
                        phase <= '0';
                    end if;

                when ST_CALC =>
                    -- ????? ?????? ???? (DIF N=16)
                    case count is
                        when 0 => ram_addr_a<=x"0"; ram_addr_b<=x"8"; twiddle_addr<=x"0";
                        when 1 => ram_addr_a<=x"1"; ram_addr_b<=x"9"; twiddle_addr<=x"1";
                        when 2 => ram_addr_a<=x"2"; ram_addr_b<=x"A"; twiddle_addr<=x"2";
                        when 3 => ram_addr_a<=x"3"; ram_addr_b<=x"B"; twiddle_addr<=x"3";
                        when 4 => ram_addr_a<=x"4"; ram_addr_b<=x"C"; twiddle_addr<=x"4";
                        when 5 => ram_addr_a<=x"5"; ram_addr_b<=x"D"; twiddle_addr<=x"5";
                        when 6 => ram_addr_a<=x"6"; ram_addr_b<=x"E"; twiddle_addr<=x"6";
                        when 7 => ram_addr_a<=x"7"; ram_addr_b<=x"F"; twiddle_addr<=x"7";
                        -- Stage 2
                        when 8 => ram_addr_a<=x"0"; ram_addr_b<=x"4"; twiddle_addr<=x"0";
                        when 9 => ram_addr_a<=x"1"; ram_addr_b<=x"5"; twiddle_addr<=x"2";
                        when 10=> ram_addr_a<=x"2"; ram_addr_b<=x"6"; twiddle_addr<=x"4";
                        when 11=> ram_addr_a<=x"3"; ram_addr_b<=x"7"; twiddle_addr<=x"6";
                        when 12=> ram_addr_a<=x"8"; ram_addr_b<=x"C"; twiddle_addr<=x"0";
                        when 13=> ram_addr_a<=x"9"; ram_addr_b<=x"D"; twiddle_addr<=x"2";
                        when 14=> ram_addr_a<=x"A"; ram_addr_b<=x"E"; twiddle_addr<=x"4";
                        when 15=> ram_addr_a<=x"B"; ram_addr_b<=x"F"; twiddle_addr<=x"6";
                        -- Stage 3
                        when 16=> ram_addr_a<=x"0"; ram_addr_b<=x"2"; twiddle_addr<=x"0";
                        when 17=> ram_addr_a<=x"1"; ram_addr_b<=x"3"; twiddle_addr<=x"4";
                        when 18=> ram_addr_a<=x"4"; ram_addr_b<=x"6"; twiddle_addr<=x"0";
                        when 19=> ram_addr_a<=x"5"; ram_addr_b<=x"7"; twiddle_addr<=x"4";
                        when 20=> ram_addr_a<=x"8"; ram_addr_b<=x"A"; twiddle_addr<=x"0";
                        when 21=> ram_addr_a<=x"9"; ram_addr_b<=x"B"; twiddle_addr<=x"4";
                        when 22=> ram_addr_a<=x"C"; ram_addr_b<=x"E"; twiddle_addr<=x"0";
                        when 23=> ram_addr_a<=x"D"; ram_addr_b<=x"F"; twiddle_addr<=x"4";
                        -- Stage 4
                        when 24=> ram_addr_a<=x"0"; ram_addr_b<=x"1"; twiddle_addr<=x"0";
                        when 25=> ram_addr_a<=x"2"; ram_addr_b<=x"3"; twiddle_addr<=x"0";
                        when 26=> ram_addr_a<=x"4"; ram_addr_b<=x"5"; twiddle_addr<=x"0";
                        when 27=> ram_addr_a<=x"6"; ram_addr_b<=x"7"; twiddle_addr<=x"0";
                        when 28=> ram_addr_a<=x"8"; ram_addr_b<=x"9"; twiddle_addr<=x"0";
                        when 29=> ram_addr_a<=x"A"; ram_addr_b<=x"B"; twiddle_addr<=x"0";
                        when 30=> ram_addr_a<=x"C"; ram_addr_b<=x"D"; twiddle_addr<=x"0";
                        when 31=> ram_addr_a<=x"E"; ram_addr_b<=x"F"; twiddle_addr<=x"0";
                        when others => null;
                    end case;

                    -- ?????? Read/Write
                    if phase = '0' then
                        ram_we_a <= '0';
                        ram_we_b <= '0';
                        phase <= '1';
                    else
                        ram_we_a <= '1';
                        ram_we_b <= '1';
                        phase <= '0';
                        if count = 31 then
                            state <= ST_WAIT; -- ????? ?????, ?????? ??????
                        else
                            count <= count + 1;
                        end if;
                    end if;

                when ST_WAIT =>
                    -- ?-WE ???? ???? ???? ??? ???? ??? ????? ?? ????? 15
                    ram_we_a <= '1';
                    ram_we_b <= '1';
                    done <= '1'; -- ?? ????? ????? ?? ?-Done
                    state <= ST_IDLE;

            end case;
        end if;
    end process;
end rtl;
