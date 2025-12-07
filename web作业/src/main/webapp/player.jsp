<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.gobang.util.DBUtil" %>
<%@ page import="java.sql.*" %>
<%
    // 安全检查：如果没登录，跳回首页
    String currentUser = (String) session.getAttribute("currentUser");
    if (currentUser == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    // 实时查询最新的 level
    int currentLevel = 0;
    int totalPlayers = 0; // 新增：全服玩家数
    int totalGames = 0;   // 新增：全服对局数
    
    try (Connection conn = DBUtil.getConnection()) {
        // 查 Level
        String sql = "SELECT level FROM Player WHERE username = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, currentUser);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            currentLevel = rs.getInt("level");
        }
        
        // 查总人数
        ResultSet rs1 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM Player");
        if(rs1.next()) totalPlayers = rs1.getInt(1);
        
        // 查总对局
        ResultSet rs2 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM Game");
        if(rs2.next()) totalGames = rs2.getInt(1);
        
    } catch (Exception e) { e.printStackTrace(); }

    // 计算头衔
    String title = "初出茅庐";
    if (currentLevel >= 1 && currentLevel <= 10) title = "初窥门径";
    else if (currentLevel <= 20) title = "落子有声";
    else if (currentLevel <= 30) title = "星罗布局";
    else if (currentLevel <= 40) title = "算路初成";
    else if (currentLevel <= 50) title = "攻防有道";
    else if (currentLevel <= 60) title = "棋风初显";
    else if (currentLevel <= 70) title = "掌控全局";
    else if (currentLevel <= 80) title = "料敌机先";
    else if (currentLevel <= 90) title = "弈林高手";
    else if (currentLevel <= 100) title = "五子宗师";
    else if (currentLevel > 100) title = "天下无双";
