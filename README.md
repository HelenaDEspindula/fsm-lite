## 📘 README - fsm-lite (modified version)


### 🔍 Overview
`fsm-lite` is a tool for efficiently identifying shared *kmers* across multiple FASTA files using a compact suffix tree and wavelet tree, based on the [SDSL](https://github.com/simongog/sdsl-lite) library.

---

### 🚀 Compilation

Requirements:
- GCC >= 5.0
- SDSL library installed (with headers and libraries available)

```bash
make depend && make
```

To compile with debug information:
```bash
make depend && make DEBUG=1
```

---

### 📂 Imput List File (`list.txt`)

```
P1 sample1.fa
P2 sample2.fa
```

Input files are given as a list of <data-identifier> <data-filename> pairs. 
The <data-identifier>'s are assumed to be unique. 
Here's an example how to construct such a list out of all /input/dir/*.fasta files:

```bash
for f in /input/dir/*.fasta; do id=$(basename "$f" .fasta); echo $id $f; done > input.list
```
---

### 🔧 Basic Usage
The files can then be processed by

```bash
./fsm-lite -l input.list -t tmp | gzip - > output.txt.gz
```
where `tmp` is a prefix filename for storing temporary index files.

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
| `--help`  | Enable debug mode | - |

---

### 👷 Contributors & Modifications

Modified by Helena R. S. D'Espíndula (2025)
- Verbose logging (`[VERBOSE]` messages)
- Index validation & bounds checking
- Memory usage optimizations (`shrink_to_fit`)
- BWT character validation

Original base: [fsm-lite](https://github.com/nvalimak/fsm-lite)

---