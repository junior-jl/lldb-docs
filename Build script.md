```bash
# Store the current working directory in a variable
LLDB_BUILD_DIR="$PWD/lldb-build"

# Create the lldb-build directory
mkdir -p "$LLDB_BUILD_DIR"
cd "$LLDB_BUILD_DIR"

# Clone the LLVM project repository
git clone https://github.com/llvm/llvm-project.git "$LLDB_BUILD_DIR/llvm-project"

# Create the necessary install directory
mkdir -p "$LLDB_BUILD_DIR/install"

# Run CMake with the appropriate flags
cmake -G Ninja \
      -DCMAKE_BUILD_TYPE=Debug \
      -DBUILD_SHARED_LIBS=True \
      -DLLVM_USE_SPLIT_DWARF=True \
      -DLLVM_ENABLE_PROJECTS="clang;lldb" \
      -DCMAKE_INSTALL_PREFIX="$LLDB_BUILD_DIR/install/" \
      -DLLVM_OPTIMIZED_TABLEGEN=True \
      -DLLVM_BUILD_TESTS=False \
      "$LLDB_BUILD_DIR/llvm-project/llvm"

# Build using ninja
ninja

```
