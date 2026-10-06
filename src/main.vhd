library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity digital_door_lock is
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
           
        digit_input : in STD_LOGIC_VECTOR(15 downto 0); 
        
        btn_enter : in STD_LOGIC;      
        btn_next : in STD_LOGIC;       
        btn_program : in STD_LOGIC;    
        btn_override : in STD_LOGIC;   
        
        led_correct : out STD_LOGIC;
        led_wrong : out STD_LOGIC;
        led_program_mode : out STD_LOGIC;
        led_locked : out STD_LOGIC;
        
        seg : out STD_LOGIC_VECTOR(6 downto 0);
        an : out STD_LOGIC_VECTOR(7 downto 0)
    );
end digital_door_lock;

architecture Behavioral of digital_door_lock is
    
    type state_type is (LOCKED, INPUT_FIRST_4, INPUT_SECOND_4, CHECKING, 
                        CORRECT_STATE, WRONG_STATE, PROGRAM_MODE_1, PROGRAM_MODE_2, 
                        UNLOCKED, AUTO_LOCKING);
    signal current_state, next_state : state_type := LOCKED;
    
    signal stored_password : STD_LOGIC_VECTOR(31 downto 0) := "00010010001101000101011001111000";
    
     signal temp_first_4 : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal temp_second_4 : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal input_password : STD_LOGIC_VECTOR(31 downto 0);
    
    signal btn_enter_prev, btn_next_prev, btn_program_prev : STD_LOGIC := '0';
    signal btn_enter_pulse, btn_next_pulse, btn_program_pulse : STD_LOGIC := '0';
    
    signal auto_lock_counter : unsigned(28 downto 0) := (others => '0');
    constant AUTO_LOCK_TIME : unsigned(28 downto 0) := to_unsigned(500000000, 29);
    signal auto_lock_enable : STD_LOGIC := '0';
    
    signal refresh_counter : unsigned(19 downto 0) := (others => '0');
    signal digit_select : unsigned(2 downto 0) := (others => '0');
    signal current_digit : STD_LOGIC_VECTOR(4 downto 0); 
    signal display_mode : STD_LOGIC := '0';
    signal display_benar : STD_LOGIC := '0';
    signal display_salah : STD_LOGIC := '0';
    
