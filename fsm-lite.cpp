#include "default.h"
#include "configuration.h"
#include "input_reader.h"
#include <sdsl/suffix_trees.hpp>
#include <sdsl/wt_algorithm.hpp>
#include <iostream>
#include <vector>
#include <cstdlib>
using namespace std;

typedef sdsl::cst_sct3<> cst_t;
typedef sdsl::wt_int<> wt_t;
typedef sdsl::bit_vector bitv_t;
typedef cst_t::char_type char_type;
typedef cst_t::node_type node_type;
typedef wt_t::size_type size_type;

void wt_init(wt_t &wt, bitv_t &separator, cst_t &cst, input_reader *ir, configuration &config) {
  uint64_t n = cst.csa.size();
  sdsl::int_vector<DBITS> labels(n, ~0u);
  separator = bitv_t(n, 0);
  uint64_t k = ir->total_seqs() - 1;
  if (cst.csa.wavelet_tree.size() == 0) {
    cerr << "[ERRO] wavelet_tree vazio." << endl;
    exit(1);
  }
  uint64_t j = cst.csa.wavelet_tree.select(1, 0);
  if (config.debug)
    cerr << "bwt end marker pos = " << j << endl;
  uint64_t bwtendpos = j;
  
  if (j >= cst.csa.lf.size()) {
    cerr << "[ERRO] Índice 'j' fora dos limites de lf[]." << endl;
    exit(1);
  }
  j = cst.csa.lf[j];
  
  labels[j] = 0;
  separator[n - 1] = 0;
  separator[n - 2] = 1;
  
  for (uint64_t i = n - 2; i > 0; i--) {
    if (j >= cst.csa.lf.size()) {
      cerr << "[ERRO] Índice 'j' fora dos limites de lf[] durante iteração." << endl;
      exit(1);
    }
    char_type c = cst.csa.bwt[j];
    labels[j] = k;
    if (c == '$') k--;
    if (c == '$' || c == '#') separator[i - 1] = 1;
    j = cst.csa.lf[j];
  }
  
  labels[j] = k;
  if (j != bwtendpos || k != 0) {
    cerr << "[ERROR]Labeling failed, j = " << j << ", k = " << k << endl;
    exit(1);
  }
  
  std::string tmp_file = sdsl::ram_file_name(sdsl::util::to_string(sdsl::util::pid()) + "_" + sdsl::util::to_string(sdsl::util::id()));
  sdsl::store_to_file(labels, tmp_file);
  sdsl::int_vector_buffer<DBITS> text_buf(tmp_file);
  wt = wt_t(text_buf, labels.size());
  
  if (config.debug)
    cerr << "wt size = " << wt.size() << ", n = " << n << endl;
  
  uint64_t j_sum = 0;
  for (uint64_t i = 0; i < ir->size(); ++i)
    j_sum += wt.rank(n, i);
  
  if (j_sum != n) {
    cerr << "[ERROR]Label sum failed, j = " << j_sum << ", n = " << n << endl;
    exit(1);
  }
}

int main(int argc, char **argv) {
  configuration config(argc, argv);
  if (!config.good) config.print_short_usage();
  
  input_reader *ir = input_reader::build(config);
  
  if (config.verbose)
    cerr << "Reading input files...\nRead " << ir->size() << " input files and " << ir->total_seqs() << " sequences of total length " << ir->total_size() << endl;
  
  if (config.verbose) cerr << "Constructing the data structures..." << endl;
  cst_t cst;
  construct(cst, config.tmpfile + ".tmp", 1);
  
  if (cst.empty()) {
    cerr << "[ERRO] O CST está vazio." << endl;
    exit(1);
  }
  
  wt_t label_wt;
  bitv_t separator;
  wt_init(label_wt, separator, cst, ir, config);
  
  bitv_t::rank_1_type sep_rank1(&separator);
  if (sep_rank1(cst.size()) != ir->total_seqs()) {
    cerr << "[ERRO] Número de separadores diferente do número de sequências." << endl;
    exit(1);
  }
  
  size_type support = 0;
  vector<wt_t::value_type> result_labels(ir->size(), 0);
  vector<size_type> rank_sp(ir->size(), 0);
  vector<size_type> rank_ep(ir->size(), 0);
  
  node_type root = cst.root();
  vector<node_type> buffer;
  buffer.reserve(1024 * 1024);
  for (auto &child : cst.children(root)) buffer.push_back(child);
  
  while (!buffer.empty()) {
    node_type node = buffer.back();
    buffer.pop_back();
    
    unsigned depth = cst.depth(node);
    if (depth > 10000) continue;
    if (depth < config.maxlength)
      for (auto &child : cst.children(node)) buffer.push_back(child);
    if (depth < config.minlength || cst.is_leaf(node)) continue;
    
    size_type sp = cst.lb(node), ep = cst.rb(node);
    if (sp >= cst.csa.bwt.size()) {
      cerr << "[ERRO] sp fora do limite de BWT." << endl;
      exit(1);
    }
    
    char_type next_char = cst.csa.bwt[sp];
    if (next_char == '\0' || next_char > 127) continue;
    
    node_type wn = cst.wl(node, next_char);
    if (wn == cst.root() || wn == node) continue;
    
    if (depth < config.maxlength && cst.rb(wn) - cst.lb(wn) == ep - sp)
      continue;
    
    sdsl::interval_symbols(label_wt, sp, ep + 1, support, result_labels, rank_sp, rank_ep);
    if (support < config.minsupport || support > config.maxsupport) continue;
    
    size_type truesupp = 0;
    for (size_type i = 0; i < support; ++i)
      if (config.minfreq <= rank_ep[i] - rank_sp[i]) ++truesupp;
      if (truesupp < config.minsupport) continue;
      
      if (depth > config.maxlength) depth = config.maxlength;
      
      if (sp >= cst.csa.size()) {
        cerr << "[ERRO] sp fora do limite de CSA." << endl;
        exit(1);
      }
      
      size_type pos = cst.csa[sp];
      if (pos + depth - 1 >= cst.csa.size()) continue;
      auto s = extract(cst.csa, pos, pos + depth - 1);
      if (input_reader::smaller_than_rev_cmpl(s)) continue;
      
      cout << s + " |";
      for (size_type i = 0; i < support; ++i)
        if (config.minfreq <= rank_ep[i] - rank_sp[i])
          cout << ' ' << ir->id(result_labels[i]) << ':' << rank_ep[i] - rank_sp[i];
        cout << '\n';
        
        result_labels.clear(); rank_sp.clear(); rank_ep.clear();
        result_labels.shrink_to_fit(); rank_sp.shrink_to_fit(); rank_ep.shrink_to_fit();
  }
  
  delete ir;
  return 0;
}
