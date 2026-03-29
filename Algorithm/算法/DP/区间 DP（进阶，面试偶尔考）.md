适用场景
区间范围内的最优解（比如最长回文子串、戳气球）。

```java
// LeetCode 5. 最长回文子串（区间DP版）
public String longestPalindrome(String s) {
    int n = s.length();
    // 1. 状态定义：dp[i][j]表示s[i..j]是否是回文子串
    boolean[][] dp = new boolean[n][n];
    String res = "";
    
    // 2. 初始化：单个字符都是回文
    for (int i = 0; i < n; i++) {
        dp[i][i] = true;
        res = s.substring(i, i+1);
    }
    
    // 3. 遍历顺序：斜序（从短区间到长区间）
    for (int len = 2; len <= n; len++) { // 区间长度
        for (int i = 0; i + len <= n; i++) { // 区间起点
            int j = i + len - 1; // 区间终点
            // 4. 状态转移
            if (s.charAt(i) == s.charAt(j)) {
                if (len == 2) {
                    dp[i][j] = true; // 两个字符相等，是回文
                } else {
                    dp[i][j] = dp[i+1][j-1]; // 依赖更小的区间
                }
            }
            // 更新结果
            if (dp[i][j] && len > res.length()) {
                res = s.substring(i, j+1);
            }
        }
    }
    
    // 5. 返回结果
    return res;
}
```

