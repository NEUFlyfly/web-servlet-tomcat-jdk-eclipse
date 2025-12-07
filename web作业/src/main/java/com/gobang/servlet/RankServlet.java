package com.gobang.servlet;

import com.gobang.util.DBUtil;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/rank")
public class RankServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // 玩家排行数据对象
    public static class PlayerRank {
        public String username;
        public int level;
        public int totalGames;
        public int winGames;
        public double winRate;

        public PlayerRank(String username, int level, int totalGames, int winGames) {
            this.username = username;
            this.level = level;
            this.totalGames = totalGames;
            this.winGames = winGames;
            this.winRate = (totalGames == 0) ? 0.0 : (double)winGames * 100.0 / totalGames;
        }
        
        // 方便前端JS直接使用
        public String getWinRateStr() {
            return String.format("%.1f", winRate);
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String currentUser = (String) session.getAttribute("currentUser");
        
        if (currentUser == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        List<PlayerRank> list = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection()) {
            // 联表查询：查询所有玩家的 username, level 以及 统计胜负
            // 使用 LEFT JOIN 确保即使没玩过游戏的玩家也在榜单上
            String sql = "SELECT p.username, p.level, " +
                         "COUNT(g.game_count) as total, " +
                         "SUM(CASE WHEN g.is_win=1 THEN 1 ELSE 0 END) as wins " +
                         "FROM Player p " +
                         "LEFT JOIN Game g ON p.username = g.username " +
                         "GROUP BY p.username, p.level";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                list.add(new PlayerRank(
                    rs.getString("username"),
                    rs.getInt("level"),
                    rs.getInt("total"),
                    rs.getInt("wins")
                ));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 默认先按胜率排一下，方便计算当前玩家排名
        list.sort((a, b) -> Double.compare(b.winRate, a.winRate));

        // 计算当前玩家的数据
        int myRank = 0;
        double myWinRate = 0;
        int totalPlayers = list.size();
        
        for (int i = 0; i < list.size(); i++) {
            if (list.get(i).username.equals(currentUser)) {
                myRank = i + 1;
                myWinRate = list.get(i).winRate;
                break;
            }
        }
        
        // 计算击败了多少人
        // 比如 10 人里排第 1，击败 9 人 (90%)
        // 10 人里排第 10，击败 0 人 (0%)
        double beatPercent = 0;
        if (totalPlayers > 1) {
            beatPercent = (double)(totalPlayers - myRank) / (totalPlayers - 1) * 100;
        } else if (totalPlayers == 1) {
            beatPercent = 100; // 就一个人，就是第一也是倒一，算100吧
        }

        // 传递数据
        request.setAttribute("rankList", list);
        request.setAttribute("myRank", myRank);
        request.setAttribute("myWinRate", String.format("%.1f", myWinRate));
        request.setAttribute("beatPercent", String.format("%.0f", beatPercent));
        
        request.getRequestDispatcher("rank.jsp").forward(request, response);
    }
}

