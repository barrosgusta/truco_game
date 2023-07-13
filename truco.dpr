program Truco;

{$APPTYPE CONSOLE}

uses
  SysUtils, Dialogs,
  Windows;

const

  CARTA_STRING : array[1..40]of string = ('3 de Paus','3 de Copas','3 de Espadas','3 de Ouros',
                                          '2 de Paus','2 de Copas','2 de Espadas','2 de Ouros',
                                          'A, ¡Ås de Paus','A, ¡Ås de Copas','A, ¡sÅ de Espadas','A, ¡Ås de Ouros',
                                          'K, Rei de Paus','K, Rei de Copas','K, Rei de Espadas','K, Rei de Ouros',
                                          'J, Valete de Paus','J, Valete de Copas','J, Valete de Espadas','J, Valete de Ouros',
                                          'Q, Dama de Paus','Q, Dama de Copas','Q, Dama de Espadas','Q, Dama de Ouros',
                                          '7 de Paus','7 de Copas','7 de de Espadas','7 de Ouros',
                                          '6 de Paus','6 de Copas','6 de Espadas','6 de Ouros',
                                          '5 de Paus','5 de Copas','5 de Espadas','5 de Ouros',
                                          '4 de Paus','4 de Copas','4 de Espadas','4 de Ouros');

//N„o usado no momento
  NAIPE_PAUS    = 4;
  NAIPE_COPAS   = 3;
  NAIPE_ESPADAS = 2;
  NAIPE_OUROS   = 1;

type
	TCarta = record
		Nome         : string;
		Valor        : Smallint;
    Naipe        : SmallInt;
    isManilha    : Boolean;
    ManilhaValor : SmallInt;
	end;

	TBaralho = record
 		Carta    : array[1..40] of TCarta;
    QntCarta : Smallint;
 	end;

	TJogador = record
 		Carta    : array[1..3] of TCarta;
    Pontos   : SmallInt;
    QntCarta : Smallint;
 	end;

  TDisputa = record
    CartaJogador1 : TCarta;
    CartaJogador2 : TCarta;
  end;

  TRodada = record
    Disputa        : array[1..3] of TDisputa;
    Truco          : SmallInt; {1 = 3 pontos, 2 = 6 pontos, 3 = 9 pontos, 4 = 12}
    Jogador1Venceu : Smallint;
    Jogador2Venceu : SmallInt;
    Jogador1Correu : Boolean;
    Jogador2Correu : Boolean;
  end;

 	TMao = record
    Jogador  : array[1..2] of TJogador;
    Rodada      : array[1..24] of TRodada;
 		Vencedor : Smallint;
 	end;

	TPartida = record
		Mao   : array[1..3] of TMao;
		Vencedor : Smallint;
	end;

//MÈtodo que limpa a tela do cmd line (Ignorar)
procedure ClearScreen;
var
  stdout: THandle;
  csbi: TConsoleScreenBufferInfo;
  ConsoleSize: DWORD;
  NumWritten: DWORD;
  Origin: TCoord;
begin
  stdout := GetStdHandle(STD_OUTPUT_HANDLE);
  Win32Check(stdout<>INVALID_HANDLE_VALUE);
  Win32Check(GetConsoleScreenBufferInfo(stdout, csbi));
  ConsoleSize := csbi.dwSize.X * csbi.dwSize.Y;
  Origin.X := 0;
  Origin.Y := 0;
  Win32Check(FillConsoleOutputCharacter(stdout, ' ', ConsoleSize, Origin,
    NumWritten));
  Win32Check(FillConsoleOutputAttribute(stdout, csbi.wAttributes, ConsoleSize, Origin,
    NumWritten));
  Win32Check(SetConsoleCursorPosition(stdout, Origin));
end;

//Filtra a string e deixa somente os n˙meros
procedure FiltraNumeros(var sString : string);
var sStringAux : string; i : SmallInt;
begin
  for i := 1 to Length(sString) do
   if sString[i] in ['0'..'9'] then
    sStringAux := sStringAux + sString[i];

  sString := sStringAux;
end;

{Pilha}
procedure PreencheBaralho(var Baralho : TBaralho);
var iIdx, iIdy : Smallint;
begin
  iIdy := 40;
	with Baralho do
	begin
    for iIdx := 1 to 40 do
    begin
      Carta[iIdx].Nome         := UTF8Encode(CARTA_STRING[iIdx]);
      Carta[iIdx].Valor        := iIdy;
      Carta[iIdx].isManilha    := False;
      Carta[iIdx].ManilhaValor := -1;
      Dec(iIdy);
    end;
    QntCarta := 40;
	end;
end;

//Sorteia 4 cartas aleatÛrias para serem as manilhas
procedure SorteiaManilha(var Baralho : TBaralho);
var iIdx, iIdy, CartaIndex, ManilhasCount : SmallInt;
    ManilhasIndexes : array[1..4] of SmallInt;
