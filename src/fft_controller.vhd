library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft_controller is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        start     : in  std_logic;
        done      : out std_logic;

        ram_we_a  : out std_logic;
        ram_we_b  : out std_logic;
        ram_addr_a: out std_logic_vector(3 downto 0);
        ram_addr_b: out std_logic_vector(3 downto 0);
        twiddle_addr: out std_logic_vector(3 downto 0) 
    );
end fft_controller;

architecture rtl of fft_controller is
    constant N_LOG2 : integer := 4;
    constant N      : integer := 16;
    
    type state_type is (IDLE, READ, READ_WAIT, BUTTERFLY_WAIT, WRITE, UPDATE, FINISH);
    signal state : state_type := IDLE;

    signal stage      : integer range 0 to N_LOG2 := 0;
    signal bf_index   : integer range 0 to N/2-1 := 0;

    signal addr_a_sig, addr_b_sig, twiddle_addr_sig : unsigned(3 downto 0);
    signal done_reg : std_logic := '0';

begin
    ram_addr_a <= std_logic_vector(addr_a_sig);
    ram_addr_b <= std_logic_vector(addr_b_sig);
    twiddle_addr <= std_logic_vector(twiddle_addr_sig);
    done <= done_reg;
    
    ram_we_a <= '1' when state = WRITE else '0';
    ram_we_b <= '1' when state = WRITE else '0';

    -- לוגיקת חישוב כתובות
    process(stage, bf_index)
        variable h_len : integer;
        variable block_idx : integer;
        variable current_addr : integer;
        variable tw_idx : integer;
        variable multiplier : integer;
    begin
        h_len := 2**stage; -- 1, 2, 4, 8
        
        -- חישוב אינדקס הבלוק ע"י הזזה במקום חילוק (bf_index / 2^stage)
        block_idx := to_integer(shift_right(to_unsigned(bf_index, 16), stage));
        
        -- כתובת בסיס: block_idx * 2^(stage+1) + שארית
        -- השארית היא bf_index masked with (h_len - 1)
        current_addr := block_idx * (2**(stage + 1)) + (bf_index mod h_len);
        
        addr_a_sig <= to_unsigned(current_addr, 4);
        addr_b_sig <= to_unsigned(current_addr + h_len, 4);
        
        -- חישוב Twiddle: (index % h_len) * (N / 2^(stage+1))
        multiplier := N / (2**(stage + 1));
        tw_idx := (bf_index mod h_len) * multiplier;
        twiddle_addr_sig <= to_unsigned(tw_idx, 4);
    end process;

    -- מכונת המצבים
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            stage <= 0;
            bf_index <= 0;
            done_reg <= '0';
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= READ;
                        stage <= 0;
                        bf_index <= 0;
                        done_reg <= '0';
                    end if;
                    
                when READ =>
                    -- במחזור זה הכתובות יציבות לכניסת ה-RAM
                    state <= READ_WAIT;
                    
                when READ_WAIT =>
                    -- מחכים מחזור אחד שה-RAM יוציא את המידע (Synchronous Read)
                    state <= BUTTERFLY_WAIT;

                when BUTTERFLY_WAIT =>
                    -- כעת המידע זמין לפרפר, ממתינים להתייצבות קומבינטורית
                    state <= WRITE;
                    
                when WRITE =>
                    state <= UPDATE;
                    
                when UPDATE =>
                    if bf_index < N/2 - 1 then
                        bf_index <= bf_index + 1;
                        state <= READ;
                    else
                        if stage < N_LOG2 - 1 then
                            stage <= stage + 1;
                            bf_index <= 0;
                            state <= READ;
                        else
                            state <= FINISH;
                        end if;
                    end if;
                    
                when FINISH =>
                    done_reg <= '1';
                    if start = '0' then 
                         state <= IDLE;
                    end if;
                    
                when others => state <= IDLE;
            end case;
        end if;
    end process;

end rtl;