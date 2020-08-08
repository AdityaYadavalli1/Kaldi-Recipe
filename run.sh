#!/usr/bin/env bash

nj=1
lm_order=1

. ./cmd.sh # should be run.pl for both training scripts and decoding if you don't have SunGrid or SLURM machines

. ./path.sh #should point to kaldi source directory

# remove previosuly created experiment folders/files
rm -rf exp mfcc data/train/spk2utt data/train/cmvn.scp data/train/feats.scp data/train/split1 data/test/spk2utt data/test/cmvn.scp data/test/feats.scp data/test/split1 data/local/lang data/lang data/local/tmp data/local/dict/lexiconp.txt

echo
echo "===== PREPARING ACOUSTIC DATA ====="
echo

utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt

# prepare lm
echo
echo "===== PREPARING LANGUAGE DATA ====="
echo

utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang #extra files it creates such as vocabulary etc

echo
echo "===== LANGUAGE MODEL ====="
echo

if [ -z $loc ]; then
        if uname -a | grep 64 >/dev/null; then
                sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
        else
                        sdir=$KALDI_ROOT/tools/srilm/bin/i686
        fi
        if [ -f $sdir/ngram-count ]; then
                        echo "Using SRILM language modelling tool from $sdir"
                        export PATH=$PATH:$sdir
        else
                        echo "SRILM toolkit is probably not installed.
                                Instructions: tools/install_srilm.sh"
                        exit 1
        fi
fi

local=data/local
mkdir $local/tmp
ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa

echo
echo "===== MAKING G.fst ====="
echo
lang=data/lang
arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang/words.txt $local/tmp/lm.arpa $lang/G.fst


echo
echo "===== FEATURES EXTRACTION ====="
echo

mfccdir=mfcc

# extract features. 1sy argument training/test directory, 2nd log files, 3rd extracted features directory
steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir
steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/test exp/make_mfcc/test $mfccdir

#mean and vocal tract normalisation of the features extracted
steps/compute_cmvn_stats.sh data/train exp/make_mfcc/train $mfccdir
steps/compute_cmvn_stats.sh data/test exp/make_mfcc/test $mfccdir

echo
echo "===== MONO TRAINING, DECODING AND ALIGNMENT ====="
echo
steps/train_mono.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono  || exit 1
utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph || exit 1
steps/decode.sh --config conf/decode.conf --nj $nj --cmd "$decode_cmd" exp/mono/graph data/test exp/mono/decode
steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali || exit 1

echo
echo "===== TRI1 TRAINING, DECODING AND ALIGNMENT (DELTAs + double DELTAs) ====="
echo
steps/train_deltas.sh --cmd "$train_cmd" 2000 10000 data/train data/lang exp/mono_ali exp/tri1 || exit 1
utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
steps/decode.sh --config conf/decode.conf --nj $nj --cmd "$decode_cmd" exp/tri1/graph data/test exp/tri1/decode
steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali

echo
echo "===== TRI2 TRAINING, DECODING AND ALIGNMENT (LDA + MLLT) ====="
echo
steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2 || exit 1
utils/mkgraph.sh data/lang exp/tri2 exp/tri2/graph || exit 1
steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri2/graph data/test exp/tri2/decode
steps/align_si.sh  --nj $nj --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2 exp/tri2_ali

echo
echo "===== TRI3 TRAINING, DECODING AND ALIGNMENT (SAT) ====="
echo
steps/train_sat.sh --cmd "$train_cmd" 2500 15000  data/train data/lang exp/tri2_ali exp/tri3 || exit 1
utils/mkgraph.sh data/lang exp/tri3 exp/tri3/graph || exit 1
steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" exp/tri3/graph data/test exp/tri3/decode
steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri3 exp/tri3_ali #this we may have to comment for now

echo
echo "===== run.sh script is finished ====="
echo
