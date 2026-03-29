```java
// 示例：岛屿数量（LeetCode 200）
public int numIslands(char[][] grid) {
    int count = 0;
    int m = grid.length, n = grid[0].length;
    // 访问标记：矩阵用二维数组，避免重复遍历
    boolean[][] visited = new boolean[m][n];
    
    // 遍历每个格子
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            // 未访问且是陆地，启动DFS
            if (grid[i][j] == '1' && !visited[i][j]) {
                dfsMatrix(grid, i, j, visited);
                count++;
            }
        }
    }
    return count;
}

// 矩阵DFS专用模板（上下左右四个方向）
private void dfsMatrix(char[][] grid, int i, int j, boolean[][] visited) {
    // 终止条件：越界/已访问/不是陆地
    if (i < 0 || i >= grid.length || j < 0 || j >= grid[0].length 
        || visited[i][j] || grid[i][j] == '0') {
        return;
    }
    
    // 标记访问
    visited[i][j] = true;
    
    // 遍历上下左右四个方向
    dfsMatrix(grid, i-1, j, visited); // 上
    dfsMatrix(grid, i+1, j, visited); // 下
    dfsMatrix(grid, i, j-1, visited); // 左
    dfsMatrix(grid, i, j+1, visited); // 右
    
    // 岛屿问题无需回溯（标记后不用恢复，因为只需要统计数量）
    // 若需找所有路径，才需要恢复visited[i][j] = false
}
```

