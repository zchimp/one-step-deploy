适用场景 

一维数组的最值 / 计数问题（比如最大子数组和、爬楼梯、打家劫舍） 

示例 1：最大子数组和（LeetCode 53）

    public int maxSubArray(int[] nums) {
        // 1. 状态定义：dp[i]表示以nums[i]结尾的最大子数组和
        int n = nums.length;
        int[] dp = new int[n];
        
        // 2. 初始化：第一个元素的最大子数组和就是自己
        dp[0] = nums[0];
        int maxSum = dp[0]; // 记录全局最大值
        
        // 3. 遍历顺序：正序
        for (int i = 1; i < n; i++) {
            // 4. 状态转移：要么加入前一个子数组，要么自己单独成组
            dp[i] = Math.max(dp[i-1] + nums[i], nums[i]);
            // 更新全局最大值
            maxSum = Math.max(maxSum, dp[i]);
        }
        
        // 5. 返回结果
        return maxSum;
    }

示例 2：爬楼梯（LeetCode 70）

```java
public int climbStairs(int n) {
    // 优化空间：用两个变量代替数组（DP常见优化）
    if (n <= 2) return n;
    int dp1 = 1; // 上1阶的方法数
    int dp2 = 2; // 上2阶的方法数
    
    for (int i = 3; i <= n; i++) {
        int cur = dp1 + dp2; // 状态转移：dp[i] = dp[i-1] + dp[i-2]
        dp1 = dp2;
        dp2 = cur;
    }
    return dp2;
}
```

