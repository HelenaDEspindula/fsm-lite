## 📘 README - fsm-lite (modified version)

### 🔍 Overview
`fsm-lite` is a tool for efficiently identifying shared *kmers* across multiple FASTA files using a compact suffix tree and wavelet tree, based on the [SDSL](https://github.com/simongog/sdsl-lite) library.

---

### 🚀 Compilation

Requirements:
- GCC >= 5.0
- SDSL library installed (with headers and libraries available)

```bash
make
```

To compile with debug information:
```bash
make DEBUG=1
```

---

### 🔧 Basic Usage
```bash
./fsm-lite -l list.txt -t output/tmp [options]
```

| Parameter | Description |
|-----------|-------------|
| `-l`      | Text file listing `<ID> <fasta_path>` pairs |
| `-t`      | Prefix for temporary output files |

#### ⚙️ Additional Options
| Parameter | Description | Default |
|-----------|-------------|---------|
| `-m`      | Minimum kmer length | 9 |
| `-M`      | Maximum kmer length | 100 |
| `-f`      | Minimum frequency per input file | 1 |
| `-s`      | Minimum number of files supporting the kmer | 2 |
| `-S`      | Maximum number of supporting files | `inf` |
| `-v`      | Enable verbose output | - |
| `-D`      | Enable debug mode | - |

---

### ⚠️ Common Errors

- **Segmentation fault after structure construction**:
  - Check if system RAM is sufficient for `wt_init`
  - Make sure number of input files ≤ `2^DBITS` in `default.h`
  - Run with `-v` and redirect `stderr`:
    ```bash
    ./fsm-lite ... -v 2> fsm_debug.log
    ```

- **"[ERROR] Index out of bounds"**:
  - Can happen with malformed input or memory exhaustion

---

### 📂 Example List File (`list.txt`)
```
OXA-23 sample1.fa
OXA-24 sample2.fa
```

---

### 🧪 Minimal Test

Place two small FASTA files under `test/`, then run:

```bash
make test
```

---

### 👷 Contributors & Modifications

Modified by Helena R. S. D'Espíndula (2025)
- Verbose logging (`[VERBOSE]` messages)
- Index validation & bounds checking
- Memory usage optimizations (`shrink_to_fit`)
- BWT character validation

Original base: [fsm-lite](https://github.com/nvalimak/fsm-lite)

---

### 📜 License
MIT

---

### 📄 Makefile with DEBUG Support

```makefile
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
```

---

### 🧰 Execution Script with Logging (`fsm_lite_modificacoes.sh`)

```bash
#!/bin/bash

INPUT_LIST=$1
TMP_PREFIX=$2
MINLEN=6
MAXLEN=610

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
LOGDIR="logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/fsm_output_log_${DATE}.txt"

ulimit -v 838860800

TMUX_SESSION="fsm_run_$DATE"
tmux new-session -d -s $TMUX_SESSION "./fsm-lite -l $INPUT_LIST -t $TMP_PREFIX -s $MINLEN -S $MAXLEN -v > $LOGFILE 2>&1"
tmux split-window -h -t $TMUX_SESSION "watch -n 1 'ps -o pid,vsz,comm -C fsm-lite'"
tmux attach -t $TMUX_SESSION
```

This script allows:
- Execution within `tmux`
- Automatic log creation with timestamps
- Live process monitoring with `watch`
