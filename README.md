📘 README - fsm-lite (versão modificada)

### 🔍 Objetivo
`fsm-lite` é uma ferramenta para identificação eficiente de *kmers* compartilhados em múltiplos arquivos FASTA, utilizando árvore de sufixos compacta e wavelet tree, baseada na biblioteca [SDSL](https://github.com/simongog/sdsl-lite).

---

### 🚀 Compilação

Requisitos:
- GCC >= 5.0
- Biblioteca SDSL instalada (com headers e libs)

```bash
make
```

Para compilar com informações de debug:
```bash
make DEBUG=1
```

---

### 🔧 Uso Básico
```bash
./fsm-lite -l lista.txt -t saida/tmp [opções]
```

| Parâmetro | Descrição |
|----------|-----------|
| `-l`     | Arquivo texto com pares `<ID> <caminho_fasta>` |
| `-t`     | Prefixo para arquivos temporários |

#### ⚙️ Opções adicionais
| Parâmetro | Descrição | Valor padrão |
|-----------|-----------|---------------|
| `-m`      | Tamanho mínimo do kmer | 9 |
| `-M`      | Tamanho máximo do kmer | 100 |
| `-f`      | Frequência mínima por arquivo | 1 |
| `-s`      | Suporte mínimo (nº de arquivos) | 2 |
| `-S`      | Suporte máximo | `inf` |
| `-v`      | Ativa saída detalhada | - |
| `-D`      | Modo debug (ainda parcial) | - |

---

### ⚠️ Erros comuns

- **Segmentation fault logo após construir estruturas**:
  - Verifique se a RAM foi suficiente para `wt_init`
  - Verifique se `2^DBITS` é maior que o número de arquivos no `-l`
  - Tente executar com `-v` e redirecione o `stderr` para log:
    ```bash
    ./fsm-lite ... -v 2> fsm_debug.log
    ```

- **"[ERRO] Índice fora dos limites"**:
  - Ocorre se `sp`, `bwt[sp]` ou `csa[sp]` está fora do vetor
  - Pode ser problema de entrada corrompida ou limitação de memória

---

### 📂 Exemplo de lista (`lista.txt`)
```
OXA-23 sample1.fa
OXA-24 sample2.fa
```

---

### 🧪 Teste mínimo

Inclua na pasta `test/` dois arquivos FASTA pequenos:

```bash
make test
```

---

### 👷 Desenvolvedores e modificações

Versão modificada por Helena R. S. D'Espíndula (2025)
- Inclusão de mensagens `VERBOSE`
- Validação de índices e memória
- Otimizações de consumo (shrink_to_fit)
- Validação de caracteres BWT

Base original: [fsm-lite](https://github.com/nvalimak/fsm-lite)

---

### 📜 Licença
MIT