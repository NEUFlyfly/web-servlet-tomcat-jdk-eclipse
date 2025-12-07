package com.gobang.servlet;

import com.gobang.core.GobangAI;
import com.gobang.util.DBUtil;
import java.awt.Point;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/play")
public class GameServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final int BOARD_SIZE = 15;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        
        String action = request.getParameter("action");
        HttpSession session = request.getSession();

        int[][] board = (int[][]) session.getAttribute("board");

        if (board == null || "start".equals(action)) {
            board = new int[BOARD_SIZE][BOARD_SIZE];
            session.setAttribute("board", board);
            session.setAttribute("stepCount", 0);
            
            String levelStr = request.getParameter("level");
            int difficulty = (levelStr != null) ? Integer.parseInt(levelStr) : 1;
            session.setAttribute("difficulty", difficulty);
            
            String currentUser = (String) session.getAttribute("currentUser");
            if (currentUser == null) currentUser = "Unknown";

            int newGameId = createNewGame(currentUser);
            session.setAttribute("currentGameId", newGameId);
            
            response.getWriter().write("{\"status\":\"started\", \"gameId\":" + newGameId + "}");
            return;
        }

        if ("move".equals(action)) {
            int x = Integer.parseInt(request.getParameter("x"));
            int y = Integer.parseInt(request.getParameter("y"));
            
            Integer stepCountObj = (Integer) session.getAttribute("stepCount");
            int stepCount = (stepCountObj == null) ? 0 : stepCountObj;
            
            Integer difficultyObj = (Integer) session.getAttribute("difficulty");
            int difficulty = (difficultyObj == null) ? 1 : difficultyObj;
            
            Integer gameIdObj = (Integer) session.getAttribute("currentGameId");
            int gameId = (gameIdObj == null) ? 1 : gameIdObj;

            String currentUser = (String) session.getAttribute("currentUser");
            if (currentUser == null) currentUser = "Unknown";

            if (board[x][y] != 0) return;
            board[x][y] = 1; 
            stepCount++;
            
            saveStepToDB(currentUser, gameId, stepCount, 1, x + "," + y);

            if (checkWin(board, x, y, 1)) {
                updateGameResult(currentUser, gameId, 1); 
                int[] lvInfo = updatePlayerLevel(currentUser, difficulty, true); 
                session.removeAttribute("board"); 
                
                String json = String.format(
                    "{\"ai_x\":-1, \"ai_y\":-1, \"winner\":1, \"oldLevel\":%d, \"newLevel\":%d}", 
                    lvInfo[0], lvInfo[1]);
                response.getWriter().write(json);
                return;
            }

            GobangAI ai = new GobangAI();
            ai.setDifficulty(difficulty); 
            Point aiMove = ai.think(board);
            
            if (aiMove.x != -1) {
                board[aiMove.x][aiMove.y] = 2; 
                stepCount++;
                
                saveStepToDB(currentUser, gameId, stepCount, 2, aiMove.x + "," + aiMove.y);
                
                if (checkWin(board, aiMove.x, aiMove.y, 2)) {
                    updateGameResult(currentUser, gameId, 2); 
                    int[] lvInfo = updatePlayerLevel(currentUser, difficulty, false); 
                    session.removeAttribute("board");
                    
                    String json = String.format(
                        "{\"ai_x\":%d, \"ai_y\":%d, \"winner\":2, \"oldLevel\":%d, \"newLevel\":%d}", 
                        aiMove.x, aiMove.y, lvInfo[0], lvInfo[1]);
                    response.getWriter().write(json);
                    return;
                }
            } else {
                response.getWriter().write("{\"ai_x\":-1, \"ai_y\":-1, \"winner\":3}");
                return;
            }

            session.setAttribute("stepCount", stepCount);
            
            String json = String.format("{\"ai_x\":%d, \"ai_y\":%d, \"winner\":0}", aiMove.x, aiMove.y);
            response.getWriter().write(json);
        }
    }

    // --- 积分逻辑 (修改版：返回 int[]{old, new}) ---
    private int[] updatePlayerLevel(String username, int difficulty, boolean isWin) {
        int delta = 0;
        if (difficulty == 0) { delta = isWin ? 1 : -10; } 
        else if (difficulty == 1) { delta = isWin ? 5 : -5; } 
        else if (difficulty == 2) { delta = isWin ? 10 : -3; }
        
        int currentLevel = 0;
        int newLevel = 0;

        try (Connection conn = DBUtil.getConnection()) {
            String q = "SELECT level FROM Player WHERE username=?";
            PreparedStatement psQ = conn.prepareStatement(q);
            psQ.setString(1, username);
            ResultSet rs = psQ.executeQuery();
            if (rs.next()) currentLevel = rs.getInt(1);
            
            newLevel = currentLevel + delta;
            if (newLevel < 0) newLevel = 0;
            
            String u = "UPDATE Player SET level=? WHERE username=?";
            PreparedStatement psU = conn.prepareStatement(u);
            psU.setInt(1, newLevel);
            psU.setString(2, username);
            psU.executeUpdate();
            
        } catch (Exception e) { e.printStackTrace(); }
        
        return new int[]{currentLevel, newLevel};
    }

    private int createNewGame(String username) {
        int nextGameId = 1;
        try (Connection conn = DBUtil.getConnection()) {
            String query = "SELECT MAX(game_count) FROM Game WHERE username = ?";
            PreparedStatement psQuery = conn.prepareStatement(query);
            psQuery.setString(1, username);
            ResultSet rs = psQuery.executeQuery();
            if (rs.next()) {
                nextGameId = rs.getInt(1) + 1;
            }
            String insert = "INSERT INTO Game (username, game_count, is_win, game_time) VALUES (?, ?, 0, NOW())";
            PreparedStatement psInsert = conn.prepareStatement(insert);
            psInsert.setString(1, username);
            psInsert.setInt(2, nextGameId);
            psInsert.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
        return nextGameId;
    }
    
    private void saveStepToDB(String user, int gameId, int step, int who, String coord) {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO Step (username, game_count, step_count, by_who, coordination) VALUES (?,?,?,?,?)")) {
            ps.setString(1, user);
            ps.setInt(2, gameId);
            ps.setInt(3, step);
            ps.setInt(4, who);
            ps.setString(5, coord);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }
    
    private void updateGameResult(String user, int gameId, int result) {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "UPDATE Game SET is_win = ? WHERE username = ? AND game_count = ?")) {
            ps.setInt(1, result);
            ps.setString(2, user);
            ps.setInt(3, gameId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    private boolean checkWin(int[][] board, int x, int y, int type) {
        int[][] directions = {{1, 0}, {0, 1}, {1, 1}, {1, -1}}; 
        for (int[] dir : directions) {
            int count = 1; 
            for (int i = 1; i < 5; i++) {
                int r = x + i * dir[0];
                int c = y + i * dir[1];
                if (r < 0 || r >= BOARD_SIZE || c < 0 || c >= BOARD_SIZE || board[r][c] != type) break;
                count++;
            }
            for (int i = 1; i < 5; i++) {
                int r = x - i * dir[0];
                int c = y - i * dir[1];
                if (r < 0 || r >= BOARD_SIZE || c < 0 || c >= BOARD_SIZE || board[r][c] != type) break;
                count++;
            }
            if (count >= 5) return true;
        }
        return false;
    }
}
