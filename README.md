# flutter_application_1

Flutter 示例项目。

## 启动

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 查看可用设备

```bash
flutter devices
```

当前环境里已确认可用的目标包括：

- Windows
- Chrome
- Edge

### 3. 启动项目

#### 推荐：本地 Web Server

这个方式在当前机器上已验证可启动。

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --no-web-resources-cdn
```

启动后访问：`http://127.0.0.1:8080`

#### 直接跑浏览器

如果本机浏览器调试连接正常，可以使用：

```bash
flutter run -d chrome --no-web-resources-cdn
```

或：

```bash
flutter run -d edge --no-web-resources-cdn
```

### 4. 热重载常用命令

启动后在终端内可用：

- `r`：Hot reload
- `R`：Hot restart
- `q`：退出运行

## 已知限制

### Windows 桌面端

当前机器直接运行：

```bash
flutter run -d windows
```

会因为缺少 Visual Studio C++ toolchain 失败。需要先安装带有 Desktop development with C++ 工作负载的 Visual Studio，再执行：

```bash
flutter doctor
```

确认环境通过后再启动 Windows 桌面端。

## 参考

- [Flutter 文档](https://docs.flutter.dev/)
