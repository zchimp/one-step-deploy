DFS 优先用递归实现（代码简洁，面试手写快），迭代版（栈）仅在递归深度超限（比如 1e4 层）时使用

```java
/**
 * DFS通用递归模板
 * @param node  当前遍历节点
 * @param visited  访问标记（图/矩阵用，树可省略）
 * @param path     记录当前路径（找路径/组合用）
 * @param result   存储最终结果
 */
public void dfs(节点类型 node, 访问标记 visited, 路径容器 path, 结果容器 result) {
    // 1. 终止条件（递归出口）：节点越界/已访问/满足结束条件
    if (node == null || visited.contains(node)) {
        // 可选：如果path满足目标，加入result
        if (path满足条件) {
            result.add(new ArrayList<>(path)); // 注意拷贝，避免引用覆盖
        }
        return;
    }

    // 2. 标记访问（图/矩阵必须，树可选）
    visited.add(node); // 矩阵用visited[i][j]=true，图用Set/数组
    path.add(node.val); // 记录当前节点到路径

    // 3. 遍历所有邻接节点（树：左右子树；图：邻接表；矩阵：上下左右）
    for (邻接节点 next : node的邻接列表) {
        dfs(next, visited, path, result); // 递归遍历下一层
    }

    // 4. 回溯（关键！恢复状态，用于找所有解的场景）
    path.remove(path.size() - 1); // 移出当前节点
    visited.remove(node); // 取消访问标记（矩阵：visited[i][j]=false）
}
```

