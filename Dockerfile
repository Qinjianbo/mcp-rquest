# 使用 uv 基础镜像
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS uv

# 设置工作目录
WORKDIR /app

# 启用字节码编译
ENV UV_COMPILE_BYTECODE=1

# 使用复制模式而不是链接
ENV UV_LINK_MODE=copy

# 复制项目文件
COPY . .

# 安装项目依赖和项目本身
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system .

# 运行阶段
FROM python:3.11-slim-bookworm

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 创建非 root 用户
RUN groupadd -r mcp && useradd -r -g mcp mcp

# 复制安装的包
COPY --from=uv /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=uv /app/mcp_rquest /app/mcp_rquest

# 设置权限
RUN chown -R mcp:mcp /app/mcp_rquest

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV TZ=Asia/Shanghai
ENV HOME=/home/mcp

# 切换到非 root 用户
USER mcp

# 暴露默认端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# 启动命令
CMD ["python", "-m", "mcp_rquest"] 
