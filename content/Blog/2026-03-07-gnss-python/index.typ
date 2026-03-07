#import "../../index.typ": template, tufted
#show: template.with(
  title: "GNSS数据处理中的Python编程实践",
  date: (year: 2026, month: 3, day: 7),
  description: "介绍Python在GNSS数据处理中的应用，包括RINEX文件解析、坐标转换、可视化分析和RTKLIB集成",
)

= GNSS数据处理中的Python编程实践

Python因其简洁的语法和丰富的科学计算库，在GNSS数据处理领域得到了广泛应用。本文将介绍Python在GNSS数据处理中的实际应用，包括RINEX文件解析、坐标转换、数据可视化和与RTKLIB的集成。

== Python生态系统

=== 核心科学计算库

*NumPy* - 数值计算基础
```python
import numpy as np

# 创建观测历元数组
epochs = np.arange(0, 28800, 30)  # 8小时数据，30秒采样
satellites = np.array(['G01', 'G02', 'G03', 'R01', 'R02'])

# 载波相位观测值（cycles）
phase_L1 = np.array([1234567.89, 1234568.34, 1234569.12])
phase_L2 = np.array([923456.78, 923457.23, 923457.89])
```

*SciPy* - 科学计算和信号处理
```python
from scipy import signal, optimize

# Kalman滤波器实现
from scipy.signal import lfilter

# 最小二乘估计
def least_squares_adjustment(A, L):
    x, residuals, rank, s = np.linalg.lstsq(A, L, rcond=None)
    return x, residuals
```

*Matplotlib* - 数据可视化
```python
import matplotlib.pyplot as plt

# 绘制定位精度时间序列
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))

ax1.plot(time, east_error, 'b-', label='East')
ax1.plot(time, north_error, 'g-', label='North')
ax1.set_ylabel('Position Error (m)')
ax1.legend()
ax1.grid(True)

ax2.plot(time, up_error, 'r-', label='Up')
ax2.set_xlabel('Time (hour)')
ax2.set_ylabel('Position Error (m)')
ax2.legend()
ax2.grid(True)

plt.tight_layout()
plt.savefig('position_error.png', dpi=300)
```

== RINEX文件解析

=== 读取观测文件（.obs）

RINEX 3.0格式示例：

```python
import re
from collections import defaultdict

def parse_rinex_obs(filename):
    """
    解析RINEX观测文件，返回观测数据字典
    """
    obs_data = defaultdict(dict)
    current_epoch = None

    with open(filename, 'r') as f:
        for line in f:
            # 解析历元头
            if line[0] == ' ' and len(line) > 29:
                year = int(line[1:3])
                month = int(line[4:6])
                day = int(line[7:9])
                hour = int(line[10:12])
                minute = int(line[13:15])
                second = float(line[15:26])

                epoch_num_sats = int(line[29:32])
                current_epoch = f"{year:02d}{month:02d}{day:02d}{hour:02d}{minute:02d}{second:09.2f}"
                obs_data[current_epoch] = {}

            # 解析卫星观测值
            elif line[0] != ' ' and line[0] != '>':
                sat_id = line[:3].strip()
                obs_values = []
                for i in range(16, 80, 16):
                    obs_str = line[i:i+16]
                    if obs_str.strip():
                        try:
                            obs_values.append(float(obs_str))
                        except ValueError:
                            obs_values.append(0.0)

                if sat_id:
                    obs_data[current_epoch][sat_id] = obs_values

    return obs_data
```

=== 读取导航文件（.nav）

```python
def parse_rinex_nav(filename):
    """
    解析RINEX导航文件，返回卫星星历数据
    """
    ephemeris = {}
    current_sat = None

    with open(filename, 'r') as f:
        while True:
            # 读取卫星ID和历元时间
            line = f.readline()
            if not line:
                break

            if line[0].isdigit():
                sat_id = line[:3].strip()
                year = int(line[4:8])
                month = int(line[9:11])
                day = int(line[12:14])

                # 读取后续7行星历参数
                params = []
                for _ in range(7):
                    params.append(f.readline())

                # 解析星历参数
                ephemeris[sat_id] = {
                    'epoch': (year, month, day),
                    'cr': float(params[0][4:23]),
                    'delta_n': float(params[0][23:42]),
                    'M0': float(params[0][42:61]),
                    # ... 更多参数
                }

    return ephemeris
```

