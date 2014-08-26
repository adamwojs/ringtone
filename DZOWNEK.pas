{
                       =====================================
                       =====================================
                       == Dzownek v.1.0                   ==
                       == Autor: Adawo                    ==
                       == Kontakt:                        ==
                       == e-mail: adamw7@vp.pl            ==
                       == GG: 5463911                     ==
                       == Ostatnia kompilacja: 20.06.2007 ==
                       =====================================
                       =====================================
}

program Dzwonek;

uses
    Crt, AS_INT;

//const
//     ConfigFName = 'c:\DZWIEK.cfg'; {Sciezka dostepu do pliku z ustawienami}

Type
    TDzwiek = record
            Hz : word;  {Czestotliwosc dzwieku}
            Ms : word;  {Czas trwania dzwieku}
          end;

    TKey = record
         Dzwiek : TDzwiek; {Dzwiek...}
         Char : byte;      {kod przypisanego mu klawisza}
        end;

    TMenu = object

             Odp : char;     {Kod naciscietego klawisza}
             ActItem : byte; {Pozycja kursora w menu}

             ItemTColor : byte; {Kolor tekstu}
             ItemBColor : byte; {Kolor tla}
             ZazItemTColor : byte; {Kolor tekstu zaznaczonego elementu}
             ZazItemBColor : byte; {Kolor tla zaznaczonego elementu}

           end;

    TMenuG = object(TMenu)

             Items : array[0..5] of string;

             procedure InicjalizujMenu;
             procedure Wyswietl;{Wyswietla Menu}
             procedure ReadOdp; //Reakcja na akcje uzytkownika
             procedure Nowy;
             procedure Otworz;
             procedure Zapisz;
             procedure Powrot;

           end;

    TEditor = object

            page,cursor,column : byte;
            Panel : boolean;

            MenuEditor : TMenu; //Przchowuje kolorystyke menu i aktualna pozycje kursora w menu
            MenuItems : array[0..5] of string; //Przechowuje teksty przyciskow w menu

            function MaxDzw : byte;  //zwraca liczbe skladowych dźwięków na dzwonek
            procedure IncColumn(i : shortint); //Przechodzi do nastepnejkolumny

            procedure WyswietlMenu;            //Wyswietla menu
            procedure WyswietlTabele;          //Wyswietla tablice z dźwiękami

            procedure Inicjalizuj;             //Ustalenie kolorystyki, przypisanie tekstów do przysckow
            procedure ReadOdp;                 //!!! Czyta reakcje użytkownika
            procedure DzwRead;                 //Pyta o czestotliwosc i dlugosc trwania dzwieku
            procedure DzwAdd(Dz : TDzwiek);    //Dodaje do tablicy dzwiek
            procedure DzwPlay (Dzw : TDzwiek); //Odgrywa pojedynczy dzwiek
            procedure DzwDelete (index : byte);//Usuwa z tablicy pojedznczy dzwiek
            procedure DznPlay;                 //Odgrywa dzwonek

          end;

    TSkr = object

           SkrTable : array[0..25] of TKey;   //Tablica Uzupelniana Sprotami
           MenuItems : array[0..2] of string; //Przyciski Menu Dolnego
           MenuSkr : TMenu;         //Menu Dolne

           TableColors : TMenu;           //Tablica ze sktótami
           PTColor, PBColor : byte; //Kolor Tekstu i Tla parzystego elementu

           procedure InicjalizujMenu;  //Ustalenie kolorystkyki, tekstow przyciskow w dolnym menu
           procedure WyswietlMenu;     //Odpowiedziane za wyswielenia menu

//           procedure WyswietlTabele;   //Odpowiedzialne za wyswietlenie Tablicy ze skrotami

           procedure SkrRead(key : byte); //Sprawdza przypisanie do skrotu do klawisza i reaguje na skrot
           procedure SkrAdd;              //Dodaje di tablicy skrot(!!! lub modyfikuje jeśli wczesniej przypisano)
           procedure SkrDelete;           //Usuwa skrot z tablicy

           end;

var
   TmpDzw : TDzwiek;
   F : file of TDzwiek; //Plik z dzwonkiem ze sciezki FName
   Menu : TMenuG;
   Editor : TEditor;
   FName : string;      //Sciezka dostepu do pilku z dzwonekim, jesli = '' standardowo przyjmuje wartość C:\TEMP.DZW
   DzwonekDz : array[0..255] of TDzwiek; //Tablica dźwięków
   MessageOpt : TMessageOptions;
   Skr : TSkr;

