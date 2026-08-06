下载 https://github.com/steveteuber/kubectl-graph/releases/download/v0.7.0/kubectl-graph_v0.7.0_linux_amd64.tar.gz
tar -zxf kubectl-graph_v0.7.0_linux_amd64.tar.gz
chmod +x kubectl-graph
mv kubectl-graph /usr/local/bin


kubectl graph pods,deployments,configmaps,serviceaccounts -n monitoring
