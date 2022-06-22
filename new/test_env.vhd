library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

entity test_env is
  Port ( clk : in std_logic;
         sw : in std_logic_vector(15 downto 0);
         led : out std_logic_vector(15 downto 0);
         cat : out std_logic_vector(6 downto 0);
         an : out std_logic_vector(3 downto 0);
         btn : in std_logic_vector(4 downto 0)
  );
end test_env;

architecture Behavioral of test_env is

--semnale de control
signal zero, lzero, regDst, extOp, ALUSrc, branch, jump, memWrite, memToReg, regWrite, PCSrc : std_logic;
signal ALUOp : std_logic_vector(2 downto 0);

--semnal de activare semnale de control
signal instrToUC : std_logic_vector(5 downto 0);

--instructiunea
signal instruction : std_logic_vector(15 downto 0);

--adresa urmatoare, rezultatul ALU, citirea din memorie, etc
signal nextAddress, ALURes, memData, branchAddress, jumpAddress, afis : std_logic_vector(15 downto 0);

--semnale muxuri
signal muxWa : std_logic_vector(2 downto 0);
--semnale butoane
   signal q, en1, en2 : std_logic := '0' ;

--semnale de scriere / iesire din regFile    
signal wd, rd1, rd2: std_logic_vector(15 downto 0) := "0000000000000000";

--semnal de extins
signal extTo : std_logic_vector(15 downto 0);

--declarare componente
component MPG is
Port ( en : out STD_LOGIC;
       input : in STD_LOGIC;
       clk : in STD_LOGIC);
end component;

component ssd is
port(
    sw : in std_logic_vector(15 downto 0);
    an : out std_logic_vector(3 downto 0);
    cat : out std_logic_vector(6 downto 0);
    clk : in std_logic
    );
end component;

component counter16biti is
port(
    clk : in std_logic;
    sw : in std_logic;
    led : out std_logic_vector(15 downto 0)
    );
end component;

component ALU is
port(
    rd1, rd2, extImm : in std_logic_vector(15 downto 0);
    ALUOp : in std_logic_vector(2 downto 0);
    ALUSrc : in std_logic;
    zero, lzero : out std_logic;
    ALURes : out std_logic_vector(15 downto 0)
    );
end component;

component rom_memory is
  Port (
         sw0 : in std_logic;
         led0 : out std_logic_vector(15 downto 0);
         btn0 : in std_logic
  );
end component;

component MEM is
  Port ( 
  memWrite, clk : in std_logic;
  ALURes, rd2 : in std_logic_vector(15 downto 0);
  memData : out std_logic_vector(15 downto 0)
  );
end component;


component reg_file is
  Port ( clk, we : in std_logic;
        ra1, ra2, wa : in std_logic_vector(2 downto 0);
        wd : in std_logic_vector(15 downto 0);
        rd1, rd2 : out std_logic_vector(15 downto 0)
  );
end component;

component instructionFetch is
Port (
    jumpAddress : in std_logic_vector(15 downto 0);
    branchAddress : in std_logic_vector(15 downto 0);
    PCSrc, jump, clk : in std_logic;
    PC1 : out std_logic_vector(15 downto 0);
    instruction : out std_logic_vector(15 downto 0)
  );
end component;

component UC is
port(
    instr : in std_logic_vector(5 downto 0);
    zero, lzero : in std_logic;
    regDst, ALUSrc, branch, jump, memWrite, memToReg, regWrite : out std_logic;
    ALUOp : out std_logic_vector(2 downto 0)
);
end component;

component afisare is
  Port ( 
  sel: in std_logic_vector(2 downto 0);
  instruction, nextAddress, rd1, rd2, ext, ALURes, memData, wd : in std_logic_vector(15 downto 0);
  afisare : out std_logic_vector(15 downto 0));
end component;

begin

--componente mari

   component1MPG : MPG port map(en => en1, input => btn(0), clk => clk);
   componentSSD : ssd port map(sw => afis, an =>an, cat =>cat, clk =>clk);
   componentUC : UC port map(instr => instrToUC, zero => zero, lzero => lzero, regDst => regDst, ALUSrc => ALUSrc, branch => branch, jump => jump, memWrite => memWrite, memToReg => memToReg, regWrite => regWrite, ALUOp => ALUOp);
   componentInstructions : instructionFetch port map(jumpAddress =>jumpAddress, branchAddress => branchAddress, PCSrc => PCSrc, jump => jump, clk =>en1, PC1 => nextAddress, instruction =>instruction);
   componentREGFILE: reg_file port map(clk =>clk, we => regWrite, ra1 => instruction(12 downto 10), ra2=>instruction(9 downto 7), wa =>muxWa, wd =>wd, rd1 =>rd1, rd2 =>rd2);
   componentALU: ALU port map(rd1 => rd1, rd2 => rd2, extImm => extTo, ALUOp => ALUOp, ALUSrc => ALUSrc, zero => zero, lzero =>lzero, ALURes => ALuRes);
   componentMEM: MEM port map(memWrite => memWrite, clk => clk, ALURes => ALURes, rd2 => rd2, memData => memData);
   componentAfisare: afisare port map(sel => sw(2 downto 0), instruction => instruction, nextAddress => nextAddress, rd1 => rd1, rd2 => rd2, ext => extTo, ALURes => ALURes, memData => memData, wd => wd, afisare => afis);
   
--componente simple - procese

    --mux to write address - ID
    process(regDst)
    begin
        if regDst = '0' then muxWa <= instruction(9 downto 7);
        else muxWa <= instruction(6 downto 4); end if;
    end process;
    
    --extUnit - ID
    process(extOp)
    begin
        if extOp = '0' then extTo <= "000000000" & instruction(6 downto 0);
            else extTo <= "111111111" & instruction(6 downto 0); end if;
    end process;
    
    --memToreg
    process(memToReg)
    begin
        if memToReg = '1' then wd <= memData;
        else wd <= ALURes; end if;
    end process;    
    
--atribuiri de semnale
    instrToUC(5 downto 3) <= instruction(15 downto 13);
    instrToUC(2 downto 0) <= instruction(2 downto 0);
    --led <= instruction;
    extOp <= instruction(6);
    branchAddress <= nextAddress + extTo;
    jumpAddress <= nextAddress(15 downto 13) & instruction(12 downto 0);
    PCSrc <= branch and (zero or lzero);
    
end Behavioral;