procedure ProgCommend(s : string);
begin
     TextBackground(4);
     TextColor(white);
     ClrEol;
     Writeln(s);
     TextBackground(Black);
     TextColor(7);
end;

function FileEx(FName : string; Create : boolean) : boolean;
var
   f : file;
begin
     Assign(f,FName);
     {$i-}
     Reset(f);
     if IOResult = 0 then
        begin
             FileEx := true;
             Close(f);
        end
     else
        if Create then
           begin
                ReWrite(f);
                Close(f);
                FileEx := true;
           end
              else FileEx := false;
     {$i+}
end;

{
=============================================================================
==                             METODY OBIEKTU TEditor                      ==
=============================================================================
}

procedure TEditor.Inicjalizuj;
begin

     MenuEditor.ItemTColor := 0;
     MenuEditor.ItemBColor := 7;

     MenuEditor.ZazItemTColor := 15;
     MenuEditor.ZazItemBColor := 1;

     MenuItems[0] := '[F2] Dod Dz';
     MenuItems[1] := '[ENTER] Edt Dz';
     MenuItems[2] := '[Del] Usu Dz';
     MenuItems[3] := '[F4] Odt Dzwn.';
//     MenuItems[4] := '[F5] Skr klaw.';
     MenuItems[4] := '[F6] MenuGl';

     if page= 0 then page := 1;

end;

procedure TEditor.WyswietlMenu;
var i : byte;
begin
     Inicjalizuj;
     GoToXY(1,24);
     TextBackground(MenuEditor.ItemBColor);
     ClrEol;
     for i := 0 to 4 do
         begin
              if i <> MenuEditor.ActItem then
                 begin
                      GoToXY(WhereX + 1,24);
                      TextColor(MenuEditor.ItemTColor);
                      TextBackground(MenuEditor.ItemBColor);
                      Write(MenuItems[i]);
                      TextColor(7);
                      TextBackground(0);
                 end
               else
                 begin
                      GoTOXY(WhereX + 1,24);
                      TextColor(MenuEditor.ZazItemTColor);
                      TextBackground(MenuEditor.ZazItemBColor);
                      Write(MenuItems[i]);
                      TextColor(7);
                      TextColor(0);
                 end;
         end;
         TextColor(7);
         TextBackground(0);
end;

procedure TEditor.WyswietlTabele;
var
   i,j : byte;
   LabelBColor : byte;
   LabelTColor : byte;
   CaptionTColor,CaptionBColor,LPTColor : byte;

begin
     GoToXY(1,1);
     i := (page - 1) * 69;
     while (i  < 69 * page) and (i < 255) do
           begin
                for j := 0 to 2 do
                    begin
                         Inc(i);
                         if (DzwonekDz[i -1].Hz = 0) and (DzwonekDz[i - 1].Ms = 0) then Exit;
                         if i - 1 <> cursor then
                            begin
                                 CaptionBColor := 7;
                                 CaptionTColor := 0;
                                 LabelBColor := 0;
                                 LabelTColor := 7;
                                 LPTColor := 15;
                            end
                         else
                             begin
                                  CaptionBColor := 7;
                                  CaptionTColor := green;
                                  LabelBColor := 0;
                                  LabelTColor := lightgreen;
                                  LPTColor := 15;
                             end;
                         GoToXY(27 * j,WhereY);
                         TextColor(LPTColor);
                         Write(i);
                         GoToXY(27 * j + 4,WhereY);
                         TextColor(CaptionTColor);
                         TextBackground(CaptionBColor);
                         Write(' Hz:');
                         TextBackground(0);
                         GoToXY(27 * j + 9,WhereY);
                         TextColor(LabelTColor);
                         Write(DzwonekDz[i - 1].Hz);
                         GoToXY(27 * j + 14,WhereY);
                         TextColor(CaptionTColor);
                         TextBackground(CaptionBColor);
                         Write(' Ms:');
                         TextBackground(LabelBColor);
                         TextColor(LabelTColor);
                         Write(' ',DzwonekDz[i - 1].Ms);
                         end;
                Writeln;
           end;
