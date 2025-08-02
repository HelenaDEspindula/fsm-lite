#include "default.h"
#include "configuration.h"
#include "input_reader.h"
#include <sdsl/suffix_trees.hpp>

using namespace std;
using namespace sdsl;

int main(int argc, char **argv)
{
    configuration config(argc, argv);

    cerr << "[DEBUG] Iniciando leitura dos dados..." << endl;
    input_reader *reader = input_reader::build(config);

    cerr << "[DEBUG] Lendo e concatenando sequências..." << endl;
    string concatenated_text = reader->load_and_concatenate_input(config);
    size_t num_seqs = reader->total_seqs();

    cerr << "[DEBUG] Número total de sequências: " << num_seqs << endl;
    cerr << "[DEBUG] Comprimento do texto concatenado: " << concatenated_text.size() << endl;
    cerr << "[DEBUG] Primeiros 100 caracteres: " << concatenated_text.substr(0, 100) << endl;

    cerr << "[DEBUG] Construindo CST..." << endl;
    cst_sada<> cst;
    construct_im(cst, concatenated_text, 1);
    cerr << "[DEBUG] CST construída com sucesso." << endl;
    cerr << "[DEBUG] Tamanho do índice: " << cst.size() << " nós" << endl;

    // Placeholder para lógica de labeling e extração de k-mers
    cerr << "[DEBUG] Execução completa. (Lógica de mineração ainda não implementada nesta versão)" << endl;

    delete reader;
    return 0;
}
