```java
// 示例：01矩阵（找每个单元格到最近0的最短距离）
public int[][] updateMatrix(int[][] mat) {
    int m = mat.length, n = mat[0].length;
    Queue<int[]> queue = new LinkedList<>();
    boolean[][] visited = new boolean[m][n];
    
    // 初始化：所有0入队（起始节点）
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            if (mat[i][j] == 0) {
                queue.offer(new int[]{i, j});
                visited[i][j] = true;
            }
        }
    }
    
    // 上下左右四个方向
    int[][] dirs = {{-1,0}, {1,0}, {0,-1}, {0,1}};
    int step = 0;
    
    while (!queue.isEmpty()) {
        int size = queue.size();
        for (int i = 0; i < size; i++) {
            int[] cur = queue.poll();
            int x = cur[0], y = cur[1];
            
            // 遍历四个方向
            for (int[] dir : dirs) {
                int nx = x + dir[0], ny = y + dir[1];
                // 未越界+未访问（即1的位置）
                if (nx >=0 && nx < m && ny >=0 && ny < n && !visited[nx][ny]) {
                    mat[nx][ny] = step + 1; // 距离=当前步数+1
                    visited[nx][ny] = true;
                    queue.offer(new int[]{nx, ny});
                }
            }
        }
        step++;
    }
    return mat;
}
```

