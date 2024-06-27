# Introduction 
This is a repository for the project about the processing and analysis of TERS mapping.   
And the key method can be found at the following link: 
+ [scripts](https://github.com/XMUSpecLab/CLRMA) 
+ [paper](https://pubs.acs.org/doi/10.1021/acs.analchem.1c02071)

# How to use

+ Install MATLAB and related packages.
+ set the default parameters.
+ run the script`main.m`

# ChangeLog

## workflow

目前的流程如下：
1. 利用聚类分割出不同的区域
2. 计算背景区域的平均谱
3. 对target区域做一次去噪
4. 所有pixel除以背景区域的平均谱（each spectrum_targt / averaged spectrum_background）

## roadmap  

+ 事先去背景以优化聚类效果
+ 分别拟合300-400和1800-2000cm-1处的信号，以获取谱峰的拉曼位移和强度等信息
+ 根据拟合出的拉曼位移和强度信息绘制成像图
+ ......

## Update  

已完成的功能：
+ 自动补全了成像尺寸以避免ALRMA的质因数分解问题 (2024-06-27)
+ ......


注：
* 根据绘图，峰位置偏差极小，感觉是可以忽略的
* 我发现去噪前后的平均背景光谱差距很小
* 唯一有风险的地方在于，聚类不能完美地勾勒出所有的目标物，导致有些包含目标物的pixel被遗漏，而这部分pixel是不会被降噪的