begin
  ManilhasCount := 0;
  for iIdy := 1 to 4 do
  begin
    ManilhasIndexes[iIdy] := 0;
  end;

  with Baralho do
  begin
    for iIdx := 1 to QntCarta do
    begin
      if ManilhasCount = 4 then Break;

      Randomize;
      CartaIndex := Random(QntCarta-1)+1;

      for iIdy := 1 to 4 do
        if CartaIndex = ManilhasIndexes[iIdy] then Continue;

      Inc(ManilhasCount);
      ManilhasIndexes[ManilhasCount] := CartaIndex;
      Carta[CartaIndex].isManilha    := True;
      Carta[CartaIndex].ManilhaValor := ManilhasCount;
      Carta[CartaIndex].Nome         := Carta[CartaIndex].Nome + ' - Manilha de Valor: ' + IntToStr(ManilhasCount);
    end;
  end;
end;

procedure MostraBaralho(Baralho : TBaralho);
var iIdx : Smallint;
begin
	writeln('Baralho: ');
  with Baralho do
  begin
    for iIdx := 1 to QntCarta do
    begin
      if Baralho.Carta[iIdx].Valor <> 0 then
      begin
        write(Baralho.Carta[iIdx].Nome);
        if iIdx < QntCarta then
          write(', ');
        if iIdx in [5,10,15,20,25,30,35] then
          writeln('');
      end;
    end;
  end;

end;

procedure EmbaralhaBaralho(var Baralho : TBaralho);
var iIdx, iAuxIdx : Smallint;
    CartaAux : TCarta;
begin
  with Baralho do
  begin
    for iIdx := 1 to QntCarta do
    begin
      Randomize;
      iAuxIdx := Random(QntCarta-1)+1;

      CartaAux       := Carta[iIdx];
      Carta[iIdx]    := Carta[iAuxIdx];
      Carta[iAuxIdx] := CartaAux;
    end;
  end;
end;

procedure ReIndex(var Baralho : TBaralho); overload
var
  iIdx, iIdy: Smallint;
begin
  with Baralho do
  begin
    for iIdx := 1 to QntCarta + 1 do
    begin
      if Carta[iIdx].Valor = 0 then
      begin
        for iIdy := iIdx to 40 do
        begin
          if iIdy > QntCarta then
          begin
            Carta[iIdy].Nome  := '';
            Carta[iIdy].Valor := 0;
          end
          else
            Carta[iIdy] := Carta[iIdy+1];
        end;;
      end;
    end;
  end;
end;

procedure ReIndex(var Jogador : TJogador); overload
var
  iIdx, iIdy: Smallint;
begin
  with Jogador do
  begin
    for iIdx := 1 to QntCarta + 1 do
    begin
      if Carta[iIdx].Valor = 0 then
      begin
        for iIdy := iIdx to 3 do
        begin
          if iIdy > QntCarta then
          begin
            Carta[iIdy].Nome  := '';
            Carta[iIdy].Valor := 0;
          end
          else
            Carta[iIdy] := Carta[iIdy+1];
        end;
      end;
    end;
  end;
end;

{Lista}
procedure RemoveCarta(var Baralho : TBaralho; iValorOuIndice : Smallint; bIndice : Boolean = False); overload
var iIdx : Smallint;
begin
  with Baralho do
  begin
    //Removendo a carta
    if bIndice then
    begin
      Carta[iValorOuIndice].Nome         := '';
      Carta[iValorOuIndice].Valor        := 0;
      Carta[iValorOuIndice].Naipe        := 0;
      Carta[iValorOuIndice].isManilha    := False;
      Carta[iValorOuIndice].ManilhaValor := 0;
      Dec(QntCarta);
    end
    else
    begin
      for iIdx := 1 to QntCarta do
      begin
        if Carta[iIdx].Valor = iValorOuIndice then
        begin
          Carta[iIdx].Nome                   := '';
          Carta[iIdx].Valor                  := 0;
          Carta[iValorOuIndice].Naipe        := 0;
          Carta[iValorOuIndice].isManilha    := False;
          Carta[iValorOuIndice].ManilhaValor := 0;
          Dec(QntCarta);
        end;
      end;
    end;
    //Re-Indexando
    ReIndex(Baralho);
  end;
end;

{Lista}
procedure RemoveCarta(var Jogador : TJogador; iValorOuIndice : Smallint; bIndice : Boolean = False); overload
var iIdx : Smallint;
begin
  with Jogador do
  begin
    //Removendo a carta
    if bIndice then
    begin
      Carta[iValorOuIndice].Nome  := '';
      Carta[iValorOuIndice].Valor := 0;
      Dec(QntCarta);
    end
    else
    begin
      for iIdx := 1 to QntCarta do
      begin
        if Carta[iIdx].Valor = iValorOuIndice then
        begin
          Carta[iIdx].Nome  := '';
          Carta[iIdx].Valor := 0;
          Dec(QntCarta);
        end;
      end;
    end;
    //Re-Indexando
    ReIndex(Jogador);
  end;
