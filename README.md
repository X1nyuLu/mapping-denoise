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

+ 分别拟合300-400和1800-2000 $cm^{-1}$处的信号，以获取谱峰的拉曼位移和强度等信息
+ 根据拟合出的拉曼位移和强度信息绘制成像图
+ ......

## Update  

已完成的功能：
|    日期    |                             内容                             |
| :--------: | :----------------------------------------------------------: |
| 2024-06-27 |自动补全了成像尺寸以避免ALRMA的质因数分解问题|
| 2024-06-27 |添加了size_x, size_y 自动计算|
| 2024-07-02 |添加了去基线以优化聚类效果|
| 2024-07-02 |允许设置聚类中心数量，添加了选择目标区和背景区聚类中心的交互|
| 2024-07-02 |删除原背景去噪部分,添加了保存文件部分|
| 2024-07-03 |添加只保存recontarget部分，添加全图像素经过处理后的mapping|
| 2024-07-04 |添加了峰拟合功能，不过效果不尽如人意，待优化|
|    ...     |                             ...                              |


## Others

* 根据绘图，峰位置偏差极小，感觉是可以忽略的
* 我发现去噪前后的平均背景光谱差距很小
* 唯一有风险的地方在于，聚类不能完美地勾勒出所有的目标物，导致有些包含目标物的pixel被遗漏，而这部分pixel是不会被降噪的