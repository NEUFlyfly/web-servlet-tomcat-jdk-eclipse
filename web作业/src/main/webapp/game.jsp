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
    try (Connection conn = DBUtil.getConnection()) {
        String sql = "SELECT level FROM Player WHERE username = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, currentUser);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            currentLevel = rs.getInt("level");
        }
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
    <title>五子棋 Web 版</title>
    <style>
        body { 
            font-family: "Microsoft YaHei", sans-serif; 
            /* 背景图设置 */
            background: url('picture/fight_bg.png') no-repeat center center fixed;
            background-size: cover;
            margin: 0; padding: 0;
            display: flex; justify-content: center; align-items: center;
            min-height: 100vh;
        }
        .container { 
            /* 稍微调低透明度，让背景图透出来一点点，增加氛围 */
            background: rgba(255, 255, 255, 0.95);
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            text-align: center; 
            position: relative;
            width: 500px;
            backdrop-filter: blur(5px); /* 毛玻璃效果 */
        }
        
        /* 顶部区域 */
        .header { margin-bottom: 20px; }
        h2 { margin: 0 0 10px; color: #2c3e50; }
        .back-btn { 
            position: absolute; top: 20px; left: 20px; 
            text-decoration: none; color: #95a5a6; font-size: 14px; 
            display: flex; align-items: center; gap: 5px;
            transition: 0.2s;
        }
        .back-btn:hover { color: #2196F3; transform: translateX(-3px); }

        .title-badge { 
            background: linear-gradient(90deg, #FF9800, #F44336); 
            color: white; padding: 3px 10px; border-radius: 12px; 
            font-size: 0.6em; vertical-align: middle; margin-left: 8px; 
        }

        /* 控制区 */
        .controls { 
            background: #f8f9fa; 
            padding: 15px; 
            border-radius: 12px; 
            margin-bottom: 20px; 
            display: flex;
            flex-direction: column;
            gap: 15px;
        }
        
        .control-row { display: flex; justify-content: center; align-items: center; gap: 15px; }

        select { 
            padding: 10px 15px; 
            border-radius: 8px; 
            border: 1px solid #ddd; 
            background: white; 
            font-size: 14px; 
            outline: none; 
            cursor: pointer;
        }
        select:hover { border-color: #aaa; }

        button { 
            padding: 10px 25px; 
            font-size: 16px; 
            background: linear-gradient(135deg, #4CAF50, #45a049); 
            color: white; 
            border: none; 
            border-radius: 50px; 
            cursor: pointer; 
            box-shadow: 0 4px 15px rgba(76, 175, 80, 0.3);
            transition: all 0.2s ease; 
        }
        button:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(76, 175, 80, 0.4); }
        button:active { transform: translateY(0); }

        #status { 
            font-weight: bold; color: #555; font-size: 16px; 
            min-height: 24px; 
            transition: color 0.3s;
        }

        /* 棋盘样式 */
        canvas { 
            background: url('picture/chessboard.png') no-repeat center center; 
            background-size: cover; /* 确保图片填满 */
            border-radius: 4px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
            cursor: pointer; 
            transition: transform 0.2s;
        }
        /* 让棋盘有点质感 */
        canvas:active { cursor: grabbing; }

        /* 结算弹窗 */
        .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.6); justify-content: center; align-items: center; z-index: 100; }
        .modal-content { 
            background: white; padding: 30px; border-radius: 15px; width: 350px; text-align: center; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.3); 
            animation: popIn 0.3s ease;
        }
        @keyframes popIn { from { transform: scale(0.8); opacity: 0; } to { transform: scale(1); opacity: 1; } }
        
        .result-title { font-size: 24px; font-weight: bold; margin-bottom: 20px; }
        .result-win { color: #4CAF50; }
        .result-lose { color: #F44336; }
        
        .level-change { margin: 20px 0; font-size: 16px; color: #555; line-height: 1.8; }
        .level-arrow { color: #999; margin: 0 5px; }
        .diff-val { font-weight: bold; }
        .diff-up { color: #4CAF50; }
        .diff-down { color: #F44336; }
        
        .title-change { margin-top: 10px; padding-top: 10px; border-top: 1px dashed #eee; font-size: 14px; color: #888; }
        .new-title { color: #FF9800; font-weight: bold; font-size: 16px; }

        .modal-btn { 
            margin-top: 25px; padding: 10px 30px; background: #2196F3; color: white; border: none; border-radius: 20px; cursor: pointer; font-size: 16px; 
        }
        .modal-btn:hover { background: #1976D2; }
    </style>
</head>
<body>
    <div class="container">
        <a href="player.jsp" class="back-btn">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 12H5M12 19l-7-7 7-7"/></svg>
            返回大厅
        </a>

        <div class="header">
            <h2>
                你好，<%= currentUser %>
                <span id="headerTitle" class="title-badge"><%= title %></span>
                <span id="headerLevel" style="font-size:0.7em; color:#999; font-weight:normal;">(Lv.<%= currentLevel %>)</span>
            </h2>
        </div>
        
        <div class="controls">
            <div class="control-row">
                <label style="color:#666; font-size:14px;">难度设置</label>
                <select id="difficultyLevel">
                    <option value="0">简单 (胜+1 负-10)</option>
                    <option value="1" selected>中级 (胜+5 负-5)</option>
                    <option value="2">困难 (胜+10 负-3)</option>
                </select>
                <button onclick="startGame()">开始新游戏</button>
            </div>
            <div id="status">请选择难度并点击开始...</div>
        </div>

        <canvas id="chessBoard" width="450" height="450"></canvas>
    </div>

    <!-- 结算弹窗 -->
    <div id="resultModal" class="modal">
        <div class="modal-content">
            <div id="resTitle" class="result-title">恭喜胜利！</div>
            
            <div class="level-change">
                <div>等级变化</div>
                <span id="oldLv">10</span> 
                <span class="level-arrow">➜</span> 
                <span id="newLv" style="font-size:24px; font-weight:bold;">15</span>
                <span id="diffVal" class="diff-val diff-up">(+5)</span>
            </div>
            
            <div id="titleChangeBox" class="title-change" style="display:none;">
                头衔改变为：<div id="newTitleText" class="new-title">落子有声</div>
            </div>
            <div id="titleNoChangeBox" class="title-change" style="color:#ccc;">
                头衔未发生改变
            </div>

            <button class="modal-btn" onclick="closeResult()">确定</button>
        </div>
    </div>

<script>
    const canvas = document.getElementById('chessBoard');
    const ctx = canvas.getContext('2d');
    const gridSize = 30; 
    let isGameActive = false;
    let isThinking = false;

    // 画棋盘（背景已经是棋盘图片了，所以这里只需要清空画布即可，不需要再画线）
    function drawBoard() {
        ctx.clearRect(0, 0, 450, 450);
    }

    function drawPiece(x, y, type) {
        ctx.beginPath();
        ctx.arc(15 + y * gridSize, 15 + x * gridSize, 13, 0, 2 * Math.PI);
        // 1是黑棋(玩家)，2是白棋(AI)
        let gradient = ctx.createRadialGradient(15 + y * gridSize - 5, 15 + x * gridSize - 5, 0, 15 + y * gridSize, 15 + x * gridSize, 13);
        if (type === 1) {
            gradient.addColorStop(0, "#666"); gradient.addColorStop(1, "#000");
        } else {
            gradient.addColorStop(0, "#fff"); gradient.addColorStop(1, "#ddd");
        }
        ctx.fillStyle = gradient;
        ctx.fill();
    }

    function startGame() {
        let level = document.getElementById("difficultyLevel").value;
        isGameActive = true;
        isThinking = false;
        drawBoard(); // 清空棋盘
        
        // 发送开始请求，带上难度参数
        fetch('play?action=start&level=' + level, { method: 'POST' })
            .then(res => res.json())
            .then(data => {
                document.getElementById("status").innerText = "游戏开始，你是黑棋，请落子";
            });
    }

    canvas.onclick = function(e) {
        if (!isGameActive) {
            alert("请先点击【开始新游戏】！");
            return;
        }
        if (isThinking) return; // 锁住

        let rect = canvas.getBoundingClientRect();
        let x = e.clientX - rect.left;
        let y = e.clientY - rect.top;
        // 计算最近的交叉点
        let col = Math.round((x - 15) / gridSize);
        let row = Math.round((y - 15) / gridSize);

        // 边界检查
        if (row < 0 || row > 14 || col < 0 || col > 14) return;

        // 先画玩家的子（假设该位置为空，具体防止覆盖逻辑后端也会校验，前端可以简化）
        drawPiece(row, col, 1);
        isThinking = true;
        document.getElementById("status").innerText = "AI 思考中...";

        // 发送落子请求
        fetch('play?action=move&x=' + row + '&y=' + col, { method: 'POST' })
            .then(res => res.json())
            .then(data => {
                // 定义处理逻辑
                const handleResponse = () => {
                    // 1. 处理 AI 落子
                    if (data.ai_x !== -1) {
                        drawPiece(data.ai_x, data.ai_y, 2);
                    }

                    // 2. 处理胜负逻辑
                    if (data.winner === 1 || data.winner === 2) {
                        isGameActive = false;
                        showResult(data.winner === 1, data.oldLevel, data.newLevel);
                    } else if (data.winner === 3) {
                        alert("平局！");
                        isGameActive = false;
                    } else {
                        // 游戏继续
                        document.getElementById("status").innerText = "轮到你了";
                        isThinking = false; // 解锁
                    }
                };

                // 如果有 AI 落子，强制延迟 500ms 模拟思考
                if (data.ai_x !== -1) {
                    setTimeout(handleResponse, 500);
                    // setTimeout(handleResponse, 1);
                } else {
                    handleResponse(); 
                }
            })
            .catch(err => {
                console.error(err);
                isThinking = false;
            });
    }

    // 页面加载时画个空棋盘
    drawBoard();
    
    // --- 结算弹窗逻辑 ---
    function getTitle(level) {
        if (level == 0) return "初出茅庐";
        if (level >= 1 && level <= 10) return "初窥门径";
        if (level >= 11 && level <= 20) return "落子有声";
        if (level >= 21 && level <= 30) return "星罗布局";
        if (level >= 31 && level <= 40) return "算路初成";
        if (level >= 41 && level <= 50) return "攻防有道";
        if (level >= 51 && level <= 60) return "棋风初显";
        if (level >= 61 && level <= 70) return "掌控全局";
        if (level >= 71 && level <= 80) return "料敌机先";
        if (level >= 81 && level <= 90) return "弈林高手";
        if (level >= 91 && level <= 100) return "五子宗师";
        if (level > 100) return "天下无双";
        return "初出茅庐";
    }

    function showResult(isWin, oldLv, newLv) {
        const modal = document.getElementById('resultModal');
        const titleEl = document.getElementById('resTitle');
        
        if (isWin) {
            titleEl.innerText = "🎉 恭喜胜利！";
            titleEl.className = "result-title result-win";
        } else {
            titleEl.innerText = "💔 遗憾落败...";
            titleEl.className = "result-title result-lose";
        }
        
        document.getElementById('oldLv').innerText = "Lv." + oldLv;
        document.getElementById('newLv').innerText = "Lv." + newLv;
        
        const diff = newLv - oldLv;
        const diffEl = document.getElementById('diffVal');
        if (diff >= 0) {
            diffEl.innerText = "(+" + diff + ")";
            diffEl.className = "diff-val diff-up";
        } else {
            diffEl.innerText = "(" + diff + ")";
            diffEl.className = "diff-val diff-down";
        }
        
        // 头衔变化
        const oldTitle = getTitle(oldLv);
        const newTitle = getTitle(newLv);
        
        if (oldTitle !== newTitle) {
            document.getElementById('titleChangeBox').style.display = 'block';
            document.getElementById('titleNoChangeBox').style.display = 'none';
            document.getElementById('newTitleText').innerText = newTitle;
        } else {
            document.getElementById('titleChangeBox').style.display = 'none';
            document.getElementById('titleNoChangeBox').style.display = 'block';
        }
        
        // --- 实时更新顶部信息 ---
        document.getElementById('headerLevel').innerText = "(Lv." + newLv + ")";
        document.getElementById('headerTitle').innerText = newTitle;
        
        modal.style.display = 'flex';
    }
    
    function closeResult() {
        document.getElementById('resultModal').style.display = 'none';
        // 可以在这里加上重置棋盘的逻辑，或者不加，让玩家看最后一眼棋局
    }
</script>
</body>
</html>
