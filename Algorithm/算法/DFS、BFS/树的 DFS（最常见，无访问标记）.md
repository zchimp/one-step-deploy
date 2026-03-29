树的 DFS（最常见，无访问标记）

```java
// 示例：二叉树的所有路径（LeetCode 257）
public List<String> binaryTreePaths(TreeNode root) {
    List<String> result = new ArrayList<>();
    if (root == null) return result;
    dfsTree(root, "", result);
    return result;
}

// 树的DFS专用模板（无visited，路径用字符串拼接）
private void dfsTree(TreeNode node, String path, List<String> result) {
    // 终止条件：叶子节点
    if (node.left == null && node.right == null) {
        result.add(path + node.val);
        return;
    }
    // 遍历左子树
    if (node.left != null) {
        dfsTree(node.left, path + node.val + "->", result);
    }
    // 遍历右子树
    if (node.right != null) {
        dfsTree(node.right, path + node.val + "->", result);
    }
}

// 二叉树节点定义（面试必写）
class TreeNode {
    int val;
    TreeNode left;
    TreeNode right;
    TreeNode(int x) { val = x; }
}
```

