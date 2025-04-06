library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_tb is
end project_tb;

architecture projecttb of project_tb is
    constant c_CLOCK_PERIOD : time := 15 ns;
    signal tb_done : std_logic;
    signal mem_address : std_logic_vector(15 downto 0) := (others => '0');
    signal tb_rst : std_logic := '0';
    signal tb_start : std_logic := '0';
    signal tb_clk : std_logic := '0';
    signal mem_o_data, mem_i_data : std_logic_vector(7 downto 0);
    signal enable_wire : std_logic;
    signal mem_we : std_logic;
    
    type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
    signal RAM: ram_type;
    
    component project_reti_logiche is
        port (
            i_clk     : in std_logic;
            i_rst     : in std_logic;
            i_start   : in std_logic;
            i_add     : in std_logic_vector(15 downto 0);
            o_done    : out std_logic;
            o_mem_addr : out std_logic_vector(15 downto 0);
            i_mem_data : in std_logic_vector(7 downto 0);
            o_mem_data : out std_logic_vector(7 downto 0);
            o_mem_we   : out std_logic;
            o_mem_en   : out std_logic
        );
    end component project_reti_logiche;
    
begin
    UUT: project_reti_logiche
    port map (
        i_clk      => tb_clk,
        i_rst      => tb_rst,
        i_start    => tb_start,
        i_add      => mem_address,
        o_done     => tb_done,
        o_mem_addr => mem_address,
        i_mem_data => mem_o_data,
        o_mem_data => mem_i_data,
        o_mem_we   => mem_we,
        o_mem_en   => enable_wire
    );

    -- Clock process
    p_CLK : process
    begin
        tb_clk <= '0';
        wait for c_CLOCK_PERIOD/2;
        tb_clk <= '1';
        wait for c_CLOCK_PERIOD/2;
    end process;
    
    -- Memoria RAM
    process (tb_clk)
    begin
        if tb_clk'event and tb_clk = '1' then
            if enable_wire = '1' then
                if mem_we = '1' then
                    RAM(to_integer(unsigned(mem_address))) <= mem_i_data;
                    mem_o_data <= mem_i_data after 1 ns;
                else
                    mem_o_data <= RAM(to_integer(unsigned(mem_address))) after 1 ns;
                end if;
            end if;
        end if;
    end process;

    -- Test case 1: Filtro di ordine 3
    test_case_1 : process
    begin
        -- Reset
        wait for 100 ns;
        tb_rst <= '1';
        wait for 10 ns;
        tb_rst <= '0';
        wait for 10 ns;
        
        -- Preparazione dati di test
        -- K1, K2 = 0, 9 (lunghezza 9)
        RAM(0) <= "00000000";  -- K1 = 0
        RAM(1) <= "00001001";  -- K2 = 9
        -- S = 0 (filtro ordine 3)
        RAM(2) <= "00000000";  -- S = 0
        -- Coefficienti (non utilizzati direttamente nel codice, ma presenti nella memoria)
        RAM(3) <= "00000000";  -- C1
        RAM(4) <= "00000000";  -- C2
        RAM(5) <= "00000000";  -- C3
        RAM(6) <= "00000000";  -- C4
        RAM(7) <= "00000000";  -- C5
        RAM(8) <= "00000000";  -- C6
        RAM(9) <= "00000000";  -- C7
        RAM(10) <= "00000000"; -- C8
        RAM(11) <= "00000000"; -- C9
        RAM(12) <= "00000000"; -- C10
        RAM(13) <= "00000000"; -- C11
        RAM(14) <= "00000000"; -- C12
        RAM(15) <= "00000000"; -- C13
        RAM(16) <= "00000000"; -- C14
        
        -- Dati da elaborare
        RAM(17) <= "01100101"; -- +101
        RAM(18) <= "10101010"; -- -86
        RAM(19) <= "11110100"; -- -12
        RAM(20) <= "00101001"; -- +41
        RAM(21) <= "01010111"; -- +87
        RAM(22) <= "10000101"; -- -123
        RAM(23) <= "10000001"; -- -127
        RAM(24) <= "01010111"; -- +87
        RAM(25) <= "01101100"; -- +108
        
        -- Avvio test
        wait for 10 ns;
        tb_start <= '1';
        mem_address <= "0000000000000000";
        wait until tb_done = '1';
        wait for 10 ns;
        tb_start <= '0';
        wait until tb_done = '0';
        
        -- Verifica risultati
        wait for 100 ns;
        
        -- Test case 2: Filtro di ordine 5
        -- Reset
        wait for 100 ns;
        tb_rst <= '1';
        wait for 10 ns;
        tb_rst <= '0';
        wait for 10 ns;
        
        -- Preparazione dati di test
        -- K1, K2 = 0, 9 (lunghezza 9)
        RAM(100) <= "00000000";  -- K1 = 0
        RAM(101) <= "00001001";  -- K2 = 9
        -- S = 1 (filtro ordine 5)
        RAM(102) <= "00000001";  -- S = 1
        -- Coefficienti (non utilizzati direttamente nel codice, ma presenti nella memoria)
        RAM(103) <= "00000000";  -- C1
        RAM(104) <= "00000000";  -- C2
        RAM(105) <= "00000000";  -- C3
        RAM(106) <= "00000000";  -- C4
        RAM(107) <= "00000000";  -- C5
        RAM(108) <= "00000000";  -- C6
        RAM(109) <= "00000000";  -- C7
        RAM(110) <= "00000000";  -- C8
        RAM(111) <= "00000000";  -- C9
        RAM(112) <= "00000000";  -- C10
        RAM(113) <= "00000000";  -- C11
        RAM(114) <= "00000000";  -- C12
        RAM(115) <= "00000000";  -- C13
        RAM(116) <= "00000000";  -- C14
        
        -- Dati da elaborare (stessi dati del test 1)
        RAM(117) <= "01100101"; -- +101
        RAM(118) <= "10101010"; -- -86
        RAM(119) <= "11110100"; -- -12
        RAM(120) <= "00101001"; -- +41
        RAM(121) <= "01010111"; -- +87
        RAM(122) <= "10000101"; -- -123
        RAM(123) <= "10000001"; -- -127
        RAM(124) <= "01010111"; -- +87
        RAM(125) <= "01101100"; -- +108
        
        -- Avvio test
        wait for 10 ns;
        tb_start <= '1';
        mem_address <= "0000000001100100"; -- 100 in binario
        wait until tb_done = '1';
        wait for 10 ns;
        tb_start <= '0';
        wait until tb_done = '0';
        
        -- Fine test
        wait for 100 ns;
        assert false report "Simulation Ended!" severity failure;
    end process;

end projecttb;