== 坐标转换

=== ECEF到LLA转换

```python
import numpy as np

# WGS84椭球常数
WGS84_A = 6378137.0  # 长半轴 (m)
WGS84_F = 1 / 298.257223563  # 扁率
WGS84_E2 = 2 * WGS84_F - WGS84_F**2  # 第一偏心率平方

def ecef2lla(x, y, z):
    """
    将ECEF坐标转换为大地坐标（经纬高）
    输入: x, y, z - ECEF坐标 (m)
    输出: (lat, lon, h) - 纬度(rad), 经度(rad), 高程(m)
    """
    p = np.sqrt(x**2 + y**2)
    theta = np.arctan2(z * WGS84_A, p * WGS84_A * (1 - WGS84_E2))

    # 迭代计算纬度
    N = WGS84_A / np.sqrt(1 - WGS84_E2 * np.sin(theta)**2)
    lat = np.arctan2(z + WGS84_E2 * N * np.sin(theta), p)

    # 经度
    lon = np.arctan2(y, x)

    # 高程
    N = WGS84_A / np.sqrt(1 - WGS84_E2 * np.sin(lat)**2)
    h = p / np.cos(lat) - N

    return lat, lon, h

def lla2ecef(lat, lon, h):
    """
    将大地坐标转换为ECEF坐标
    输入: lat, lon - 纬度和经度 (rad)
          h - 高程 (m)
    输出: (x, y, z) - ECEF坐标 (m)
    """
    N = WGS84_A / np.sqrt(1 - WGS84_E2 * np.sin(lat)**2)

    x = (N + h) * np.cos(lat) * np.cos(lon)
    y = (N + h) * np.cos(lat) * np.sin(lon)
    z = (N * (1 - WGS84_E2) + h) * np.sin(lat)

    return x, y, z
```

=== ITRF到ENU转换

```python
def itrf2enu(x, y, z, lat0, lon0):
    """
    将ITRF坐标转换为局部ENU坐标
    输入: x, y, z - 相对于参考点的ITRF坐标差值 (m)
          lat0, lon0 - 参考点经纬度 (rad)
    输出: (east, north, up) - ENU坐标 (m)
    """
    sin_lat = np.sin(lat0)
    cos_lat = np.cos(lat0)
    sin_lon = np.sin(lon0)
    cos_lon = np.cos(lon0)

    east = -sin_lon * x + cos_lon * y
    north = -sin_lat * cos_lon * x - sin_lat * sin_lon * y + cos_lat * z
    up = cos_lat * cos_lon * x + cos_lat * sin_lon * y + sin_lat * z

    return east, north, up
```

== 卫星位置计算

