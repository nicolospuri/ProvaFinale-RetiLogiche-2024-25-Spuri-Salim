----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Students: Nicol� Spuri 10855846 244611, Ayoub Salim
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
        IDLE,             -- Stato iniziale, attende START e setta gli indirizzi iniziali
        READ_K1,          -- Legge il primo byte della lunghezza K
        READ_K2,          -- Legge il secondo byte della lunghezza K
        READ_S,           -- Legge il byte S che indica l'ordine del filtro
        READ_COEFFS,      -- Legge i coefficienti del filtro
        READ_DATA,        -- Legge i dati da elaborare
        PROCESS_DATA,     -- Elabora i dati con il filtro
        WRITE_RESULTS,    -- Scrive i risultati in memoria
        DONE_STATE        -- Alza il segnale DONE e attende che START torni a 0
    );
    
    -- Segnali per gestire gli stati della FSM
    signal current_state, next_state : state_type;
    
    -- Segnali per gli indirizzi, per il numero di dati in input e per l'ordine del filtro
    signal base_address             : unsigned(15 downto 0);
    signal current_read_address     : unsigned(15 downto 0);
    signal current_write_address    : unsigned(15 downto 0);
    signal k_length                 : unsigned(15 downto 0);
    signal filter_order             : std_logic;                -- 0 per ordine 3, 1 per ordine 5
    signal output_data              : signed(7 downto 0);
    
    -- Array per memorizzare i coefficienti del filtro
    type data is array (0 to 6) of signed(7 downto 0);
    signal filter_coeffs    : data;
    signal input_data       : data;
    
    -- Segnali di conteggio per il controllo del processo
    signal idle_wait        : std_logic;
    signal coeff_counter    : integer range 0 to 14;
    signal data_counter     : integer range 0 to 7;
    signal read_wait        : std_logic;
    signal write_done       : std_logic;   
    
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
    process(current_state, i_start, idle_wait, data_counter, coeff_counter, k_length, read_wait, write_done)
    begin
        -- Per evitare cambi di stato non voluti
        next_state <= current_state;
        
        case current_state is
            when IDLE =>
                if i_start = '1' and idle_wait = '1' then
                    next_state <= READ_K1;
                end if;
            
            when READ_K1 =>
                next_state <= READ_K2;
                
            when READ_K2 =>
                next_state <= READ_S;
                
            when READ_S =>
                next_state <= READ_COEFFS;
                
            when READ_COEFFS =>
                if coeff_counter = 13 then
                    next_state <= READ_DATA;
                end if;
                
            when READ_DATA =>
                if data_counter = 6 then
                    next_state <= PROCESS_DATA;
                end if;
                
            when PROCESS_DATA =>
                next_state <= WRITE_RESULTS;
                
            when WRITE_RESULTS =>
                if read_wait = '1' then
                    next_state <= READ_DATA;
                end if;
                if current_write_address = base_address + 17 + k_length + k_length then
                    next_state <= DONE_STATE;
                end if;
                
            when DONE_STATE =>
                if i_start = '0' then
                    next_state <= IDLE;
                end if;
                
            when others =>
                null;   
                
        end case;
    end process;
    
    -- Processo per l'elaborazione dei dati
    process(i_clk, i_rst)
        variable temp_result        : signed(23 downto 0) := (others => '0');
        variable normalized_result  : signed(23 downto 0) := (others => '0');   
    begin
        if i_rst = '1' then
            -- Reset dei segnali
            base_address <= (others => '0');
            current_read_address <= (others => '0');
            current_write_address <= (others => '0');
            k_length <= (others => '0');
            filter_order <= '0';
            output_data <= (others => '0');

            -- Reset dei contatori
            idle_wait <= '0';
            coeff_counter <= 0;
            data_counter <= 0;
            read_wait <= '0';
            write_done <= '0';

            -- Reset degli array
            filter_coeffs <= (others => ( others => '0'));
            input_data <= (others => ( others => '0'));
            
            -- Reset dei sengnali per la memoria e per il tb
            o_done <= '0';
            o_mem_we <= '0';
            o_mem_en <= '0';
            o_mem_addr <= (others => '0');
            o_mem_data <= (others => '0');  
            
        elsif rising_edge(i_clk) then
            -- Valori di default
            o_mem_we <= '0';
            o_mem_en <= '0';
            
            case current_state is
                when IDLE =>
                    -- Salva l'indirizzo iniziale e setta a 1 il segnale di accesso alla memoria
                    o_done <= '0';
                    if i_start = '1' then
                        if idle_wait = '0' then
                            base_address <= unsigned(i_add);
                            current_read_address <= unsigned(i_add);
                            o_mem_addr <= i_add;
                            idle_wait <= '1';
                        else
                            current_read_address <= current_read_address + 1;
                            o_mem_addr <= std_logic_vector(current_read_address + 1);
                            idle_wait <= '0';
                        end if;
                        o_mem_en <= '1';

                    end if;
                    
                when READ_K1 =>
                    -- Legge il primo byte per calcolare la lunghezza K e lo salva nelle prime 8 posizioni di k_lenght
                    k_length(15 downto 8) <= unsigned(i_mem_data);
                    current_read_address <= current_read_address + 1;
                    o_mem_addr <= std_logic_vector(current_read_address + 1);
                    o_mem_en <= '1';
                    
                when READ_K2 =>
                    -- Legge il secondo byte per calcolare la lunghezza K e lo salva nelle ultime 8 posizioni di k_lenght
                    k_length(7 downto 0) <= unsigned(i_mem_data);
                    current_read_address <= current_read_address + 1;
                    o_mem_addr <= std_logic_vector(current_read_address + 1);
                    o_mem_en <= '1';
                    
                when READ_S =>
                    -- Legge il byte S che indica l'ordine del filtro e salva in filter_order solo il bit meno significativo
                    current_write_address <= base_address + 17 + k_length;
                    filter_order <= i_mem_data(0);
                    current_read_address <= current_read_address + 1;
                    o_mem_addr <= std_logic_vector(current_read_address + 1);
                    o_mem_en <= '1';
                    coeff_counter <= 0;
                    
                when READ_COEFFS =>
                    -- Setta i coefficienti del filtro in base al valore del bit meno significativo S
                    --  '0' ordine 3, '1' ordine 5
                    if filter_order = '0' and coeff_counter < 7 then
                        filter_coeffs(coeff_counter) <= signed(i_mem_data);
                    elsif filter_order = '1' and coeff_counter > 6 then
                        filter_coeffs(coeff_counter - 7) <= signed(i_mem_data);
                    end if;
                    
                    coeff_counter <= coeff_counter + 1;
                    current_read_address <= current_read_address + 1;
                    o_mem_addr <= std_logic_vector(current_read_address + 1);
                    o_mem_en <= '1';
                    
                    if coeff_counter = 12 then
                        current_read_address <= current_read_address + 1 - 3;
                        o_mem_addr <= std_logic_vector(current_read_address + 1 - 3);
                    end if;
                    
                    -- Se sei arrivato all'ultimo coefficiente, inizializza il contatore dei dati da leggere
                    if coeff_counter = 13 then
                        data_counter <= 0;                      
                    end if;
                    
                when READ_DATA =>
                    -- Legge i dati da elaborare
                    if current_read_address - 1 < base_address + 17 OR current_read_address - 1 > base_address + 17 + k_length - 1 then  -- Caso oltre i limiti
                        input_data(data_counter) <= (others => '0');
                    else
                        input_data(data_counter) <= signed(i_mem_data);
                    end if; 
                        
                    data_counter <= data_counter + 1;
                    
                    -- Scorri l'indirizzo se non sei arrivato all'ultimo dei 7
                    if data_counter < 6 then
                        current_read_address <= current_read_address + 1;
                        o_mem_addr <= std_logic_vector(current_read_address + 1);
                        o_mem_en <= '1';
                    else
                        -- Se sei all'ultimo dato da leggere reimposta l'indirizzo
                        current_read_address <= current_read_address - 6;
                        read_wait <= '0';
                    end if;                
                    
                when PROCESS_DATA =>
                    -- Elabora i dati con il filtro
                    temp_result := (others => '0');
                    normalized_result := (others => '0');
                                        
                    for i in 0 to 6 loop
                        if filter_order = '0' AND (i = 0 OR i = 6) then   -- Se stai usando il filtro di ordine 3, non  considerare il primo e l'ultimo coefficiente
                            temp_result := temp_result + 0 * input_data(i);
                        else
                            temp_result := temp_result + filter_coeffs(i) * input_data(i);
                        end if;
                    end loop;
                    
                    if filter_order = '0' then
                        -- Filtro di ordine 3
                        -- 1/12 approssimato con 1/16 + 1/64 + 1/256 + 1/1024
                        if temp_result < 0 then
                            normalized_result := resize(shift_right(temp_result, 4) + 1, 24) + 
                                                 resize(shift_right(temp_result, 6) + 1, 24) + 
                                                 resize(shift_right(temp_result, 8) + 1, 24) + 
                                                 resize(shift_right(temp_result, 10) + 1, 24);
                        else
                            normalized_result := resize(shift_right(temp_result, 4), 24) + 
                                                 resize(shift_right(temp_result, 6), 24) + 
                                                 resize(shift_right(temp_result, 8), 24) + 
                                                 resize(shift_right(temp_result, 10), 24);
                        end if;
                    
                    else
                        -- Filtro di ordine 5
                        -- 1/60 approssimato con 1/64 + 1/1024
                        if temp_result < 0 then
                            normalized_result := resize(shift_right(temp_result, 6) + 1, 24) + 
                                                 resize(shift_right(temp_result, 10) + 1, 24);
                        else
                            normalized_result := resize(shift_right(temp_result, 6), 24) + 
                                                 resize(shift_right(temp_result, 10), 24);
                        end if;
                    end if;
                    
                    -- Saturazione
                    if normalized_result > 127 then
                        output_data <= to_signed(127, 8);
                    elsif normalized_result < -128 then
                        output_data <= to_signed(-128, 8);
                    else
                        output_data <= normalized_result(7 downto 0);
                    end if;
                    
                    write_done <= '0';
                    
                when WRITE_RESULTS =>
                    -- Scrive i risultati in memoria
                    if write_done = '0' then
                        o_mem_we <= '1';
                        o_mem_addr <= std_logic_vector(current_write_address);
                        o_mem_data <= std_logic_vector(output_data);
                        current_write_address <= current_write_address + 1;
                        write_done <= '1';
                    elsif read_wait = '0' AND current_write_address < base_address + 17 + k_length + k_length then                                                                         
                        -- Reimposta l'indirizzo per leggere i dati
                        o_mem_addr <= std_logic_vector(current_read_address);
                        read_wait <= '1';
                    elsif read_wait = '1' AND current_write_address < base_address + 17 + k_length + k_length then
                        -- Scorri dinuovo l'indirizzo per leggere i dati così lo stato READ_DATA può leggere subito il dato
                        o_mem_addr <= std_logic_vector(current_read_address + 1);
                        current_read_address <= current_read_address + 1;
                        data_counter <= 0;
                        read_wait <= '0';
                    end if;
                    o_mem_en <= '1';
                    
                when DONE_STATE =>
                    o_done <= '1';
                    
                when others =>
                    null;   
                     
            end case;
        end if;
    end process;
end Behavioral;
