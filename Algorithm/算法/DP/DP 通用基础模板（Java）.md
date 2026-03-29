这是所有 DP 题的「母模板」，只需调整「状态定义」「转移方程」「初始化」即可适配所有场景：

```java
/**
 * DP通用模板
 * @param nums/arr  输入的原始数据（数组/字符串）
 * @return 最终结果（最大和/最长长度/方案数等）
 */
public int dpTemplate(int[] nums) {
    // 1. 状态定义：根据题目调整维度（一维/二维）
    int n = nums.length;
    int[] dp = new int[n]; // 一维DP：适用于线性问题（比如最长递增子序列）
    // int[][] dp = new int[n][m]; // 二维DP：适用于二维/字符串问题（比如最长公共子序列）

    // 2. 初始化：边界条件（必须先初始化，否则会出错）
    dp[0] = 初始值; // 一维初始化
    // for (int i = 0; i < n; i++) dp[i][0] = 初始值; // 二维初始化
    // for (int j = 0; j < m; j++) dp[0][j] = 初始值;

    // 3. 遍历顺序：根据状态转移方程确定（正序/倒序/斜序）
    for (int i = 1; i < n; i++) { // 一维遍历
        // for (int j = 1; j < m; j++) { // 二维遍历
            // 4. 状态转移方程：核心！根据题目推导
            dp[i] = 最优选择(比如Math.max/min(dp[i-1] + nums[i], nums[i]));
            // dp[i][j] = nums[i]==nums[j] ? dp[i-1][j-1]+1 : Math.max(dp[i-1][j], dp[i][j-1]);
        // }
    }

    // 5. 返回结果：根据题目要求返回（比如dp[n-1]、dp[n][m]、或遍历dp找最大值）
    return dp[n-1];
}
```