end;

function TEditor.MaxDzw : byte; {Zwraca ilo† element˘w d«wi©ku}
var
   i : byte;
begin
     for i := 0 to 255 do
         if (DzwonekDz[i].Hz = 0) and (DzwonekDz[i].Ms = 0) then Break;
     MaxDzw := i;
end;

procedure TEditor.IncColumn(i : shortint); {i C (-128..127); Column zostanie zwi©kzone o i}
begin
     case Column of
            1 : Inc(Column,i);
            0 : if i > 0 then Inc(Column,i) else Column := 2;
            2 : if i < 0 then Inc(Column,i) else Column := 0;
          end;
end;

procedure TEditor.ReadOdp;
var
     Odp : char;
     i : byte;
begin
     while true do
           begin
                ClrScr;
                TEditor.WyswietlMenu;
                TEditor.WyswietlTabele;
                Odp := Readkey;
                if Panel then
                   case odp of
                          #60 : begin
                                  TEditor.DzwRead;
                                  TEditor.DzwAdd(TmpDzw);
                                end;
                          #62 : begin
                                for i := 0 to 255 do
                                    TEditor.DzwPlay(DzwonekDz[i]);
                                end;
                          #64 : Break;
                          #77 : if MenuEditor.ActItem <> 4 then Inc(MenuEditor.ActItem) else MenuEditor.ActItem := 0;
                          #75 : if Menueditor.ActItem <> 0 then Dec(MenuEditor.ActItem) else MenuEditor.ActItem := 4;
                          #13 : begin
                                     case MenuEditor.ActItem of
                                          0 : begin
                                                    TEditor.DzwRead;
                                                    DzwAdd(TmpDzw);
                                              end;
                                          1 : begin
                                                   TEditor.DzwRead;
                                                   DzwonekDz[Cursor] := TmpDzw;
                                              end;
                                          2 : TEditor.DzwDelete(Cursor);
                                          3 : for i := 0 to 255 do TEditor.DzwPlay(DzwonekDz[i]);

                                          4 : Break;
                                     end;
                                end;
                          #9 : Panel := False;
                end
                   else
                       begin
                            case odp of
                                 #9 : Panel := true;
                                 #60 : begin
                                            TEditor.DzwRead;
                                            TEditor.DzwAdd(TmpDzw);
                                       end;
                                 #62 : begin
                                            for i := 0 to 255 do
                                                TEditor.DzwPlay(DzwonekDz[i]);
                                       end;
                                 #64 : Break;
                                 #77 : begin
                                           i := TEditor.MaxDzw;
                                           if Cursor + 1 <> i then
                                               begin
                                                    if Cursor > (69 * page) - 2   then
                                                         begin
                                                              Inc(page);
                                                              Inc(Cursor);
                                                              IncColumn(1);
                                                         end
                                                    else
                                                        if Cursor + 1 < i then
                                                           begin
                                                                Inc(cursor);
                                                                IncColumn(1);
                                                           end;
                                               end
                                             else
                                                 begin
                                                      Cursor := 0;
                                                      Page := 1;
                                                      Column := 0;
                                                 end;
                                       end;
                                 #75 : begin
                                     i := TEditor.MaxDzw;
                                     if Cursor <> ((page - 1) * 69) then
                                        begin
                                             Dec(Cursor);
                                             IncColumn(-1);
                                        end
                                     else
                                         begin
                                              if Cursor = 0 then
                                                 begin
                                                      Cursor := i - 1;
                                                      Page := (i div 69) + 1;
                                                      if (i mod 3) = 0 then Column := 2;
                                                      if ((i + 1) mod 3) = 0 then Column := 1;
                                                      if ((i + 2) mod 3) = 0 then Column := 0;
                                                 end
                                              else
                                                  begin
                                                       Dec(Page);
                                                       Cursor := Page * 69 - 1;
                                                       Column := 2;
                                                  end;
                                         end;
                                      end;
                                 #80 : begin
                                            i := TEditor.MaxDzw;
                                            if Column = 2 then
                                               begin
                                                    if ((i div 3) * 3 - 1) = Cursor then
                                                       begin
                                                            Cursor := 2;
                                                            Page := 1;
                                                       end
                                                    else
                                                        begin
                                                             if (Cursor >= ((Page * 69) - 1)) and
                                                                ((((i div 3) * 3) + 2) >= (((Page - 1) * 68) + 1)) then
                                                                      Inc(Page);
                                                             Inc(Cursor,3);
                                                        end;
                                               end;
                                            if Column = 1 then
                                               begin
                                                    if ((((i + 1) div 3) - 1) * 3 + 1) = Cursor then
                                                      begin
                                                           Cursor := 1;
                                                           Page := 1;
                                                      end
                                                    else
                                                        begin
                                                             if (Cursor >= ((Page * 68) - 3)) and
                                                             (((((i + 1) div 3) - 1) * 3 + 4) >= (((Page - 1) * 68) - 3))
                                                                   then Inc(Page);
                                                                Inc(Cursor,3);
                                                        end;
                                               end;
                                            if Column = 0 then
                                               begin
                                                    if (((i + 2) div 3) * 3 - 3) = Cursor then
                                                       begin
                                                            Cursor := 0;
                                                            Page := 1;
                                                       end
                                                    else
                                                        begin
                                                             if ((Cursor >= (Page * 69) - 5)) and (((i + 2) div 3) * 3 - 3
                                                                >= (((Page - 1) * 69) - 8)) then Inc(Page);
                                                             Inc(Cursor,3);
                                                        end;
                                               end;
                                       end;
                                 #72 : begin
                                            i := TEditor.MaxDzw;
                                            case Column of
                                               2 : begin
                                                        if Cursor = 2 then
                                                           begin
                                                                 Cursor := ((i div 3) * 3 - 1);
                                                                 if Cursor >= ((Page * 69)) then Page := ((Cursor div 69) + 1);
                                                           end
                                                        else
                                                            begin
                                                                  Dec(Cursor,3);
                                                                  if Cursor = (((Page - 1) * 69) - 1) then Dec(Page);
                                                            end;
                                                   end;
                                               1 : begin
                                                        if Cursor = 1 then
                                                           begin
                                                                if (i mod 3 = 0) or (( i + 2) mod 3 = 0) then
                                                                   Cursor := (((i div 3) - 1) * 3) + 1
                                                                  else
                                                                   Cursor := ((( i div 3) * 3) + 1);

                                                                  Page := ((i div 69) + 1 );
                                                           end
                                                        else
                                                            Dec(Cursor,3);
                                                            if Cursor = (((Page - 1) * 69) - 2) then Dec(Page);
                                                   end;
                                               0 : begin
                                                        if Cursor = 0 then
                                                           begin
                                                                Cursor := (((i + 2) div 3) * 3 - 3);
                                                                Page := ((i div 69) + 1);
                                                           end
                                                        else
                                                            begin
                                                                 Dec(Cursor,3);
                                                                 if Cursor = (((Page - 1) * 69) - 3) then Dec(Page);
                                                            end;
                                                   end;
                                            end;
                                       end;
                                 #13 : begin
                                            if (TEditor.MaxDzw - 1) > 0 then
                                               begin
                                                    TEditor.DzwRead;
                                                    DzwonekDz[Cursor] := TmpDzw;
                                               end;
                                       end;
{!!!}                            {POMOCNICZE DO USUNIECIA!!!}
                                 #49 : begin
                                            randomize;
                                            TmpDzw.Hz := random(6000);
                                            TmpDzw.Ms := random(1000);
                                            TEditor.DzwAdd(TmpDzw);
                                       end;
                                 #50 : begin
                                            ClrScr;
                                            i := TEditor.MaxDzw;
                                            Writeln('page: ',page, ' cursor: ' , Cursor,' i: ',TEditor.MaxDzw,
                                            ' column: ',Column);
                                            Writeln('Wiersz: ',i div 3);
                                            Writeln((((Page - 1) * (22 div ((i div 69) + 1))) + 2));
                                            Readkey;
                                       end;
                                 #51 : Cursor := 68;
                            end;
                       end;
           end;
