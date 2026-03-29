需求：数组的所有全排列（无重复元素）

```java
public List<List<Integer>> permute(int[] nums) {
    List<List<Integer>> result = new ArrayList<>();
    boolean[] used = new boolean[nums.length]; // 标记已使用元素
    backtrack(nums, new ArrayList<>(), result, used);
    return result;
}

private void backtrack(int[] nums, List<Integer> path, List<List<Integer>> result, boolean[] used) {
    // 终止条件：路径长度等于数组长度
    if (path.size() == nums.length) {
        result.add(new ArrayList<>(path));
        return;
    }

    // 遍历选择列表：i从0开始（排列可重复选不同位置的元素）
    for (int i = 0; i < nums.length; i++) {
        // 剪枝：元素已使用过，跳过
        if (used[i]) {
            continue;
        }
        // 做出选择
        path.add(nums[i]);
        used[i] = true;
        // 递归：start传0（排列需要重新遍历所有元素）
        backtrack(nums, path, result, used);
        // 撤销选择
        path.remove(path.size() - 1);
        used[i] = false;
    }
}
```

