/* VERSION 2.0 */

/* --- Includes and Namespace --- */

#include "default.h"
#include "configuration.h"
#include "input_reader.h"
#include <sdsl/suffix_trees.hpp> 
#include <sdsl/wt_algorithm.hpp>
#include <iostream>
#include <vector>
#include <cstdlib> // std::exit()

using namespace std;

/* --- Type Definitions --- */

typedef sdsl::cst_sct3<> cst_t;
typedef sdsl::wt_int<> wt_t;
typedef sdsl::bit_vector bitv_t;
typedef cst_t::char_type char_type;
typedef cst_t::node_type node_type;
typedef wt_t::size_type size_type;

/**
 * Construct the sequence labels
 *
 * Assumes that the number of input files is less than 2^DBITS.
 * The value of DBITS has to be set at compile time (in defaults.h).
 * Large DBITS values result in large memory requirements for wt_init().
 */

/* --- Wavelet tree function --- */

void wt_init(wt_t &wt, bitv_t &separator, cst_t &cst, input_reader *ir, configuration &config)
{
  uint64_t n = cst.csa.size();
  sdsl::int_vector<DBITS> labels(n, ~0u);
  separator = bitv_t(n, 0);
  uint64_t k = ir->size()-1;
  uint64_t j = cst.csa.wavelet_tree.select(1, 0);
  if (config.debug)
    cerr << "[DEBUG] bwt end marker pos = " << j << endl;
  uint64_t bwtendpos = j;
  
  /* New in Version 2.1 */
  if (j >= cst.csa.lf.size()) {
    cerr << "[ERRO] Índice 'j' fora dos limites de lf[]." << endl;
    exit(1);
  }
  /* --- */
  
  
  
  j = cst.csa.lf[j];
  labels[j] = 0;  // Label of last byte
  separator[n-1] = 0;
  separator[n-2] = 1;
  j = cst.csa.lf[j];
  for (uint64_t i = n-2; i > 0; i--) {
    char_type c = cst.csa.bwt[j];
    labels[j] = k;
    if (c == '$')
      k --;
    if (c == '$' || c == '#')
      separator[i-1] = 1;
    
    j = cst.csa.lf[j];
  }
  labels[j] = k;
  if (j != bwtendpos || k != 0) // Assert
  {
    cerr << "[ERROR] Labeling failed, j = " << j << ", k = " << k << endl;
    exit(1);
  }
  
  
  /* 
   * std::string tmp_file = sdsl::ram_file_name(sdsl::util::to_string(sdsl::util::pid())+"_"+sdsl::util::to_string(sdsl::util::id()));
   * sdsl::store_to_file(labels, tmp_file);
   * sdsl::int_vector_buffer<DBITS> text_buf(tmp_file);
   * wt = wt_t(text_buf, labels.size()); 
  */
  
  /* New in Version 2.5 */
  sdsl::construct_im(wt, labels, 1);
  /* --- */
  
  if (config.debug)
    cerr << "[DEBUG] wt size = " << wt.size() << ", n = " << n << endl;
  j = 0;
  for (uint64_t i = 0; i < ir->size(); ++i)
    j += wt.rank(n, i);
  if (j != n) // Assert
  {
    cerr << "[ERROR] Label sum failed, j = " << j << ", n = " << n << endl;
    exit(1);
  }
  
}

/* --- Main function --- */