end;

procedure TEditor.DzwPlay (Dzw : TDzwiek); {Odgrywa pojedynczy dzwiek}
begin
     Sound(Dzw.Hz);
     Delay(Dzw.Ms);
     NoSound;
end;

procedure TEditor.DznPlay;
begin
     FileEx(FName,false);
     Assign(F,FName);
     Reset(F);
     while not(eof(F)) do
           begin
                Read(F,TmpDzw);
                TEditor.DzwPlay(TmpDzw);
           end;
     Close(f);
end;

procedure TEditor.DzwAdd(Dz : TDzwiek); {Dodaj dzwiek}
var
   i : byte;
begin
     if FName = '' then FName := 'c:\TEMP.dzw';
     FileEx(FName,true);
     for i := 0 to 255 do
         begin
              if (DzwonekDz[i].Ms) = 0 then
                 begin
                      DzwonekDz[i] := Dz;
                      Break;
                 end;
         end;
end;

procedure TEditor.DzwRead;
var
   s : string;
   error : integer;
begin
     ClrScr;
     ProgCommend('Cz©stotliwo† d«wi©ku:');
     Readln(s);
     val(s,TmpDzw.Hz,error);
     ProgCommend('Podaj dugo† trwania d«wi©ku(w ms)');
     Readln(s);
     val(s,TmpDzw.Ms,error);

