package com.gobang.servlet;

import com.gobang.util.DBUtil;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/review")
public class ReviewServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // 内部类：用于封装单局游戏的简要信息
    public static class GameRecord {
        public int gameCount;
        public int isWin; // 0=进行中, 1=赢, 2=输
        public String gameTime;
        public int totalSteps;

        public GameRecord(int gameCount, int isWin, String gameTime, int totalSteps) {
            this.gameCount = gameCount;
            this.isWin = isWin;
            this.gameTime = gameTime;
            this.totalSteps = totalSteps;
        }
        
        public String getResultStr() {
            if (isWin == 1) return "胜利";
            if (isWin == 2) return "失败";
            return "平局";
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String username = (String) session.getAttribute("currentUser");
        
        if (username == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        // --- 新增：处理 AJAX 获取步数请求 ---
        String action = request.getParameter("action");
        if ("getSteps".equals(action)) {
            handleGetSteps(request, response, username);
            return;
        }
        // ----------------------------------

        int totalGames = 0;
        int winGames = 0;
        int currentLevel = 1; // 默认等级
        List<GameRecord> games = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection()) {
            // 0. 查询当前等级
            String levelSql = "SELECT level FROM Player WHERE username=?";
            PreparedStatement psLevel = conn.prepareStatement(levelSql);
            psLevel.setString(1, username);
            ResultSet rsLevel = psLevel.executeQuery();
            if (rsLevel.next()) {
                currentLevel = rsLevel.getInt(1);
            }

            // 1. 查询统计数据
            String statSql = "SELECT COUNT(*), SUM(CASE WHEN is_win=1 THEN 1 ELSE 0 END) FROM Game WHERE username=?";
            PreparedStatement psStat = conn.prepareStatement(statSql);
            psStat.setString(1, username);
            ResultSet rsStat = psStat.executeQuery();
            if (rsStat.next()) {
                totalGames = rsStat.getInt(1);
                winGames = rsStat.getInt(2);
            }

            // 2. 查询详细对局列表 (关联 Step 表获取步数)
            String listSql = "SELECT g.game_count, g.is_win, g.game_time, MAX(s.step_count) as steps " + 
                             "FROM Game g LEFT JOIN Step s ON g.username = s.username AND g.game_count = s.game_count " +
                             "WHERE g.username = ? " +
                             "GROUP BY g.game_count, g.is_win, g.game_time " +
                             "ORDER BY g.game_count DESC"; 
            
            PreparedStatement psList = conn.prepareStatement(listSql);
            psList.setString(1, username);
            ResultSet rsList = psList.executeQuery();
            
            while (rsList.next()) {
                int count = rsList.getInt("game_count");
                int win = rsList.getInt("is_win");
                String time = rsList.getString("game_time");
                if (time == null) time = "未知时间";
                if (time.endsWith(".0")) time = time.substring(0, time.length()-2);
                
                int steps = rsList.getInt("steps");
                
                games.add(new GameRecord(count, win, time, steps));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        // 计算胜率
        double winRate = (totalGames == 0) ? 0.0 : (double)winGames * 100 / totalGames;
        String winRateStr = String.format("%.1f", winRate);

        request.setAttribute("totalGames", totalGames);
        request.setAttribute("winGames", winGames);
        request.setAttribute("winRate", winRateStr);
        request.setAttribute("currentLevel", currentLevel); // 传给 JSP
        request.setAttribute("games", games);
        
        request.getRequestDispatcher("review.jsp").forward(request, response);
    }

    // 新增：处理获取步数逻辑
    private void handleGetSteps(HttpServletRequest request, HttpServletResponse response, String username) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        int gameId = Integer.parseInt(request.getParameter("gameId"));
        
        StringBuilder json = new StringBuilder("[");
        
        try (Connection conn = DBUtil.getConnection()) {
            String sql = "SELECT step_count, by_who, coordination FROM Step WHERE username=? AND game_count=? ORDER BY step_count ASC";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            ps.setInt(2, gameId);
            ResultSet rs = ps.executeQuery();
            
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                first = false;
                
                int step = rs.getInt("step_count");
                int who = rs.getInt("by_who");
                String[] coords = rs.getString("coordination").split(",");
                int x = Integer.parseInt(coords[0]);
                int y = Integer.parseInt(coords[1]);
                
                json.append(String.format("{\"step\":%d, \"who\":%d, \"x\":%d, \"y\":%d}", step, who, x, y));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        json.append("]");
        response.getWriter().write(json.toString());
    }
}