```python
def calculate_sat_position(ephemeris, t):
    """
    根据星历计算卫星在ECEF坐标系中的位置
    输入: ephemeris - 卫星星历参数字典
          t - 接收时间 (GPS周秒)
    输出: (x_s, y_s, z_s) - 卫星ECEF坐标 (m)
    """
    # 提取星历参数
    M0 = ephemeris['M0']
    delta_n = ephemeris['delta_n']
    e = ephemeris['e']
    sqrt_a = ephemeris['sqrt_a']
    omega0 = ephemeris['omega0']
    i0 = ephemeris['i0']
    omega = ephemeris['omega']
    omega_dot = ephemeris['omega_dot']
    idot = ephemeris['idot']
    cuc = ephemeris['cuc']
    cus = ephemeris['cus']
    crc = ephemeris['crc']
    crs = ephemeris['crs']
    cic = ephemeris['cic']
    cis = ephemeris['cis']
    toe = ephemeris['toe']
    t0 = ephemeris['t0']

    # 计算时间差
    tk = t - toe
    if tk > 302400:
        tk -= 604800
    elif tk < -302400:
        tk += 604800

    # 计算平近点角
    A = sqrt_a**2
    n0 = np.sqrt(3.986005e14 / A**3)
    M = M0 + (n0 + delta_n) * tk

    # 求解开普勒方程（迭代法）
    E = M
    for _ in range(10):
        E = M + e * np.sin(E)

    # 计算真近点角
    nu = 2 * np.arctan2(np.sqrt(1 + e) * np.sin(E/2),
                        np.sqrt(1 - e) * np.cos(E/2))

    # 升交点角距
    Phi = nu + omega

    # 周期改正项
    delta_u = cus * np.sin(2*Phi) + cuc * np.cos(2*Phi)
    delta_r = crs * np.sin(2*Phi) + crc * np.cos(2*Phi)
    delta_i = cis * np.sin(2*Phi) + cic * np.cos(2*Phi)

    # 改正后的参数
    u = Phi + delta_u
    r = A * (1 - e * np.cos(E)) + delta_r
    i = i0 + idot * tk + delta_i

    # 计算轨道平面位置
    x_orbit = r * np.cos(u)
    y_orbit = r * np.sin(u)

    # 升交点经度
    omega_e = 7.2921151467e-5  # 地球自转角速度
    Omega = omega0 + (omega_dot - omega_e) * tk - omega_e * t0

    # 转换到ECEF坐标系
    x_s = x_orbit * np.cos(Omega) - y_orbit * np.cos(i) * np.sin(Omega)
    y_s = x_orbit * np.sin(Omega) + y_orbit * np.cos(i) * np.cos(Omega)
    z_s = y_orbit * np.sin(i)

    return x_s, y_s, z_s
```

== RTKLIB集成

=== 调用RTKLIB进行解算

```python
import subprocess
import os

def run_rtklib(obs_file, nav_file, config_file, output_file):
    """
    调用RTKCLI进行PPP解算
    输入: obs_file - 观测文件路径
          nav_file - 导航文件路径
          config_file - 配置文件路径
          output_file - 输出文件路径
    """
    # 构建命令
    cmd = [
        '/path/to/rtklib/bin/rtkpos',
        '-k', config_file,
        '-o', output_file,
        obs_file,
        nav_file
    ]

    # 执行命令
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"RTKLIB error: {result.stderr}")
        return False

    print(f"RTKLIB solution saved to {output_file}")
    return True
```

=== 解析RTKLIB结果文件

```python
def parse_rtklib_result(filename):
    """
    解析RTKLIB生成的.pos文件
    """
    results = []
    with open(filename, 'r') as f:
        # 跳过文件头
        for line in f:
            if line.startswith('%'):
                continue
            break

        # 解析数据行
        for line in f:
            if not line.strip():
                continue

            parts = line.split()
            if len(parts) < 17:
                continue

            result = {
                'time': parts[0],
                'x': float(parts[1]),
                'y': float(parts[2]),
                'z': float(parts[3]),
                'q': int(parts[4]),  # 质量标识
                'ns': int(parts[5]),  # 卫星数量
                'sdn': float(parts[6]),  # 北向精度
                'sde': float(parts[7]),  # 东向精度
                'sdu': float(parts[8]),  # 天向精度
            }
            results.append(result)

    return results
```

== 数据分析与可视化

=== 定位精度分析

