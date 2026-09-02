package email

import (
	"context"
	"fmt"
	"net"
	"net/smtp"
	"strings"
	"time"

	"github.com/nextdms/authservice/internal/domain/entity"
	"go.uber.org/zap"
)

// SMTPClient gửi email qua SMTP
type SMTPClient struct {
	cfg    SMTPConfig
	logger *zap.Logger
}

func NewSMTPClient(cfg SMTPConfig, logger *zap.Logger) *SMTPClient {
	return &SMTPClient{cfg: cfg, logger: logger}
}

func (c *SMTPClient) Send(ctx context.Context, ev *entity.EmailEvent) error {
	body, err := c.renderTemplate(ev)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}
	addr := fmt.Sprintf("%s:%d", c.cfg.Host, c.cfg.Port)
	auth := smtp.PlainAuth("", c.cfg.Username, c.cfg.Password, c.cfg.Host)
	from := c.cfg.FromAddr
	if c.cfg.FromName != "" {
		from = fmt.Sprintf("%s <%s>", c.cfg.FromName, c.cfg.FromAddr)
	}
	msg := buildMimeMessage(from, ev.To, ev.Subject, body)

	dialer := &net.Dialer{Timeout: 10 * time.Second}
	conn, err := dialer.DialContext(ctx, "tcp", addr)
	if err != nil {
		return fmt.Errorf("smtp dial: %w", err)
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, c.cfg.Host)
	if err != nil {
		return fmt.Errorf("smtp client: %w", err)
	}
	defer client.Quit()

	if c.cfg.UseTLS {
		if ok, _ := client.Extension("STARTTLS"); ok {
			if err := client.StartTLS(nil); err != nil {
				return fmt.Errorf("starttls: %w", err)
			}
		}
	}
	if c.cfg.Username != "" {
		if err := client.Auth(auth); err != nil {
			return fmt.Errorf("smtp auth: %w", err)
		}
	}
	if err := client.Mail(c.cfg.FromAddr); err != nil {
		return fmt.Errorf("smtp mail: %w", err)
	}
	if err := client.Rcpt(ev.To); err != nil {
		return fmt.Errorf("smtp rcpt: %w", err)
	}
	w, err := client.Data()
	if err != nil {
		return fmt.Errorf("smtp data: %w", err)
	}
	if _, err := w.Write([]byte(msg)); err != nil {
		return fmt.Errorf("smtp write: %w", err)
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("smtp close: %w", err)
	}
	c.logger.Info("email sent", zap.String("to", ev.To), zap.String("event", ev.EventType))
	return nil
}

func (c *SMTPClient) renderTemplate(ev *entity.EmailEvent) (string, error) {
	switch ev.Template {
	case "forgot_password_otp":
		return forgotPasswordOTPTemplate(ev), nil
	case "password_changed":
		return passwordChangedTemplate(ev), nil
	default:
		return defaultTemplate(ev), nil
	}
}

func forgotPasswordOTPTemplate(ev *entity.EmailEvent) string {
	return fmt.Sprintf(`
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Reset Password</title></head>
<body style="font-family:Arial,sans-serif;background:#f5f5f5;padding:20px">
<div style="max-width:600px;margin:0 auto;background:#fff;border-radius:12px;padding:30px;box-shadow:0 2px 10px rgba(0,0,0,0.1)">
  <h2 style="color:#1976d2;margin-top:0">🔐 Đặt lại mật khẩu</h2>
  <p>Xin chào <strong>%s</strong>,</p>
  <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Sử dụng mã OTP dưới đây để xác nhận:</p>
  <div style="background:#f0f4f8;padding:20px;text-align:center;border-radius:8px;margin:20px 0">
    <span style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#1976d2">%s</span>
  </div>
  <p>⏱️ Mã có hiệu lực trong <strong>%d phút</strong>.</p>
  <p>📍 Yêu cầu từ IP: <code>%s</code></p>
  <p style="color:#d32f2f">⚠️ Nếu bạn không yêu cầu, vui lòng bỏ qua email này.</p>
  <hr style="border:none;border-top:1px solid #eee;margin:20px 0">
  <p style="color:#999;font-size:12px">© DMS Sales Automation</p>
</div>
</body></html>`, ev.Data.FullName, ev.Data.OTPCode, ev.Data.ExpiresInMin, ev.Data.IPAddress)
}

func passwordChangedTemplate(ev *entity.EmailEvent) string {
	return fmt.Sprintf(`
<div style="max-width:600px;margin:0 auto;background:#fff;padding:30px;border-radius:12px">
  <h2 style="color:#2e7d32">✅ Mật khẩu đã được thay đổi</h2>
  <p>Xin chào <strong>%s</strong>,</p>
  <p>Mật khẩu của bạn đã được thay đổi thành công lúc %s.</p>
  <p style="color:#d32f2f">Nếu không phải bạn thực hiện, vui lòng liên hệ admin ngay.</p>
</div>`, ev.Data.FullName, time.Now().Format("02/01/2006 15:04:05"))
}

func defaultTemplate(ev *entity.EmailEvent) string {
	return fmt.Sprintf("<p>%s</p>", ev.Subject)
}

func buildMimeMessage(from, to, subject, htmlBody string) string {
	var b strings.Builder
	b.WriteString(fmt.Sprintf("From: %s\r\n", from))
	b.WriteString(fmt.Sprintf("To: %s\r\n", to))
	b.WriteString(fmt.Sprintf("Subject: %s\r\n", subject))
	b.WriteString("MIME-Version: 1.0\r\n")
	b.WriteString("Content-Type: text/html; charset=UTF-8\r\n")
	b.WriteString("\r\n")
	b.WriteString(htmlBody)
	return b.String()
}
