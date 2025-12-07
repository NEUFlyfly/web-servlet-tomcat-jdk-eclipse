package com.gobang.servlet;

import com.gobang.util.DBUtil;
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

@WebServlet("/user")
public class UserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // 设置编码，防止中文乱码
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");
        
        String action = request.getParameter("action");
        
        if ("register".equals(action)) {
            handleRegister(request, response);
        } else if ("login".equals(action)) {
            handleLogin(request, response);
        }
    }

    // 处理注册
    private void handleRegister(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String u = request.getParameter("username");
        String p = request.getParameter("password");
        
        try (Connection conn = DBUtil.getConnection()) {
            // 检查用户是否已存在
            String checkSql = "SELECT username FROM Player WHERE username = ?";
            PreparedStatement checkPs = conn.prepareStatement(checkSql);
            checkPs.setString(1, u);
            ResultSet rs = checkPs.executeQuery();
            if (rs.next()) {
                response.getWriter().write("<script>alert('注册失败：用户名已存在'); window.location='index.jsp';</script>");
                return;
            }
            
            // 插入新用户，默认等级 1
            String sql = "INSERT INTO Player (username, password, level) VALUES (?, ?, 1)";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, u);
            ps.setString(2, p);
            ps.executeUpdate();
            
            // 注册成功，跳回首页让用户登录
            response.getWriter().write("<script>alert('注册成功！请登录'); window.location='index.jsp';</script>");
            
        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("<script>alert('数据库错误'); window.location='index.jsp';</script>");
        }
    }

    // 处理登录
    private void handleLogin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String u = request.getParameter("username");
        String p = request.getParameter("password");
        String role = request.getParameter("role");

        // --- 1. 管理员登录逻辑 ---
        if ("admin".equals(role)) {
            if ("admin".equals(u) && "admin".equals(p)) {
                HttpSession session = request.getSession();
                session.setAttribute("isAdmin", true);
                session.setAttribute("currentUser", "Administrator");
                response.sendRedirect("admin.jsp");
            } else {
                response.getWriter().write("<script>alert('管理员账号或密码错误！'); window.location='index.jsp';</script>");
            }
            return;
        }

        // --- 2. 玩家登录逻辑 ---
        // 严禁玩家使用 admin 账号登录
        if ("admin".equals(u)) {
             response.getWriter().write("<script>alert('该账号为管理员账号，请选择【管理员】身份登录'); window.location='index.jsp';</script>");
             return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            String sql = "SELECT * FROM Player WHERE username = ? AND password = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, u);
            ps.setString(2, p);
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                // 登录成功！
                // 1. 把用户信息存入 Session
                HttpSession session = request.getSession();
                session.setAttribute("currentUser", u);
                session.setAttribute("currentLevel", rs.getInt("level"));
                
                // 2. 跳转到玩家大厅页面
                response.sendRedirect("player.jsp");
            } else {
                // 登录失败
                response.getWriter().write("<script>alert('登录失败：账号或密码错误'); window.location='index.jsp';</script>");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("<script>alert('系统错误'); window.location='index.jsp';</script>");
        }
    }
}


