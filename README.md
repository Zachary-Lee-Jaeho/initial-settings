# initial-settings
vimrc and tmuxconf

## VIMRC

from : https://github.com/timss/vimconf
thx to timss!

## TMUX CONF
install tpm and https://github.com/tmux-plugins/tmux-continuum

mkdir -p /home/ubuntu/projects/llvm-project/build
cd /home/ubuntu/projects/llvm-project/build
cmake -G Ninja ../llvm \
   -DLLVM_ENABLE_PROJECTS=mlir \
   -DLLVM_TARGETS_TO_BUILD="host" \
   -DCMAKE_BUILD_TYPE=Debug \
   -DLLVM_ENABLE_ASSERTIONS=ON \
   -DLLVM_ENABLE_RTTI=ON
cmake --build . -- -j4
