#import "../../index.typ": template, tufted
#show: template.with(
  title: "GREAT-PVT GNSS软件编译与运行指南",
  date: (year: 2026, month: 3, day: 7),
  description: "详细介绍了GREAT-PVT开源GNSS定位软件的下载、编译、配置和运行过程，以及PPP解算结果分析",
)

= GREAT-PVT GNSS软件编译与运行指南

本文档详细介绍了武汉大学GREAT团队开发的GREAT-PVT开源GNSS定位软件的安装、编译和运行过程。

== 软件简介

GREAT-PVT是武汉大学测绘遥感信息工程国家重点实验室GREAT团队开发的一款高精度GNSS定位软件。

*主要特性：*
- 支持多种定位模式：PPP（精密单点定位）、RTK（实时动态差分）
- 支持多系统融合：GPS、GLONASS、Galileo、BDS-2/3
- 开源免费：基于C++开发，源码开放

== 环境要求

*操作系统：* Linux (WSL2、Ubuntu等)
*编译工具：* CMake 3.10+
*C++编译器：* GCC 7+ 或 Clang
*构建工具：* Make

== 下载软件

从GitHub官方仓库下载源码：

```bash
# 克隆仓库
git clone https://github.com/WuhanUniversityGREAT/GREAT-PVT.git

# 或直接下载ZIP压缩包
# https://github.com/WuhanUniversityGREAT/GREAT-PVT/archive/refs/heads/master.zip
```

== 安装依赖

在Ubuntu/Debian系统上安装必要依赖：

```bash
# 更新包管理器
sudo apt update

# 安装CMake
sudo apt install -y cmake

# 安装编译工具
sudo apt install -y g++ make
```

== 编译软件

进入源码目录进行编译：

```bash
cd GREAT-PVT

# 创建构建目录
mkdir -p src/build_Linux
cd src/build_Linux

# 运行CMake配置
cmake ..

# 编译（使用多核加速）
make -j$(nproc)
```

*编译成功后，可执行文件位于：*
- 二进制文件：`bin/Linux/GREAT_PVT`
- 静态库：`src/build_Linux/`
- 共享库：`bin/Linux/libLibGREAT.so`, `bin/Linux/libLibGnut.so`

== 配置环境变量

设置共享库路径：

```bash
# 临时设置（当前终端）
export LD_LIBRARY_PATH=/path/to/GREAT-PVT/bin/Linux:$LD_LIBRARY_PATH

# 永久设置（添加到 ~/.bashrc）
echo 'export LD_LIBRARY_PATH=/path/to/GREAT-PVT/bin/Linux:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

== 运行示例数据

解压示例数据并运行：

```bash
# 进入示例数据目录
cd sample_data/PPPFLT_2023305

# 运行PPP解算
../../bin/Linux/GREAT_PVT -c ../GREAT_PPP.xml

# 查看结果
ls result/
```

== 解算结果分析

*示例数据信息：*
- 测站：GODN、HARB
- 日期：2023年第305天（2023-11-01）
- 采样间隔：30秒
- 历元数：2,870

*解算性能（静态双频固定解）：*

| 站点 | 固定解率 | X-RMS | Y-RMS | Z-RMS | 3D-RMS |
|------|---------|-------|-------|-------|--------|
| GODN | 99.72% | 0.25mm | 0.60mm | 0.49mm | 0.81mm |
| HARB | 99.90% | 0.48mm | 0.31mm | 0.27mm | 0.63mm |

*关键技术参数：*
- GNSS系统：GPS + GLONASS + Galileo + BDS-2/3
- 观测值组合：无电离层组合
- 参考框架：IGS20 (ITRF2020)
- 平均卫星数：29-30颗
- PDOP：0.88-0.96

== 结果文件格式

每个结果文件包含以下字段：

- `Seconds of Week`：周内秒数
- `X/Y/Z-ECEF`：地心地固坐标系位置 (m)
- `Vx/Vy/Vz-ECEF`：地心地固坐标系速度 (m/s)
- `X/Y/Z-RMS`：位置精度 (m)
- `NSat`：参与解算的卫星数量
- `PDOP`：位置精度衰减因子
- `AmbStatus`：模糊度状态（Fixed/Float）
- `Ratio`：模糊度固定解检验率比

== 常见问题

=== 编译失败

*问题：* make进程挂起或编译失败

*解决方案：*
- 检查CMake版本：`cmake --version`
- 使用预编译版本（位于 `bin/Linux/` 目录）
- 减少并行编译数：`make -j4`

=== 找不到共享库

*错误信息：* `error while loading shared libraries`

*解决方案：*
- 设置 `LD_LIBRARY_PATH` 环境变量
- 或将库文件复制到系统库目录：`sudo cp bin/Linux/*.so /usr/local/lib/`

=== 频率代码错误

*错误信息：* `Not defined frequency code I09`

*原因：* 示例数据包含BDS-3新频点，旧版本软件不支持

*解决方案：*
- 使用最新版本的GREAT-PVT
- 或在配置文件中禁用不支持的频点

== 总结

GREAT-PVT是一款功能强大的GNSS高精度定位软件，通过本文档的步骤可以顺利完成软件的编译和运行。实测表明，该软件在PPP解算中能够达到毫米级定位精度，固定解率超过99.7%，非常适合大地测量、地壳形变监测等高精度应用场景。

#link("https://github.com/WuhanUniversityGREAT/GREAT-PVT")[官方GitHub仓库]
#link("https://github.com/WuhanUniversityGREAT/GREAT-PVT/wiki")[官方Wiki文档]
