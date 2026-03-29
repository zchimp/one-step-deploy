适用场景
两个字符串 / 数组的匹配问题（比如编辑距离、最长回文子序列）。

```java
// LeetCode 1143. 最长公共子序列
public int longestCommonSubsequence(String text1, String text2) {
    int n = text1.length(), m = text2.length();
    // 1. 状态定义：dp[i][j]表示text1前i个字符和text2前j个字符的LCS长度
    int[][] dp = new int[n+1][m+1];
    
    // 2. 初始化：dp[0][j]=0，dp[i][0]=0（默认初始化）
    
    // 3. 遍历顺序：正序
    for (int i = 1; i <= n; i++) {
        for (int j = 1; j <= m; j++) {
            // 4. 状态转移
            if (text1.charAt(i-1) == text2.charAt(j-1)) {
                dp[i][j] = dp[i-1][j-1] + 1; // 字符相等，长度+1
            } else {
                dp[i][j] = Math.max(dp[i-1][j], dp[i][j-1]); // 取最大值
            }
        }
    }
    
    // 5. 返回结果
    return dp[n][m];
}
```

