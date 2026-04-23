---
tags:
  - 主题
  - 数组
  - 二分查找
  - 算法题
type: problem
source: https://leetcode.cn/problems/binary-search/
---

# LeetCode 704 二分查找

题目链接：[Binary Search](https://leetcode.cn/problems/binary-search/)

## 题目在问什么

给定一个升序且元素不重复的数组 `nums`，查找目标值 `target`。

- 找到就返回下标
- 找不到就返回 `-1`

## 这题为什么重要

这题是二分查找最标准的入门题。

它真正训练的不是“会不会写 if”，而是：

- 你能不能识别二分查找的适用前提
- 你能不能保持区间定义不乱

## 看到题目时先判断什么

这题适合二分查找，因为它满足两个关键条件：

- 数组有序
- 查找目标明确

如果数组无序，通常就不能直接上二分。

## 我的第一反应

二分查找最容易出错的地方不是思路，而是边界。

所以我做这题时，第一件事不是直接写代码，而是先决定：

我是用左闭右闭区间，还是左闭右开区间？

只要区间定义定了，后面的 `while` 条件、左右边界更新方式都必须一致。

## 核心思路

每次取中点 `mid`：

- 如果 `nums[mid] == target`，直接返回
- 如果 `nums[mid] < target`，去右半边继续找
- 如果 `nums[mid] > target`，去左半边继续找

核心不是“折半”本身，而是每一步都要严格缩小有效区间。

## 写法一：左闭右闭 `[left, right]`

这是我更容易先写对的一种版本。

### 区间定义

目标值如果存在，一定在 `[left, right]` 中。

### 由区间定义推出来的规则

- `while (left <= right)`
- 当 `nums[mid] > target` 时，`right = mid - 1`
- 当 `nums[mid] < target` 时，`left = mid + 1`

### C++ 代码

```cpp
class Solution {
public:
    int search(vector<int>& nums, int target) {
        int left = 0;
        int right = nums.size() - 1;

        while (left <= right) {
            int mid = left + (right - left) / 2;

            if (nums[mid] == target) {
                return mid;
            }

            if (nums[mid] < target) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }

        return -1;
    }
};
```

## 写法二：左闭右开 `[left, right)`

这种写法也完全正确，但更需要你对区间定义非常清楚。

### 区间定义

目标值如果存在，一定在 `[left, right)` 中。

### 由区间定义推出来的规则

- `while (left < right)`
- 当 `nums[mid] > target` 时，`right = mid`
- 当 `nums[mid] < target` 时，`left = mid + 1`

### C++ 代码

```cpp
class Solution {
public:
    int search(vector<int>& nums, int target) {
        int left = 0;
        int right = nums.size();

        while (left < right) {
            int mid = left + (right - left) / 2;

            if (nums[mid] == target) {
                return mid;
            }

            if (nums[mid] < target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        return -1;
    }
};
```

## 最容易错的地方

### 1. 区间定义和代码不一致

比如你明明写的是 `[left, right]`，却用了：

```cpp
while (left < right)
```

或者：

```cpp
right = mid
```

这就是最常见的混乱来源。

### 2. `mid` 计算写成 `(left + right) / 2`

虽然很多题里也能过，但更稳妥的写法是：

```cpp
left + (right - left) / 2
```

这样能避免溢出风险。

### 3. 忘了二分的前提是“有序”

一看到查找题就想二分，是很常见的误区。

## 这题真正该记住的东西

这题不是为了背一份模板，而是为了记住一句话：

区间定义就是不变量。

你一旦定义了当前有效区间，后面的每一步更新都必须维护这个定义。

## 复杂度

- 时间复杂度：`O(log n)`
- 空间复杂度：`O(1)`

## 复盘

- 这题本质上在考什么：二分查找的区间不变量
- 我哪里容易卡住：`while` 条件和边界更新不统一
- 可以迁移到哪些题型：搜索插入位置、平方根、边界查找问题

## 相关笔记

- [[数组]]
- [[数组总览]]