end;

{Pilha}
procedure RemoveCarta(var Baralho : TBaralho); overload
begin
  with Baralho do
  begin
    Carta[QntCarta].Nome  := '';
    Carta[QntCarta].Valor := 0;
    Dec(QntCarta);
  end;
end;

{Pilha}
procedure AdicionaCarta(var Baralho : TBaralho; Carta : TCarta);
begin
  Inc(Baralho.QntCarta);
  Baralho.Carta[Baralho.QntCarta] := Carta;
end;

{Pilha}
function RetornaCarta(Baralho : TBaralho): TCarta;
begin
  with Baralho do
    Result := Carta[QntCarta];
end;

procedure PreencheCartaJogadores(var Mao : TMao;var Baralho : TBaralho);
var iIdx , iIdy: Smallint;
    TerminouPreencher : Boolean;
begin
  iIdy := 0;
  iIdx := 1;
  TerminouPreencher := False;
  with Mao do
  begin
    while not TerminouPreencher do
    begin
      Inc(iIdy);
      Jogador[iIdy].Carta[iIdx] := RetornaCarta(Baralho);
      Inc(Jogador[iIdy].QntCarta);
      RemoveCarta(Baralho);
      if (iIdy = 2) and (iIdx <> 3) then
      begin
        Inc(iIdx);
        iIdy := 0;
      end;
      TerminouPreencher := (iIdx = 3) and (iIdy = 2);
    end;
  end;
end;

procedure MostraCartas(var Jogador : TJogador);
var iIdx : Smallint;
begin
  with Jogador do
    for iIdx := 1 to Length(Carta) do
    begin
      if iIdx - 1 < QntCarta then
        write('[');

      write(Carta[iIdx].Nome);

      if iIdx < QntCarta then
        write('], ')
      else if iIdx - 1 < QntCarta then
        write(']')
    end;

  Writeln('');
end;

function VencedorPartida(Partida : TPartida): Smallint;
var iIdx, Jogador1Venceu, Jogador2Venceu : Smallint;
begin
  Jogador1Venceu := 0;
  Jogador2Venceu := 0;

  with Partida do
  begin
    for iIdx := 1 to Length(Mao) do
    begin
      if Mao[iIdx].Vencedor = 1 then
        Inc(Jogador1Venceu)
      else if Mao[iIdx].Vencedor = 2 then
        Inc(Jogador2Venceu);
    end;

    if Jogador1Venceu >= 2 then
      Result := 1
    else if Jogador2Venceu >= 2 then
      Result := 2
    else
      Result := -1;
  end;
end;

function JogadorComCartaMaior(Disputa : TDisputa): Smallint;
begin
  with Disputa do
  begin
    if (CartaJogador1.Valor = 0) or (CartaJogador2.Valor = 0) then
    begin
      Result := -1;
      Exit;
    end;

    if CartaJogador1.isManilha and not CartaJogador2.isManilha then
    begin
      Result := 1;
      Exit;
    end
    else if CartaJogador2.isManilha and not CartaJogador1.isManilha then
    begin
      Result := 2;
      Exit;
    end
    else if CartaJogador1.isManilha and CartaJogador2.isManilha then
    begin
      if CartaJogador1.ManilhaValor > CartaJogador2.ManilhaValor then
        Result := 1
      else if CartaJogador2.ManilhaValor > CartaJogador1.ManilhaValor then
        Result := 2;
      Exit;
    end;

    if (CartaJogador1.Valor > CartaJogador2.Valor) then
      Result := 1
    else
      Result := 2;
  end;
end;

function Empatou(Disputa : TDisputa): Boolean;
begin
  Result := False;
  with Disputa do
  begin
    if (CartaJogador1.Nome[1] = CartaJogador2.Nome[1]) and (CartaJogador1.isManilha or CartaJogador2.isManilha) then Exit;

    if (CartaJogador1.Nome[1] = CartaJogador2.Nome[1]) then
      Result := True;
  end;
end;

function VencedorEmpate(Rodada : TRodada; DisputaIndex, DisputaIndexEmpate : SmallInt): SmallInt;
begin
  Result := -1;

  with Rodada do
  begin
    if Truco > 0 then
    begin
      Result := JogadorComCartaMaior(Disputa[DisputaIndex]);
      Exit;
    end;

    begin
        if Disputa[DisputaIndexEmpate].CartaJogador1.Naipe > Disputa[DisputaIndexEmpate].CartaJogador2.Naipe then
          Result := 1
        else if Disputa[DisputaIndexEmpate].CartaJogador2.Naipe > Disputa[DisputaIndexEmpate].CartaJogador1.Naipe then
          Result := 2;
    end;
  end;