end;

procedure TEditor.DzwDelete(index : byte);
var
   i : byte;
begin
     for i := index to (TEditor.MaxDzw - 1) do
         begin
             DzwonekDz[i] := DzwonekDz[i + 1];
         end;
     DzwonekDz[TEditor.MaxDzw].Hz := 0;
     DzwonekDz[TEditor.MaxDzw].Ms := 0;
end;
{
=============================================================================
==                             KONIEC METOD OBIEKTU TEditor                ==
=============================================================================
}

{
=============================================================================
==                             METODY OBIEKTU TMemu                        ==
=============================================================================
}

procedure TMenuG.InicjalizujMenu;
begin
     Items[0] := 'Powrot';
     Items[1] := 'Nowy';
     Items[2] := 'Otworz';
     Items[3] := 'Zapisz';
     Items[4] := 'Wyjscie';

     ItemTColor := 7;
     ItemBColor := 0;

     ZazItemTColor := 15;
     ZazItemBColor := 0;
end;

procedure TMenuG.Wyswietl;
var
   i : byte;
begin
     ClrScr;
     Window(30,10,80,25);
     for i := 0 to 4 do
         begin
              if i <> ActItem then
                 begin
                      TextColor(ItemTColor);
                      TextBackground(ItemBColor);
                      Writeln(Items[i]);
                      TextBackground(Black);
                      TextColor(7);
                 end
               else
                 begin
                      TextColor(ZazItemTColor);
                      TextBackground(ZazItemBColor);
                      Writeln(Items[i]);
                      TextBackground(ZazItemBColor);
                      TextColor(7);
                 end;
         end;
     Window(1,1,80,25);
end;

procedure TMenuG.ReadOdp;
begin
     Wyswietl;
     repeat
           begin
                Odp := Readkey;
                   case Ord(Odp) of
                     72 :  if ActItem <> 0 then Dec(ActItem) else ActItem := 4;
                     80 :  if ActItem <> 4 then Inc(ActItem) else ActItem := 0;
                     13 :  case ActItem of
                                     0 : if DzwonekDz[0].Ms <> 0 then Powrot;
                                     1 : Nowy;
                                     2 : Otworz;
                                     3 : Zapisz;
                                     {4 : opcje}
                                     4 : Break;
                                end;
                     27 : Break;
                     97 : begin
                               Skr.WyswietlMenu;
                               ReadKey;
                          end;
                   end;
           Wyswietl;
           end
     until false;
end;

procedure TMEnuG.Powrot;
begin
     ClrScr;
     Editor.column := 0;
     Editor.page := 0;
     Editor.cursor := 0;
     Editor.ReadOdp;
end;

procedure TMenuG.Nowy;
var
     i : byte;
begin
     FName := '';
     for i := 0 to 255 do
         begin
              DzwonekDz[i].Hz := 0;
              DzwonekDz[i].Ms := 0;
         end;
     ClrScr;
     Editor.column := 0;
     Editor.page := 0;
     Editor.cursor := 0;
     Editor.ReadOdp;
end;