```python
def analyze_position_accuracy(results, reference):
    """
    分析定位精度统计指标
    输入: results - 定位结果列表
          reference - 参考站坐标 (x0, y0, z0)
    输出: 统计指标字典
    """
    # 计算坐标偏差
    errors = []
    for res in results:
        dx = res['x'] - reference[0]
        dy = res['y'] - reference[1]
        dz = res['z'] - reference[2]
        errors.append([dx, dy, dz])

    errors = np.array(errors)

    # 统计指标
    stats = {
        'mean': np.mean(errors, axis=0),
        'std': np.std(errors, axis=0),
        'rms': np.sqrt(np.mean(errors**2, axis=0)),
        'max_abs': np.max(np.abs(errors), axis=0),
        'max_2d': np.max(np.sqrt(errors[:,0]**2 + errors[:,1]**2)),
        'max_3d': np.max(np.sqrt(np.sum(errors**2, axis=1))),
    }

    return stats

def plot_position_time_series(results, reference):
    """
    绘制定位偏差时间序列
    """
    # 转换为ENU坐标
    x_ref, y_ref, z_ref = reference
    ref_lla = ecef2lla(x_ref, y_ref, z_ref)

    enu_errors = []
    times = []

    for res in results:
        dx = res['x'] - x_ref
        dy = res['y'] - y_ref
        dz = res['z'] - z_ref

        east, north, up = itrf2enu(dx, dy, dz, *ref_lla[:2])
        enu_errors.append([east, north, up])
        times.append(res['time'])

    enu_errors = np.array(enu_errors)

    # 绘制
    fig, axes = plt.subplots(3, 1, figsize=(12, 8), sharex=True)

    labels = ['East (m)', 'North (m)', 'Up (m)']
    colors = ['blue', 'green', 'red']

    for i, ax in enumerate(axes):
        ax.plot(times, enu_errors[:, i], color=colors[i], linewidth=0.8)
        ax.set_ylabel(labels[i])
        ax.axhline(y=0, color='black', linestyle='--', alpha=0.5)
        ax.grid(True, alpha=0.3)

    axes[-1].set_xlabel('Time')
    plt.suptitle('Position Error Time Series (ENU)', fontsize=14)
    plt.tight_layout()
    plt.savefig('position_error_time_series.png', dpi=300)
```

=== 卫星可见性分析

```python
def plot_skyplot(azimuths, elevations, prns=None):
    """
    绘制卫星天空图
    输入: azimuths - 方位角数组 (degrees)
          elevations - 仰角数组 (degrees)
          prns - 卫星PRN列表
    """
    fig, ax = plt.subplots(figsize=(10, 10), subplot_kw={'projection': 'polar'})

    # 转换为极坐标
    theta = np.radians(90 - azimuths)  # 方位角：0度=北，顺时针
    r = 90 - elevations  # 半径：天顶=0，地平=90

    colors = ['red', 'green', 'blue', 'orange', 'purple']
    unique_prns = list(set(prns)) if prns else None

    for i, (th, r_val, prn) in enumerate(zip(theta, r, prns)):
        color_idx = unique_prns.index(prn) % len(colors) if unique_prns else 0
        ax.scatter(th, r_val, c=colors[color_idx], s=50, alpha=0.7, label=prn)

    # 设置极坐标图
    ax.set_theta_zero_location('N')  # 北方向为0度
    ax.set_theta_direction(-1)  # 顺时针方向
    ax.set_rlim(0, 90)
    ax.set_rticks([0, 30, 60, 90])
    ax.set_rlabel_position(135)
    ax.set_yticklabels(['90°', '60°', '30°', '0°'], fontsize=10)

    # 添加网格
    ax.grid(True, alpha=0.3)

    # 图例
    handles, labels = ax.get_legend_handles_labels()
    unique = list(dict(zip(labels, handles)).items())
    ax.legend([h for l, h in unique], [l for l, h in unique],
              loc='upper right', bbox_to_anchor=(1.3, 1))

    plt.title('Satellite Skyplot', fontsize=14, pad=20)
    plt.tight_layout()
    plt.savefig('skyplot.png', dpi=300)
```

== 实际应用示例

=== 完整的PPP解算流程

```python
import glob
import pandas as pd

def ppp_workflow(obs_dir, nav_dir, config_file, output_dir):
    """
    完整的PPP数据处理流程
    """
    # 获取所有观测文件
    obs_files = sorted(glob.glob(os.path.join(obs_dir, '*.o')))

    results_all = []

    for obs_file in obs_files:
        # 提取站点名和日期
        station_name = os.path.basename(obs_file)[:4]
        date_str = os.path.basename(obs_file)[4:12]

        # 查找对应的导航文件
        nav_file = os.path.join(nav_dir, f'BRDC{date_str}.00P')

        # 输出文件
        output_file = os.path.join(output_dir, f'{station_name}_{date_str}.pos')

        # 运行RTKLIB PPP解算
        success = run_rtklib(obs_file, nav_file, config_file, output_file)

        if success:
            # 解析结果
            results = parse_rtklib_result(output_file)
            results_all.extend(results)

    # 转换为DataFrame便于分析
    df = pd.DataFrame(results_all)

    # 保存结果
    df.to_csv('ppp_results_all.csv', index=False)

    return df
```