end;

function RetornaValorDaRodada(Mao : TMao; Rodada : TRodada): Smallint;
begin
  Result := 1;

  //M„o de 11
  if (Mao.Jogador[1].Pontos = 11) or (Mao.Jogador[2].Pontos = 11) then
    Result := 3;

  //Truco
  if Rodada.Truco = 1 then
    Result := 3
  else if Rodada.Truco = 2 then
    Result := 6
  else if Rodada.Truco = 3 then
    Result := 9
  else if Rodada.Truco = 4 then
    Result := 12
end;

function RetornaCartaBot(Jogador : TJogador): TCarta;
var iIdx : Integer;
begin
  Result.Valor := 0;
  with Jogador do
    for iIdx := 1 to QntCarta do
      if Carta[iIdx].Valor > Result.Valor then
        Result := Carta[iIdx];
end;

function RetornaTrucoBot(Jogador : TJogador; Mao : TMao; Rodada : TRodada; RetornaCorreu : Boolean = False): Boolean;
begin
  Result := False;
  Randomize;
  if RetornaCorreu then
  begin
    if (RetornaCartaBot(Jogador).Valor <= 24) and (not RetornaCartaBot(Jogador).isManilha) then
      if Random(4) = 2 then
        Result := True;
  end
  else
    if (RetornaCartaBot(Jogador).Valor >= 25) or (RetornaCartaBot(Jogador).isManilha) then
      if Random(6) = 2 then
        Result := True;
end;

function SomatoriaPontos(Partida : TPartida; iJogador : SmallInt): SmallInt;
var iIdx : SmallInt;
begin
  Result := 0;
  with Partida do
    for iIdx := 1 to 3 do
      Result := Result + Mao[iIdx].Jogador[iJogador].Pontos;
end;

procedure DevolveCartas(var Mao : TMao;var Baralho : TBaralho);
var iIdx : Integer;
begin
  with Mao do
  begin
    iIdx := 3;
    //Verificando e devolvendo as cartas dos Jogadores
    while iIdx <> 0 do
    begin
      if Jogador[1].Carta[iIdx].Valor <> 0 then
      begin
        AdicionaCarta(Baralho, Jogador[1].Carta[iIdx]);
        RemoveCarta(Jogador[1], Jogador[1].Carta[iIdx].Valor);
      end;
      if Jogador[2].Carta[iIdx].Valor <> 0 then
      begin
        AdicionaCarta(Baralho, Jogador[2].Carta[iIdx]);
        RemoveCarta(Jogador[2], Jogador[2].Carta[iIdx].Valor);
      end;
      Dec(iIdx);
    end;
  end;
end;

function CartaEscolhaValida(var CartaEscolha : string;Jogador : TJogador): Boolean;
begin
  Result := False;

  FiltraNumeros(CartaEscolha);

  if CartaEscolha <> '' then
    if StrToInt(CartaEscolha) in [1..10] then
      if Jogador.Carta[StrToInt(CartaEscolha)].Valor in [1..40] then
        Result := True;
end;

procedure LimpaMao(var Mao : TMao);
var iIdx, iIdy : integer;
begin
  with Mao do
  begin
    Vencedor := 0;
    for iIdx := 1 to 2 do
      for iIdY := 1 to 3 do
      begin
        Jogador[iIdx].Carta[iIdy].Nome  := '';
        Jogador[iIdx].Carta[iIdy].Valor := 0;
      end;

    for iIdx := 1 to 6 do
    begin
      Rodada[iIdx].Truco := 0;
      Rodada[iIdx].Jogador1Venceu := 0;
      Rodada[iIdx].Jogador2Venceu := 0;
      Rodada[iIdx].Jogador1Correu := False;
      Rodada[iIdx].Jogador2Correu := False;
      for iIdY := 1 to 3 do
      begin
        Rodada[iIdx].Disputa[iIdy].CartaJogador1.Nome  := '';
        Rodada[iIdx].Disputa[iIdy].CartaJogador1.Valor := 0;
      end;
    end;
  end;
end;

procedure CortaBaralho(var Baralho : TBaralho; CorteIndex : SmallInt);
var BaralhoAux : TBaralho;
    iIdx: SmallInt;
begin
  //Preenchendo o baralho auxiliar a partir do Ìndice do baralho informado
  for iIdx := CorteIndex to Baralho.QntCarta do
  begin
    BaralhoAux.Carta[iIdx - CorteIndex + 1] := Baralho.Carta[iIdx];
  end;
  //Preenchendo o restante das cartas
  for iIdx := 1 to CorteIndex - 1 do
  begin
    BaralhoAux.Carta[iIdx + Baralho.QntCarta - CorteIndex + 1] := Baralho.Carta[iIdx];
  end;
  //Cartas do baralho auxiliar se tornam do baralho principal
  Baralho.Carta := BaralhoAux.Carta;
