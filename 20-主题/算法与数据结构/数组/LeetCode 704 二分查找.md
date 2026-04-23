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

## 这是什么

这是一道最标准的二分查找入门题。

题目给定一个升序且元素不重复的数组 `nums`，要求查找目标值 `target`：

- 找到就返回下标
- 找不到就返回 `-1`

## 为什么重要

- 这题是二分查找最干净的起点，几乎没有额外干扰
- 它真正训练的不是“会不会写 if”，而是能不能先确认二分前提、再把区间边界写稳
- 后面很多边界查找题，都会回到这道题里的区间不变量

## 这题先判断什么

这题适合二分查找，因为它满足两个关键条件：

- 数组有序
- 查找目标明确

如果数组无序，通常就不能直接上二分。

## 我的第一反应

这题最容易出错的地方不是思路，而是边界。

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

## 一个最容易错的地方

很多人不是不会二分，而是会在写代码时把区间逻辑混掉。

比如：

- 明明定义的是 `[left, right]`
- 却用了 `while (left < right)` 或 `right = mid`

这种错误的本质，不是粗心，而是没有把“区间定义就是不变量”记牢。

## 这题真正该记住的东西

这题不是为了背一份模板，而是为了记住一句话：

区间定义就是不变量。

你一旦定义了当前有效区间，后面的每一步更新都必须维护这个定义。

## 复杂度

- 时间复杂度：`O(log n)`
- 空间复杂度：`O(1)`

## 易错点

- 容易一看到查找题就想二分，却忘了先确认“有序”前提
- 容易把两种区间写法混在一起
- 容易把 `mid` 写成 `(left + right) / 2`

## 我的理解

这题真正的价值不在答案本身，而在它是最适合练“区间不变量”的起点题。

只要这题的边界写稳了，后面的搜索插入位置、左边界、右边界和答案二分都会更容易迁移。

## 相关笔记

- [[数组]]
- [[数组总览]]
- [[二分查找模板]]
