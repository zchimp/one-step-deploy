# GitHub Actions
Workflow（工作流）：CI/CD 流水线，YAML 文件存放路径固定：.github/workflows/xxx.yml
Event（触发事件）：代码 push、PR、tag、手动触发等
Job（任务）：流水线并行 / 串行任务，跑在独立虚拟机
Step（步骤）：单个 Job 内顺序执行的操作（拉代码、编译、打包镜像）
Runner（运行器）：GitHub 提供免费云主机（ubuntu-latest/windows/macOS），也可自建私有 Runner
Secrets：仓库私密配置（镜像仓库账号、服务器密码，不暴露日志）