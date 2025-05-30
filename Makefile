# =========================
# Configuration Parameters
# =========================

# SDSL installation path for fsm-lite
SDSL_INSTALL_PREFIX=/home/joyce.souza

# Compiler and flags
CXX=g++
CPPFLAGS=-std=c++11 -I$(SDSL_INSTALL_PREFIX)/include -DNDEBUG -O3 -msse4.2 -I./gzstream
LIBS=-lsdsl -ldivsufsort -ldivsufsort64

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

# Installation prefix for boost (if needed)
PREFIX=${HOME}/software

# Linker options for dynamic and static builds
COMBINE_LDLIBS=-lz -lboost_program_options
COMMON_LDLIBS=-static -static-libstdc++ -static-libgcc
COMBINE_STATIC_LDLIBS=$(COMMON_LDLIBS) -lz -lboost_program_options

# Object files for combineKmers
COMBINE_OBJECTS=combineInit.o combineCmdLine.o combineKmers.o gzstream/gzstream.o

# Build target for dynamic combineKmers
combineKmers: $(COMBINE_OBJECTS)
	$(CXX) $(CPPFLAGS) $^ $(COMBINE_LDLIBS) -o $@

# Build target for static combineKmers
combineKmers_static: $(COMBINE_OBJECTS)
	$(CXX) $(CPPFLAGS) $^ $(COMBINE_STATIC_LDLIBS) -o combineKmers

# Rule to build gzstream object
gzstream/gzstream.o: gzstream/gzstream.C gzstream/gzstream.h
	$(CXX) $(CPPFLAGS) -c $< -o $@

# =========
# Utilities
# =========

# Clean up object and binary files
clean:
	$(RM) fsm-lite combineKmers *.o gzstream/*.o *~

# Automatically generate header dependencies
depend:
	g++ -MM -std=c++11 -I$(SDSL_INSTALL_PREFIX)/include *.cpp > dependencies.mk

# Include dependencies if present
-include dependencies.mk

# ============
# Phony Targets
# ============

.PHONY: all test clean depend combineKmers combineKmers_static
