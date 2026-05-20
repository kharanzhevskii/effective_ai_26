# Берем официальный образ PyTorch времен выхода FlashAttention 1
FROM pytorch/pytorch:1.13.1-cuda11.6-cudnn8-devel

# Ставим утилиты для компиляции C++/CUDA
RUN apt-get update && apt-get install -y git build-essential
RUN pip install --upgrade pip
RUN pip install ninja packaging pandas jupyter

# Компилируем оригинальный FlashAttention v1.0.9
# Флаг --no-build-isolation помогает избежать багов со старыми версиями pip
RUN pip install flash-attn==1.0.9 --no-build-isolation

# Настраиваем рабочую директорию
WORKDIR /workspace