end;

function CorteEscolhaValido(var CorteEscolha : string): Boolean;
begin
  Result := False;

  FiltraNumeros(CorteEscolha);

  if CorteEscolha <> '' then
    if StrToInt(CorteEscolha) in [10..30] then
      Result := True;
end;

function RetornaPrintTruco(Rodada : TRodada; JogadorIndex : SmallInt): string;
begin
  with Rodada do
  begin
    if Truco = 0 then
      Writeln('Jogador ', JogadorIndex,' Trucou!!')
    else
      Writeln('Jogador ', JogadorIndex,' ReTrucou!!');
  end;
end;

function TrucoEscolhaValida(var TrucoEscolha: string): Boolean;
begin
  Result := False;

  FiltraNumeros(TrucoEscolha);

  if TrucoEscolha <> '' then
    if StrToInt(TrucoEscolha) in [1..2] then
      Result := True;
end;

procedure DefineVencedorDisputa(var Mao : TMao; RodadaIndex, DisputaIndex : SmallInt);
begin
  with Mao do
    if Empatou(Rodada[RodadaIndex].Disputa[DisputaIndex]) then
    begin
      Writeln('Empate!!');
      Readln;
      Readln;
      if (DisputaIndex = 3) and (not Empatou(Rodada[RodadaIndex].Disputa[1])) and (not Empatou(Rodada[RodadaIndex].Disputa[2])) then
      begin
        if VencedorEmpate(Rodada[RodadaIndex], DisputaIndex, 3) = 1 then
        begin
          Writeln('O vencedor do empate da disputa "3" foi o Jogador 1');
          Inc(Rodada[RodadaIndex].Jogador1Venceu);
        end
        else
        begin
          Writeln('O vencedor do empate da disputa "3" foi o Jogador 2');
          Inc(Rodada[RodadaIndex].Jogador2Venceu);
        end;
      end
      else if (DisputaIndex = 3) and (Empatou(Rodada[RodadaIndex].Disputa[1])) and (not Empatou(Rodada[RodadaIndex].Disputa[2])) then
      begin
        if VencedorEmpate(Rodada[RodadaIndex], DisputaIndex, 1) = 1 then
        begin
          Writeln('O vencedor dos empates das disputas "1" e "3" foi o Jogador 1');
          Rodada[RodadaIndex].Jogador1Venceu := 2;
          Rodada[RodadaIndex].Jogador2Venceu := 0;
        end
        else
        begin
          Writeln('O vencedor dos empates das disputas "1" e "3" foi o Jogador 2');
          Rodada[RodadaIndex].Jogador1Venceu := 0;
          Rodada[RodadaIndex].Jogador2Venceu := 2;
        end;
      end
      else if (DisputaIndex = 3) and (not Empatou(Rodada[RodadaIndex].Disputa[1])) and (Empatou(Rodada[RodadaIndex].Disputa[2])) then
      begin
        if VencedorEmpate(Rodada[RodadaIndex], DisputaIndex, 2) = 1 then
        begin
          Writeln('O vencedor dos empates das disputas "2" e "3" foi o Jogador 1');
          Rodada[RodadaIndex].Jogador1Venceu := 2;
          Rodada[RodadaIndex].Jogador2Venceu := 0;
        end
        else
        begin
          Writeln('O vencedor dos empates das disputas "2" e "3" foi o Jogador 2');
          Rodada[RodadaIndex].Jogador1Venceu := 0;
          Rodada[RodadaIndex].Jogador2Venceu := 2;
        end;
      end
      else if (DisputaIndex = 3) and (Empatou(Rodada[RodadaIndex].Disputa[1])) and (Empatou(Rodada[RodadaIndex].Disputa[2])) then
      begin
        if JogadorComCartaMaior(Rodada[RodadaIndex].Disputa[DisputaIndex]) = 1 then
        begin
          Writeln('O vencedor dos empates das disputas "1", "2" e "3" foi o Jogador 1');
          Rodada[RodadaIndex].Jogador1Venceu := 2;
          Rodada[RodadaIndex].Jogador2Venceu := 0;
        end
        else
        begin
          Writeln('O vencedor dos empates das disputas "1", "2" e "3" foi o Jogador 2');
          Rodada[RodadaIndex].Jogador1Venceu := 0;
          Rodada[RodadaIndex].Jogador2Venceu := 2;
        end;
      end;
    end
    else
    begin
      //Quando n„o empatou na terceira e segunda disputa mas empatou a primeira
      if (DisputaIndex = 3) and Empatou(Rodada[RodadaIndex].Disputa[1]) and (not Empatou(Rodada[RodadaIndex].Disputa[2])) then
      begin
        if VencedorEmpate(Rodada[RodadaIndex], DisputaIndex, 1) = 1 then
        begin
          Writeln('O vencedor do empate da disputa "1" foi o Jogador 1');
          Inc(Rodada[RodadaIndex].Jogador1Venceu);
        end
        else
        begin
          Writeln('O vencedor do empate da disputa "1" foi o Jogador 2');
          Inc(Rodada[RodadaIndex].Jogador2Venceu);
        end;
      end
      else
      //Quando n„o empatou na terceira e primeira disputa mas empatou na segunda
      if (DisputaIndex = 3) and Empatou(Rodada[RodadaIndex].Disputa[2]) and (not Empatou(Rodada[RodadaIndex].Disputa[1])) then
      begin
        if VencedorEmpate(Rodada[RodadaIndex], DisputaIndex, 2) = 1 then
        begin
          Writeln('O vencedor do empate da disputa "2" foi o Jogador 1');
          Inc(Rodada[RodadaIndex].Jogador1Venceu);
        end
        else
        begin
          Writeln('O vencedor do empate da disputa "2" foi o Jogador 2');
          Inc(Rodada[RodadaIndex].Jogador2Venceu);
        end;
      end
      else
      //Quando n„o empatou na terceira disputa mas empatou na primeira e segunda
      if (DisputaIndex = 3) and Empatou(Rodada[RodadaIndex].Disputa[2]) and Empatou(Rodada[RodadaIndex].Disputa[1]) then
      begin
        if VencedorEmpate(Rodada[RodadaIndex], DisputaIndex, 1) = 1 then
        begin
          Writeln('O vencedor dos empates das disputas "1" e "2" foi o Jogador 1');
          Rodada[RodadaIndex].Jogador1Venceu := 2;
          Rodada[RodadaIndex].Jogador2Venceu := 0;
        end
        else
        begin
          Writeln('O vencedor dos empates das disputas "1" e "2" foi o Jogador 2');
          Rodada[RodadaIndex].Jogador1Venceu := 0;
          Rodada[RodadaIndex].Jogador2Venceu := 2;
        end;
      end;

      //Se n„o empatou na disputa atual verifica a carta de maior valor para definir o vencedor da disputa
      if JogadorComCartaMaior(Rodada[RodadaIndex].Disputa[DisputaIndex]) = 1 then
      begin
        Writeln('Carta de maior valor da disputa "',DisputaIndex,'" pertence ao Jogador 1');
        Inc(Rodada[RodadaIndex].Jogador1Venceu);
      end
      else if JogadorComCartaMaior(Rodada[RodadaIndex].Disputa[DisputaIndex]) = 2 then
      begin
        Writeln('Carta de maior valor da disputa "',DisputaIndex,'" pertence ao Jogador 2');
        Inc(Rodada[RodadaIndex].Jogador2Venceu);
      end;
    end;
