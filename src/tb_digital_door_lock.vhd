library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_digital_door_lock is
end tb_digital_door_lock;

architecture tb of tb_digital_door_lock is

    component digital_door_lock
        port (clk              : in std_logic;
              reset            : in std_logic;
              digit_input      : in std_logic_vector (15 downto 0);
              btn_enter        : in std_logic;
              btn_next         : in std_logic;
              btn_program      : in std_logic;
              btn_override     : in std_logic;
              led_correct      : out std_logic;
              led_wrong        : out std_logic;
              led_program_mode : out std_logic;
              led_locked       : out std_logic;
              seg              : out std_logic_vector (6 downto 0);
              an               : out std_logic_vector (7 downto 0));
    end component;

    signal clk              : std_logic := '0';
    signal reset            : std_logic := '0';
    signal digit_input      : std_logic_vector (15 downto 0) := (others => '0');
    signal btn_enter        : std_logic := '0';
    signal btn_next         : std_logic := '0';
    signal btn_program      : std_logic := '0';
    signal btn_override     : std_logic := '0';
    signal led_correct      : std_logic;
    signal led_wrong        : std_logic;
    signal led_program_mode : std_logic;
    signal led_locked       : std_logic;
    signal seg              : std_logic_vector (6 downto 0);
    signal an               : std_logic_vector (7 downto 0);

    constant TbPeriod : time := 10 ns; 

begin

    dut : digital_door_lock
    port map (clk              => clk,
              reset            => reset,
              digit_input      => digit_input,
              btn_enter        => btn_enter,
              btn_next         => btn_next,
              btn_program      => btn_program,
              btn_override     => btn_override,
              led_correct      => led_correct,
              led_wrong        => led_wrong,
              led_program_mode => led_program_mode,
              led_locked       => led_locked,
              seg              => seg,
              an               => an);

    clk_process : process
    begin
        clk <= '0';
        wait for TbPeriod / 2;
        clk <= '1';
        wait for TbPeriod / 2;
    end process;

    stim_proc: process
    begin
        -- 1. Reset--------------------------------------------------------------------------------
        reset <= '1';
        digit_input <= (others => '0');
        btn_enter <= '0';
        btn_next <= '0';
        btn_program <= '0';
        btn_override <= '0';
        wait for 100 ns;
        
        reset <= '0';
        wait for 100 ns;

        -- 2. Override--------------------------------------------------------------------------------
        btn_override <= '1';
        wait for 50 ns;
        btn_override <= '0';
        
        wait for 200 ns;
        
        btn_enter <= '1'; wait for 20 ns; btn_enter <= '0'; 
        wait for 100 ns;

        -- 3. Basic doorlock + autolock--------------------------------------------------------------------------------
        btn_next <= '1'; wait for 20 ns; btn_next <= '0';
        wait for 50 ns;

        digit_input <= x"1234";
        wait for 20 ns; 
        btn_next <= '1'; wait for 20 ns; btn_next <= '0';
        wait for 50 ns;

        digit_input <= x"5678";
        wait for 20 ns; 
        btn_enter <= '1'; wait for 20 ns; btn_enter <= '0';

        wait for 2000 ns; 

        -- Password salah --------------------------------------------------------------------------------
        btn_next <= '1'; wait for 20 ns; btn_next <= '0';
        wait for 50 ns;

        digit_input <= x"5678";
        wait for 20 ns;
        btn_next <= '1'; wait for 20 ns; btn_next <= '0'; 
        wait for 50 ns;

        digit_input <= x"1234";
        wait for 20 ns;
        btn_enter <= '1'; wait for 20 ns; btn_enter <= '0'; 

        wait for 300 ns; 

        btn_enter <= '1'; wait for 20 ns; btn_enter <= '0';
        wait for 100 ns;


        -- 4. Ganti Password 4444 5555 --------------------------------------------------------------------------------
        btn_program <= '1'; wait for 20 ns; btn_program <= '0';
        wait for 50 ns;

        digit_input <= x"4444"; 
        wait for 20 ns;         
        btn_next <= '1'; wait for 20 ns; btn_next <= '0'; 
        wait for 50 ns;

        digit_input <= x"5555"; 
        wait for 20 ns;         
        btn_enter <= '1'; wait for 20 ns; btn_enter <= '0'; 
        wait for 100 ns;

        -- 5. Verifikasi Password Baru--------------------------------------------------------------------------------
        btn_next <= '1'; wait for 20 ns; btn_next <= '0';
        wait for 50 ns;

        digit_input <= x"4444"; 
        wait for 20 ns;         
        btn_next <= '1'; wait for 20 ns; btn_next <= '0'; 
        wait for 50 ns;

        digit_input <= x"5555"; 
        wait for 20 ns;         
        btn_enter <= '1'; wait for 20 ns; btn_enter <= '0'; 

        wait for 200 ns;

        wait;
    end process;

end tb;
