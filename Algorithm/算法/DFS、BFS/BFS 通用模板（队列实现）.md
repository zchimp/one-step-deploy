BFS 必须用队列实现，核心是「层序遍历」，尤其适合找「最短路径 / 最小步数」

```java
/**
 * BFS通用模板
 * @param start  起始节点
 * @param target 目标节点（可选）
 * @return 结果（最短路径长度/是否可达/所有层序结果）
 */
public int bfs(节点类型 start, 节点类型 target) {
    // 1. 初始化队列+访问标记（避免重复访问）
    Queue<节点类型> queue = new LinkedList<>();
    Set<节点类型> visited = new HashSet<>();
    
    // 2. 起始节点入队+标记
    queue.offer(start);
    visited.add(start);
    
    // 3. 记录步数/层数（找最短路径必用）
    int step = 0;
    
    // 4. 层序遍历
    while (!queue.isEmpty()) {
        // 关键：获取当前层的节点数（层序遍历核心）
        int size = queue.size();
        
        // 遍历当前层所有节点
        for (int i = 0; i < size; i++) {
            // 取出队首节点
            节点类型 cur = queue.poll();
            
            // 终止条件：找到目标节点，返回步数
            if (cur == target) {
                return step;
            }
            
            // 遍历所有邻接节点
            for (邻接节点 next : cur的邻接列表) {
                // 未访问过则入队+标记
                if (!visited.contains(next)) {
                    queue.offer(next);
                    visited.add(next);
                }
            }
        }
        
        // 一层遍历完，步数+1
        step++;
    }
    
    // 未找到目标，返回-1
    return -1;
}
```

