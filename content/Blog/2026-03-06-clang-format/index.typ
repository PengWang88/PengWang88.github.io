#import "../../index.typ": template, tufted
#show: template.with(
  title: "使用 clang-format 进行代码格式化",
  date: (year: 2026, month: 3, day: 6),
  description: "使用 clang-format 工具对 C/C++ 代码进行格式化，支持递归处理整个项目目录",
)

= 使用 clang-format 进行代码格式化

在 C/C++ 项目中维护一致代码风格的工具。

== 递归格式化目录

*用于递归格式化所有 C/C++ 文件的 PowerShell 命令：*

```powershell
Get-ChildItem -Recurse -Include *.cpp,*.h,*.c,*.hpp | ForEach-Object { clang-format -i $_.FullName }
```

该命令的功能：
- 递归搜索 `.cpp`、`.h`、`.c` 和 `.hpp` 文件
- 对每个文件就地应用 clang-format
- 在整个项目中保持一致的格式化风格

== .clang-format 配置模板

*基于 Google 风格并自定义的配置文件示例：*

```yaml
BasedOnStyle: google # 基础风格：Google

BreakBeforeBraces: Custom # 花括号断行风格
BraceWrapping:
  BeforeElse: true # 在 else 前换行

IndentWidth: 2 # 缩进宽度
ColumnLimit: 0 # 每行字符长度限制（0 表示不限制）

AccessModifierOffset: -2 # 访问修饰符偏移量
AlignAfterOpenBracket: true # 在开括号后对齐

# 未使用的参数
# AlignArrayOfStructures
# AlignConsecutiveAssignments
```

*关键配置选项说明：*

- *BasedOnStyle*: 预定义风格（Google、LLVM、Mozilla 等）
- *IndentWidth*: 每级缩进的空格数
- *ColumnLimit*: 每行最大字符数（0 表示无限制）
- *AccessModifierOffset*: 访问修饰符的缩进偏移
- *AlignAfterOpenBracket*: 在开括号后对齐参数

== 安装方法

#link("https://clang.llvm.org/docs/ClangFormat.html")[官方文档]

安装方式：
- *Windows*: 下载 LLVM 或使用包管理器
- *Linux*: `sudo apt install clang-format`
- *macOS*: `brew install clang-format`

== 使用方法

*格式化单个文件：*
```bash
clang-format -i myfile.cpp
```

*使用指定配置文件格式化：*
```bash
clang-format -i myfile.cpp --style=file
```

*检查格式但不修改文件：*
```bash
clang-format --dry-run --Werror myfile.cpp
```
