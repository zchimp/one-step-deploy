需求：数组的所有子集（无重复元素）

```java
public List<List<Integer>> subsets(int[] nums) {
    List<List<Integer>> result = new ArrayList<>();
    backtrack(nums, 0, new ArrayList<>(), result);
    return result;
}

private void backtrack(int[] nums, int start, List<Integer> path, List<List<Integer>> result) {
    // 终止条件：无显式终止！每一步的路径都是一个子集，直接加入结果
    result.add(new ArrayList<>(path));

    // 遍历选择列表：i从start开始（避免重复子集）
    for (int i = start; i < nums.length; i++) {
        // 做出选择
        path.add(nums[i]);
        // 递归：start传i+1
        backtrack(nums, i + 1, path, result);
        // 撤销选择
        path.remove(path.size() - 1);
    }
}
```

