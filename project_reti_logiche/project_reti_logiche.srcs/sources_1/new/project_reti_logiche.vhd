----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Students: Nicolò Spuri 10855846 244611, Ayoub Salim
-- 
-- Project Name: Prova Finale - Reti Logiche - 2024/25
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_add : in std_logic_vector(15 downto 0);

        o_done : out std_logic;

        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in  std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    -- Definizione degli stati della FSM
    type state_type is (
        IDLE,             -- Stato iniziale, attende START
        READ_K1,          -- Legge il primo byte della lunghezza K
        READ_K2,          -- Legge il secondo byte della lunghezza K
        READ_S,           -- Legge il byte S che indica l'ordine del filtro
        SET_COEFFS,      -- Setta i coefficienti del filtro
        READ_DATA,        -- Legge i dati da elaborare
        PROCESS_DATA,     -- Elabora i dati con il filtro
        WRITE_RESULTS,    -- Scrive i risultati in memoria
        DONE_STATE        -- Alza il segnale DONE e attende che START torni a 0
    );
    
    -- Segnali per gestire gli stati della FSM
    signal current_state, next_state : state_type;
    
    -- Segnali per gli indirizzi, per il numero di dati in input e per l'ordine del filtro
    signal base_address : unsigned(15 downto 0);
    signal current_address : unsigned(15 downto 0);
    signal k_length : unsigned(15 downto 0);
    signal filter_order : std_logic;  -- 0 per ordine 3, 1 per ordine 5
    
    -- Array per memorizzare i coefficienti del filtro
    type filter is array (0 to 6) of signed(7 downto 0);
    signal filter_coeffs : filter;
    
    -- Array per memorizzare i dati letti e quelli elaborati
    type data_array is array (0 to 65535) of signed(7 downto 0);
    signal input_data : data_array;
    signal output_data : data_array;
    
    -- Segnali di conteggio per il controllo del processo
    signal coeff_counter : integer range 0 to 14;
    signal data_counter : integer range 0 to 65535;
    signal process_counter : integer range 0 to 65535;
    signal write_counter : integer range 0 to 65535;
    
