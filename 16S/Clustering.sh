###########################################
##                                       ##
##     这是一个16S扩增子分析的简单流程     ##
##                                       ## 
##              OTU聚类分析              ##
##                                       ##
###########################################

#无参聚类 De novo clustering
time qiime vsearch cluster-features-de-novo \
  --i-table table.qza \ #输入频率数据特征表
  --i-sequences rep-seqs.qza \ #输入代表序列
  --p-perc-identity 0.99 \ #聚类阈值
  --o-clustered-table table-dn-99.qza \
  --o-clustered-sequences rep-seqs-dn-99.qza

#有参聚类 Closed-reference clustering
time qiime vsearch cluster-features-closed-reference \
  --i-table table.qza \ #输入频率数据特征表
  --i-sequences rep-seqs.qza \ #输入代表序列
  --i-reference-sequences 85_otus.qza \ #输入参考序列
  --p-perc-identity 0.85 \ #聚类阈值
  --o-clustered-table table-cr-85.qza \
  --o-clustered-sequences rep-seqs-cr-85.qza \
  --o-unmatched-sequences unmatched-cr-85.qza

#半有参聚类 Open-reference clustering
time qiime vsearch cluster-features-open-reference \
  --i-table table.qza \ #输入频率数据特征表
  --i-sequences rep-seqs.qza \ #输入代表序列
  --i-reference-sequences 85_otus.qza \ #输入参考序列
  --p-perc-identity 0.85 \ #聚类阈值
  --o-clustered-table table-or-85.qza \
  --o-clustered-sequences rep-seqs-or-85.qza \
  --o-new-reference-sequences new-ref-seqs-or-85.qza


##后续可用于物种注释 多样性分析等