Frequency-based String Mining (lite)
===

# FSM-lite v1.0

**Frequency-based String Mining (lite)**

FSM-lite is a single-core implementation of frequency-based substring mining over large sequence datasets. It relies on compressed suffix trees provided by the [SDSL-lite](https://github.com/simongog/sdsl-lite) library. This implementation has been tested with `sdsl-lite-2.0.3`.

---

## Installation and Recommended Setup

To ensure compatibility and proper versions of required libraries, we highly recommend installing FSM-lite via [Conda](https://docs.conda.io/en/latest/). This guarantees a working configuration, especially for the SDSL-lite dependency.

### Conda Installation (Recommended)

Create a new Conda environment and install `sdsl-lite` and `fsm-lite` from the official channels:

```bash
conda create -n fsm-env -c conda-forge -c bioconda sdsl-lite fsm-lite
conda activate fsm-env
```

Alternatively, you can use the explicit environment specification below.

#### Predefined Environment File

Save the following as `fsm-env.txt` and recreate the exact environment:

```bash
conda create --name fsm-env --file fsm-env.txt
```

**Contents of `fsm-env.txt`:**

```
# platform: linux-64
# created-by: conda 25.5.1
@EXPLICIT
https://repo.anaconda.com/pkgs/main/linux-64/_libgcc_mutex-0.1-main.conda
https://conda.anaconda.org/conda-forge/linux-64/libgomp-15.1.0-h767d61c_4.conda
https://repo.anaconda.com/pkgs/main/linux-64/_openmp_mutex-5.1-1_gnu.conda
https://conda.anaconda.org/conda-forge/linux-64/libgcc-15.1.0-h767d61c_4.conda
https://conda.anaconda.org/conda-forge/linux-64/libgcc-ng-15.1.0-h69a702a_4.conda
https://conda.anaconda.org/conda-forge/linux-64/libstdcxx-15.1.0-h8f9b012_4.conda
https://conda.anaconda.org/conda-forge/linux-64/libstdcxx-ng-15.1.0-h4852527_4.conda
https://conda.anaconda.org/conda-forge/linux-64/sdsl-lite-2.1.1-h00ab1b0_1002.conda
https://conda.anaconda.org/bioconda/linux-64/fsm-lite-1.0-h9948957_6.tar.bz2
```

### Manual Installation (Advanced)

To compile FSM-lite manually:

1. Download and extract [`sdsl-lite-2.0.3`](https://github.com/simongog/sdsl-lite/archive/v2.0.3.tar.gz)
2. Install SDSL with:  
   ```bash
   ./install.sh /your/installation/path/sdsl-lite-2.0.3
   ```
3. Edit the `fsm-lite/Makefile` to set the correct SDSL path.
4. Optionally, adjust compiler optimization flags in the Makefile.
5. Compile with:  
   ```bash
   make depend && make
   ```

---

## Usage

Input files must be provided as a plain text list with lines containing:

```
<unique_identifier> <absolute_or_relative_path_to_fasta_file>
```

### Generating Input List

Example script to list `.fasta` files in `/input/dir/`:

```bash
for f in /input/dir/*.fasta; do
  id=$(basename "$f" .fasta)
  echo "$id $f"
done > input.list
```

### Running FSM-lite


```bash
./fsm-lite -l input.list -t tmp | gzip > output.txt.gz
```

`tmp` is a prefix used for creating temporary index files.

### Debug Mode

Use `--debug` and `-v` to enable verbose output for development and troubleshooting:

```bash
./fsm-lite -l input.list -t tmp -v --debug | gzip > output.txt.gz
```

For full command-line options:

```bash
./fsm-lite --help
```

---

## Links

- [FSM-lite on Bioconda](https://anaconda.org/bioconda/fsm-lite)
- [SDSL-lite on Conda-Forge](https://anaconda.org/conda-forge/sdsl-lite)
- [SDSL-lite GitHub](https://github.com/simongog/sdsl-lite)

---

## TODO

1. Optimize time and memory efficiency.
2. Implement multi-threading support.
3. Enable gzip-compressed input support.

---
