#import "../../index.typ": template, tufted
#show: template.with(
  title: "Code Formatting with clang-format",
  date: (year: 2026, month: 3, day: 6),
  description: "How to use clang-format for C/C++ code formatting with recursive directory processing",
)

= Code Formatting with clang-format

Tools for maintaining consistent code style in C/C++ projects.

== Recursive Directory Formatting

*PowerShell command to format all C/C++ files recursively:*

```powershell
Get-ChildItem -Recurse -Include *.cpp,*.h,*.c,*.hpp | ForEach-Object { clang-format -i $_.FullName }
```

This command:
- Searches recursively for `.cpp`, `.h`, `.c`, and `.hpp` files
- Applies clang-format to each file in place
- Maintains consistent formatting across the entire project

== .clang-format Template Configuration

*Sample configuration file based on Google style with customizations:*

```yaml
BasedOnStyle: google # Base style: Google

BreakBeforeBraces: Custom # Brace breaking style
BraceWrapping:
  BeforeElse: true # New line before else

IndentWidth: 2 # Indentation width
ColumnLimit: 0 # Line length limit (0 = no limit)

AccessModifierOffset: -2 # Access modifier offset
AlignAfterOpenBracket: true # Align after open bracket

# Unused parameters
# AlignArrayOfStructures
# AlignConsecutiveAssignments
```

*Key Configuration Options:*

- *BasedOnStyle*: Predefined style (Google, LLVM, Mozilla, etc.)
- *IndentWidth*: Number of spaces per indentation level
- *ColumnLimit*: Maximum characters per line (0 for unlimited)
- *AccessModifierOffset*: Indentation for access modifiers
- *AlignAfterOpenBracket*: Align parameters after opening bracket

== Installation

#link("https://clang.llvm.org/docs/ClangFormat.html")[Official Documentation]

Install via:
- *Windows*: Download LLVM or use package manager
- *Linux*: `sudo apt install clang-format`
- *macOS*: `brew install clang-format`

== Usage

*Format a single file:*
```bash
clang-format -i myfile.cpp
```

*Format with specific config file:*
```bash
clang-format -i myfile.cpp --style=file
```

*Check formatting without modifying:*
```bash
clang-format --dry-run --Werror myfile.cpp
```
