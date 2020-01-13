###########################################
##                                       ##
##     这是一个16S扩增子分析的简单流程     ##
##                                       ## 
##           denoise-16S流程             ##
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

# 双端合并 
qiime vsearch join-pairs \
  --i-demultiplexed-seqs output/trimmed-seqs.qza \
  --o-joined-sequences output/joined-demux.qza

# 质控
qiime quality-filter q-score-joined \
  --i-demux output/joined-demux.qza \
  --p-min-quality 25 \ #质控阈值 根据情况设定
  --o-filtered-sequences output/demux-joined-filtered.qza \
  --o-filter-stats output/demux-joined-filter-stats.qza 

# 对指控后样品质量进行统计
qiime demux summarize \
  --i-data output/demux-joined-filtered.qza \
  --o-visualization output/demux-joined-filtered.qzv

# 去噪
qiime deblur denoise-16S \
  --i-demultiplexed-seqs output/demux-joined-filtered.qza \
  --p-left-trim-len 0 \ #切掉5’段碱基的个数 根据质控后的样品质量设定 默认0
  --p-trim-length 380 \ #保留的长度 根据质控后的样品质量设定
  --p-jobs-to-start 10 \ #同时进行的工作数量 根据服务器性能设定
  --p-sample-stats \ #收集每个样品的信息
  --o-representative-sequences output/deblur-rep-seqs.qza \
  --o-table output/deblur-table.qza \
  --o-stats output/deblur-stats.qza 

# 查看Feature/OTU表的统计结果
qiime feature-table summarize \
  --i-table output/deblur-table.qza \
  --o-visualization output/deblur-table.qzv \
  --m-sample-metadata-file  metadata.txt  #分组信息文件

# 此步骤之前可进行聚类分析 再将聚类分析的结果作为此步骤的输入文件
# 物种分类 
qiime feature-classifier classify-sklearn \
  --i-classifier ../training-feature-classifiers/silva_132_97_16S_V57classifier.qza \ #物种分类器 根据测序区间和数据库等选择 
  --i-reads output/deblur-rep-seqs.qza \
  --o-classification output/taxonomy-silva.qza \
  --verbose 

# 生成物种柱形图  
qiime taxa barplot \
  --i-table output/deblur-table.qza \
  --i-taxonomy output/taxonomy-silva.qza \
  --m-metadata-file metadata.txt \
  --o-visualization output/taxa-bar-plots.qzv

## 生成带注释的丰度表格
# 生成相对丰度表格  将绝对丰度的表格转换为相对丰度的表格
qiime feature-table relative-frequency \
  --i-table output/deblur-table.qza \
  --o-relative-frequency-table output/relative-frequency-table.qza

# 生成BIOM表格
qiime tools export \
  --input-path output/deblur-table.qza \
  --output-path output/deblur-table.biom \
  --output-format BIOMV210Format 

# 生成BIOM表格
qiime tools export \
  --input-path output/relative-frequency-table.qza \
  --output-path output/relative-frequency-table.biom \
  --output-format BIOMV210Format 

# 导出注释信息
qiime tools export \
  --input-path output/taxonomy-silva.qza \
  --output-path output/taxonomy.tsv \
  --output-format TSVTaxonomyFormat 

# 添加物种信息至OTU表最后一列，命名为taxonomy
biom add-metadata \
  -i output/deblur-table.biom \
  -o output/otu_table_tax.biom \
  --observation-metadata-fp output/taxonomy.tsv \
  --sc-separated taxonomy \
  --observation-header OTUID,taxonomy 

# 添加物种信息至OTU表最后一列，命名为taxonomy
biom add-metadata \
  -i output/relative-frequency-table.biom  \
  -o output/otu_table_tax_relative.biom \
  --observation-metadata-fp output/taxonomy.tsv \
  --sc-separated taxonomy \
  --observation-header OTUID,taxonomy 

# 转换格式
biom convert \
  -i output/otu_table_tax.biom \
  -o output/otu_table_tax.tsv \
  --header-key taxonomy \
  --to-tsv 

# 转换格式
biom convert \
  -i output/otu_table_tax_relative.biom \
  -o output/otu_table_tax_relative.tsv \
  --header-key taxonomy \
  --to-tsv 


## 多样性分析
# 代表性序列统计
qiime feature-table tabulate-seqs \
  --i-data output/deblur-rep-seqs.qza \
  --o-visualization output/deblur-rep-seqs.qzv

# 多序列比对
qiime alignment mafft \
  --i-sequences output/deblur-rep-seqs.qza \
  --o-alignment output/aligned-rep-seqs.qza

# 移除高变区
qiime alignment mask \
  --i-alignment output/aligned-rep-seqs.qza \
  --o-masked-alignment output/masked-aligned-rep-seqs.qza

# 建树
qiime phylogeny fasttree \
  --i-alignment output/masked-aligned-rep-seqs.qza \
  --o-tree output/unrooted-tree.qza

# 无根树转换为有根树
qiime phylogeny midpoint-root \
  --i-tree output/unrooted-tree.qza \
  --o-rooted-tree output/rooted-tree.qza

# 计算多样性(包括所有常用的Alpha和Beta多样性方法)
qiime diversity core-metrics-phylogenetic \
  --i-table output/deblur-table.qza \
  --i-phylogeny output/rooted-tree.qza \
  --p-sampling-depth 16582 \ #样本重采样深度(一般为最小样本数据量，或覆盖绝大多数样品的数据量)
  --m-metadata-file metadata.txt \
  --output-dir output/core-metrics-results

