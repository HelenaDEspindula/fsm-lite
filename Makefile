# =========================
# Configuration Parameters
# =========================

# SDSL installation path for fsm-lite
SDSL_INSTALL_PREFIX=/home/joyce.souza

# Include and compiler flags
CPPFLAGS=-std=c++11 -I$(SDSL_INSTALL_PREFIX)/include -DNDEBUG -O3 -msse4.2
LIBS=-lsdsl -ldivsufsort -ldivsufsort64

# Compiler
CXX=g++

# ====================
# fsm-lite Build Rules
# ====================

# Object files for fsm-lite
OBJ = configuration.o input_reader.o fsm-lite.o

# Build target for fsm-lite
fsm-lite: $(OBJ)
	$(LINK.cpp) $^ -L$(SDSL_INSTALL_PREFIX)/lib $(LIBS) -o $@

# Test command for fsm-lite
test: fsm-lite
	./fsm-lite -l test.list -t tmp -v --debug -m 1

# =========================
# combineKmers Build Rules
# =========================

# Installation prefix for gzstream/boost headers and libraries
PREFIX=${HOME}/software

# Include paths (add gzstream support)
COMBINE_CPPFLAGS=-I$(PREFIX)/include -I../gzstream

# Linker options for dynamic and static builds
COMBINE_LDLIBS=-L../gzstream -L$(PREFIX)/lib -lgzstream -lz -lboost_program_options
COMMON_LDLIBS=-L../gzstream -L$(PREFIX)/lib -static -static-libstdc++ -static-libgcc
COMBINE_STATIC_LDLIBS=$(COMMON_LDLIBS) -lgzstream -lz -lboost_program_options

# Object files for combineKmers
COMBINE_OBJECTS=combineInit.o combineCmdLine.o combineKmers.o

# Build target for dynamic combineKmers
combineKmers: $(COMBINE_OBJECTS)
	$(CXX) $(CPPFLAGS) $(COMBINE_CPPFLAGS) $^ $(COMBINE_LDLIBS) -o $@

# Build target for static combineKmers
combineKmers_static: $(COMBINE_OBJECTS)
	$(CXX) $(CPPFLAGS) $(COMBINE_CPPFLAGS) $^ $(COMBINE_STATIC_LDLIBS) -o combineKmers

# =========
# Utilities
# =========

# Clean up object and binary files
clean:
	$(RM) fsm-lite combineKmers *.o *~

# Automatically generate header dependencies
depend:
	g++ -MM -std=c++11 -I$(SDSL_INSTALL_PREFIX)/include *.cpp > dependencies.mk

# Include dependencies if present
-include dependencies.mk

# ============
# Phony Targets
# ============

.PHONY: all test clean depend combineKmers combineKmers_static
