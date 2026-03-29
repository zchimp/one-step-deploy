核心：先排序 + 剪枝去重（面试高频坑点）

```java
public List<List<Integer>> combinationSum2(int[] candidates, int target) {
    List<List<Integer>> result = new ArrayList<>();
    Arrays.sort(candidates); // 先排序，方便去重
    backtrack(candidates, target, 0, new ArrayList<>(), result);
    return result;
}

private void backtrack(int[] candidates, int target, int start, List<Integer> path, List<List<Integer>> result) {
    // 终止条件：路径和等于target
    int sum = path.stream().mapToInt(Integer::intValue).sum();
    if (sum == target) {
        result.add(new ArrayList<>(path));
        return;
    }
    // 剪枝：和超过target，直接返回
    if (sum > target) {
        return;
    }

    for (int i = start; i < candidates.length; i++) {
        // 剪枝：跳过重复元素（关键！）
        if (i > start && candidates[i] == candidates[i-1]) {
            continue;
        }
        path.add(candidates[i]);
        backtrack(candidates, target, i + 1, path, result);
        path.remove(path.size() - 1);
    }
}
```

