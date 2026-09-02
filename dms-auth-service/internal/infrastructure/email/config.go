package email

type SMTPConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	FromName string
	FromAddr string
	UseTLS   bool
}

func DefaultSMTPConfig() SMTPConfig {
	return SMTPConfig{
		Host:     "smtp.gmail.com",
		Port:     587,
		Username: "",
		Password: "",
		FromName: "DMS Sales",
		FromAddr: "noreply@dms.local",
		UseTLS:   true,
	}
}
