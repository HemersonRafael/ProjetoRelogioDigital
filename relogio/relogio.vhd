library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
entity relogio is
	port( 
	  clockIn, mode, set, reset, startStop, conf : in  std_logic; -- ClockIn e uma entrada 50MHz
	  --modeAtivo					 							: in  std_logic_vector(1 downto 0); -- estado do botao
	  
	  unidade_Minutos, dezena_Minutos : out std_logic_vector(3 downto 0);
	  unidade_Horas, dezena_Horas		 : out std_logic_vector(3 downto 0);
	  
	  DisplayUnidadeSegundos 							: out std_logic_vector(6 downto 0);
	  DisplayDezenaSegundos  							: out std_logic_vector(6 downto 0);
	  DisplayUnidadeMinutos	 							: out std_logic_vector(6 downto 0);
	  DisplayDezenaMinutos 	 							: out std_logic_vector(6 downto 0);
	  DisplayUnidadeHoras	 							: out std_logic_vector(6 downto 0);
	  DisplayDezenaHoras   	 							: out std_logic_vector(6 downto 0);
	  DisplayHEX0   	 		 							: out std_logic_vector(6 downto 0);
	  DisplayHEX1   	 		 							: out std_logic_vector(6 downto 0)
	);
end relogio;
 
architecture hardware of relogio is

	component conversor_7seg is
		port(
		  entrada	: in  std_logic_vector (3 downto 0);  -- vetor de entrada com 4 bits
		  segmentos	: out std_logic_vector (6 downto 0)-- vetor de saida que vai receber o valor de entrada representando em 7 bits
		);
	end component;
	
	signal clockOutDF 							: std_logic 					 	 := '0';
	signal unidadeSegundos, dezenaSegundos	: std_logic_vector(3 downto 0) := "1111";
	signal unidadeMinutos, dezenaMinutos	: std_logic_vector(3 downto 0) := "1111";
	signal unidadeHoras, dezenaHoras			: std_logic_vector(3 downto 0) := "1111";
	
	begin
	  
	  --Divisor de frequencia de 50 MHz para 1 Hz.
		DF : process(clockIn)
			variable contagem : integer := 1;
			begin
				if(clockIn'event and clockIn='1' ) then
					contagem := contagem + 1;
					if(contagem = 250000) then
					  clockOutDF <= not clockOutDF;
					  contagem := 1;
					end if;
				end if;
		end process DF;
	  
	   -- Contador de horas, minutos e segundos
		CONTADOR_HMS : process(clockOutDF, mode, set, reset, startStop)   -- Periodo de 1 segundo.
			variable contSegundos, contMinutos, contHoras 	: integer range 0 to 60		:= 0;
			variable contDecSegundos 							 	: integer range 0 to 100 	:= 0;
			variable contBlink 							 			: integer range 0 to 1000 	:= 0;
			variable quocienteDecSegundos, restoDecSegundo	: integer range 0 to 9 		:= 0;
			variable quocienteSegundos, restoSegundo			: integer range 0 to 9 		:= 0;
			variable quocienteMinutos, restoMinutos			: integer range 0 to 9 		:= 0;
			variable quocienteHoras, restoHoras 				: integer range 0 to 9  	:= 0;
			variable estadoSet 										: integer range 0 to 2  	:= 0;
			
			begin			
				if(clockOutDF'event and clockOutDF='1') then
					contDecSegundos := contDecSegundos + 1;
					contBlink := contBlink + 1;
					if(contDecSegundos = 1000) then
						contBlink := 0;
					end if;
					if(contDecSegundos = 100)	then
						contDecSegundos := 0;
						contSegundos := contSegundos + 1;
						if(contSegundos = 60) then
							contSegundos := 0;
							contMinutos := contMinutos + 1;
							if(contMinutos = 60) then
								contHoras := contHoras + 1;
								contMinutos := 0;
								if(contHoras = 24) then
									contHoras := 0;
								end if;
							end if;
						end if;
					end if;
					
					if(conf = '1' and (contBlink rem 2)/= 0) then
							
							if(set = '0') then
								estadoSet := estadoSet + 1;
							end if;
							
							if(estadoSet = 0) then
								unidadeHoras	 <= "1111";
								dezenaHoras		 <= "1111";
								if(startStop = '0') then
									contHoras := contHoras + 1;
								end if;
								if(contHoras = 23 or reset = '0') then
									contHoras :=  0;
								end if;
								
							elsif(estadoSet = 1) then
								unidadeMinutos	 <= "1111";
								dezenaMinutos	 <= "1111";
								if(startStop = '0') then
									contMinutos := contMinutos + 1;
								end if;
								if(contMinutos = 59 or reset = '0') then
									contMinutos :=  0;
								end if;
								
							elsif(estadoSet = 2) then
								estadoSet := 0;
							end if;
						
					else
						estadoSet := 0;
						-- Processo abaixo e utilizado para extrair de um numero inteiro sua dezena e unidade
						quocienteSegundos := contSegundos/10;
						restoSegundo 		:= contSegundos rem 10; -- rem retorna o resto de divisao
						
						quocienteMinutos	:= contMinutos/10;
						restoMinutos		:= contMinutos rem 10;
						
						quocienteHoras		:= contHoras/10;
						restoHoras			:= contHoras rem 10;
						
						-- Processo abaixo e utilizado para converte inteiros para vetores de 4 bits
						unidadeSegundos	<= conv_std_logic_vector(restoSegundo, 4); -- conv_std_logic_vector realiza a conversao de inteiro para um vetor de bits
						dezenaSegundos 	<= conv_std_logic_vector(quocienteSegundos, 4);
						
						unidadeMinutos		<= conv_std_logic_vector(restoMinutos, 4);
						dezenaMinutos 		<= conv_std_logic_vector(quocienteMinutos, 4);
						
						unidadeHoras 		<= conv_std_logic_vector(restoHoras, 4);
						dezenaHoras 		<= conv_std_logic_vector(quocienteHoras, 4);
						
					end if;
				end if;
		end process CONTADOR_HMS;
		
		-- O conversor de 7 segmentos e utilizado para mutplaxacao de 4 bits para 7 bits 
		C7SUS: conversor_7seg port map(unidadeSegundos, DisplayUnidadeSegundos);
		C7SDS: conversor_7seg port map(dezenaSegundos, DisplayDezenaSegundos);
		
		C7SUM: conversor_7seg port map(unidadeMinutos, DisplayUnidadeMinutos);
		C7SDM: conversor_7seg port map(dezenaMinutos, DisplayDezenaMinutos);
		
		C7SUH: conversor_7seg port map(unidadeHoras, DisplayUnidadeHoras);
		C7SDH: conversor_7seg port map(dezenaHoras, DisplayDezenaHoras);
		
		DisplayHEX0 <= "1111111";
		DisplayHEX1 <= "1111111";
		
		unidade_Minutos <= unidadeMinutos;
		dezena_Minutos	 <= dezenaSegundos; 	
	   unidade_Horas   <= unidadeHoras; 
		dezena_Horas	 <= dezenaHoras;
 end hardware;