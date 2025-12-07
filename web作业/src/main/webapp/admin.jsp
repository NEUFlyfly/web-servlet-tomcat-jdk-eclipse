<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // 简单权限检查
    if (session.getAttribute("isAdmin") == null) {
        response.sendRedirect("index.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>后台管理系统 - 五子棋</title>
    <style>
        body { 
            font-family: "Microsoft YaHei", sans-serif; 
            margin: 0; padding: 0; 
            display: flex; 
            height: 100vh; 
            /* 背景图设置 */
            background: url('picture/admin_bg.png') no-repeat center center fixed;
            background-size: cover;
        }
        
        /* 侧边栏：使用半透明深色，提升质感 */
        .sidebar { 
            width: 240px; 
            background: rgba(0, 21, 41, 0.9); /* 半透明 */
            color: white; 
            display: flex; 
            flex-direction: column; 
            backdrop-filter: blur(10px); /* 毛玻璃效果 */
            box-shadow: 2px 0 10px rgba(0,0,0,0.3);
        }
        .logo { 
            height: 64px; line-height: 64px; text-align: center; 
            font-size: 20px; font-weight: bold; 
            background: rgba(0, 33, 64, 0.5); 
            letter-spacing: 2px;
        }
        .menu-item { 
            padding: 18px 25px; 
            cursor: pointer; 
            transition: 0.3s; 
            border-left: 4px solid transparent; 
            font-size: 15px;
            display: flex; align-items: center; gap: 10px;
        }
        .menu-item:hover { background: rgba(24, 144, 255, 0.2); }
        .menu-item.active { background: #1890ff; border-left-color: #fff; font-weight: bold; }
        
        .logout { margin-top: auto; padding: 15px 20px; cursor: pointer; background: #d93025; text-align: center; text-decoration: none; color: white; font-weight: bold; }
        .logout:hover { background: #ff4d4f; }

        /* 主内容区 */
        .main-content { 
            flex: 1; padding: 30px; 
            overflow-y: auto; 
            /* 内容区无需背景色，直接透出大背景，但各个Panel需要背景 */
        }
        .panel { 
            display: none; 
            background: rgba(255, 255, 255, 0.95); /* 半透明白底，保证可读性 */
            padding: 30px; 
            border-radius: 12px; 
            box-shadow: 0 4px 20px rgba(0,0,0,0.1); 
            animation: fadeIn 0.3s ease;
        }
        .panel.active { display: block; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

        h2 { margin-top: 0; border-bottom: 2px solid #1890ff; padding-bottom: 15px; color: #333; display: inline-block; }

        /* 表格样式 */
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 15px; text-align: left; border-bottom: 1px solid #eee; }
        th { background: #f7f9fa; font-weight: 600; color: #555; }
        tr:hover { background: #e6f7ff; }
        
        /* 按钮样式 */
        .btn { padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; margin-right: 8px; color: white; font-size: 14px; transition: 0.2s; }
        .btn:hover { opacity: 0.9; transform: translateY(-1px); }
        .btn-primary { background: #1890ff; }
        .btn-danger { background: #ff4d4f; }
        .btn-success { background: #52c41a; }
        .btn-warning { background: #faad14; }

        /* 输入框 */
        input[type="text"], input[type="password"], input[type="number"], select {
            padding: 8px 12px; border: 1px solid #d9d9d9; border-radius: 4px; outline: none; transition: 0.2s;
        }
        input:focus { border-color: #1890ff; box-shadow: 0 0 0 2px rgba(24, 144, 255, 0.2); }

        /* 弹窗样式 */
        .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.6); justify-content: center; align-items: center; z-index: 1000; backdrop-filter: blur(3px); }
        .modal-box { background: white; padding: 25px; border-radius: 8px; width: 400px; position: relative; box-shadow: 0 10px 30px rgba(0,0,0,0.2); }
        .modal-close { position: absolute; top: 10px; right: 15px; cursor: pointer; font-size: 24px; color: #999; transition: 0.2s; }
        .modal-close:hover { color: #333; }
        
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; margin-bottom: 8px; color: #666; font-weight: bold; }
        .form-group input, .form-group select { width: 100%; box-sizing: border-box; }
        
        /* 宽弹窗 */
        .modal-box.wide { width: 900px; display: flex; gap: 30px; }
        .game-list-scroll { max-height: 500px; overflow-y: auto; flex: 1; padding-right: 10px; }
        .canvas-area { width: 420px; display: flex; flex-direction: column; align-items: center; background: #fafafa; padding: 15px; border-radius: 8px; }
    </style>
</head>
<body>

    <div class="sidebar">
        <div class="logo">🏁 五子棋后台管理</div>
        <!-- 调整顺序：查 -> 增 -> 改 -> 删 -->
        <div class="menu-item active" onclick="switchTab('read')">📊 查看玩家数据</div>
        <div class="menu-item" onclick="switchTab('create')">➕ 增加玩家/对局</div>
        <div class="menu-item" onclick="switchTab('update')">📝 修改玩家信息</div>
        <div class="menu-item" onclick="switchTab('delete')">🗑️ 删除玩家/对局</div>
        <a href="index.jsp" class="logout">退出登录</a>
    </div>

    <div class="main-content">
        <!-- 1. 查看玩家数据 -->
        <div id="panel-read" class="panel active">
            <h2>查看玩家数据</h2>
            <div style="margin-bottom: 15px; color: #666;">您可以查看所有注册玩家的基本信息，并深入查看其详细对局记录。</div>
            <button class="btn btn-primary" onclick="loadAllPlayers()">🔄 刷新列表</button>
            <table id="read_table">
                <thead><tr><th>用户名</th><th>密码</th><th>等级</th><th>操作</th></tr></thead>
                <tbody></tbody>
            </table>
        </div>

        <!-- 2. 增加玩家/对局 -->
        <div id="panel-create" class="panel">
            <h2>增加数据</h2>
            <div style="display: flex; gap: 30px;">
                <div style="flex: 1; background: #f9f9f9; padding: 20px; border-radius: 8px;">
                    <h3 style="margin-top:0; color:#1890ff;">新增玩家</h3>
                    <div class="form-group"><label>用户名</label><input type="text" id="add_u" placeholder="设置用户名"></div>
                    <div class="form-group"><label>密码</label><input type="text" id="add_p" placeholder="设置密码"></div>
                    <div class="form-group"><label>初始等级</label><input type="number" id="add_l" value="1"></div>
                    <button class="btn btn-primary" style="width:100%" onclick="doAddPlayer()">提交</button>
                </div>
                <div style="flex: 1; background: #f9f9f9; padding: 20px; border-radius: 8px;">
                    <h3 style="margin-top:0; color:#52c41a;">新增对局记录</h3>
                    <div class="form-group"><label>目标玩家用户名</label><input type="text" id="add_game_u"></div>
                    <div class="form-group">
                        <label>胜负结果</label>
                        <select id="add_game_win">
                            <option value="1">玩家赢 (Win)</option>
                            <option value="2">AI赢 (Lose)</option>
                        </select>
                    </div>
                    <div style="margin-top: 20px; font-size: 12px; color: #999;">注：系统会自动查询该玩家当前最大对局数并顺延 +1。</div>
                    <button class="btn btn-success" style="width:100%; margin-top:10px;" onclick="doAddGame()">提交</button>
                </div>
            </div>
        </div>

        <!-- 3. 修改玩家信息 -->
        <div id="panel-update" class="panel">
            <h2>修改玩家信息</h2>
            <div style="background: #fffbe6; border: 1px solid #ffe58f; padding: 10px; margin-bottom: 20px; border-radius: 4px; color: #d48806;">
                ⚠️ 警告：修改用户名是一项高风险操作，系统会自动迁移该玩家的所有历史对局记录。
            </div>
            <div style="display: flex; gap: 10px; margin-bottom: 20px;">
                <input type="text" id="upd_search_u" placeholder="请输入原用户名..." style="width: 300px;">
                <button class="btn btn-primary" onclick="loadForUpdate()">搜索玩家</button>
            </div>
            
            <div id="upd_form" style="display:none; width: 500px; background: #fafafa; padding: 20px; border-radius: 8px;">
                <input type="hidden" id="upd_old_u">
                <div class="form-group"><label>新用户名</label><input type="text" id="upd_new_u"></div>
                <div class="form-group"><label>密码</label><input type="text" id="upd_p"></div>
                <div class="form-group"><label>等级</label><input type="number" id="upd_l"></div>
                <button class="btn btn-warning" style="width:100%" onclick="doUpdatePlayer()">保存修改</button>
            </div>
        </div>

        <!-- 4. 删除玩家/对局 -->
        <div id="panel-delete" class="panel">
            <h2>删除数据</h2>
            <p style="color:#666;">您可以完全注销一个账号，或者仅撤销某一场异常的对局记录（后续局号会自动前移）。</p>
            <div style="display: flex; gap: 10px; margin-bottom: 20px;">
                <input type="text" id="del_search_u" placeholder="输入用户名..." style="width: 300px;">
                <button class="btn btn-primary" onclick="loadForDelete()">搜索玩家</button>
            </div>
            
            <div id="del_result" style="display:none;">
                <div style="background: #fff1f0; border: 1px solid #ffa39e; padding: 15px; margin-bottom: 20px; border-radius: 4px; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <strong style="color: #cf1322; font-size: 16px;">危险操作区</strong>
                        <div style="font-size: 12px; color: #cf1322;">将永久删除该玩家及其所有对局、步数数据。</div>
                    </div>
                    <button class="btn btn-danger" onclick="doDeletePlayer()">🗑️ 确认销号</button>
                </div>
                
                <h3>该玩家的对局列表 <span style="font-size:12px; font-weight:normal; color:#999;">(点击右侧按钮删除单局)</span></h3>
                <table id="del_game_table">
                    <thead><tr><th>ID</th><th>时间</th><th>结果</th><th>操作</th></tr></thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- 查：查看对局详情弹窗 -->
    <div id="modal-games" class="modal">
        <div class="modal-box wide">
            <span class="modal-close" onclick="closeModal('modal-games')">×</span>
            <div class="game-list-scroll">
                <h3 style="border-bottom: 1px solid #eee; padding-bottom: 10px;"><span id="view_u_title"></span> 的对局记录</h3>
                <table id="view_game_table">
                    <thead><tr><th>ID</th><th>时间</th><th>结果</th><th>操作</th></tr></thead>
                    <tbody></tbody>
                </table>
            </div>
            <div class="canvas-area">
                <h4 style="margin-top:0;">对局详情</h4>
                <div id="canvas-placeholder" style="color:#999; margin-top: 100px;">点击左侧“详情”按钮显示棋盘</div>
                <canvas id="adminBoard" width="400" height="400" style="display:none; background:#DEB887; border-radius:4px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"></canvas>
            </div>
        </div>
    </div>

<script>
    // --- 基础 UI 逻辑 ---
    function switchTab(tabName) {
        document.querySelectorAll('.menu-item').forEach(el => el.classList.remove('active'));
        event.target.classList.add('active');
        document.querySelectorAll('.panel').forEach(el => el.classList.remove('active'));
        document.getElementById('panel-' + tabName).classList.add('active');
        
        // 如果切到“查”页面，自动刷新
        if (tabName === 'read') loadAllPlayers();
    }
    
    function closeModal(id) { document.getElementById(id).style.display = 'none'; }

    // --- API 封装 (保留之前的错误处理逻辑) ---
    async function api(action, params = {}) {
        const query = new URLSearchParams({ action, ...params }).toString();
        const res = await fetch('admin?' + query, { method: 'POST' });
        if (!res.ok) {
            try {
                const errJson = await res.json();
                alert("操作失败: " + errJson.error);
            } catch (e) {
                alert("操作失败: " + res.statusText);
            }
            throw new Error(res.statusText);
        }
        return res.json();
    }

    // --- 增 ---
    async function doAddPlayer() {
        const u = document.getElementById('add_u').value;
        const p = document.getElementById('add_p').value;
        const l = document.getElementById('add_l').value;
        if(!u || !p) return alert("请填写完整");
        await api('addPlayer', { username: u, password: p, level: l });
        alert('添加成功');
        document.getElementById('add_u').value = '';
    }
    async function doAddGame() {
        const u = document.getElementById('add_game_u').value;
        const win = document.getElementById('add_game_win').value;
        if(!u) return alert("请填写用户名");
        await api('addGame', { username: u, isWin: win });
        alert('添加对局成功');
    }

    // --- 删 ---
    let currentDelUser = '';
    async function loadForDelete() {
        currentDelUser = document.getElementById('del_search_u').value;
        if(!currentDelUser) return alert("请输入用户名");
        try {
            const games = await api('getGames', { username: currentDelUser });
            document.getElementById('del_result').style.display = 'block';
            const tbody = document.querySelector('#del_game_table tbody');
            if (games.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; color:#999;">该玩家暂无对局记录</td></tr>';
            } else {
                tbody.innerHTML = games.map(g => `
                    <tr>
                        <td>\${g.game_count}</td>
                        <td>\${g.time}</td>
                        <td>\${g.is_win==1?'<span style="color:green">胜</span>':(g.is_win==2?'<span style="color:red">负</span>':'平局')}</td>
                        <td><button class="btn btn-danger" onclick="doDeleteGame(\${g.game_count})">删除本局</button></td>
                    </tr>
                `).join('');
            }
        } catch(e) {
            // 用户可能不存在，API会报错，这里可以处理一下
        }
    }
    async function doDeletePlayer() {
        if(!confirm('确定删除该玩家吗？不可恢复！')) return;
        await api('deletePlayer', { username: currentDelUser });
        alert('删除成功');
        document.getElementById('del_result').style.display = 'none';
        document.getElementById('del_search_u').value = '';
    }
    async function doDeleteGame(id) {
        if(!confirm('确定删除第 ' + id + ' 局吗？后续局号将前移！')) return;
        await api('deleteGame', { username: currentDelUser, gameId: id });
        alert('删除成功');
        loadForDelete(); // 刷新
    }

    // --- 改 ---
    async function loadForUpdate() {
        const u = document.getElementById('upd_search_u').value;
        if(!u) return alert("请输入用户名");
        const players = await api('listPlayers');
        const p = players.find(x => x.username === u);
        if (p) {
            document.getElementById('upd_form').style.display = 'block';
            document.getElementById('upd_old_u').value = p.username;
            document.getElementById('upd_new_u').value = p.username;
            document.getElementById('upd_p').value = p.password;
            document.getElementById('upd_l').value = p.level;
        } else {
            alert('未找到该玩家');
            document.getElementById('upd_form').style.display = 'none';
        }
    }
    async function doUpdatePlayer() {
        const oldU = document.getElementById('upd_old_u').value;
        const newU = document.getElementById('upd_new_u').value;
        const p = document.getElementById('upd_p').value;
        const l = document.getElementById('upd_l').value;
        await api('updatePlayer', { oldUsername: oldU, newUsername: newU, newPassword: p, newLevel: l });
        alert('修改成功');
        document.getElementById('upd_form').style.display = 'none';
        document.getElementById('upd_search_u').value = '';
    }

    // --- 查 ---
    async function loadAllPlayers() {
        const list = await api('listPlayers');
        const tbody = document.querySelector('#read_table tbody');
        tbody.innerHTML = list.map(p => `
            <tr>
                <td>\${p.username}</td>
                <td>\${p.password}</td>
                <td>\${p.level}</td>
                <td><button class="btn btn-primary" onclick="viewPlayerGames('\${p.username}')">查看对局</button></td>
            </tr>
        `).join('');
    }

    async function viewPlayerGames(u) {
        document.getElementById('modal-games').style.display = 'flex';
        document.getElementById('view_u_title').innerText = u;
        // 清空旧画板
        document.getElementById('canvas-placeholder').style.display = 'block';
        document.getElementById('adminBoard').style.display = 'none';
        
        const games = await api('getGames', { username: u });
        const tbody = document.querySelector('#view_game_table tbody');
        if (games.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; color:#999;">暂无记录</td></tr>';
        } else {
            tbody.innerHTML = games.map(g => `
                <tr>
                    <td>\${g.game_count}</td>
                    <td>\${g.time}</td>
                    <td>\${g.is_win==1?'<span style="color:green">胜</span>':(g.is_win==2?'<span style="color:red">负</span>':'平局')}</td>
                    <td><button class="btn btn-success" onclick="viewReplay('\${u}', \${g.game_count})">详情</button></td>
                </tr>
            `).join('');
        }
    }

    // --- 棋盘绘制逻辑 ---
    async function viewReplay(u, id) {
        document.getElementById('canvas-placeholder').style.display = 'none';
        const canvas = document.getElementById('adminBoard');
        canvas.style.display = 'block';
        const ctx = canvas.getContext('2d');
        const steps = await api('getGameSteps', { username: u, gameId: id });
        
        // 画盘
        ctx.clearRect(0, 0, 400, 400);
        ctx.strokeStyle = "#000";
        const gridSize = 400 / 15; 
        const offset = gridSize / 2;
        
        for (let i = 0; i < 15; i++) {
            ctx.beginPath(); ctx.moveTo(offset + i * gridSize, offset); ctx.lineTo(offset + i * gridSize, 400-offset); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(offset, offset + i * gridSize); ctx.lineTo(400-offset, offset + i * gridSize); ctx.stroke();
        }

        // 画子
        steps.forEach((s, idx) => {
            const x = s.x; 
            const y = s.y; 
            const cx = offset + y * gridSize;
            const cy = offset + x * gridSize;
            
            ctx.beginPath();
            ctx.arc(cx, cy, gridSize/2 - 2, 0, 2 * Math.PI);
            ctx.fillStyle = (s.who === 1) ? "black" : "white";
            ctx.fill();
            if(s.who === 2) { ctx.strokeStyle = "#ddd"; ctx.stroke(); }
            
            // 显示手数
            ctx.fillStyle = (s.who === 1) ? "white" : "black";
            ctx.font = "10px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText(idx + 1, cx, cy);
        });
    }
    
    // 页面加载时自动加载列表
    loadAllPlayers();
</script>
</body>
</html>