int main(int argc, char ** argv)
{
  configuration config(argc, argv);
  if (!config.good)
    config.print_short_usage();
  
  if (config.verbose)
    cerr << "[VERBOSE] Reading input files..." << endl;
  input_reader *ir = input_reader::build(config);
  if (config.verbose)
    cerr << "[VERBOSE] Read " << ir->size() << " input files and " << ir->total_seqs() << " sequences of total length " << ir->total_size() << " (includes rev.compl. sequences)" << endl;
  
  /**
   * Initialize the data structures
   */
  if (config.verbose)
    cerr << "[VERBOSE] Constructing the data structures..." << endl;
  cst_t cst;    
  construct(cst, config.tmpfile + ".tmp", 1);
  
  /* Modify in Version 2.1 */
  if (config.verbose)
    cerr << "[VERBOSE] cst built successfully. Size: " << cst.size() << endl;
  
  if (!cst.csa.size())
  {
    cerr << "error: unable to construct the data structure; out of memory?" << endl;
    if (config.verbose)
      cerr << "[VERBOSE] Failed to build cst. Total data size may have exceeded RAM capacity." << endl;
    abort();
  }
  /* --- */
  
  
  wt_t label_wt;
  bitv_t separator;
  wt_init(label_wt, separator, cst, ir, config);
  
  /* New in Version 2.2 */
  if (config.verbose)
    cerr << "[VERBOSE] Wavelet tree e vetor de separadores inicializados." << endl;
  /* --- */
  
  bitv_t::rank_1_type sep_rank1(&separator);
  
  assert(sep_rank1(cst.size()) == ir->total_seqs());
  
  size_type support = 0;
  vector<wt_t::value_type> labels(ir->size(), 0);
  vector<size_type> rank_sp(ir->size(), 0);
  vector<size_type> rank_ep(ir->size(), 0);
  
  if (config.verbose)
    cerr << "[VERBOSE] Construction complete, the main index requires " << size_in_mega_bytes(cst) << " MiB plus " << size_in_mega_bytes(label_wt) << " MiB for labels." << endl;
  
  /**
   * Main Processing Loop
   * Steps:
   * 1. Node processing (depth-first traversal)
   * 2. Length filtering (`minlength`/`maxlength`)
   * 3. Weiner link checks
   * 4. Support calculation
   * 5. Frequency filtering
   * 6. Pattern output
   */
  
  /* New in Version 2.2 */
  if (config.verbose)
    cerr << "[VERBOSE] Starting suffix tree traversal..." << endl;
  /* --- */
  
  node_type root = cst.root();
  vector<node_type> buffer;
  buffer.reserve(1024*1024);
  for (auto& child: cst.children(root))
    buffer.push_back(child);
  while (!buffer.empty())
  {
    
    /* New in Version 2.2 */
    if (config.verbose)
      cerr << "[VERBOSE] Iteração: buffer com " << buffer.size() << " nós." << endl;
    
    static size_t node_counter = 0;
    node_counter++;
    if (config.verbose && node_counter % 100000 == 0){
      cerr << "[VERBOSE] Processados " << node_counter << " nós da árvore de sufixos..." << endl;
    }
    /* --- */
    
    node_type const node = buffer.back();
    buffer.pop_back();        
    unsigned depth = cst.depth(node);
    
    /* New in Version 2.2 */
    static size_t max_depth_seen = 0;
    if (depth > max_depth_seen) {
      max_depth_seen = depth;
      cerr << "[VERBOSE] Nova profundidade máxima observada: " << depth << endl;
    }
    /* --- */
    
    /* New in Version 2.0 */
    if (depth > 1000)
      continue;
    /* --- */
    
    if (depth < config.maxlength)
      for (auto& child: cst.children(node))
        buffer.push_back(child);
    if (depth < config.minlength)
      continue;
    if (cst.is_leaf(node))
      continue;
    
    // Process the candidate node
    size_type sp = cst.lb(node);
    size_type ep = cst.rb(node);
    
    
    /* New in Version 2.3 */
    if (config.verbose)
      cerr << "[VERBOSE] Accessing cst.csa.bwt[sp] with sp = " << sp
           << ", bwt.size() = " << cst.csa.bwt.size() << endl;
      
      if (sp >= cst.csa.bwt.size()) {
        cerr << "[ERRO] sp value outside the BWT vector limit: sp = "
             << sp << ", limite = " << cst.csa.bwt.size() << endl;
        exit(1);
      }
      char_type next_char = cst.csa.bwt[sp];
      
      // Protects against invalid characters (e.g. '\0' or other unexpected characters)
      if (next_char == '\0' || next_char > 127) {
        cerr << "[ERRO] Invalid character for Weiner-link: bwt[sp] = " << (int)next_char << endl;
        continue;
      }
      
      node_type wn = cst.wl(node, next_char);
      
      // To validate that the link is valid:
      if (wn == cst.root()) {
        if (config.verbose)
          cerr << "[VERBOSE] No Weiner-link available for node with sp = "
               << sp << ", bwt[sp] = " << cst.csa.bwt[sp] << endl;
          continue;
      }
      /* --- */
    
    
    if (depth < config.maxlength && cst.rb(wn)-cst.lb(wn) == ep-sp)
      continue; // not left-branching
    
    sdsl::interval_symbols(label_wt, sp, ep+1, support, labels, rank_sp, rank_ep);
    if (support < config.minsupport || support > config.maxsupport)
      continue;
    
    size_type truesupp = 0;
    for (size_type i = 0; i < support; ++i)
      if (config.minfreq <= rank_ep[i]-rank_sp[i])
        ++truesupp;
      if (truesupp < config.minsupport)
        continue;
      
      if (depth > config.maxlength)
        depth = config.maxlength;
      
      /* New in Version 2.3 */
      if (sp >= cst.csa.size()) {
        cerr << "[ERRO] Valor de sp fora do limite do vetor CSA: sp = "
             << sp << ", limite = " << cst.csa.size() << endl;
        exit(1);
      }
      /* --- */
      
      size_type pos = cst.csa[sp];
      
      if (sep_rank1(pos) != sep_rank1(pos + depth))
        continue;
      
      /* New in Version 2.3 */
      if (pos + depth - 1 >= cst.csa.size()) {
        cerr << "[ERRO] Tentativa de extrair sequência além dos limites do CSA: "
             << "pos = " << pos << ", depth = " << depth 
             << ", limite = " << cst.csa.size() << endl;
        continue;  // ou exit(1);
      }
      /* --- */
      
      auto s = extract(cst.csa, pos, pos + depth - 1);
      if (input_reader::smaller_than_rev_cmpl(s))
        continue;
      cout << s + " |";
      for (size_type i = 0; i < support; ++i)
        if (config.minfreq <= rank_ep[i]-rank_sp[i])
          cout << ' ' << ir->id(labels[i]) << ':' << rank_ep[i]-rank_sp[i];
        cout << '\n';
        
        // /* New in version 2.5 */
        // labels.clear();
        // rank_sp.clear();
        // rank_ep.clear();
        // labels.assign(labels.size(), 0);
        // rank_sp.assign(rank_sp.size(), 0);
        // rank_ep.assign(rank_ep.size(), 0);
        // /* --- */
  }
  
  /* New in Version 2.4 */
  if (config.verbose)
  {
    cerr << "[VERBOSE] Finishing execution. Total allocated memory estimated by SDSL: "
         << size_in_mega_bytes(cst) + size_in_mega_bytes(label_wt)
         << " in MiB (not counting buffers and auxiliary vectors)." << endl;
  }
  /* --- */
  
  if (config.verbose)
    cerr << "[VERBOSE] All done." << endl;    
  delete ir; ir = 0;
  return 0;
}