# 统计faith_pd算法Alpha多样性组间差异是否显著，输入多样性值、实验设计，输出统计结果
qiime diversity alpha-group-significance \
  --i-alpha-diversity output/core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file metadata.txt \
  --o-visualization output/core-metrics-results/faith-pd-group-significance.qzv
# 统计evenness组间差异是否显著
qiime diversity alpha-group-significance \
  --i-alpha-diversity output/core-metrics-results/evenness_vector.qza \
  --m-metadata-file metadata.txt \
  --o-visualization output/core-metrics-results/evenness-group-significance.qzv
# 统计observed_otus组间差异是否显著
qiime diversity alpha-group-significance \
  --i-alpha-diversity output/core-metrics-results/observed_otus_vector.qza \
  --m-metadata-file metadata.txt \
  --o-visualization output/core-metrics-results/observed_otus-group-significance.qzv
# 统计shannon组间差异是否显著
qiime diversity alpha-group-significance \
  --i-alpha-diversity output/core-metrics-results/shannon_vector.qza \
  --m-metadata-file metadata.txt \
  --o-visualization output/core-metrics-results/shannon-group-significance.qzv

# 导出组间差异结果
qiime tools extract \
  --input-path output/core-metrics-results/evenness-group-significance.qzv \
  --output-path output/core-metrics-results/evenness-group-significance/
# 导出组间差异结果  
qiime tools extract \
  --input-path output/core-metrics-results/faith-pd-group-significance.qzv \
  --output-path output/core-metrics-results/faith-pd-group-significance/  
# 导出组间差异结果   
qiime tools extract \
  --input-path output/core-metrics-results/observed_otus-group-significance.qzv \
  --output-path output/core-metrics-results/observed_otus-group-significance/  
# 导出组间差异结果  
qiime tools extract \
  --input-path output/core-metrics-results/shannon-group-significance.qzv \
  --output-path output/core-metrics-results/shannon-group-significance/

# 导出bray_curtis矩阵
qiime tools export \
  --input-path output/core-metrics-results/bray_curtis_distance_matrix.qza \
  --output-path output/core-metrics-results/bray_curtis_distance_matrix
# 导出jaccard_distance矩阵  
qiime tools export \
  --input-path output/core-metrics-results/jaccard_distance_matrix.qza \
  --output-path output/core-metrics-results/jaccard_distance_matrix
# 导出unweighted_unifrac矩阵   
qiime tools export \
  --input-path output/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --output-path output/core-metrics-results/unweighted_unifrac_distance_matrix
# 导出weighted_unifrac矩阵     
qiime tools export \
  --input-path output/core-metrics-results/weighted_unifrac_distance_matrix.qza \
  --output-path output/core-metrics-results/weighted_unifrac_distance_matrix
# 导出rarefied表格
qiime tools export \
  --input-path output/core-metrics-results/rarefied_table.qza \
  --output-path output/core-metrics-results/rarefied_table

# 导出shannon_vector表格  
qiime tools export \
  --input-path output/core-metrics-results/shannon_vector.qza \
  --output-path output/core-metrics-results/shannon_vector.tsv \
  --output-format AlphaDiversityFormat 
# 导出observed_otus_vector表格    
qiime tools export \
  --input-path output/core-metrics-results/observed_otus_vector.qza \
  --output-path output/core-metrics-results/observed_otus_vector.tsv \
  --output-format AlphaDiversityFormat 
# 导出faith_pd_vector表格    
qiime tools export \
  --input-path output/core-metrics-results/faith_pd_vector.qza \
  --output-path output/core-metrics-results/faith_pd_vector.tsv \
  --output-format AlphaDiversityFormat 
# 导出evenness_vector表格    
qiime tools export \
  --input-path output/core-metrics-results/evenness_vector.qza \
  --output-path output/core-metrics-results/evenness_vector.tsv \
  --output-format AlphaDiversityFormat 

# 提取需要的数据
mkdir export
cp output/otu_table_tax.tsv export/otu_table_tax.tsv
cp output/otu_table_tax_relative.tsv export/otu_table_tax_relative.tsv
cp output/taxa-bar-plots.qzv export/taxa-bar-plots.qzv
cp output/core-metrics-results/faith-pd-group-significance/ -r export/faith-pd-group-significance/
cp output/core-metrics-results/evenness-group-significance/ -r export/evenness-group-significance/
cp output/core-metrics-results/observed_otus-group-significance/ -r export/observed_otus-group-significance/
cp output/core-metrics-results/shannon-group-significance/ -r export/shannon-group-significance/
cp output/core-metrics-results/bray_curtis_distance_matrix/distance-matrix.tsv export/bray_curtis_distance_matrix.tsv
cp output/core-metrics-results/jaccard_distance_matrix/distance-matrix.tsv export/jaccard_distance_matrix.tsv
cp output/core-metrics-results/unweighted_unifrac_distance_matrix/distance-matrix.tsv export/unweighted_unifrac_distance_matrix.tsv
cp output/core-metrics-results/weighted_unifrac_distance_matrix/distance-matrix.tsv export/weighted_unifrac_distance_matrix.tsv
cp output/core-metrics-results/shannon_vector.tsv export/shannon_vector.tsv
cp output/core-metrics-results/observed_otus_vector.tsv export/observed_otus_vector.tsv
cp output/core-metrics-results/faith_pd_vector.tsv export/faith_pd_vector.tsv
cp output/core-metrics-results/evenness_vector.tsv export/evenness_vector.tsv