=== 质量控制检查

```python
def quality_control_check(obs_file):
    """
    进行数据质量控制检查
    """
    obs_data = parse_rinex_obs(obs_file)

    # 统计卫星数量
    sat_counts = {epoch: len(sats) for epoch, sats in obs_data.items()}

    # 检测周跳
    def cycle_slip_detection(prev_obs, curr_obs):
        # 使用宽巷组合检测周跳
        WL_prev = (prev_obs[0] * 154 - prev_obs[1] * 120) / 34  # L1-L2宽巷
        WL_curr = (curr_obs[0] * 154 - curr_obs[1] * 120) / 34

        # 4-sigma准则
        threshold = 4 * 0.5  # 0.5 cycles为典型噪声水平

        if abs(WL_curr - WL_prev) > threshold:
            return True
        return False

    # 遍历所有卫星检测周跳
    cycle_slips = {}
    for epoch in sorted(obs_data.keys()):
        for sat in obs_data[epoch]:
            if sat not in cycle_slips:
                cycle_slips[sat] = []
            # 比较当前历元与前一历元的观测值
            # ...

    return sat_counts, cycle_slips
```

== 性能优化

=== 使用NumPy加速

```python
import numpy as np
from numba import jit

@jit(nopython=True)
def ecef2lla_fast(x, y, z, WGS84_A, WGS84_E2):
    """
    使用Numba JIT加速的ECEF到LLA转换
    """
    p = np.sqrt(x**2 + y**2)
    theta = np.arctan2(z * WGS84_A, p * WGS84_A * (1 - WGS84_E2))

    # 迭代计算纬度（最多10次迭代）
    for _ in range(10):
        N = WGS84_A / np.sqrt(1 - WGS84_E2 * np.sin(theta)**2)
        lat_new = np.arctan2(z + WGS84_E2 * N * np.sin(theta), p)
        if np.abs(lat_new - theta) < 1e-12:
            break
        theta = lat_new

    lat = theta
    lon = np.arctan2(y, x)
    N = WGS84_A / np.sqrt(1 - WGS84_E2 * np.sin(lat)**2)
    h = p / np.cos(lat) - N

    return lat, lon, h

# 批量处理
def batch_convert_coordinates(x_arr, y_arr, z_arr):
    """
    批量转换坐标数组
    """
    n = len(x_arr)
    lats = np.zeros(n)
    lons = np.zeros(n)
    hs = np.zeros(n)

    for i in range(n):
        lats[i], lons[i], hs[i] = ecef2lla_fast(
            x_arr[i], y_arr[i], z_arr[i], WGS84_A, WGS84_E2
        )

    return lats, lons, hs
```

== 总结

Python为GNSS数据处理提供了强大而灵活的工具链。通过NumPy、SciPy等科学计算库，结合RTKLIB等专业软件，可以实现高效的GNSS数据处理和分析。

*主要优势：*
- 代码简洁易读，开发效率高
- 丰富的第三方库支持
- 良好的可视化能力
- 易于与C/C++软件集成
- 支持并行计算和GPU加速

*应用场景：*
- RINEX文件解析和转换
- 卫星星历计算和位置解算
- 坐标系统和投影转换
- 数据质量控制和周跳检测
- 定位精度分析和可视化
- RTKLIB结果后处理

通过合理使用Python和这些工具，可以显著提升GNSS数据处理的效率和可维护性。

#link("https://numpy.org/")[NumPy文档]
#link("https://scipy.org/")[SciPy文档]
#link("https://matplotlib.org/")[Matplotlib文档]
#link("https://rtklib.com/")[RTKLIB官网]
