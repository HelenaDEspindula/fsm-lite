SDSL_INSTALL_PREFIX=/home/helena.despindula/.conda/pkgs/sdsl-lite-2.1.1-h00ab1b0_1002

CPPFLAGS=-std=c++11 -I$(SDSL_INSTALL_PREFIX)/include -DNDEBUG -O3 -msse4.2
LIBS=-lsdsl -ldivsufsort -ldivsufsort64
OBJ = configuration.o input_reader.o fsm-lite.o

fsm-lite: $(OBJ)
	$(LINK.cpp) $^ -L$(SDSL_INSTALL_PREFIX)/lib $(LIBS) -o $@

test: fsm-lite
	./fsm-lite -l test.list -t tmp -v --debug -m 1

clean:
	$(RM) fsm-lite *.o *~

depend:
	g++ -MM -std=c++11 -I$(SDSL_INSTALL_PREFIX)/include *.cpp > dependencies.mk

include dependencies.mk
