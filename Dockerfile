# 构建阶段：使用 Alpine 基础镜像
FROM python:3.11-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装构建依赖
RUN apk add --no-cache \
    build-base \
    curl \
    git

# 复制所有文件
COPY . .

# 安装依赖
RUN pip install --no-cache-dir .

# 运行阶段：使用更小的基础镜像
FROM python:3.11-alpine

# 设置工作目录
WORKDIR /app

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# 复制安装的包和必要文件
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /app/mcp_rquest /app/mcp_rquest

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV TZ=Asia/Shanghai

# 创建非 root 用户
RUN addgroup -S mcp && adduser -S -G mcp mcp
USER mcp

# 暴露默认端口（MCP 服务器默认端口）
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# 启动命令
CMD ["python", "-m", "mcp_rquest"] 