end;

var
	Baralho : TBaralho;
  Partida : TPartida;

  CorteEscolha : string;
  CartaEscolha : string;
  TrucoEscolha : string;

  RodadaIndex  : Smallint;
  DisputaIndex : SmallInt;
  MaoIndex     : SmallInt;

  isRodadaTerminada  : Boolean;
  isMaoTerminada     : Boolean;
  isPartidaTerminada : Boolean;
begin
  //Troca o encoding do console para aceitar caractere especial usando a funÁ„o UTF8Encode quando for "printar" na tela (ignorar)
  SetConsoleOutputCP(CP_UTF8);

	PreencheBaralho(Baralho);
  SorteiaManilha(Baralho);

  LimpaMao(Partida.Mao[1]);
  LimpaMao(Partida.Mao[2]);
  LimpaMao(Partida.Mao[3]);

  MaoIndex := 0;
  while not isPartidaTerminada do
  begin
    if VencedorPartida(Partida) = 1 then
    begin
      Writeln('Jogador 1 venceu essa partida com ', SomatoriaPontos(Partida, 1),' Pontos');
      Partida.Vencedor := 1;
      isPartidaTerminada := True;
      Break;
    end
    else if VencedorPartida(Partida) = 2 then
    begin
      Writeln('Jogador 2 venceu essa partida com ', SomatoriaPontos(Partida, 2),' Pontos');
      Partida.Vencedor := 2;
      isPartidaTerminada := True;
      Break;
    end;

    CorteEscolha := '';
    while not CorteEscolhaValido(CorteEscolha) do
    begin
      Writeln(UTF8Encode('Informe o Ìndice para o corte do baralho "10-30"'));
      Readln(CorteEscolha);
    end;

    Inc(MaoIndex);
    isMaoTerminada := False;
    RodadaIndex := 0;
    while not isMaoTerminada do
    begin
      CartaEscolha := '';
      TrucoEscolha := '';
      with Partida.Mao[MaoIndex] do
      begin
        CortaBaralho(Baralho, StrToInt(CorteEscolha));
        ClearScreen;
        EmbaralhaBaralho(Baralho);
        PreencheCartaJogadores(Partida.Mao[MaoIndex], Baralho);

        Inc(RodadaIndex);

        isRodadaTerminada := False;
        DisputaIndex := 0;
        while not isRodadaTerminada do
        begin
          Writeln(UTF8Encode('M„o: '), IntToStr(MaoIndex));
          Writeln('==============================================');
          Writeln('Rodada: ', IntToStr(RodadaIndex));
          Writeln('==============================================');
          Writeln('Pontos Jogador 1: ', IntToStr(Jogador[1].Pontos));
          Writeln('==============================================');
          Writeln('Pontos Jogador 2: ', IntToStr(Jogador[2].Pontos));
          Writeln('==============================================');
          Writeln('Disputas Vencidas Jogador 1: ', IntToStr(Rodada[RodadaIndex].Jogador1Venceu));
          Writeln('==============================================');
          Writeln('Disputas Vencidas Jogador 2: ', IntToStr(Rodada[RodadaIndex].Jogador2Venceu));
          Writeln('==============================================');

          Writeln('');
          Writeln('Cartas Jogador 1: ');
          MostraCartas(Jogador[1]);
          Writeln('');

          if RetornaTrucoBot(Jogador[2], Partida.Mao[MaoIndex], Partida.Mao[MaoIndex].Rodada[RodadaIndex]) then
            if Partida.Mao[MaoIndex].Rodada[RodadaIndex].Truco < 4 then
            begin
              RetornaPrintTruco(Partida.Mao[MaoIndex].Rodada[RodadaIndex], 2);
              Inc(Partida.Mao[MaoIndex].Rodada[RodadaIndex].Truco);
            end;

          if Rodada[RodadaIndex].Truco <> 0 then
          begin
            while not TrucoEscolhaValida(TrucoEscolha) do
            begin
              Writeln('1 para continuar ou 2 para correr');
              Readln(TrucoEscolha);
            end;

            if TrucoEscolha = '2' then
            begin
              Dec(Rodada[RodadaIndex].Truco);
              isRodadaTerminada := True;
              Rodada[RodadaIndex].Jogador2Venceu := 2;
              Rodada[RodadaIndex].Jogador1Venceu := 0;
            end;
          end;

          if not isRodadaTerminada then
          begin
            Inc(DisputaIndex);
            //Jogador 2 sempre da a carta antes do 1 nesse caso, porÈm sÛ mostra a carta se venceu a ˙ltima rodada
