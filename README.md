# INP_1_2021

21/23 bodů

INP první projekt, 2021
- [x]  vypis ABCDEFGHIJKL
- [x]  vypis inp-proj2021
- [ ]  vypis znaku z klavesnice 
- [x]  vypis ABCD skrze tildu
- [x]  vypis xlogin
- [x]  vypis xlogin na FitKit
- [x]  vnořené cykly 

# Poznámky vyučujícího
Overeni cinnosti kodu CPU:
   testovany program (kod)       vysledek
   1.  ++++++++++                    ok
   2.  ----------                    ok
   3.  +>++>+++                      ok
   4.  <+<++<+++                     ok
   5.  .+.+.+.                       ok
   6.  ,+,+,+,                       chyba
   7.  [........]noLCD[.........]    ok
   8.  +++[.-]                       ok
   9.  +++++[>++[>+.<-]<-]           ok
  10.  +[+~.------------]+           ok

  Podpora jednoduchych cyklu: ano
  Podpora vnorenych cyklu: ano

Poznamky k implementaci:
Data z klavesnice korektne nactena, ale chybne zapsana do RAM (zpozdeni jeden takt)
Mozne problematicke rizeni nasledujicich signalu: OUT_DATA

Celkem bodu za CPU implementaci: 15 (z 17)
