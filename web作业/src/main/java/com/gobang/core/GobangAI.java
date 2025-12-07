package com.gobang.core;

import java.awt.Point;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class GobangAI {
    private int size = 15; // 棋盘大小
    private int difficulty = 1; // 0=Simple, 1=Medium, 2=Hard
    private Random random = new Random();

    public void setDifficulty(int level) {
        this.difficulty = level;
    }

    // 主入口：根据当前棋盘返回 AI 的落子坐标
    public Point think(int[][] board) {
        if (difficulty == 0) return simpleThink(board);
        else if (difficulty == 1) return mediumThink(board);
        else return hardThink(board);
    }

    // 简单模式：随机找空位
    private Point simpleThink(int[][] board) {
        List<Point> empty = new ArrayList<>();
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                if (board[i][j] == 0) empty.add(new Point(i, j));
            }
        }
        if (empty.isEmpty()) return new Point(-1, -1);
        return empty.get(random.nextInt(empty.size()));
    }

    // 中级模式：简单的攻防逻辑 (C++移植)
    private Point mediumThink(int[][] board) {
        int[][] score = new int[size][size];
        int maxScore = 0;
        List<Point> candidates = new ArrayList<>();

        for (int row = 0; row < size; row++) {
            for (int col = 0; col < size; col++) {
                if (board[row][col] != 0) continue;

                int val = 0;
                // 遍历8个方向
                for (int y = -1; y <= 1; y++) {
                    for (int x = -1; x <= 1; x++) {
                        if (y == 0 && x == 0) continue;

                        int blackNum = 0; // 玩家连子数
                        for (int i = 1; i <= 4; i++) {
                            int r = row + i * y;
                            int c = col + i * x;
                            if (r < 0 || r >= size || c < 0 || c >= size) break;
                            if (board[r][c] == 1) blackNum++; // 1代表玩家
                            else break;
                        }
                        // 评分逻辑 (移植自你的C++)
                        if (blackNum == 1) val += 10;
                        else if (blackNum == 2) val += 30;
                        else if (blackNum == 3) val += 100;
                        else if (blackNum >= 4) val += 5000;
                    }
                }
                score[row][col] = val;
                if (val > maxScore) {
                    maxScore = val;
                    candidates.clear();
                    candidates.add(new Point(row, col));
                } else if (val == maxScore) {
                    candidates.add(new Point(row, col));
                }
            }
        }
        if (candidates.isEmpty()) return simpleThink(board);
        return candidates.get(random.nextInt(candidates.size()));
    }

    // 困难模式：全盘评分 (C++移植)
    private Point hardThink(int[][] board) {
        int[][] value = calculateScore(board);
        int maxScore = -1;
        List<Point> maxPos = new ArrayList<>();

        for (int row = 0; row < size; row++) {
            for (int col = 0; col < size; col++) {
                if (board[row][col] == 0) {
                    if (value[row][col] > maxScore) {
                        maxScore = value[row][col];
                        maxPos.clear();
                        maxPos.add(new Point(row, col));
                    } else if (value[row][col] == maxScore) {
                        maxPos.add(new Point(row, col));
                    }
                }
            }
        }
        if (maxPos.isEmpty()) return simpleThink(board);
        return maxPos.get(random.nextInt(maxPos.size()));
    }

    // 困难模式核心：评分计算
    private int[][] calculateScore(int[][] board) {
        int[][] value = new int[size][size];
        
        for (int row = 0; row < size; row++) {
            for (int col = 0; col < size; col++) {
                if (board[row][col] != 0) continue;

                // 遍历4个方向 (水平、垂直、两个对角)
                // C++代码用了双向探测，这里简化为遍历所有方向
                int[][] directions = {{1,0}, {0,1}, {1,1}, {1,-1}};
                
                for(int[] dir : directions) {
                    int x = dir[0], y = dir[1];
                    
                    // --- 评估玩家 (Black, 1) 的威胁 ---
                    int blackNum = 0, emptyNum = 0;
                    // 正向查
                    for (int i = 1; i <= 4; i++) {
                        int r = row + i * y; 
                        int c = col + i * x;
                        if (!isValid(r, c)) break;
                        if (board[r][c] == 1) blackNum++;
                        else if (board[r][c] == 0) { emptyNum++; break; }
                        else break; // 遇到白子
                    }
                    // 反向查
                    for (int i = 1; i <= 4; i++) {
                        int r = row - i * y; 
                        int c = col - i * x;
                        if (!isValid(r, c)) break;
                        if (board[r][c] == 1) blackNum++;
                        else if (board[r][c] == 0) { emptyNum++; break; }
                        else break;
                    }
                    
                    if (blackNum == 1) value[row][col] += 10;
                    else if (blackNum == 2) value[row][col] += (emptyNum >= 2 ? 40 : 30);
                    else if (blackNum == 3) value[row][col] += (emptyNum >= 2 ? 5000 : 60);
                    else if (blackNum >= 4) value[row][col] += 20000;

                    // --- 评估AI (White, 2) 的机会 ---
                    int whiteNum = 0; 
                    emptyNum = 0;
                    // 正向
                    for (int i = 1; i <= 4; i++) {
                        int r = row + i * y; 
                        int c = col + i * x;
                        if (!isValid(r, c)) break;
                        if (board[r][c] == 2) whiteNum++;
                        else if (board[r][c] == 0) { emptyNum++; break; }
                        else break;
                    }
                    // 反向
                    for (int i = 1; i <= 4; i++) {
                        int r = row - i * y; 
                        int c = col - i * x;
                        if (!isValid(r, c)) break;
                        if (board[r][c] == 2) whiteNum++;
                        else if (board[r][c] == 0) { emptyNum++; break; }
                        else break;
                    }

                    if (whiteNum == 1) value[row][col] += 10;
                    else if (whiteNum == 2) value[row][col] += (emptyNum >= 2 ? 50 : 25);
                    else if (whiteNum == 3) value[row][col] += (emptyNum >= 2 ? 10000 : 55);
                    else if (whiteNum >= 4) value[row][col] += 30000;
                }
            }
        }
        return value;
    }

    private boolean isValid(int r, int c) {
        return r >= 0 && r < size && c >= 0 && c < size;
    }
}