begin

    -- Processo per gestire il reset e il cambio di stato
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            current_state <= IDLE;
        elsif rising_edge(i_clk) then
            current_state <= next_state;
        end if;
    end process;
    
    -- Processo per individuare lo stato prossimo
    process(current_state, i_start, data_counter, process_counter, write_counter, coeff_counter, k_length)
    begin
        -- Per evitare cambi di stato non voluti
        next_state <= current_state;
        
        case current_state is
            when IDLE =>
                if i_start = '1' then
                    next_state <= READ_K1;
                end if;
                
            when READ_K1 =>
                next_state <= READ_K2;
                
            when READ_K2 =>
                next_state <= READ_S;
                
            when READ_S =>
                next_state <= SET_COEFFS;
                
            when SET_COEFFS =>
                if coeff_counter = 14 then
                    next_state <= READ_DATA;
                end if;
                
            when READ_DATA =>
                if data_counter = to_integer(k_length) then
                    next_state <= PROCESS_DATA;
                end if;
                
            when PROCESS_DATA =>
                if process_counter = to_integer(k_length) then
                    next_state <= WRITE_RESULTS;
                end if;
                
            when WRITE_RESULTS =>
                if write_counter = to_integer(k_length) then
                    next_state <= DONE_STATE;
                end if;
                
            when DONE_STATE =>
                if i_start = '0' then
                    next_state <= IDLE;
                end if;        
        end case;
    end process;
    
    -- Processo per l'elaborazione dei dati
    process(i_clk, i_rst)
        variable temp_result : signed(31 downto 0) := (others => '0');
        variable normalized_result : signed(7 downto 0) := (others => '0');   
    begin
        if i_rst = '1' then
            -- Reset dei segnali
            base_address <= (others => '0');
            current_address <= (others => '0');
            k_length <= (others => '0');
            filter_order <= '0';
            coeff_counter <= 0;
            data_counter <= 0;
            process_counter <= 0;
            write_counter <= 0;
            o_done <= '0';
            o_mem_we <= '0';
            o_mem_en <= '0';
            o_mem_addr <= (others => '0');
            o_mem_data <= (others => '0');
   
            
            -- Reset degli array
            for i in 0 to 6 loop
                filter_coeffs(i) <= (others => '0');
            end loop;
            
            for i in 0 to 65535 loop
                input_data(i) <= (others => '0');
                output_data(i) <= (others => '0');
            end loop;
            
        elsif rising_edge(i_clk) then
            -- Valori di default
            o_mem_we <= '0';
            o_mem_en <= '0';
            
            case current_state is
                when IDLE =>
                    -- Salva l'indirizzo iniziale e setta a 1 il segnale di accesso alla memoria
                    o_done <= '0';
                    if i_start = '1' then
                        base_address <= unsigned(i_add);
                        current_address <= unsigned(i_add);
                        o_mem_addr <= i_add;
                        o_mem_en <= '1';
                    end if;
                    
                when READ_K1 =>
                    -- Legge il primo byte per calcolare la lunghezza K e lo salva nelle prime 8 posizioni di k_lenght
                    k_length(15 downto 8) <= unsigned(i_mem_data);
                    current_address <= current_address + 1;
                    o_mem_addr <= std_logic_vector(current_address + 1);
                    o_mem_en <= '1';
                    
                when READ_K2 =>
                    -- Legge il secondo byte per calcolare la lunghezza K e lo salva nelle ultime 8 posizioni di k_lenght
                    k_length(7 downto 0) <= unsigned(i_mem_data);
                    current_address <= current_address + 1;
                    o_mem_addr <= std_logic_vector(current_address + 1);
                    o_mem_en <= '1';
                    
                when READ_S =>
                    -- Legge il byte S che indica l'ordine del filtro e salva in filter_order solo il bit meno significativo
                    filter_order <= i_mem_data(0);
                    current_address <= current_address + 1;
                    o_mem_addr <= std_logic_vector(current_address + 1);
                    o_mem_en <= '1';
                    coeff_counter <= 0;
                    
                when SET_COEFFS =>
                    -- Setta i coefficienti del filtro in base al valore del bit meno significativo S ('0' ordine 3
                    if filter_order = '0' then
                        -- Filtro di ordine 3: c=[0, -1, 8, 0, -8, 1, 0]
                        case coeff_counter is
                            when 0 =>
                                filter_coeffs(0) <= signed(i_mem_data);
                            when 1 =>
                                filter_coeffs(1) <= signed(i_mem_data);
                            when 2 =>
                                filter_coeffs(2) <= signed(i_mem_data);
                            when 3 =>
                                filter_coeffs(3) <= signed(i_mem_data);
                            when 4 =>
                                filter_coeffs(4) <= signed(i_mem_data);
                            when 5 =>
                                filter_coeffs(5) <= signed(i_mem_data);
                            when 6 =>
                                filter_coeffs(6) <= signed(i_mem_data);
                            when others =>
                                null;
                        end case;
                    else
                        -- Filtro di ordine 5: c=[1, -9, 45, 0, -45, 9,-1]
                        case coeff_counter is
                            when 0 =>
                                filter_coeffs(0) <= signed(i_mem_data);
                            when 1 =>
                                filter_coeffs(1) <= signed(i_mem_data);
                            when 2 =>
                                filter_coeffs(2) <= signed(i_mem_data);
                            when 3 =>
                                filter_coeffs(3) <= signed(i_mem_data);
                            when 4 =>
                                filter_coeffs(4) <= signed(i_mem_data);
                            when 5 =>
                                filter_coeffs(5) <= signed(i_mem_data);
                            when 6 =>
                                filter_coeffs(6) <= signed(i_mem_data);
                            when others =>
                                null;
                        end case;
                    end if;
                    
                    -- Scorri i contatori
                    if coeff_counter < 14 then
                        coeff_counter <= coeff_counter + 1;
                        current_address <= current_address + 1;
                        o_mem_addr <= std_logic_vector(current_address + 1);
                        o_mem_en <= '1';
                    end if;
                    
                    -- Se sei arrivato all'ultimo coefficiente, inizializza il contatore dei dati da leggere
                    if coeff_counter = 13 then
                        data_counter <= 0;
                    end if;
                    
                when READ_DATA =>
                    -- Legge i dati da elaborare e scorri i contatori
                    input_data(data_counter) <= signed(i_mem_data);
                    data_counter <= data_counter + 1;
                    current_address <= current_address + 1;
                    o_mem_addr <= std_logic_vector(current_address + 1);
                    o_mem_en <= '1';
                    
                    if data_counter = to_integer(k_length) - 1 then
                        process_counter <= 0;
                    end if;
                    
                when PROCESS_DATA =>
                    -- Elabora i dati con il filtro
                    temp_result := (others => '0');
                    normalized_result := (others => '0');
                                        
                    for i in 0 to 6 loop
                        if process_counter + i - 3 < 0 or process_counter + i - 3 >= to_integer(k_length) then
                            -- Fuori dai limiti, usa 0
                            temp_result := temp_result + filter_coeffs(i) * 0;
                        else
                            temp_result := temp_result + filter_coeffs(i) * input_data(process_counter + i - 3);
                        end if;
                    end loop;
                    
                    if filter_order = '0' then
                        -- Filtro di ordine 3
                        -- 1/12 approssimato con 1/16 + 1/64 + 1/256 + 1/1024
                        if temp_result < 0 then
                            normalized_result := resize(shift_right(temp_result, 4) + 1, 8) + 
                                               resize(shift_right(temp_result, 6) + 1, 8) + 
                                               resize(shift_right(temp_result, 8) + 1, 8) + 
                                               resize(shift_right(temp_result, 10) + 1, 8);
                        else
                            normalized_result := resize(shift_right(temp_result, 4), 8) + 
                                               resize(shift_right(temp_result, 6), 8) + 
                                               resize(shift_right(temp_result, 8), 8) + 
                                               resize(shift_right(temp_result, 10), 8);
                        end if;
                    
                    else
                        -- Filtro di ordine 5
                        -- 1/60 approssimato con 1/64 + 1/1024
                        if temp_result < 0 then
                            normalized_result := resize(shift_right(temp_result, 6) + 1, 8) + 
                                               resize(shift_right(temp_result, 10) + 1, 8);
                        else
                            normalized_result := resize(shift_right(temp_result, 6), 8) + 
                                               resize(shift_right(temp_result, 10), 8);
                        end if;
                    end if;
                    
                    -- Saturazione
                    if normalized_result > 127 then
                        output_data(process_counter) <= to_signed(127, 8);
                    elsif normalized_result < -128 then
                        output_data(process_counter) <= to_signed(-128, 8);
                    else
                        output_data(process_counter) <= normalized_result;
                    end if;
                    
                    process_counter <= process_counter + 1;
                    
                    if process_counter = to_integer(k_length) - 1 then
                        write_counter <= 0;
                        current_address <= base_address + 17 + k_length;
                    end if;
                    
                when WRITE_RESULTS =>
                    -- Scrive i risultati in memoria
                    o_mem_we <= '1';
                    o_mem_en <= '1';
                    o_mem_addr <= std_logic_vector(current_address);
                    o_mem_data <= std_logic_vector(output_data(write_counter));
                    
                    write_counter <= write_counter + 1;
                    current_address <= current_address + 1;
                    
                when DONE_STATE =>
                    o_done <= '1';
                    
            end case;
        end if;
    end process;
end Behavioral;
