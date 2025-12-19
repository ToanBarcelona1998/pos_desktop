const offlineHtml = '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Mất kết nối</title>
  <style>
    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      height: 100vh;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI",
        Roboto, Helvetica, Arial, sans-serif;
      background: linear-gradient(135deg, #f5f7fa, #e4ebf5);
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .screen {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 32px;
    }

    .content {
      max-width: 480px;
      width: 100%;
      text-align: center;
    }

    .icon {
      font-size: 72px;
      margin-bottom: 20px;
    }

    h1 {
      font-size: 26px;
      margin: 0 0 12px;
      color: #333333;
    }

    p {
      font-size: 16px;
      line-height: 1.6;
      color: #666666;
      margin: 0 0 32px;
    }

    button {
      padding: 14px 36px;
      font-size: 16px;
      font-weight: 600;
      border-radius: 10px;
      border: none;
      cursor: pointer;
      background-color: #1976d2;
      color: #ffffff;
      transition: background-color 0.2s ease, transform 0.1s ease;
    }

    button:hover {
      background-color: #155fa0;
    }

    button:active {
      transform: scale(0.97);
    }

    .hint {
      margin-top: 24px;
      font-size: 14px;
      color: #999999;
    }
  </style>
</head>
<body>
  <div class="screen">
    <div class="content">
      <div class="icon">📡</div>
      <h1>Mất kết nối Internet</h1>
      <p>
        Không thể kết nối đến máy chủ.<br />
        Vui lòng kiểm tra lại Wi-Fi hoặc đường truyền Internet của bạn.
      </p>
      <div class="hint">
        Hệ thống sẽ tự động hoạt động khi có kết nối trở lại.
      </div>
    </div>
  </div>
</body>
</html>
''';