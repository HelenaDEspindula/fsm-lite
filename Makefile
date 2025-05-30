SDSL_PREFIX ?= $(HOME)/software
CPPFLAGS += -std=c++11 -I$(SDSL_PREFIX)/include $(EXTRAFLAGS)
LDFLAGS  += -L$(SDSL_PREFIX)/lib -lsdsl -ldivsufsort -ldivsufsort64
OBJ = configuration.o input_reader.o fsm-lite.o

ifdef DEBUG
CPPFLAGS += -DDEBUG -g -O0
else
CPPFLAGS += -DNDEBUG -O3 -msse4.2
endif

all: fsm-lite

fsm-lite: $(OBJ)
	$(CXX) $(CPPFLAGS) -o $@ $^ $(LDFLAGS)

test: fsm-lite
	./fsm-lite -l test/list.txt -t test/tmp -v

clean:
	rm -f *.o fsm-lite *~ test/tmp.* test/tmp.meta