procedure TMenuG.Otworz;
begin
     ClrScr;
     repeat
           begin
                ProgCommend('Podaj sciezke dostepu do pliku');
                Readln(FName);
                if FName = '' then Exit; {Gdy nazwa podanego pliku pusta, anuluj}
           end
     until FileEx(FName,false);
     Assign(F,FName);
     Reset(F);
     if FileSize(F) <> 0 then
     while not(eof(F)) do Read(F,DzwonekDz[FilePos(F)]);
     Editor.column := 0;
     Editor.page := 0;
     Editor.cursor := 0;
     Editor.ReadOdp;
end;

procedure TMenuG.Zapisz;
var
   i : byte;
begin
     ClrScr;
     if (FName = '') or (FName = 'c:\TEMP.dzw') then
        begin
             ProgCommend('Podaj nazwe pliku');
             Readln(FName);
             if FName = '' then Exit{Gdy podana nazwa = '', anuluj}
        end;
     Assign(f,FName);
     ReWrite(f);
     for i := 0 to 255 do
         begin
           Write(F,DzwonekDz[i]);
         end;
     Close(f);
     Message('Zapisalem w: ' + FName +'. ',20,10,MessageOpt,0);
end;

{
================================================================================
==                          KONIEC METOD OBIEKTU TMenuG                       ==
================================================================================
}

{
================================================================================
==                          POCZATEK METOD OBIEKTU TSkr                       ==
================================================================================
}

procedure TSkr.InicjalizujMenu;
begin
     TSkr.MenuItems[0] := '[Enter] Dodaj Skr';
     TSkr.MenuItems[1] := '[Del] Usun Skr';

     MenuSkr.ActItem := 0;

     MenuSkr.ItemTColor := 0;
     MenuSkr.ItemBColor := 7;
     MenuSkr.ZazItemTColor := 15;
     MenuSkr.ZazItemBColor := 1;
end;

procedure TSkr.WyswietlMenu;
var
   i : byte;
begin
   GoToXY(13,WhereY);
   for i := 0 to 1 do
      begin
           TextColor(MenuSkr.ItemTColor);
           TextBackground(MenuSkr.ItemBColor);
           Write('   ');
           if MenuSkr.ActItem <> i then
              begin
                   TextColor(MenuSkr.ItemTColor);
                   TextBackground(MenuSkr.ITemBColor);
                   Write(TSkr.MenuItems[i]);
              end
            else
              begin
                   TextColor(MenuSkr.ZazItemTColor);
                   TextBackground(MenuSkr.ZazItemBColor);
                   Write(TSkr.MenuItems[i]);
              end;
      end;
   Write('                    ');
   TextColor(7);
   TextBackground(Black);
end;

{procedure TSkr.WyswietlTabele;
var
   i : byte;
begin
     for i := 0 to 24 do
         begin
              if i = TSkr.TableColors.ActItem then //Jeśli element i zaznaczony...
                 begin
                      TextColor(TSkr.TableColors.ZazItemTColor); //zmien kolor jego tekstu na zaznaczony
                      TextBackground(TSkr.TableColors.ZazITemBColor); //Zmien tlo jego tekstu na zaznaczony
                 end else
                     if i mod 2 = 0 then  //Jesli element parzysty..
                        begin
                             TextColor(TSkr.PTColor);
                             TextBackground(TSkr.PBColor);
                        end
                           else           //Jesli nie...
                               begin
                                    TextColor(TSkr.TableColors.ItemTColor);
                                    TextBackground(TSkr.TableColors.ItemBColor);
                               end;
              WRiteLn(TSkr.SkrTable[i].Key);
         end;
end;}

procedure TSkr.SkrRead(key : byte);
begin
end;

procedure TSkr.SkrAdd;
begin
end;

procedure TSkr.SkrDelete;
begin
end;

{
================================================================================
==                          KONIEC METOD OBIEKTU TSkr                         ==
================================================================================
}

begin
     NoSound;
     //FileEx(ConfigFName,true);
     //Inicjalizacja MessageOption:
     with MessageOpt do
          begin
              MBorderColor := 7;
              MBackgroundColor := 1;
              MTextColor := 15;
              Normal.TextColor := 8;
              Normal.BorderColor := 8;
              Normal.BackgroundColor := 1;
              Zaznaczony.BorderColor := 15;
              Zaznaczony.BackgroundColor := 0;
              Zaznaczony.TextColor := 15;
          end;
     Menu.InicjalizujMenu;
     Skr.InicjalizujMenu;
     Menu.ReadOdp;
     ClrScr;
end.
