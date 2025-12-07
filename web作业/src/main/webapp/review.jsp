<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.gobang.servlet.ReviewServlet.GameRecord" %>
<%
    // 如果直接访问jsp没有数据，就跳去Servlet加载
    if (request.getAttribute("games") == null) {
        response.sendRedirect("review");
        return;
    }
    
    String username = (String) session.getAttribute("currentUser");
    int totalGames = (int) request.getAttribute("totalGames");
    int winGames = (int) request.getAttribute("winGames");
    String winRate = (String) request.getAttribute("winRate");
    int currentLevel = (int) request.getAttribute("currentLevel");
    List<GameRecord> games = (List<GameRecord>) request.getAttribute("games");

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
    <title>对局复盘</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background-color: #f5f5f5; padding: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .stats { font-size: 18px; color: #555; background: white; padding: 15px 30px; border-radius: 8px; display: inline-block; box-shadow: 0 2px 5px rgba(0,0,0,0.1); line-height: 1.8; }
        .highlight { color: #d32f2f; font-weight: bold; font-size: 20px; }
        .title-badge { background: #FF9800; color: white; padding: 2px 8px; border-radius: 4px; font-size: 14px; margin-left: 5px; }
        
        .container { width: 900px; margin: 0 auto; display: flex; flex-wrap: wrap; gap: 20px; justify-content: center; }
        
        .card {
            background: white;
            width: 260px;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 3px 8px rgba(0,0,0,0.1);
            transition: transform 0.2s;
            border-left: 5px solid #ddd;
            cursor: pointer;
            text-decoration: none;
            color: #333;
            display: block;
        }
        .card:hover { transform: translateY(-3px); box-shadow: 0 5px 15px rgba(0,0,0,0.15); }
        .card.win { border-left-color: #4CAF50; } 
        .card.lose { border-left-color: #F44336; }
        
        .card h3 { margin-top: 0; font-size: 18px; display: flex; justify-content: space-between; }
        .card .time { font-size: 12px; color: #999; margin-bottom: 10px; display: block; }
        .card .info { font-size: 14px; color: #666; line-height: 1.6; }
        
        .replay-btn {
            margin-top: 15px; 
            display: block; 
            text-align: center; 
            color: #2196F3; 
            font-size: 13px; 
            font-weight: bold;
            padding: 8px 0;
            border: 1px solid #2196F3;
            border-radius: 20px;
            transition: all 0.2s ease;
            background: white;
        }
        .replay-btn:hover {
            background: #2196F3;
            color: white;
            box-shadow: 0 4px 10px rgba(33, 150, 243, 0.3);
            transform: translateY(-2px);
        }
        
        .back-btn { position: fixed; top: 20px; left: 20px; padding: 8px 15px; background: #333; color: white; text-decoration: none; border-radius: 5px; }

        /* --- 复盘 Modal 样式 --- */
        .modal-overlay {
            display: none; /* 默认隐藏 */
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0,0,0,0.6);
            z-index: 999;
            justify-content: center; align-items: center;
        }
        .modal-content {
            background: white;
            padding: 20px;
            border-radius: 10px;
            display: flex;
            gap: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            position: relative;
        }
        .left-panel { width: 200px; border-right: 1px solid #eee; padding-right: 20px; }
        .right-panel { width: 150px; display: flex; flex-direction: column; justify-content: center; gap: 15px; }
        
        .info-item { margin-bottom: 15px; }
        .info-label { color: #888; font-size: 12px; }
        .info-value { font-size: 18px; font-weight: bold; color: #333; }
        
        canvas { background-color: #DEB887; box-shadow: 2px 2px 5px rgba(0,0,0,0.2); }
        
        .control-btn {
            padding: 12px 20px;
            border: none; border-radius: 5px;
            font-size: 16px; cursor: pointer;
            transition: background 0.2s;
        }
        .btn-prev { background: #f0f0f0; color: #333; }
        .btn-next { background: #2196F3; color: white; }
        .btn-close { 
            position: absolute; top: -15px; right: -15px; 
            width: 35px; height: 35px; border-radius: 50%; 
            background: white; border: 1px solid #ddd; 
            font-weight: bold; cursor: pointer; 
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }
        .control-btn:hover { opacity: 0.9; }
        .control-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    </style>
</head>
<body>
    <a href="player.jsp" class="back-btn">&lt; 返回大厅</a>

    <div class="header">
        <h1>复盘中心</h1>
        <div class="stats">
            你好，玩家 <b><%= username %></b><br>
            一共进行了 <span class="highlight"><%= totalGames %></span> 场游戏，
            获胜 <span class="highlight"><%= winGames %></span> 场，
            胜率 <span class="highlight"><%= winRate %>%</span><br>
            level是 <span class="highlight"><%= currentLevel %></span>，
            头衔是 <span class="title-badge"><%= title %></span>
        </div>
    </div>

    <div class="container">
        <% for (GameRecord g : games) { %>
            <div class="card <%= g.isWin == 1 ? "win" : (g.isWin == 2 ? "lose" : "") %>"
                 onclick="loadReplay(<%= g.gameCount %>, '<%= g.gameTime %>')">
                <h3>
                    第 <%= g.gameCount %> 局
                    <span style="color: <%= g.isWin == 1 ? "green" : (g.isWin == 2 ? "red" : "gray") %>">
                        <%= g.getResultStr() %>
                    </span>
                </h3>
                <span class="time"><%= g.gameTime %></span>
                <div class="info">
                    <div>总步数：<%= g.totalSteps %> 步</div>
                    <div class="replay-btn">点击复盘 >></div>
                </div>
            </div>
        <% } %>
        
        <% if (games.isEmpty()) { %>
            <p style="text-align:center; color:#999; width:100%;">暂无对局记录，快去下一盘吧！</p>
        <% } %>
    </div>

    <!-- 复盘弹窗 -->
    <div class="modal-overlay" id="replayModal">
        <div class="modal-content">
            <button class="btn-close" onclick="closeReplay()">×</button>
            
            <div class="left-panel">
                <h3>对局详情</h3>
                <div class="info-item">
                    <div class="info-label">对局编号</div>
                    <div class="info-value" id="lblGameId">--</div>
                </div>
                <div class="info-item">
                    <div class="info-label">对局时间</div>
                    <div class="info-value" id="lblTime" style="font-size:14px;">--</div>
                </div>
                <div class="info-item">
                    <div class="info-label">当前步数</div>
                    <div class="info-value"><span id="lblStep">0</span> / <span id="lblTotal">0</span></div>
                </div>
            </div>
            
            <div class="center-panel">
                <canvas id="replayBoard" width="450" height="450"></canvas>
            </div>
            
            <div class="right-panel">
                <button class="control-btn btn-prev" onclick="prevStep()">上一步</button>
                <button class="control-btn btn-next" onclick="nextStep()">下一步</button>
            </div>
        </div>
    </div>

<script>
    const canvas = document.getElementById('replayBoard');
    const ctx = canvas.getContext('2d');
    const gridSize = 30;
    
    let currentReplaySteps = []; // 存储当前对局的所有步骤
    let currentStepIndex = 0;    // 当前显示到第几步 (0表示空盘)

    // 打开复盘窗口
    function loadReplay(gameId, gameTime) {
        document.getElementById('replayModal').style.display = 'flex';
        document.getElementById('lblGameId').innerText = "Game #" + gameId;
        document.getElementById('lblTime').innerText = gameTime;
        
        // 重置状态
        currentReplaySteps = [];
        currentStepIndex = 0;
        updateUI();
        drawReplayBoard();
        
        // 异步请求获取步数
        fetch('review?action=getSteps&gameId=' + gameId)
            .then(res => res.json())
            .then(steps => {
                currentReplaySteps = steps;
                document.getElementById('lblTotal').innerText = steps.length;
                // 加载完数据后，先显示第一步（如果有）
                if (steps.length > 0) {
                    currentStepIndex = 1;
                    renderCurrentState();
                }
            });
    }
    
    function closeReplay() {
        document.getElementById('replayModal').style.display = 'none';
    }

    function nextStep() {
        if (currentStepIndex < currentReplaySteps.length) {
            currentStepIndex++;
            renderCurrentState();
        }
    }

    function prevStep() {
        if (currentStepIndex > 0) {
            currentStepIndex--;
            renderCurrentState();
        }
    }
    
    function updateUI() {
        document.getElementById('lblStep').innerText = currentStepIndex;
    }

    // 核心渲染逻辑
    function renderCurrentState() {
        drawReplayBoard(); // 1. 清空并画线
        
        // 2. 画出 0 到 currentStepIndex 之间的所有子
        for (let i = 0; i < currentStepIndex; i++) {
            let stepData = currentReplaySteps[i];
            drawPiece(stepData.x, stepData.y, stepData.who, (i === currentStepIndex - 1));
        }
        updateUI();
    }

    // 画棋盘背景
    function drawReplayBoard() {
        ctx.clearRect(0, 0, 450, 450);
        ctx.strokeStyle = "#000";
        ctx.lineWidth = 1;
        for (let i = 0; i < 15; i++) {
            ctx.beginPath(); ctx.moveTo(15 + i * gridSize, 15); ctx.lineTo(15 + i * gridSize, 435); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(15, 15 + i * gridSize); ctx.lineTo(435, 15 + i * gridSize); ctx.stroke();
        }
        // 星位
        ctx.fillStyle = "#000";
        [3, 7, 11].forEach(r => [3, 7, 11].forEach(c => {
            ctx.beginPath(); ctx.arc(15 + c*30, 15 + r*30, 3, 0, 2*Math.PI); ctx.fill();
        }));
    }

    // 画子 (isLast 参数用于标记最后一步，可以画个红点提示)
    function drawPiece(x, y, type, isLast) {
        ctx.beginPath();
        ctx.arc(15 + y * gridSize, 15 + x * gridSize, 13, 0, 2 * Math.PI);
        let gradient = ctx.createRadialGradient(15 + y * gridSize - 5, 15 + x * gridSize - 5, 0, 15 + y * gridSize, 15 + x * gridSize, 13);
        if (type === 1) { // 玩家黑
            gradient.addColorStop(0, "#666"); gradient.addColorStop(1, "#000");
        } else { // AI白
            gradient.addColorStop(0, "#fff"); gradient.addColorStop(1, "#ddd");
        }
        ctx.fillStyle = gradient;
        ctx.fill();
        
        // 如果是最后一步，画个红色标记方便看
        if (isLast) {
            ctx.beginPath();
            ctx.arc(15 + y * gridSize, 15 + x * gridSize, 4, 0, 2 * Math.PI);
            ctx.fillStyle = "red";
            ctx.fill();
        }
    }
</script>
</body>
</html>
