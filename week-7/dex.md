```sol
function echidna_drain() public returns (bool) {
    return token0.balanceOf(address(dex)) >= 100e18 || token1.balanceOf(address(dex)) >= 100e18;
}
```

echidna_drain: FAILED! with ReturnFalse
                                                                                  
Call sequence:                                                                                                            
1.swap0_1(732110104287765549726780293162884721803425292054755846474152051621903)                                          
2.swap1_0(23992987528886962943556159745482612983417260389941142191365961780)                                              
3.swap1_0(127421175380867807798430934335171293683858675660190063046233518979)                                             


```sol
function echidna_drain() public returns (bool) {
    return token0.balanceOf(address(dex)) > 10e18 || token1.balanceOf(address(dex)) > 10e18;
}
```

echidna_drain: FAILED! with ReturnFalse
Call sequence:
1. swap0_1 (28347715217802670548969482561454023606203431966721846133622721190488773746979)
2. swap0_1 (50399339768240409167346311450033058604848698052139882356609902384811817476)
3. swap1_0 (33435706563808611571779458044060555009222283003870420604395783764869839164)
4. swap1_0 (98980026268023879098640342261794760000299510577188667898544223407655796738)
5. swapo_1 (57120)
6. swap1_0 (290270)
7. swap0_1 (61007101116961596183519497989992077609626857864265441191953738503504054019806)
8. swap1_0 (3991780337288727588439386044892992375010138394469038170739774740435048576777)
9. swap0_1 (33099995257843975453974133547732207243950828819180110679176299104818775098754)
10. swap1_0 (12539738579755918939458601067439401246894842748925459888573847290729971356922)
11. swap1_0 (2)
12. swap0_1 (59230850494400642862497171813754717767417673195065982581975159762134585311019)
13. swap0_1 (46718700595374531544)
14. swap1_0 (41894715603890328872512150449555588603158121372714195241926194821007871)
15. swap0_1 (392127796804200373849939527428522892433811557665230132938534267369900053107)
16. swap1_0 (4499419628303660551)
17. swap1_0 (8555593669830776121184397860745849096012566508184021605753412958498371094125)
18. swap0_1 (2106513742915912197444579875096326746169933201212017375614889193763022782195)
19. swap1_0 (109999999999999999999)