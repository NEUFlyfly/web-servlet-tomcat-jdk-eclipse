package com.gobang.servlet;

import com.gobang.util.DBUtil;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/admin")
public class AdminServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        doPost(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        
        String action = request.getParameter("action");
        
        try {
            if ("listPlayers".equals(action)) listPlayers(response);
            else if ("getGames".equals(action)) getGames(request, response);
            else if ("getGameSteps".equals(action)) getGameSteps(request, response);
            else if ("addPlayer".equals(action)) addPlayer(request, response);
            else if ("addGame".equals(action)) addGame(request, response);
            else if ("deletePlayer".equals(action)) deletePlayer(request, response);
            else if ("deleteGame".equals(action)) deleteGame(request, response);
            else if ("updatePlayer".equals(action)) updatePlayer(request, response);
        } catch (Exception e) {
            e.printStackTrace(); // 在服务器控制台打印堆栈
            response.setStatus(500);
            // 将具体的异常信息返回给前端，注意转义双引号
            String errMsg = e.getMessage() != null ? e.getMessage().replace("\"", "'") : "Unknown Error";
            response.getWriter().write("{\"error\":\"" + errMsg + "\"}");
        }
    }

    // --- 查 ---
    private void listPlayers(HttpServletResponse response) throws SQLException, IOException {
        StringBuilder json = new StringBuilder("[");
        try (Connection conn = DBUtil.getConnection()) {
            String sql = "SELECT username, password, level FROM Player";
            ResultSet rs = conn.createStatement().executeQuery(sql);
            boolean first = true;
            while(rs.next()) {
                if(!first) json.append(",");
                first = false;
                json.append(String.format("{\"username\":\"%s\",\"password\":\"%s\",\"level\":%d}", 
                        rs.getString("username"), rs.getString("password"), rs.getInt("level")));
            }
        }
        json.append("]");
        response.getWriter().write(json.toString());
    }

    private void getGames(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        String username = request.getParameter("username");
        StringBuilder json = new StringBuilder("[");
        try (Connection conn = DBUtil.getConnection()) {
            String sql = "SELECT game_count, is_win, game_time FROM Game WHERE username=? ORDER BY game_count ASC";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            ResultSet rs = ps.executeQuery();
            boolean first = true;
            while(rs.next()) {
                if(!first) json.append(",");
                first = false;
                String time = rs.getString("game_time");
                if(time == null) time = "";
                json.append(String.format("{\"game_count\":%d,\"is_win\":%d,\"time\":\"%s\"}", 
                        rs.getInt("game_count"), rs.getInt("is_win"), time));
            }
        }
        json.append("]");
        response.getWriter().write(json.toString());
    }
    
    private void getGameSteps(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        String username = request.getParameter("username");
        int gameId = Integer.parseInt(request.getParameter("gameId"));
        StringBuilder json = new StringBuilder("[");
        try (Connection conn = DBUtil.getConnection()) {
            String sql = "SELECT step_count, by_who, coordination FROM Step WHERE username=? AND game_count=? ORDER BY step_count ASC";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            ps.setInt(2, gameId);
            ResultSet rs = ps.executeQuery();
            boolean first = true;
            while(rs.next()) {
                if(!first) json.append(",");
                first = false;
                String[] xy = rs.getString("coordination").split(",");
                json.append(String.format("{\"step\":%d,\"who\":%d,\"x\":%s,\"y\":%s}", 
                        rs.getInt("step_count"), rs.getInt("by_who"), xy[0], xy[1]));
            }
        }
        json.append("]");
        response.getWriter().write(json.toString());
    }

    // --- 增 ---
    private void addPlayer(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        String u = request.getParameter("username");
        String p = request.getParameter("password");
        int l = Integer.parseInt(request.getParameter("level"));
        try (Connection conn = DBUtil.getConnection()) {
            String sql = "INSERT INTO Player (username, password, level) VALUES (?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, u);
            ps.setString(2, p);
            ps.setInt(3, l);
            ps.executeUpdate();
            response.getWriter().write("{\"status\":\"ok\"}");
        }
    }

    private void addGame(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        String u = request.getParameter("username");
        int isWin = Integer.parseInt(request.getParameter("isWin")); // 1 or 2
        try (Connection conn = DBUtil.getConnection()) {
            // 查最大ID
            int nextId = 1;
            ResultSet rs = conn.prepareStatement("SELECT MAX(game_count) FROM Game WHERE username='" + u + "'").executeQuery();
            if(rs.next()) nextId = rs.getInt(1) + 1;
            
            String sql = "INSERT INTO Game (username, game_count, is_win, game_time) VALUES (?, ?, ?, NOW())";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, u);
            ps.setInt(2, nextId);
            ps.setInt(3, isWin);
            ps.executeUpdate();
            response.getWriter().write("{\"status\":\"ok\"}");
        }
    }

    // --- 删 ---
    private void deletePlayer(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        String u = request.getParameter("username");
        try (Connection conn = DBUtil.getConnection()) {
            // 手动级联删除 (虽然外键可能有限制，但为了保险，先删子表)
            // 1. 删 Step
            conn.prepareStatement("DELETE FROM Step WHERE username='" + u + "'").executeUpdate();
            // 2. 删 Game
            conn.prepareStatement("DELETE FROM Game WHERE username='" + u + "'").executeUpdate();
            // 3. 删 Player
            conn.prepareStatement("DELETE FROM Player WHERE username='" + u + "'").executeUpdate();
            
            response.getWriter().write("{\"status\":\"ok\"}");
        }
    }

    private void deleteGame(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        String u = request.getParameter("username");
        int gId = Integer.parseInt(request.getParameter("gameId"));
        
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // 开启事务

            // 0. 临时关闭外键检查，防止更新 ID 时互相卡死
            conn.createStatement().execute("SET foreign_key_checks = 0");

            // 1. 删除该局的所有 step
            PreparedStatement ps1 = conn.prepareStatement("DELETE FROM Step WHERE username=? AND game_count=?");
            ps1.setString(1, u);
            ps1.setInt(2, gId);
            ps1.executeUpdate();

            // 2. 删除该局 game
            PreparedStatement ps2 = conn.prepareStatement("DELETE FROM Game WHERE username=? AND game_count=?");
            ps2.setString(1, u);
            ps2.setInt(2, gId);
            ps2.executeUpdate();

            // 3. 核心逻辑：后续所有局 ID - 1
            // Step 表更新
            String sqlUpdateStep = "UPDATE Step SET game_count = game_count - 1 WHERE username=? AND game_count > ?";
            PreparedStatement ps3 = conn.prepareStatement(sqlUpdateStep);
            ps3.setString(1, u);
            ps3.setInt(2, gId);
            ps3.executeUpdate();

            // Game 表更新
            String sqlUpdateGame = "UPDATE Game SET game_count = game_count - 1 WHERE username=? AND game_count > ?";
            PreparedStatement ps4 = conn.prepareStatement(sqlUpdateGame);
            ps4.setString(1, u);
            ps4.setInt(2, gId);
            ps4.executeUpdate();
            
            // 4. 恢复外键检查
            conn.createStatement().execute("SET foreign_key_checks = 1");

            conn.commit();
            response.getWriter().write("{\"status\":\"ok\"}");

        } catch (SQLException e) {
            if(conn != null) {
                // 出错也要记得恢复外键检查，否则这个连接后续会一直没有外键保护
                try { conn.createStatement().execute("SET foreign_key_checks = 1"); } catch(Exception ex) {}
                conn.rollback();
            }
            throw e;
        } finally {
            if(conn != null) conn.close();
        }
    }

    // --- 改 ---
    private void updatePlayer(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        String oldUser = request.getParameter("oldUsername");
        String newUser = request.getParameter("newUsername");
        String newPass = request.getParameter("newPassword");
        int newLevel = Integer.parseInt(request.getParameter("newLevel"));

        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // 如果用户名没变，只改密码和等级，很简单
            if (oldUser.equals(newUser)) {
                String sql = "UPDATE Player SET password=?, level=? WHERE username=?";
                PreparedStatement ps = conn.prepareStatement(sql);
                ps.setString(1, newPass);
                ps.setInt(2, newLevel);
                ps.setString(3, oldUser);
                ps.executeUpdate();
            } else {
                // 如果用户名变了，这就是大工程了，因为有外键约束
                // 策略：插入新用户 -> 复制/更新子表数据到新用户 -> 删除旧用户
                
                // 1. 插入新用户
                String sql1 = "INSERT INTO Player (username, password, level) VALUES (?, ?, ?)";
                PreparedStatement ps1 = conn.prepareStatement(sql1);
                ps1.setString(1, newUser);
                ps1.setString(2, newPass);
                ps1.setInt(3, newLevel);
                ps1.executeUpdate();

                // 2. 更新 Game 表指向新用户 (需要先解除外键检查吗？不用，因为新用户已经存在)
                String sql2 = "UPDATE Game SET username=? WHERE username=?";
                PreparedStatement ps2 = conn.prepareStatement(sql2);
                ps2.setString(1, newUser);
                ps2.setString(2, oldUser);
                ps2.executeUpdate();

                // 3. 更新 Step 表指向新用户
                String sql3 = "UPDATE Step SET username=? WHERE username=?";
                PreparedStatement ps3 = conn.prepareStatement(sql3);
                ps3.setString(1, newUser);
                ps3.setString(2, oldUser);
                ps3.executeUpdate();

                // 4. 删除旧用户
                String sql4 = "DELETE FROM Player WHERE username=?";
                PreparedStatement ps4 = conn.prepareStatement(sql4);
                ps4.setString(1, oldUser);
                ps4.executeUpdate();
            }

            conn.commit();
            response.getWriter().write("{\"status\":\"ok\"}");

        } catch (SQLException e) {
            if(conn != null) conn.rollback();
            throw e;
        } finally {
            if(conn != null) conn.close();
        }
    }
}

