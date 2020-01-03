###########################################
##                                       ##
##     这是一个16S扩增子分析的简单流程     ##
##                                       ## 
##           denoise-16S流程             ##
##                                       ##
###########################################

#导入测序数据
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.txt  \ #测序数据的路径表格
  --input-format PairedEndFastqManifestPhred33 \
  --output-path output/paired-end-demux.qza

# 对样品质量进行统计
qiime demux summarize \
  --i-data output/paired-end-demux.qza \
  --o-visualization output/paired-end-demux.qzv #可视化文件

#去除barcode和linker 
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences output/paired-end-demux.qza \
  --p-cores 10 \ #核心数 根据服务器性能设定
  --p-front-f AACMGGATTAGATACCCKG \ #正向引物 根据测序引物设定
  --p-front-r ACGTCATCCCCACCTTCC \ #反向引物 根据测序引物设定
  --o-trimmed-sequences output/trimmed-seqs.qza  \
  --verbose #显示过程 可删去

#双端合并 
qiime vsearch join-pairs \
  --i-demultiplexed-seqs output/trimmed-seqs.qza \
  --o-joined-sequences output/joined-demux.qza

#质控
qiime quality-filter q-score-joined \
  --i-demux output/joined-demux.qza \
  --p-min-quality 25 \ #质控阈值 根据情况设定
  --o-filtered-sequences output/demux-joined-filtered.qza \
  --o-filter-stats output/demux-joined-filter-stats.qza 