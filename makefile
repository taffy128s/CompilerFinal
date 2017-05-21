FF = flex
YY = byacc
YYFLAG = -d
CC = gcc
SRCF = scanner.l
SRCY = parser.y
GENC = lex.yy.c y.tab.c
OTHC = my_code.c
GENH = y.tab.h
EXE = codegen

$(EXE): $(FF) $(YY)
	$(CC) $(GENC) $(OTHC) -o $(EXE)

$(FF): $(SRCF)
	$(FF) $(SRCF)

$(YY): $(SRCY)
	$(YY) $(YYFLAG) $(SRCY)

clean:
	rm $(EXE) $(GENC) $(GENH)
