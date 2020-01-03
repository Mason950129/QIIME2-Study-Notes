###########################################
##                                       ##
##     这是一个16S扩增子分析的简单流程     ##
##                                       ## 
##            训练分类器流程              ##
##                                       ##
###########################################

# 导入参考序列
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path silva_132_99_16S.fna \
  --output-path 99_otus.qza

# 导入注释信息
qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path taxonomy_7_levels.txt \
  --output-path ref-taxonomy.qza

# 生成代表序列
qiime feature-classifier extract-reads \
  --i-sequences 99_otus.qza \
  --p-f-primer AACMGGATTAGATACCCKG \ #正向引物 根据测序区间设置
  --p-r-primer ACGTCATCCCCACCTTCC \ #反向引物 根据测序区间设置
  --p-trunc-len 400 \ #片段长度 根据实际情况设置
  --p-min-length 100 \ #最小长度阈值
  --p-max-length 400 \ #最大长度阈值
  --o-reads ref-seqs.qza

# 生成分类器
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads ref-seqs.qza \
  --i-reference-taxonomy ref-taxonomy.qza \
  --o-classifier silva_132_99_16S_V57classifier.qza
