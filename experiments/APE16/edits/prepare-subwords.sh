#!/usr/bin/env bash

# Summary of the task at: http://www.statmt.org/wmt16/ape-task.html
# interesting papers on the subject:
# https://arxiv.org/abs/1606.07481:   multi-source, no additional data, predicts a sequence of edits, good results
# https://arxiv.org/abs/1605.04800:   merges two mono-source models, lots of additional (parallel data), creates
# synthetic PE data by using back-translation

# Ideas: multi-source, additional monolingual data, and some parallel data (not too much)
# pre-train with auto-encoder / word-embeddings / multi-task
# + Beam-search + LM + Ensemble
# other info ? e.g. POS tags
# Finetune with REINFORCE

# xz -dkf commoncrawl.de.xz --verbose

raw_data=experiments/APE16/raw_data
data_dir=experiments/APE16/edits/data_subwords

rm -rf ${data_dir}
mkdir -p ${data_dir}

cat ${raw_data}/500K.mt > ${data_dir}/concat.mt
cat ${raw_data}/500K.pe > ${data_dir}/concat.pe
for i in {1..20}; do   # oversample PE data
    cat ${raw_data}/train.mt >> ${data_dir}/concat.mt
    cat ${raw_data}/train.pe >> ${data_dir}/concat.pe
done

cat ${data_dir}/concat.{mt,pe} > ${data_dir}/concat.de

scripts/learn_bpe.py -s 40000 < ${data_dir}/concat.de > ${data_dir}/bpe.de
scripts/apply_bpe.py -c ${data_dir}/bpe.de < ${data_dir}/concat.pe > ${data_dir}/train.pe
scripts/apply_bpe.py -c ${data_dir}/bpe.de < ${data_dir}/concat.mt > ${data_dir}/train.mt

scripts/apply_bpe.py -c ${data_dir}/bpe.de < ${raw_data}/dev.pe > ${data_dir}/dev.pe
scripts/apply_bpe.py -c ${data_dir}/bpe.de < ${raw_data}/dev.mt > ${data_dir}/dev.mt

scripts/apply_bpe.py -c ${data_dir}/bpe.de < ${raw_data}/test.pe > ${data_dir}/test.pe
scripts/apply_bpe.py -c ${data_dir}/bpe.de < ${raw_data}/test.mt > ${data_dir}/test.mt

scripts/extract-edits.py ${data_dir}/train.{mt,pe} > ${data_dir}/train.edits
scripts/extract-edits.py ${data_dir}/dev.{mt,pe} > ${data_dir}/dev.edits
scripts/extract-edits.py ${data_dir}/test.{mt,pe} > ${data_dir}/test.edits

scripts/prepare-data.py ${data_dir}/train mt edits ${data_dir} --mode vocab --vocab-size 0
scripts/concat-bpe.py ${data_dir}/vocab.mt ${data_dir}/bpe.de > ${data_dir}/vocab_extended.mt
mv ${data_dir}/vocab_extended.mt ${data_dir}/vocab.mt
scripts/concat-bpe.py ${data_dir}/vocab.edits ${data_dir}/bpe.de > ${data_dir}/vocab_extended.edits
mv ${data_dir}/vocab_extended.edits ${data_dir}/vocab.edits

# TODO: Truecasing
