<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>五子棋 - 登录/注册</title>
    <style>
        body { 
            font-family: "Microsoft YaHei"; 
            text-align: center; 
            padding-top: 50px; 
            /* 背景设置 */
            background-image: url('picture/flame_bg.jpg');
            background-size: cover;       /* 填满屏幕 */
            background-position: center;  /* 居中 */
            background-attachment: fixed; /* 滚动时背景不动 */
            background-repeat: no-repeat;
        }
        /* 为了让文字在深色背景上更清晰，可能需要调整一下 */
        h1 { color: white; text-shadow: 2px 2px 4px rgba(0,0,0,0.8); margin-bottom: 40px; }
        
        .container { width: 800px; margin: 0 auto; display: flex; justify-content: space-around; }
        .box { background: rgba(255, 255, 255, 0.95); padding: 30px; border-radius: 10px; box-shadow: 0 0 15px rgba(0,0,0,0.5); width: 300px; }
        h2 { margin-top: 0; color: #333; }
        input { width: 90%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; }
        button { width: 100%; padding: 10px; background-color: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
        /* 故事卡片样式 */
        .story-box {
            width: 800px; 
            margin: 0 auto 30px; 
            color: #333; 
            line-height: 1.8; 
            text-align: center; 
            background: rgba(255, 255, 255, 0.9); 
            padding: 25px; 
            border-radius: 12px; 
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
            transition: all 0.3s ease; /* 动画过渡 */
            border-left: 5px solid #FF9800;
        }
        
        /* 鼠标悬停效果 */
        .story-box:hover {
            transform: translateY(-5px) scale(1.02); /* 上浮并微放大 */
            background: rgba(255, 255, 255, 1); /* 变不透明 */
            box-shadow: 0 10px 25px rgba(0,0,0,0.5); /* 阴影加深 */
            border-left-color: #FF5722; /* 边框变色 */
        }

        /* 关键文字高亮 */
        .key-word {
            font-weight: bold;
            font-size: 1.2em; /* 放大 */
            color: #d32f2f;   /* 醒目红 */
            margin: 0 3px;
        }
        .key-word.level { color: #2196F3; }
        .key-word.title { color: #FF9800; text-shadow: 0 0 2px rgba(255,152,0,0.3); }
    </style>
</head>
<body>
    <h1>五子棋在线对战</h1>
    
    <div class="story-box">
        <p style="margin: 0;">
            你意外掉进了神秘的 <span class="key-word">五子棋王国</span>。<br>
            在这里，只有不断 <span class="key-word">磨练棋艺</span>，战胜各路 AI 高手，才能提升你的 <span class="key-word level">Level</span>。<br>
            从“初出茅庐”到“天下无双”，至高无上的荣耀 <span class="key-word title">头衔</span> 正在等待它的主人……<br>
            现在，快登录进行对战吧！
        </p>
    </div>
    
    <div class="container">
        <!-- 登录框 -->
        <div class="box">
            <h2>登录</h2>
            <form action="user?action=login" method="post">
                <input type="text" name="username" placeholder="请输入用户名" required>
                <input type="password" name="password" placeholder="请输入密码" required>
                
                <div style="margin: 15px 0; display: flex; align-items: center; justify-content: center; gap: 20px;">
                    <label style="cursor: pointer; display: flex; align-items: center;">
                        <input type="radio" name="role" value="player" checked style="width: auto; margin-right: 5px;"> 
                        <span>玩家</span>
                    </label>
                    <label style="cursor: pointer; display: flex; align-items: center;">
                        <input type="radio" name="role" value="admin" style="width: auto; margin-right: 5px;"> 
                        <span>管理员</span>
                    </label>
                </div>

                <button type="submit">立即登录</button>
            </form>
        </div>

        <!-- 注册框 -->
        <div class="box">
            <h2>注册新账号</h2>
            <form action="user?action=register" method="post">
                <input type="text" name="username" placeholder="设置用户名" required>
                <input type="password" name="password" placeholder="设置密码" required>
                <button type="submit" class="register-btn">注册账号</button>
            </form>
        </div>
    </div>
</body>
</html>