//            if RodadaIndex > 1 then
//              if Rodada[RodadaIndex-1].Jogador2Venceu = 2 then
              begin
                Rodada[RodadaIndex].Disputa[DisputaIndex].CartaJogador2 := RetornaCartaBot(Jogador[2]);
                writeln('Carta Jogador 2 [',Rodada[RodadaIndex].Disputa[DisputaIndex].CartaJogador2.Nome,']');
                writeln('');
              end;
//              else if Rodada[RodadaIndex-1].Jogador1Venceu = 2 then
//              begin
//                Rodada[RodadaIndex].Disputa[DisputaIndex].CartaJogador2 := RetornaCartaBot(Jogador[2]);
//              end;

            if RodadaIndex = 1 then
              Rodada[RodadaIndex].Disputa[DisputaIndex].CartaJogador2 := RetornaCartaBot(Jogador[2]);


            while not CartaEscolhaValida(CartaEscolha, Jogador[1]) and (not isRodadaTerminada) do
            begin

              Writeln('Rodada valendo: ',IntToStr(RetornaValorDaRodada(Partida.Mao[MaoIndex], Partida.Mao[MaoIndex].Rodada[RodadaIndex])),' Pontos');

              if Jogador[1].QntCarta = 3 then
                Writeln('Selecione a carta (1,2,3) ou escreva 10 para trucar')
              else if Jogador[1].QntCarta = 2 then
                Writeln('Selecione a carta (1,2) ou escreva 10 para trucar')
              else
                Writeln('Selecione a carta (1) ou escreva 10 para trucar');
              ReadLn(CartaEscolha);

              if (Jogador[1].Pontos = 11) and (CartaEscolha = '10') or (Jogador[2].Pontos = 11) and (CartaEscolha = '10') then
              begin
                Writeln(UTF8Encode('Burr„o ein... trucou em m„o de 11 seu nÛia'));
                Writeln(UTF8Encode('Boa, perdeu tudo.'));
                isRodadaTerminada := True;
                isMaoTerminada    := True;
                Partida.Mao[1].Vencedor := 2;
                Partida.Mao[2].Vencedor := 2;
                Partida.Mao[3].Vencedor := 2;
                Rodada[RodadaIndex].Jogador2Venceu := 2;
                Rodada[RodadaIndex].Jogador1Venceu := 0;
                Break;
              end;


              if (CartaEscolha = '10') and (Partida.Mao[MaoIndex].Rodada[RodadaIndex].Truco < 4) then
              begin
                RetornaPrintTruco(Partida.Mao[MaoIndex].Rodada[RodadaIndex], 1);
                Inc(Partida.Mao[MaoIndex].Rodada[RodadaIndex].Truco);

                if RetornaTrucoBot(Jogador[2], Partida.Mao[MaoIndex], Partida.Mao[MaoIndex].Rodada[RodadaIndex]) then
                begin
                  if (Jogador[1].Pontos = 11) or (Jogador[2].Pontos = 11) then
                  begin
                    Writeln(UTF8Encode('Bot trucou em m„o de 11 kkkkkk mt burro'));
                    Writeln(UTF8Encode('ParabÈns, ganhou.'));
                    isRodadaTerminada := True;
                    isMaoTerminada    := True;
                    Partida.Mao[1].Vencedor := 1;
                    Partida.Mao[2].Vencedor := 1;
                    Partida.Mao[3].Vencedor := 1;
                    Rodada[RodadaIndex].Jogador2Venceu := 0;
                    Rodada[RodadaIndex].Jogador1Venceu := 2;
                    Break;
                  end;

                  RetornaPrintTruco(Partida.Mao[MaoIndex].Rodada[RodadaIndex], 2);
                  Inc(Partida.Mao[MaoIndex].Rodada[RodadaIndex].Truco);
                end
                else
                if RetornaTrucoBot(Jogador[2], Partida.Mao[MaoIndex], Partida.Mao[MaoIndex].Rodada[RodadaIndex], True) then
                begin
                  Writeln('Jogador 2 Correu!!');
                  Dec(Rodada[RodadaIndex].Truco);
                  isRodadaTerminada := True;
                  Rodada[RodadaIndex].Jogador2Venceu := 0;
                  Rodada[RodadaIndex].Jogador1Venceu := 2;
                end;
              end;
            end;
          end;

          with Rodada[RodadaIndex] do
          begin

            if not isRodadaTerminada then
            begin
              Disputa[DisputaIndex].CartaJogador1 := Jogador[1].Carta[StrToInt(CartaEscolha)];
              AdicionaCarta(Baralho, Disputa[DisputaIndex].CartaJogador1);
              RemoveCarta(Jogador[1], StrToInt(CartaEscolha), True);

              Disputa[DisputaIndex].CartaJogador2 := RetornaCartaBot(Jogador[2]);
              AdicionaCarta(Baralho, Disputa[DisputaIndex].CartaJogador2);
              RemoveCarta(Jogador[2], Disputa[DisputaIndex].CartaJogador2.Valor);

              write('Disputa: ');
              write('Carta Player 1 [',Disputa[DisputaIndex].CartaJogador1.Nome,'], Carta Player 2 [',Disputa[DisputaIndex].CartaJogador2.Nome,']');
              Writeln('');

              DefineVencedorDisputa(Partida.Mao[MaoIndex], RodadaIndex, DisputaIndex);
            end;


            if Jogador1Venceu >= 2 then
            begin
              Writeln(UTF8Encode('Jogador 1 venceu essa rodada'));
              Jogador[1].Pontos := Jogador[1].Pontos + RetornaValorDaRodada(Partida.Mao[MaoIndex], Partida.Mao[MaoIndex].Rodada[RodadaIndex]);
              DevolveCartas(Partida.Mao[MaoIndex], Baralho);
              isRodadaTerminada := True;
            end
            else if Jogador2Venceu >= 2 then
            begin
              Writeln(UTF8Encode('Jogador 2 venceu essa rodada'));
              Jogador[2].Pontos := Jogador[2].Pontos + RetornaValorDaRodada(Partida.Mao[MaoIndex], Partida.Mao[MaoIndex].Rodada[RodadaIndex]);
              DevolveCartas(Partida.Mao[MaoIndex], Baralho);
              isRodadaTerminada := True;
            end;
          end;

          Readln;
          Readln;
          CartaEscolha := '';
          ClearScreen;
        end;

        if Jogador[1].Pontos >= 12 then
        begin
          Writeln(UTF8Encode('Jogador 1 venceu essa m„o'));
          Partida.Mao[MaoIndex].Vencedor := 1;
          isMaoTerminada := True;
        end
        else if Jogador[2].Pontos >= 12 then
        begin
          Writeln(UTF8Encode('Jogador 1 venceu essa m„o'));
          Partida.Mao[MaoIndex].Vencedor := 2;
          isMaoTerminada := True;
        end;
      end;
    end;
    Readln;
    Readln;
  end;
  Readln;
  Readln;
end.
