###########################################
##                                       ##
##     这是一个16S扩增子分析的简单流程     ##
##                                       ## 
##               dada2流程               ##
##                                       ##
###########################################

#创建好数据目录 整理好输入输出数据的目录结构
mkdir output
# 导入测序数据
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.txt  \ #测序数据的路径表格
  --input-format PairedEndFastqManifestPhred33 \
  --output-path output/paired-end-demux.qza

# 对样品质量进行统计
qiime demux summarize \
  --i-data output/paired-end-demux.qza \
  --o-visualization output/paired-end-demux.qzv #可视化文件

# 去除barcode和linker 
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences output/paired-end-demux.qza \
  --p-cores 10 \ #核心数 根据服务器性能设定
  --p-front-f AACMGGATTAGATACCCKG \ #正向引物 根据测序引物设定
  --p-front-r ACGTCATCCCCACCTTCC \ #反向引物 根据测序引物设定
  --o-trimmed-sequences output/trimmed-seqs.qza  \
  --verbose #显示过程 可删去

# 对样品质量进行统计
qiime demux summarize \
  --i-data output/trimmed-seqs.qza \
  --o-visualization output/trimmed-seqs.qzv

# 质控 去噪
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs output/trimmed-seqs.qza \
  --p-trim-left-f 0 \ #正向序列5’端切去长度 根据实际情况设置
  --p-trim-left-r 0 \ #反向序列5’端切去长度 根据实际情况设置
  --p-trunc-len-f 289 \ #正向序列长度 根据实际情况设置
  --p-trunc-len-r 255 \ #反向序列长度 根据实际情况设置
  --p-n-threads 14 \ #线程数
  --o-table output/fea-table.qza \
  --o-representative-sequences output/rep-seq.qza \
  --o-denoising-stats output/DADA2Stats \
  --verbose


## Alpha稀释取线
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 3700 \ #根据实际情况而设置
  --m-metadata-file -metadata.txt \
  --o-visualization alpha-rarefaction.qzv