%>
<!DOCTYPE html>
<html>
<head>
    <title>玩家大厅 - 五子棋</title>
    <style>
        body { 
            font-family: "Microsoft YaHei", sans-serif; 
            background-color: #f5f7fa; 
            background-image: radial-gradient(#e6e9f0 1px, transparent 1px);
            background-size: 20px 20px;
            text-align: center; 
            padding-top: 40px; 
            min-height: 100vh;
        }
        
        /* 顶部欢迎区 */
        .welcome-section {
            margin-bottom: 40px;
            display: flex;
            flex-direction: column;
            align-items: center; /* 让内容居中 */
        }
        h1 { 
            color: #2c3e50; 
            margin-bottom: 20px; /* 增加与下方数据条的距离 */
            text-shadow: 2px 2px 0px white; 
            display: flex; 
            align-items: center; /* 让名字和头衔垂直居中 */
            justify-content: center;
            gap: 10px; /* 元素间距 */
        }
        
        /* 数据统计条 */
        .stats-bar {
            display: inline-flex;
            background: white;
            padding: 10px 30px;
            border-radius: 50px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
            gap: 40px;
            margin-bottom: 50px;
            border: 1px solid #eee;
            margin-top: 10px; /* 额外下移 */
        }
        .stat-item { display: flex; flex-direction: column; align-items: center; }
        .stat-val { font-weight: bold; font-size: 18px; color: #333; }
        .stat-lbl { font-size: 12px; color: #888; text-transform: uppercase; letter-spacing: 1px; }

        /* 卡片容器 */
        .nav-container { 
            width: 960px; 
            margin: 0 auto; 
            display: flex; 
            justify-content: center; 
            gap: 30px;
        }
        
        /* 卡片样式 */
        .card {
            background: white;
            width: 280px;
            height: 360px; /* 变高一点 */
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.05);
            display: flex;
            flex-direction: column;
            justify-content: flex-start;
            padding: 30px 20px;
            box-sizing: border-box;
            text-decoration: none;
            color: #333;
            transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
            position: relative;
            overflow: hidden;
            border: 1px solid #fff;
        }
        
        .card:hover {
            transform: translateY(-10px);
            box-shadow: 0 20px 40px rgba(0,0,0,0.12);
        }

        /* 图标区域 */
        .icon-box {
            font-size: 48px;
            margin-bottom: 20px;
            height: 80px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.3s;
        }
        .card:hover .icon-box { transform: scale(1.1) rotate(5deg); }

        .card h2 { font-size: 22px; margin: 10px 0; color: #2c3e50; }
        .card p { color: #7f8c8d; font-size: 14px; margin-bottom: 20px; }
        
        .desc { 
            font-size: 13px; 
            color: #95a5a6; 
            line-height: 1.6; 
            background: #f9f9f9; 
            padding: 15px; 
            border-radius: 10px; 
            margin-top: auto; /* 推到底部 */
        }

        /* 个性化颜色 */
        .card.review:hover { border-top: 5px solid #FF9800; }
        .card.game { transform: scale(1.05); border: 2px solid #4CAF50; z-index: 2; }
        .card.game:hover { transform: scale(1.05) translateY(-10px); box-shadow: 0 25px 50px rgba(76, 175, 80, 0.2); }
        .card.rank:hover { border-top: 5px solid #2196F3; }
        
        .title-badge {
            background: linear-gradient(90deg, #FF9800, #F44336);
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.6em; /* 字体再小一点，避免太抢眼 */
            vertical-align: middle;
            box-shadow: 0 2px 5px rgba(244, 67, 54, 0.3);
            /* 移除之前的 margin，改用 flex gap 控制 */
            margin-left: 0; 
            text-shadow: none; /* --- 关键修复：去掉继承的文字阴影 --- */
        }
        .level-info { font-size: 0.8em; color: #555; font-weight: bold; }
        
        .logout { position: fixed; top: 20px; right: 30px; text-decoration: none; color: #999; padding: 8px 15px; background: white; border-radius: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); transition: 0.2s; }
        .logout:hover { color: #F44336; box-shadow: 0 4px 10px rgba(0,0,0,0.15); }
        
        /* 底部小贴士 */
        .tips-area { margin-top: 60px; color: #aaa; font-size: 12px; }
    </style>
</head>
<body>
    <a href="index.jsp" class="logout">退出登录</a>
    
    <div class="welcome-section">
        <h1>
            你好，欢迎玩家 <%= currentUser %>
            <span class="title-badge"><%= title %></span>
            <span class="level-info">(Lv.<%= currentLevel %>)</span>
        </h1>
        
        <div class="stats-bar">
            <div class="stat-item">
                <div class="stat-val"><%= totalPlayers %></div>
                <div class="stat-lbl">全服玩家</div>
            </div>
            <div style="width: 1px; background: #eee;"></div>
            <div class="stat-item">
                <div class="stat-val"><%= totalGames %></div>
                <div class="stat-lbl">累计对局</div>
            </div>
            <div style="width: 1px; background: #eee;"></div>
            <div class="stat-item">
                <div class="stat-val">12ms</div>
                <div class="stat-lbl">服务器延迟</div>
            </div>
        </div>
    </div>
    
    <div class="nav-container">
        <!-- 左：对局复盘 -->
        <a href="review" class="card review">
            <div class="icon-box">📂</div>
            <h2>对局复盘</h2>
            <p>Review History</p>
            <div class="desc">
                复盘是提升棋力的捷径。在这里查看你所有的历史对局，分析每一手得失，总结经验。
            </div>
        </a>

        <!-- 中：开始对局 -->
        <a href="game.jsp" class="card game">
            <div class="icon-box">⚔️</div>
            <h2>开始对局</h2>
            <p>Start Battle</p>
            <div class="desc">
                与智能 AI 一决高下！<br>
                赢了加分，输了扣分。<br>
                <b style="color:#4CAF50">中级场 (胜+5) 正在火热进行中！</b>
            </div>
        </a>

        <!-- 右：排行榜 -->
        <a href="rank" class="card rank">
            <div class="icon-box">🏆</div>
            <h2>排行榜</h2>
            <p>Leaderboard</p>
            <div class="desc">
                查看全服高手排名。<br>
                比胜率、比场次、比等级。<br>
                看看谁才是真正的“五子宗师”！
            </div>
        </a>
    </div>
    
    <div class="tips-area">
        💡 小贴士：五子棋中，先手通常有优势，但也更容易被针对哦。
    </div>
</body>
</html>