begin
    
    input_password <= temp_first_4 & temp_second_4;
    
    -- ========== BUTTON EDGE DETECTION ==========
    process(clk, reset)
    begin
        if reset = '1' then
            btn_enter_prev <= '0';
            btn_next_prev <= '0';
            btn_program_prev <= '0';
            btn_enter_pulse <= '0';
            btn_next_pulse <= '0';
            btn_program_pulse <= '0';
        elsif rising_edge(clk) then
            btn_enter_prev <= btn_enter;
            btn_next_prev <= btn_next;
            btn_program_prev <= btn_program;
            
            btn_enter_pulse <= btn_enter and not btn_enter_prev;
            btn_next_pulse <= btn_next and not btn_next_prev;
            btn_program_pulse <= btn_program and not btn_program_prev;
        end if;
    end process;
    
    -- ========== STATE MACHINE - STATE REGISTER ==========
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= LOCKED;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    -- ========== STATE MACHINE - NEXT STATE LOGIC ==========
    process(current_state, btn_enter_pulse, btn_next_pulse, btn_program_pulse, 
            btn_override, input_password, stored_password, auto_lock_counter)
    begin
        next_state <= current_state;
        
        case current_state is
            
            when LOCKED =>
                if btn_override = '1' then
                    next_state <= UNLOCKED;
                elsif btn_program_pulse = '1' then
                    next_state <= PROGRAM_MODE_1;
                elsif btn_next_pulse = '1' then
                    next_state <= INPUT_FIRST_4;
                end if;
            
            when INPUT_FIRST_4 =>
                if btn_next_pulse = '1' then
                    next_state <= INPUT_SECOND_4;
                end if;
            
            when INPUT_SECOND_4 =>
                if btn_enter_pulse = '1' then
                    next_state <= CHECKING;
                end if;
            
            when CHECKING =>
                if input_password = stored_password then
                    next_state <= CORRECT_STATE;
                else
                    next_state <= WRONG_STATE;
                end if;
            
            when CORRECT_STATE =>
                next_state <= UNLOCKED;
            
            when WRONG_STATE =>
                if btn_enter_pulse = '1' then
                    next_state <= LOCKED;
                end if;
            
            when PROGRAM_MODE_1 =>
                if btn_next_pulse = '1' then
                    next_state <= PROGRAM_MODE_2;
                end if;
            
            when PROGRAM_MODE_2 =>
                if btn_enter_pulse = '1' then
                    next_state <= LOCKED;
                end if;
            
            when UNLOCKED =>
                if auto_lock_counter >= AUTO_LOCK_TIME then
                    next_state <= AUTO_LOCKING;
                elsif btn_enter_pulse = '1' then
                    next_state <= LOCKED;
                end if;
            
            when AUTO_LOCKING =>
                next_state <= LOCKED;
                
        end case;
    end process;
    
    -- ========== STATE MACHINE - OUTPUT LOGIC ==========
    process(clk, reset)
    begin
        if reset = '1' then
            led_correct <= '0';
            led_wrong <= '0';
            led_program_mode <= '0';
            led_locked <= '1';
            auto_lock_counter <= (others => '0');
            auto_lock_enable <= '0';
            display_benar <= '0';
            display_salah <= '0';
            display_mode <= '0';
            temp_first_4 <= (others => '0');
            temp_second_4 <= (others => '0');
        elsif rising_edge(clk) then
            
            led_correct <= '0';
            led_wrong <= '0';
            led_program_mode <= '0';
            led_locked <= '1';
            display_mode <= '0';
            
            case current_state is
                
                when LOCKED =>
                    led_locked <= '1';
                    auto_lock_counter <= (others => '0');
                    auto_lock_enable <= '0';
                    display_benar <= '0';
                    display_salah <= '0';
                    temp_first_4 <= (others => '0');
                    temp_second_4 <= (others => '0');
                
                when INPUT_FIRST_4 =>
                    led_locked <= '1';
                    if btn_next_pulse = '1' then
                        temp_first_4 <= digit_input;
                    end if;
                
                when INPUT_SECOND_4 =>
                    led_locked <= '1';
                    if btn_enter_pulse = '1' then
                        temp_second_4 <= digit_input;
                    end if;
                
                when CHECKING =>
                    led_locked <= '1';
                
                when CORRECT_STATE =>
                    led_correct <= '1';
                    led_locked <= '1';
                    display_benar <= '1';
                    display_salah <= '0';
                    display_mode <= '1';
                
                when WRONG_STATE =>
                    led_wrong <= '1';
                    led_locked <= '1';
                    display_benar <= '0';
                    display_salah <= '1';
                    display_mode <= '1';
                
                when PROGRAM_MODE_1 =>
                    led_program_mode <= '1';
                    led_locked <= '1';
                    if btn_next_pulse = '1' then
                        temp_first_4 <= digit_input;
                    end if;
                
                when PROGRAM_MODE_2 =>
                    led_program_mode <= '1';
                    led_locked <= '1';
                    if btn_enter_pulse = '1' then
                        temp_second_4 <= digit_input;
                        stored_password <= temp_first_4 & digit_input;
                    end if;
                
                when UNLOCKED =>
                    led_correct <= '1';
                    led_locked <= '0';
                    auto_lock_enable <= '1';
                    display_benar <= '1';
                    display_mode <= '1';
                    
                    if auto_lock_enable = '1' then
                        auto_lock_counter <= auto_lock_counter + 1;
                    end if;
                
                when AUTO_LOCKING =>
                    led_locked <= '1';
                    auto_lock_counter <= (others => '0');
                    
            end case;
        end if;
    end process;
    
    -- ========== 7-SEGMENT DISPLAY ==========
    process(clk, reset)
    begin
        if reset = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;
    
    digit_select <= refresh_counter(19 downto 17);
    
    process(digit_select, display_mode, display_benar, display_salah, 
            current_state, temp_first_4, temp_second_4, digit_input)
    begin
        if display_mode = '0' then
            case current_state is
                when INPUT_FIRST_4 | PROGRAM_MODE_1 =>
                    case digit_select is
                        when "000" => current_digit <= digit_input(3 downto 0) & '0';
                        when "001" => current_digit <= digit_input(7 downto 4) & '0';
                        when "010" => current_digit <= digit_input(11 downto 8) & '0';
                        when "011" => current_digit <= digit_input(15 downto 12) & '0';
                        when "100" => current_digit <= "11111"; -- Blank
                        when "101" => current_digit <= "11111"; -- Blank
                        when "110" => current_digit <= "11111"; -- Blank
                        when "111" => current_digit <= "11111"; -- Blank
                        when others => current_digit <= "11111";
                    end case;
                    
                when INPUT_SECOND_4 | PROGRAM_MODE_2 =>                
                    case digit_select is
                        when "000" => current_digit <= digit_input(3 downto 0) & '0';
                        when "001" => current_digit <= digit_input(7 downto 4) & '0';
                        when "010" => current_digit <= digit_input(11 downto 8) & '0';
                        when "011" => current_digit <= digit_input(15 downto 12) & '0';
                        when "100" => current_digit <= temp_first_4(3 downto 0) & '0';
                        when "101" => current_digit <= temp_first_4(7 downto 4) & '0';
                        when "110" => current_digit <= temp_first_4(11 downto 8) & '0';
                        when "111" => current_digit <= temp_first_4(15 downto 12) & '0';
                        when others => current_digit <= "11111";
                    end case;
                    
                when others =>
                    current_digit <= "11111";
            end case;
        else
            -- Mode BENAR/SALAH
            if display_benar = '1' then
                case digit_select is
                    when "000" => current_digit <= "11111"; -- Blank
                    when "001" => current_digit <= "11111"; -- Blank
                    when "010" => current_digit <= "11111"; -- Blank
                    when "011" => current_digit <= "10100"; -- R
                    when "100" => current_digit <= "10101"; -- A
                    when "101" => current_digit <= "10110"; -- N
                    when "110" => current_digit <= "10111"; -- E
                    when "111" => current_digit <= "11000"; -- B
                    when others => current_digit <= "11111";
                end case;
            elsif display_salah = '1' then
                case digit_select is
                    when "000" => current_digit <= "11111"; -- Blank
                    when "001" => current_digit <= "11111"; -- Blank
                    when "010" => current_digit <= "11111"; -- Blank
                    when "011" => current_digit <= "11001"; -- H
                    when "100" => current_digit <= "10101"; -- A
                    when "101" => current_digit <= "11010"; -- L
                    when "110" => current_digit <= "10101"; -- A
                    when "111" => current_digit <= "11011"; -- S
                    when others => current_digit <= "11111";
                end case;
            else
                current_digit <= "11111";
            end if;
        end if;
    end process;
    
    process(digit_select)
    begin
        an <= "11111111";
        case digit_select is
            when "000" => an <= "11111110";
            when "001" => an <= "11111101";
            when "010" => an <= "11111011";
            when "011" => an <= "11110111";
            when "100" => an <= "11101111";
            when "101" => an <= "11011111";
            when "110" => an <= "10111111";
            when "111" => an <= "01111111";
            when others => an <= "11111111";         
        end case;
    end process;
    
    -- 7-segment decoder 
    process(current_digit)
    begin
        case current_digit is
            when "00000" => seg <= "0000001"; -- 0
            when "00010" => seg <= "1001111"; -- 1
            when "00100" => seg <= "0010010"; -- 2
            when "00110" => seg <= "0000110"; -- 3
            when "01000" => seg <= "1001100"; -- 4
            when "01010" => seg <= "0100100"; -- 5
            when "01100" => seg <= "0100000"; -- 6
            when "01110" => seg <= "0001111"; -- 7
            when "10000" => seg <= "0000000"; -- 8
            when "10010" => seg <= "0000100"; -- 9
            
            -- Huruf khusus untuk BENAR/SALAH 
            when "10100" => seg <= "0111001"; -- r 
            when "10101" => seg <= "0001000"; -- A 
            when "10110" => seg <= "0001001"; -- n 
            when "10111" => seg <= "0110000"; -- E 
            when "11000" => seg <= "0000000"; -- B 
            when "11001" => seg <= "1001000"; -- H 
            when "11010" => seg <= "1110001"; -- L 
            when "11011" => seg <= "0100100"; -- S 
            
            when "11111" => seg <= "1111111"; -- Blank
            when others => seg <= "1111111"; -- Blank
        end case;
    end process;
    
end Behavioral;
