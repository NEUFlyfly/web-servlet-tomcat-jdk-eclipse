<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.gobang.servlet.RankServlet.PlayerRank" %>
<%
    // 防直接访问
    if (request.getAttribute("rankList") == null) {
        response.sendRedirect("rank");
        return;
    }

    String currentUser = (String) session.getAttribute("currentUser");
    List<PlayerRank> list = (List<PlayerRank>) request.getAttribute("rankList");
    String myWinRate = (String) request.getAttribute("myWinRate");
    int myRank = (int) request.getAttribute("myRank");
    String beatPercent = (String) request.getAttribute("beatPercent");

    // 计算当前用户的头衔（这里因为 RankServlet 没有传 level 给我，只能从 rankList 里找）
    int currentLevel = 1;
    for (PlayerRank p : list) {
        if (p.username.equals(currentUser)) {
            currentLevel = p.level;
            break;
        }
    }

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
    <title>排行榜</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
        .container { width: 800px; margin: 0 auto; text-align: center; }
        
        /* 顶部个人信息区 */
        .header-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 20px rgba(118, 75, 162, 0.3);
            margin-bottom: 30px;
            position: relative;
        }
        .header-card h1 { margin: 0; font-size: 32px; }
        .stats-row { display: flex; justify-content: center; gap: 50px; margin-top: 20px; }
        .stat-box .val { font-size: 24px; font-weight: bold; color: #FFD700; }
        .stat-box .label { font-size: 14px; opacity: 0.8; }
        
        .back-link { position: absolute; top: 20px; left: 20px; color: rgba(255,255,255,0.8); text-decoration: none; }
        
        .title-badge { background: rgba(255,255,255,0.2); color: white; padding: 5px 15px; border-radius: 20px; font-size: 16px; margin-left: 10px; vertical-align: middle; }

        /* 排序按钮区 */
        .sort-controls { display: flex; justify-content: center; gap: 20px; margin-bottom: 30px; }
        .sort-btn {
            padding: 12px 30px;
            background: white;
            border: none;
            border-radius: 50px;
            font-size: 16px;
            color: #666;
            cursor: pointer;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
            outline: none;
        }
        /* 按钮动效：选中态按下，未选中态浮起 */
        .sort-btn.active {
            background: #764ba2;
            color: white;
            box-shadow: inset 0 2px 5px rgba(0,0,0,0.2); /* 内部阴影，营造按下感 */
            transform: translateY(2px); /* 下沉 */
        }
        .sort-btn:not(.active):hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.15);
        }

        /* 列表区 */
        .rank-list { list-style: none; padding: 0; }
        .rank-item {
            background: white;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 15px 30px;
            margin-bottom: 10px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            transition: transform 0.2s;
        }
        .rank-item:hover { transform: scale(1.01); }
        .rank-item.myself { border: 2px solid #764ba2; background-color: #fbfaff; }

        .rank-num { font-size: 20px; font-weight: bold; width: 50px; color: #999; font-style: italic; }
        .rank-num.top3 { color: #FFD700; font-size: 24px; }
        
        .user-info { flex-grow: 1; text-align: left; padding-left: 20px; }
        .u-name { font-size: 18px; font-weight: bold; color: #333; }
        .u-level { font-size: 12px; background: #eee; padding: 2px 8px; border-radius: 4px; color: #666; margin-left: 10px; }
        .u-title { font-size: 12px; background: #fff3e0; color: #FF9800; border: 1px solid #FF9800; padding: 1px 6px; border-radius: 4px; margin-left: 5px; }
        
        .data-col { width: 100px; text-align: center; }
        .data-val { font-weight: bold; color: #333; }
        .data-label { font-size: 12px; color: #999; }
        .win-rate { color: #E91E63; }
    </style>
</head>
<body>

<div class="container">
    <!-- 顶部：个人统计 -->
    <div class="header-card">
        <a href="player.jsp" class="back-link">&lt; 返回大厅</a>
        <h1>
            <%= currentUser %>
            <span class="title-badge"><%= title %></span>
        </h1>
        <div class="stats-row">
            <div class="stat-box">
                <div class="val"><%= myWinRate %>%</div>
                <div class="label">胜率</div>
            </div>
            <div class="stat-box">
                <div class="val">#<%= myRank %></div>
                <div class="label">全服排名</div>
            </div>
            <div class="stat-box">
                <div class="val"><%= beatPercent %>%</div>
                <div class="label">击败玩家</div>
            </div>
        </div>
    </div>

    <!-- 排序按钮 -->
    <div class="sort-controls">
        <button class="sort-btn active" onclick="changeSort('rate')" id="btn-rate">🔥 胜率排序</button>
        <button class="sort-btn" onclick="changeSort('count')" id="btn-count">🎮 场次排序</button>
        <button class="sort-btn" onclick="changeSort('level')" id="btn-level">⭐ 等级排序</button>
    </div>

    <!-- 排行榜列表容器 -->
    <ul class="rank-list" id="listContainer">
        <!-- JS会往这里填数据 -->
    </ul>
</div>

<script>
    // 1. 把后端传来的 List 转成 JS 数组
    const players = [
        <% 
        for(int i=0; i<list.size(); i++) { 
            PlayerRank p = list.get(i);
        %>
        {
            username: "<%= p.username %>",
            level: <%= p.level %>,
            total: <%= p.totalGames %>,
            wins: <%= p.winGames %>,
            rate: <%= p.getWinRateStr() %>
        }<%= i < list.size()-1 ? "," : "" %>
        <% } %>
    ];

    const currentUser = "<%= currentUser %>";

    // 2. 排序并渲染函数
    function changeSort(type) {
        // 切换按钮样式
        document.querySelectorAll('.sort-btn').forEach(btn => btn.classList.remove('active'));
        document.getElementById('btn-' + type).classList.add('active');

        // 排序逻辑
        if (type === 'rate') {
            players.sort((a, b) => b.rate - a.rate); // 胜率降序
        } else if (type === 'count') {
            players.sort((a, b) => b.total - a.total); // 场次降序
        } else if (type === 'level') {
            players.sort((a, b) => b.level - a.level); // 等级降序
        }

        // 重新渲染列表
        renderList();
    }

    // 3. 辅助函数：根据等级获取头衔
    function getTitle(level) {
        if (level >= 1 && level <= 10) return "初窥门径";
        if (level <= 20) return "落子有声";
        if (level <= 30) return "星罗布局";
        if (level <= 40) return "算路初成";
        if (level <= 50) return "攻防有道";
        if (level <= 60) return "棋风初显";
        if (level <= 70) return "掌控全局";
        if (level <= 80) return "料敌机先";
        if (level <= 90) return "弈林高手";
        if (level <= 100) return "五子宗师";
        if (level > 100) return "天下无双";
        return "初出茅庐";
    }

    function renderList() {
        const container = document.getElementById('listContainer');
        container.innerHTML = ""; // 清空

        players.forEach((p, index) => {
            const rank = index + 1;
            const isMe = (p.username === currentUser);
            const topClass = rank <= 3 ? 'top3' : '';
            const title = getTitle(p.level); // 计算头衔
            
            // 构建 HTML 字符串
            const html = `
                <li class="rank-item \${isMe ? 'myself' : ''}">
                    <div class="rank-num \${topClass}">\${rank}</div>
                    <div class="user-info">
                        <span class="u-name">\${p.username}</span>
                        <span class="u-title">\${title}</span>
                        <span class="u-level">Lv.\${p.level}</span>
                    </div>
                    <div class="data-col">
                        <div class="data-val win-rate">\${p.rate}%</div>
                        <div class="data-label">胜率</div>
                    </div>
                    <div class="data-col">
                        <div class="data-val">\${p.total}</div>
                        <div class="data-label">场次</div>
                    </div>
                    <div class="data-col">
                        <div class="data-val">\${p.level}</div>
                        <div class="data-label">等级</div>
                    </div>
                </li>
            `;
            container.innerHTML += html;
        });
    }

    // 页面加载默认按胜率排
    changeSort('rate');

</script>

</body>
</html>
