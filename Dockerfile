# 使用 Python 3.11 作为基础镜像
FROM python:3.11-slim as builder

# 设置工作目录
WORKDIR /app

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv
RUN curl -LsSf https://github.com/astral-sh/uv/releases/latest/download/uv-installer.sh | sh

# 复制项目文件
COPY . .

# 使用 uv 安装依赖
RUN uv pip install --system .

# 第二阶段：运行阶段
FROM python:3.11-slim

WORKDIR /app

# 复制安装的包和必要文件
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /app/mcp_rquest /app/mcp_rquest

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# 暴露默认端口（MCP 服务器默认端口）
EXPOSE 8080

# 启动命令
CMD ["python", "-m", "mcp_rquest"]
