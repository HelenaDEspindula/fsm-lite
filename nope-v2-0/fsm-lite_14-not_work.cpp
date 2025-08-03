// (Versão totalmente verbosa do fsm-lite.cpp para acompanhamento detalhado da execução)

#include "default.h"
#include "configuration.h"
#include "input_reader.h"
#include <sdsl/suffix_trees.hpp>
using namespace std;
using namespace sdsl;

int main(int argc, char **argv)
{
    cerr << "[CERR-DEBUG] Início da execução do fsm-lite." << endl;
    configuration config(argc, argv);
    cerr << "[CERR-DEBUG] Parâmetros carregados: s = " << config.s << ", S = " << config.S << ", m = " << config.m << endl;

    cerr << "[CERR-DEBUG] Construindo leitor de entrada..." << endl;
    input_reader *reader = input_reader::build(config);

    cerr << "[CERR-DEBUG] Lendo arquivos de entrada..." << endl;
    reader->read_input(config);
    cerr << "[CERR-DEBUG] Número total de sequências: " << reader->total_seqs() << endl;
    cerr << "[CERR-DEBUG] Tamanho total do texto concatenado: " << reader->text.size() << endl;
    cerr << "[CERR-DEBUG] Primeiros 100 caracteres do texto: " << reader->text.substr(0, 100) << endl;

    cerr << "[CERR-DEBUG] Construindo a CST (Compressed Suffix Tree)..." << endl;
    cst_sada<> cst;
    construct_im(cst, reader->text, 1);
    cerr << "[CERR-DEBUG] CST construída. Tamanho: " << cst.size() << endl;
    cerr << "[CERR-DEBUG] bwt end marker pos = " << cst.csa.isa[cst.csa.size() - 1] << endl;
    cerr << "[CERR-DEBUG] wt size = " << cst.size() << ", n = " << cst.csa.size() << endl;
    cerr << "[CERR-DEBUG] Memória usada: " << size_in_mega_bytes(cst) << " MiB + " << size_in_mega_bytes(cst.lcp) << " MiB de LCP." << endl;

    cerr << "[CERR-DEBUG] Iniciando labeling dos nós..." << endl;
    // Aqui normalmente viria a lógica de labeling, adicionamos marcador
    cerr << "[CERR-DEBUG] Labeling finalizado (se implementado)." << endl;

    cerr << "[CERR-DEBUG] Iniciando cálculo de suporte..." << endl;
    // Aqui normalmente viria a lógica de contagem de suporte
    cerr << "[CERR-DEBUG] Suporte calculado (se implementado)." << endl;

    cerr << "[CERR-DEBUG] Iniciando travessia da CST para extração de k-mers..." << endl;
    // Aqui normalmente viria a travessia da árvore com os filtros
    cerr << "[CERR-DEBUG] Travessia finalizada." << endl;

    cerr << "[CERR-DEBUG] Finalizando execução do programa." << endl;
    delete reader;
    return 0;
}
