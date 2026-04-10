#!/bin/bash

# --- 配置 ---
# 输入的PLY文件所在的目录
INPUT_DIR="data/famous"
# 预处理后文件存放的目录
PREPROCESSED_DIR="data/famous" # 输出目录和输入目录是同一个
# 配置文件所在的目录
CONFIG_DIR="configs"
# 配置文件模板的路径
TEMPLATE_CONFIG="$CONFIG_DIR/template_pc_cfg.json"
# GPU设备号
GPU_DEVICE=1

# --- 脚本开始 ---
# 创建预处理输出目录，如果它不存在
# 这个命令现在是安全的，因为它只确保 "data/famous" 存在
mkdir -p "$PREPROCESSED_DIR"

# 检查模板文件是否存在
if [ ! -f "$TEMPLATE_CONFIG" ]; then
    echo "错误: 模板配置文件 $TEMPLATE_CONFIG 未找到！"
    exit 1
fi

# 遍历输入目录下的所有 .ply 文件
for ply_file in "$INPUT_DIR"/*.ply; do
    # 检查是否找到了文件
    [ -e "$ply_file" ] || continue

    # 从完整路径中提取不带扩展名的文件名 (例如: "3DBenchy")
    dataname=$(basename "$ply_file" .ply)

    echo "================================================="
    echo "正在处理: $dataname"
    echo "================================================="

    # --- 步骤 1: 预处理 ---
    echo "-> 步骤 1/3: 正在预处理 $ply_file..."
    # 【关键修改】直接将 PREPROCESSED_DIR 作为输出目录传递给脚本。
    # preprocess.py 会自动处理文件名，将其保存为 data/famous/3DBenchy_pc.ply
    python preprocess.py "$ply_file" "$PREPROCESSED_DIR" -s 10000 -pc

    # --- 步骤 2: 生成新的配置文件 ---
    # 定义新配置文件的名称
    NEW_CONFIG_FILE="$CONFIG_DIR/${dataname}_pc.json"
    # 【关键修改】为JSON文件定义正确的数据集路径前缀
    # train.py 需要的是不带扩展名的路径前缀，例如 "data/famous/3DBenchy"
    DATASET_PATH_FOR_JSON="$PREPROCESSED_DIR/$dataname"

    echo "-> 步骤 2/3: 正在创建配置文件 $NEW_CONFIG_FILE..."
    # 使用sed命令替换模板中的占位符，并生成新的配置文件
    sed -e "s|__EXPERIMENT_NAME__|$dataname|g" \
        -e "s|__DATASET_PATH__|$DATASET_PATH_FOR_JSON|g" \
        "$TEMPLATE_CONFIG" > "$NEW_CONFIG_FILE"

    # --- 步骤 3: 开始训练 ---
    echo "-> 步骤 3/3: 正在使用 $NEW_CONFIG_FILE 开始训练..."
    python train.py "$NEW_CONFIG_FILE" $GPU_DEVICE

    echo "--- 已完成: $dataname ---"
    echo ""
done

echo "所有任务已完成！"